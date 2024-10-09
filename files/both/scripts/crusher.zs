import mods.create.CrushingManager;

// CrushingManager.addRecipe(name as string, output as Percentaged<IItemStack>[], input as IIngredient, duration as int)

<recipetype:create:crushing>.removeByInput(<item:minecraft:raw_iron>);
<recipetype:create:crushing>.addRecipe("crushed_iron", [<item:create:crushed_raw_iron> * 2, <item:create:experience_nugget> % 75], <item:minecraft:raw_iron>, 100);

<recipetype:create:crushing>.removeByInput(<item:minecraft:raw_copper>);
<recipetype:create:crushing>.addRecipe("crushed_copper", [<item:create:crushed_raw_copper> * 2, <item:create:experience_nugget> % 75], <item:minecraft:raw_copper>, 100);

<recipetype:create:crushing>.removeByInput(<item:minecraft:raw_gold>);
<recipetype:create:crushing>.addRecipe("crushed_gold", [<item:create:crushed_raw_gold> * 2, <item:create:experience_nugget> % 75], <item:minecraft:raw_gold>, 100);

<recipetype:create:crushing>.removeByInput(<item:create:raw_zinc>);
<recipetype:create:crushing>.addRecipe("crushed_zinc", [<item:create:crushed_raw_zinc> * 2, <item:create:experience_nugget> % 75], <item:create:raw_zinc>, 100);
ß