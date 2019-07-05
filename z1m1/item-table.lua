local itemTable = {};

itemTable[0x0] = {desc = "a bomb pack", game = 0, addr = 0x0658, kind = "add", toAdd = 4 };
itemTable[0x1] = {desc = "the wood sword", game = 0, addr = 0x0657, value = 1, kind = "high" };
itemTable[0x2] = {desc = "the white sword", game = 0, addr = 0x0657, value = 2, kind = "high" };
itemTable[0x3] = {desc = "the magical sword", game = 0, addr = 0x0657, value = 3, kind = "high" };
itemTable[0x4] = {desc = "bait", game = 0, addr = 0x065d, value = 1, kind = "high" };
itemTable[0x5] = {desc = "the recorder", game = 0, addr = 0x065f, value = 1, kind = "high" };
itemTable[0x6] = {desc = "the blue candle", game = 0, addr = 0x065b, value = 1, kind = "high" };
itemTable[0x7] = {desc = "the red candle", game = 0, addr = 0x065b, value = 2, kind = "high" };
itemTable[0x8] = {desc = "wooden arrows", game = 0, addr = 0x0659, value = 1, kind = "high" };
itemTable[0x9] = {desc = "silver arrows", game = 0, addr = 0x0659, value = 2, kind = "high" };
itemTable[0xA] = {desc = "the bow", game = 0, addr = 0x065a, value = 1, kind = "high" };
itemTable[0xB] = {desc = "the magical key", game = 0, addr = 0x0664, value = 1, kind = "high" };
itemTable[0xC] = {desc = "the raft", game = 0, addr = 0x0660, value = 1, kind = "high" };
itemTable[0xD] = {desc = "the stepladder", game = 0, addr = 0x0663, value = 1, kind = "high" };
itemTable[0xE] = {desc = "the triforce of power", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0xF] = {desc = "a blue rupee", game = 0, addr = 0x066d, kind = "add", toAdd = 5 };
itemTable[0x10] = {desc = "the magical rod", game = 0, addr = 0x065f, value = 1, kind = "high" };
itemTable[0x11] = {desc = "the book", game = 0, addr = 0x0661, value = 1, kind = "high" };
itemTable[0x12] = {desc = "the blue ring", game = 0, addr = 0x0662, value = 1, kind = "high" };
itemTable[0x13] = {desc = "the red ring", game = 0, addr = 0x0662, value = 2, kind = "high" };
itemTable[0x14] = {desc = "the power bracelet", game = 0, addr = 0x0665, value = 1, kind = "high" };
itemTable[0x15] = {desc = "the letter", game = 0, addr = 0x0666, value = 1, kind = "high" };
itemTable[0x16] = {desc = "a compass (unused)", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x17] = {desc = "a map (unused)", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x18] = {desc = "a yellow rupee", game = 0, addr = 0x066d, kind = "add", toAdd = 1 };
itemTable[0x19] = {desc = "a dungeon key", game = 0, addr = 0x066e, kind = "add", toAdd = 1 };
itemTable[0x1A] = {desc = "a heart container", game = 0, addr = 0x066f, kind = "high-nybble-add", toAdd = 1 };
itemTable[0x1B] = {desc = "a triforce piece (unused)", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x1C] = {desc = "the magical shield", game = 0, addr = 0x0676, value = 1, kind = "high" };
itemTable[0x1D] = {desc = "the wooden boomerang", game = 0, addr = 0x0674, value = 1, kind = "high" };
itemTable[0x1E] = {desc = "the magical boomerang", game = 0, addr = 0x0675, value = 1, kind = "high" };
itemTable[0x1F] = {desc = "a blue potion", game = 0, addr = 0x065e, kind = "add", toAdd = 1 };
itemTable[0x20] = {desc = "a red potion", game = 0, addr = 0x065e, kind = "add", toAdd = 2 };
itemTable[0x21] = {desc = "a clock", game = 0, addr = 0x066c, value = 1, kind = "high" };
itemTable[0x22] = {desc = "a one heart refill", game = 0, addr = 0x066f, kind = "low-nybble-add", toAdd = 1 };
itemTable[0x23] = {desc = "a fairy", game = 0, addr = 0x066f, kind = "low-nybble-add", toAdd = 0xf };
itemTable[0x24] = {desc = "triforce compass #1", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x01 };
itemTable[0x25] = {desc = "triforce compass #2", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x02 };
itemTable[0x26] = {desc = "triforce compass #3", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x04 };
itemTable[0x27] = {desc = "triforce compass #4", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x08 };
itemTable[0x28] = {desc = "triforce compass #5", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x10 };
itemTable[0x29] = {desc = "triforce compass #6", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x20 };
itemTable[0x2A] = {desc = "triforce compass #7", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x40 };
itemTable[0x2B] = {desc = "triforce compass #8", game = 0, addr = 0x0667, value = 1, kind = "bitOr", mask = 0x80 };
itemTable[0x2C] = {desc = "zelda's compass", game = 0, addr = 0x0669, value = 1, kind = "high" }
itemTable[0x2D] = {desc = "hyrule dungeon map #1", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x01 };
itemTable[0x2E] = {desc = "hyrule dungeon map #2", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x02 };
itemTable[0x2F] = {desc = "hyrule dungeon map #3", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x04 };
itemTable[0x30] = {desc = "hyrule dungeon map #4", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x08 };
itemTable[0x31] = {desc = "hyrule dungeon map #5", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x10 };
itemTable[0x32] = {desc = "hyrule dungeon map #6", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x20 };
itemTable[0x33] = {desc = "hyrule dungeon map #7", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x40 };
itemTable[0x34] = {desc = "hyrule dungeon map #8", game = 0, addr = 0x0668, value = 1, kind = "bitOr", mask = 0x80 };
itemTable[0x35] = {desc = "hyrule dungeon map #9", game = 0, addr = 0x066a, value = 1, kind = "high" };
itemTable[0x36] = {desc = "triforce piece #1", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x01 };
itemTable[0x37] = {desc = "triforce piece #2", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x02 };
itemTable[0x38] = {desc = "triforce piece #3", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x04 };
itemTable[0x39] = {desc = "triforce piece #4", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x08 };
itemTable[0x3A] = {desc = "triforce piece #5", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x10 };
itemTable[0x3B] = {desc = "triforce piece #6", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x20 };
itemTable[0x3C] = {desc = "triforce piece #7", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x40 };
itemTable[0x3D] = {desc = "triforce piece #8", game = 0, addr = 0x0671, value = 1, kind = "bitOr", mask = 0x80 };
itemTable[0x3E] = {desc = "a multi heart refill", game = 0, addr = 0x066f, kind = "low-nybble-add", toAdd = 3 };
itemTable[0x3F] = {desc = "a bomb capacity upgrade", game = 0, addr = 0x067c, kind = "high" };
itemTable[0x40] = {desc = "a few rupees", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x41] = {desc = "some rupees", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x42] = {desc = "copious rupees", game = 0, addr = 0x0000, bits = 0xff };
itemTable[0x43] = {desc = "morph ball bombs", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x44] = {desc = "high jump boots", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x45] = {desc = "the long beam", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x46] = {desc = "the screw attack", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x47] = {desc = "the morph ball", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x48] = {desc = "the varia suit", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x49] = {desc = "the wave beam", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4A] = {desc = "the ice beam", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4B] = {desc = "an energy tank", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4C] = {desc = "a missile capacity upgrade", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4D] = {desc = "kraid's totem", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4E] = {desc = "ridley's totem", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x4F] = {desc = "the kraid totem compass", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x50] = {desc = "the ridley totem compass", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x51] = {desc = "the brinstar map", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x52] = {desc = "the norfair map", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x53] = {desc = "the kraid's lair map", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x54] = {desc = "the ridley's hideout map", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x55] = {desc = "a disappointing energy refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x56] = {desc = "a scant energy refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x57] = {desc = "a passable energy refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x58] = {desc = "a comprehensive energy refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x59] = {desc = "a puny missile refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x5A] = {desc = "an understated missile refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x5B] = {desc = "a commonplace missile refill", game = 0, addr = 0x066f, bits = 0xff };
itemTable[0x5C] = {desc = "an engorged missile refill", game = 0, addr = 0x066f, bits = 0xff };

return {
	items = itemTable
};