#!/bin/bash
version="1.0.4"

### init ###
# error detection
set -e
error() {
	echo "ERROR: something went wrong. abandon update." 
	exit 1
}
trap "error" ERR

# extend lua lib path to allocate shipped libraries
export LUA_PATH=$(lua -e "print(package.path)")";./mmmtk/libs/?.lua;./libs/?.lua"

# generate runtime vars
workingDir=$(pwd)
packVersion=$(head -n 1 changelog.txt)
changelog=$(< changelog.txt)
prepGitBlob=""
mainGitBlob=""
versionPrepID=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 25; echo)
versionID=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 25; echo)

skipRepoBranchCheck=0
noRelease=0
noServerUpdate=0
noCleanup=0
noGitPush=0
confFile="pack.conf"

# parse args
help() {
	echo "Usage releasePackUpdate.sh [OPTIONS]"
	echo "Releases the current packwiz pack."
	echo
	echo "Single digit flags have to be passed seperately"
	echo "  -h, --help               print this text and exit."
	echo "  -v, --version            print version text and exit."
	echo "  -c, --conf               specify a conf file (default: pack.conf)."
	echo
	echo "  -G, --no-git-push        skip git pushes and push integrity checks."
	echo "  -U, --no-server-update   do not update server."
	echo "  -R, --no-release         do not publish github release."
	echo "  -S, --skip-main-repo-check  skip main repo integrity check."
	echo "  -C, --no-cleanup         do not delete generatet release files"
	exit 0	
}
while [[ $# -gt 0 ]]; do
	case $1 in
		-c|--conf)
			confFile=$2
			shift
			shift
			;;
		-G|--no-git-push)
			noGitPush=1
			shift
			;;
		-U|--no-server-update)
			noServerUpdate=1
			shift
			;;
		-R|--no-release)
			noRelease=1
			shift
			;;
		-S|--skip-main-repo-check)
			skipRepoBranchCheck=1
			shift
			;;
		-C|--no-cleanup)
			noCleanup=1
			shift
			;;
		-v|--version)
			echo "v${version}"
			shift
			;;
		-h|--help)
			help
			shift
			;;
		-*|--*)
			echo "Unknown option '$1'"
			echo "Try '--help' for help"
			exit 1
			;;
	esac
done

# load conf
. $confFile

### update ###
if [[ $noGitPush == 1 ]]; then
	echo "WARN: Skipping git push and packwiz alias creation"
	mainGitBlob=$(git rev-parse HEAD)
	prepGitBlob=$(git rev-parse HEAD)
else
	echo
	echo "Generate new modlist"
	cd packwiz
	packwiz list > ../modlist.txt
	cd ..
	echo "Copy changelog and modlist for v${packVersion}"
	mkdir -p changelogs
	cp changelog.txt changelogs/changelog_v${packVersion}.txt
	cp modlist.txt changelogs/modlist_v${packVersion}.txt
	
	echo "### push prep to git ###"
	echo $versionPrepID > .versionID
	git add .
	git commit -m "v${packVersion}_prep"
	git push
	prepGitBlob=$(git rev-parse HEAD)
	
	echo
	echo "### Create packwiz aliases ###"
	./mmmtk/createPackwizAliases.sh \
		--pack-url ${packURL}/raw/${prepGitBlob} \
		--input "files" \
		--output "./packwiz" \
		--list-file ".collectedFiles" \
		-R
	
	echo "packwiz refresh"
	cd packwiz
	packwiz refresh
	cd ..
	
	echo
	echo "### push final to git ###"
	echo $versionID > .versionID
	git add .
	git commit -m "v${packVersion}"
	git push
	mainGitBlob=$(git rev-parse HEAD)
fi

### create multimc releases ###
mkdir -p $tmpReleaseFileLocation
touch $tmpReleaseFileLocation/toDelete
rm -r ${tmpReleaseFileLocation}/*

dirName=${packName}-latest_MultiMC
cp -r multimc ${tmpReleaseFileLocation}/$dirName
cd ${tmpReleaseFileLocation}/$dirName
# echo PreLaunchCommand="\$INST_JAVA" -jar packwiz-installer-bootstrap.jar -s client ${packURL}/${branch}/packwiz/pack.toml >> instance.cfg
echo PreLaunchCommand="\$INST_JAVA" -jar update-pack.jar \"\$INST_JAVA\" \"client\" \"${packURL}\" \"${branch}\" >> instance.cfg
cd $workingDir

dirName=${packName}-v${packVersion}_MultiMC
cp -r multimc ${tmpReleaseFileLocation}/$dirName
cd ${tmpReleaseFileLocation}/$dirName
echo PreLaunchCommand="\$INST_JAVA" -jar packwiz-installer-bootstrap.jar -s client ${packURL}/raw/${mainGitBlob}/packwiz/pack.toml >> instance.cfg
cd $workingDir

echo 
if [[ $noRelease == 1 ]]; then
	echo "WARN: Skipping github release"
else
	echo "Create github release"
	./mmmtk/createGithubRelease.sh \
		--upstream "${packAPIURL}/releases" \
		--tag "$packVersion" \
		--name "v$packVersion" \
		--description "$changelog" \
		--branch "$branch" \
		--token "$githubTokenPath" \
		--release-folder "${tmpReleaseFileLocation}" \
		--release-files-only
fi
if [[ $noCleanup == 1 ]]; then
	echo "WARN: Skipping release dir cleanup"
else
	rm -r ${tmpReleaseFileLocation}
fi

wait() {
	while [[ $(wget -qO- $2) != $3 ]]; do	
		echo $1
		sleep 30
	done
}
if [[ $noGitPush == 1 ]]; then
	echo "WARN: Skipping repository check because no git push happened"
else
	echo "Check prep repository integrity (${prepGitBlob}, ${versionPrepID})"
	wait "Prep repository not updated yet. Wait another 30 seconds" ${packURL}/raw/${prepGitBlob}/.versionID $versionPrepID
	echo "Check main repository integrity (${mainGitBlob}, ${versionID})"
	wait "Main repository not updated yet. Wait another 30 seconds" ${packURL}/raw/${mainGitBlob}/.versionID $versionID
	if [[ $skipRepoBranchCheck == 1 ]]; then
		echo "Skipping branch check"
	else
		echo "Check repository branch integrity (${branch}, ${versionID})"
		wait "$branch branch not updated yet. Wait another 30 seconds" ${packURL}/raw/${branch}/.versionID $versionID
	fi
fi
	
if [[ $noServerUpdate == 1 ]]; then
	echo "WARN: Skipping server update"
else
	echo
	echo "### Update server ###"
	./mmmtk/updateServer.sh \
	   --server-id $serverID \
	   --pterodactyl-url $pterodactylURL \
	   --pack-url "${packURL}/raw/${mainGitBlob}/packwiz/pack.toml" \
	   --token $pterodactylTokenPath \
	   --ssh-args="-i $sshKeyPath $sshTarget $sshArgs" \
	   --update-script-args="$updateScriptArgs" \
		--restart-msg="Server restart for pack update in:"
fi

echo Done
