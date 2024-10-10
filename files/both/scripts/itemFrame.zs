//Here you can see, that you can use <item:minecraft:air> for an empty slot
//You can also see that this recipe only uses two rows. This means you can either craft this recipe in the first and second row in the crafting grid, or the second and third row.
craftingTable.addShaped("item_frame_from_wool_iron_nugget", <item:minecraft:item_frame>, [
	[<item:minecraft:stick>, <item:minecraft:iron_nugget>, <item:minecraft:stick>], 
	[<item:minecraft:stick>, <tag:items:minecraft:wool>, <item:minecraft:stick>],
	[<item:minecraft:stick>, <item:minecraft:stick>, <item:minecraft:stick>]
]);

craftingTable.addShaped("item_frame_from_wool_copper_nugget", <item:minecraft:item_frame>, [
	[<item:minecraft:stick>, <item:create:copper_nugget>, <item:minecraft:stick>], 
	[<item:minecraft:stick>, <tag:items:minecraft:wool>, <item:minecraft:stick>],
	[<item:minecraft:stick>, <item:minecraft:stick>, <item:minecraft:stick>]
]);
