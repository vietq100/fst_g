class_name ItemIcons
extends RefCounted
## 12×12 pixel-art item icons drawn from text bitmaps (like PixelIcons), picked by the item's type
## and id and tinted with its `tint` (T = tint, t = tint shadow). Cached per kind, tint and scale.

const SIZE := 12

const PALETTE := {
	"k": Color("2a1c10"), "L": Color("ffffff"), "b": Color("8b5e3c"), "B": Color("5a3b22"), "y": Color("f2c94c"),
	"w": Color("f4f1ea"), "g": Color("6fbf5f"), "G": Color("3f8a3a"), "r": Color("c9503f"), "p": Color("e8b98a"),
	"s": Color("9aa0a6"), "S": Color("5d5a55"), "l": Color("5fa8ff"), "o": Color("e0874a"), "v": Color("a78bfa"),
	"V": Color("6b3b8c"),
}
## Default tint for kinds whose item has none (white = untinted).
const KIND_TINT := {
	&"sword": Color("c8d0d8"), &"dagger": Color("c8d0d8"), &"bow": Color("8b5e3c"), &"mace": Color("b8bcc4"),
	&"armor": Color("b8bcc4"), &"potion": Color("ff6b7a"), &"helmet": Color("b8bcc4"), &"pants": Color("8b5e3c"),
	&"boots": Color("8b5e3c"), &"necklace": Color("5fa8ff"), &"charm": Color("a78bfa"), &"skin": Color("c9503f"), &"pet": Color("c8925a"),
}

const BITMAPS := {
	&"helmet": [
		"........................", "........................", ".........kkkkkk.........", ".......kkkkkkkkkk.......",
		".....kkkkTTTLLTkkkk.....", "...kkkkTTTTTLLTTTkkkk...", "...kkTTTTTTTLLTTTTtkk...", "..kkTTTTTTTTLLTTTTttkk..",
		"..kkTTTTTTTTTTTTTTttkk..", ".kkTTTTTTTTTTTTTTTTttkk.", ".kkTTTTTTTTTTTTTTTTttkk.", "kkTTTTTTTTTTTTTTTTTTttkk",
		"kkTTTTTTTTTTTTTTTTTTttkk", "kkTTTTTTTTTTTTTTTTTTttkk", "kkyyyyyyyyyyyyyyyyyyyykk", "kkyyyyyyyyyyyyyyyyyyyykk",
		"kkTTkk............kkttkk", "kkTTkk............kkttkk", "kkTTkk............kkttkk", ".kTTk..............kttk.",
		".kkkk..............kkkk.", "..kk................kk..", "........................", "........................",
	],
	&"pants": [
		"........................", "........................", "...kkkkkkkkkkkkkkkkkk...", "..kkkkkkkkkkkkkkkkkkkk..",
		"..kkkyyyyyyyyyyyyyykkk..", "..kkyyyyyyyyyyyyyyyykk..", "..kkTTTTTTTTTTTTTTttkk..", "..kkTTTTTTTTTTTTTTttkk..",
		"..kkTTTTTTTTTTTTTTttkk..", "..kkTTTTTTTTTTTTTTttkk..", "..kkTTTTTTTkkTTTTTttkk..", "..kkTTTTTkkkkkkTTTttkk..",
		"..kkTTTTTkk..kkTTTttkk..", "..kkTTTTkk....kkTTttkk..", "..kkTTTTkk....kkTTttkk..", "..kkTTTTkk....kkTTttkk..",
		"..kkTTTTkk....kkTTttkk..", "..kkTTTTkk....kkTTttkk..", "..kkTTTtkk....kkTTttkk..", "..kkkTtkkk....kkkTtkkk..",
		"..kkkkkkkk....kkkkkkkk..", "...kkkkkk......kkkkkk...", "........................", "........................",
	],
	&"boots": [
		"........................", "........................", ".....kkkk...............", "....kkkkkkk.............",
		"....kkkTLkk.............", "....kkTTTLkk............", "....kkTTTTkk............", "....kkTTTTkk............",
		"....kkTTTTkk...kkkk.....", "....kkTTTTkk..kkkkkkk...", "....kkTTTTkk..kkkTLkk...", "....kkTTTTkk..kkTTTLkk..",
		"....kkTTTTkk..kkTTTTkk..", "...kkTTTTTkk..kkTTTTkk..", "...kkTTTTTkkkkkkTTTTkk..", ".kkTTTTTTTkkkkkTTTTTkk..",
		".kkTTTTTTTkkkkkTTTTTkk..", "kkTTTTTTTTkkkkTTTTTTTkk.", "kkttttttttkkkkTTTTTTTkkk", "kkkttttttkkkkkTTTTTTTTkk",
		"kkkkkkkkkk..kktttttttt..", ".kkkkkkkk...kkkttttttt..", "............kkkkkkkkkk..", ".............kkkkkkkk...",
	],
	&"necklace": [
		"........................", "........................", ".....kk..........kk.....", "...kkkkk........kkkkk...",
		"...kyykk........kkyyk...", "..kkyyk..........kyykk..", "..kkyy............yykk..", "...kkyy..........yykk...",
		"...kkyy..........yykk...", "....kkyy........yykk....", "....kkyy........yykk....", ".....kkyy......yykk.....",
		".....kkyy......yykk.....", ".......kkyy..yykk.......", "........kyyyyyyk........", "........kkyyyykk........",
		".......kkkTTTTkkk.......", "......kkkTTTTTkkkk......", "......kkkTLLTTtkkk......", "......kkTTLLTTttkk......",
		"......kkTTTTTTttkk......", ".......kkTTTTTtkk.......", ".......kkkkkkkkkk.......", ".........kkkkkk.........",
	],
	&"charm": [
		".........kkkk...........", ".......kkkkkkkk.........", "......kkyyyyyykk........", "......kkyyyyyykk........",
		"........kyyyyk..........", "........kkyykk..........", ".......kkkTTkkk.........", ".....kkkkkTTTkkkk.......",
		".....kkTLLTTTTtkk.......", "...kkTTLLLTTTTTttkk.....", "...kkTLLLTTTTTTttkk.....", "..kkTTLLTTTTTTTTttkk....",
		"..kkTTTTTTyyTTTTttkk....", "..kkTTTTTyyyyTTTttkk....", "..kkTTTTyyyyyyTTttkk....", "...kkTTTyyyyyyTttkk.....",
		"...kkTTTTyyyyTTttkk.....", ".....kkTTTyyTttkk.......", ".....kkTTTTTTttkk.......", ".......kkTTttkk.........",
		".......kkktttkk.........", ".........kttk...........", ".........kkkk...........", "..........kk............",
	],
	&"skin": [
		"........................", "........................", ".....kkkk......kkkk.....", "...kkkkkkkk..kkkkkkkk...",
		"...kkTTTTkkkkkkTTTTkk...", ".kkTTTTTTTTkkTTTTTTTTkk.", ".kkTLLTTTTTTTTTTTTttTkk.", "kkTTLLTTTTTTTTTTTTtttTkk",
		"kkTTkkTTTTTyyTTTTTktttkk", ".kTTkkTTTTyyyyTTTTkkttk.", ".kkkkkTTTTyyyyTTTTkkkkk.", "...kkkTTTTTyyTTTTTkkk...",
		"...kkkTTTTTTTTTTTTkkk...", "....kkTTTTTTTTTTTTkk....", "....kkTTTTyyyyTTttkk....", "....kkTTTTyyyyTTttkk....",
		"....kkTTTTTTTTTTTTkk....", "....kkTTTTTTTTTTTTkk....", "....kkTTTTTyyTTTTtkk....", "....kkTTTTyyyyTtttkk....",
		"....kkttttttttttttkk....", "....kkkttttttttttkkk....", "....kkkkkkkkkkkkkkkk....", ".....kkkkkkkkkkkkkk.....",
	],
	&"pet": [
		"........................", "........................", ".....kk..........kk.....", "...kkkkkk......kkkkkk...",
		"...kkTTkk......kkTTkk...", "..kkTTTTkk....kkTTTTkk..", "..kkTTTTkk....kkTTTTkk..", "...kkTTkk......kkTTkk...",
		"....kkkkk......kkkkk....", "....kkk..........kkk....", "...kkk.....kk.....kkk...", ".kkkkk...kkkkkk...kkkkk.",
		".kkTTkkkkkkTTkkkkkkTTkk.", "kkTTTTkkkTTTTTTkkkTTTTkk", "kkTTTTkkkTTTTTTkkkTTTTkk", ".kkTTkkkTTTTTTTTkkkTTkk.",
		".kkkkkkkTTTTTTTTkkkkkkk.", "...kkkkkTTTTTTTTkkkkk...", ".....kkkTTTTTTTTtkkkk...", "......kkTTTTTTTTttkk....",
		"......kkTTTTTTTTttkk....", ".......kkTTTTTTTtkk.....", ".......kkkkkkkkkkkk.....", ".........kkkkkkkk.......",
	],
	&"sword": [
		"...................kk...", ".................kkkkkk.", ".................kkTLLkk", "...............kkTTLLLkk",
		"...............kkTTLLkk.", ".............kkTTLLkk...", ".............kkTTLLkk...", "...........kkTTLLkk.....",
		"...........kkTTLLkk.....", ".........kkTTLLkk.......", "kkk......kkTTLLkk.......", "kkkkk..kkkTLLkk.........",
		".kkkkkkkkkLLLkk.........", "...kkkkkkkLLk...........", "....kkyyyykk............", "....kyyyyyyk............",
		"...kyyykkyyyk...........", ".kkkyykkkkyykk..........", ".kbbkkk..kkkkk..........", "kkbbkk.....kk...........",
		"kkBBkk..................", ".kBBk...................", ".kkkk...................", "..kk....................",
	],
	&"dagger": [
		"........................", "........................", ".................kk.....", "...............kkkkkk...",
		"...............kkTLLkk..", ".............kkTTLLLkk..", ".............kkTTLLkk...", "...........kkTTLLkk.....",
		"...........kkTTLLkk.....", ".........kkTTLLkk.......", ".........kkTTLLkk.......", ".......kkkTLLkk.........",
		".....kkkkkLLLkk.........", "....kkkkkkLLk...........", "....kkyyyykkk...........", "...kkkyyyykk............",
		"...kbbkkkkkk............", "..kkbbkkkkk.............", "..kkBBkkk...............", "...kBBk.................",
		"...kkkk.................", "....kk..................", "........................", "........................",
	],
	&"bow": [
		"...........kk...........", ".........kkkkkk.........", ".......kkkTTTTk.........", ".....kkkkTTTTTTkk.......",
		".....kTTTkTkkTTTk.......", "...kkTTTTTkkkkTTkk......", "...kTTTk...kkkTTkk......", "..kkTTkk.....kTTkk......",
		"..kkTTkk.....kkkkk......", ".kkTTTk........kkk......", ".kTTTkk........kkk......", "kkTTkk..........kk......",
		"kkTTkk..........kk......", ".kTTTkk........kkk......", ".kkTTTk........kkk......", "..kkTTkk.....kkkkk......",
		"..kkTTkk.....kTTkk......", "...kTTTk...kkkTTkk......", "...kkTTTTTkkkkTTkk......", ".....kTTTkTkkTTTk.......",
		".....kkkkTTTTTTkk.......", ".......kkkTTTTk.........", ".........kkkkkk.........", "...........kk...........",
	],
	&"mace": [
		".................kkkk...", "...............kkkkkkkk.", "...............kkTTTTkk.", ".............kkTTTTTTTkk",
		"............kkTTLLTTTTkk", "............kkTTLLTTTTkk", "..............kkTTTTTTkk", "..............kkkTTTTkk.",
		".............kTTTkkkkkk.", "...........kkkTTkkkkk...", "...........kbbkkk.......", ".........kkbbbk.........",
		".........kbbbkk.........", ".......kkbbbk...........", ".......kbbbkk...........", ".....kkbbbk.............",
		".....kbbbkk.............", "...kkbbbk...............", "...kbbbkk...............", ".kkkbbk.................",
		"kkBBkkk.................", "kkBBk...................", ".kkkk...................", "..kk....................",
	],
	&"armor": [
		".....kkkk......kkkk.....", "...kkkkkkkk..kkkkkkkk...", "...kkTTTTkkkkkkTTTTkk...", ".kkTTTTTTTkkkkTTTTTTkkk.",
		".kkTLLTTTTkkkkTTTTTTtkk.", "kkTTLLTTTkTkkTkTTTTTttkk", "kkTTTTkkkkkTTkkkkkTTttkk", "kkTTTkkkkkTTTTkkkkkTttkk",
		"kkTTkkkTTTTTTTTTTkTkttkk", ".kTTkkTTTTTTTTTTTTktttk.", ".kkTkTTTTTTTTTTTTTtktkk.", "..kkTTTTTTTTTTTTTTttkk..",
		"..kkTTTTttTTTTttTTttkk..", "..kkTTTTttTTTTttTTttkk..", "..kkTTTTTTTTTTTTTTttkk..", "..kkTTTTTTTTTTTTTtTtkk..",
		"..kkTTttTTTTTTTTttTTkk..", "..kkTTttTTTTTTTTttTTkk..", "..kkTTTTTTTTTTTTTtTtkk..", "...kkTTTTTTTTTTTTTtkk...",
		"...kkTTTTTTTTTTTTTkkk...", ".....kkTTTTTTTTTTkk.....", ".....kkkkkkkkkkkkkk.....", ".......kkkkkkkkkk.......",
	],
	&"ring": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", ".......kyyyyyyyyk.......", ".....kkyyyyyyyyyykk.....",
		".....kyyyk....kyyyk.....", "....kkyyk......kyykk....", "....kkyy........yykk....", "...kkyky........ykykk...",
		"...kyyyk...kk...kyyyk...", "..kkyyk...kkkk...kyykk..", "..kkyy.k.kkTLkk.k.yykk..", "..kkyy..kkTTTLkk..yykk..",
		"..kkyy..kkTTTTkk..yykk..", "..kkyy.k.kkTTkk.k.yykk..", "..kkyyk...kkkk...kyykk..", "...kyyyk...kk...kyyyk...",
		"...kkyky........ykykk...", "....kkyy........yykk....", "....kkyyk......kyykk....", ".....kyyyk....kyyyk.....",
		".....kkyyyyyyyyyykk.....", ".......kyyyyyyyyk.......", ".......kkkkkkkkkk.......", ".........kkkkkk.........",
	],
	&"ore": [
		"........................", "........................", ".........kkkk...........", ".......kkkkkkkk.........",
		".......kksssSkk.........", ".....kksssssSSSkk.......", ".....kksLLssSSSkk.......", "...kksssLLssSSSSSkk.....",
		"...kksssssssSSSSSkk.....", "..kksssssssssSSSSSkk....", "..kkssssLLsssSSSSSkk....", ".kksssssLLssssSSSSSkk...",
		".kksssssssssssSSSSSkk...", "kkssssssssssssSSSSSSkk..", "kkssssssssssssSSSSSSkk..", "kkssssssssssssSSSSSSkk..",
		"kkSsssssssssssSSSSSSkk..", ".kkSSssssssssSSSSSSkk...", ".kkSSSSSSSSSSSSSSSSkk...", "...kkSSSSSSSSSSSSkk.....",
		"...kkkkkkkkkkkkkkkk.....", ".....kkkkkkkkkkkk.......", "........................", "........................",
	],
	&"herb": [
		".............kk.........", "...........kkkkkk.......", "...........kkgGkk.......", ".........kkggggGkk......",
		".........kkgggggkk......", ".......kkggggggkk.......", ".......kkggggGkkk.......", ".....kkgggggGkk.........",
		".....kkgGGggkk..........", "...kkgggGGgkk...........", "...kkgggGGkk...kk.......", "..kkgggGGkk...kkkkk.....",
		"..kkgggGGk...kkgGkk.....", "...kkgGkkk..kkgggGkk....", "...kkkkkkk..kkggggkk....", ".....kkkkk..kkgggkk.....",
		".....kkkkk..kkGGkkk.....", ".......kkk..kkGGk.......", ".......kkkbbkkkkk.......", "........kkbbkkk.........",
		"........kkBBkkk.........", "........kkBBk...........", "........kkkkk...........", ".........kk.............",
	],
	&"meat": [
		"........................", "........................", ".....kkkkkk.............", "...kkkkkkkkkk...........",
		"...kkooooookk...........", ".kkooooooooook..........", ".kkoooLLooooooook.......", "kkooooLLooooooookk......",
		"kkooooooooooooookk......", "kkoooooooooooooook......", "kkooooooooooooooooook...", ".kkoooooooooooooooookk..",
		".kkooooooooooooooooBkk..", "...kkoooooooooooooBBkk..", "...kkooooooooooook..kk..", ".....kkoooooooook...kk..",
		".....kkkkkkkkk...kkkk...", ".......kkkkkkk....kk....", ".........kkkkk....kk....", "...........kkk....kk....",
		"...........kkkwwwwkk....", "............kkkwwwk.....", "............kkkk........", ".............kk.........",
	],
	&"fang": [
		"........................", "........................", ".........kk.............", ".......kkkkkk...........",
		".......kkwwkk...........", "......kkwwwwkk..........", "......kkwwwwkk..........", "......kkwwwwwkk.........",
		"......kkwwwwwkk.........", ".......kkwwwwwkk........", ".......kkwwwwwkk........", "........kkwwwwkk........",
		"........kkwwwwkk........", "........kkwwwwwkk.......", "........kkwwwwwkk.......", ".........kkwwwwwkk......",
		".........kkwwwwwkk......", "..........kkwwwwkk......", "..........kkwwwwkk......", "...........kkwwwkk......",
		"...........kkwwwkk......", ".............kwwk.......", ".............kkkk.......", "..............kk........",
	],
	&"gel": [
		"........................", "........................", "........................", "........................",
		".......kkkkkkkk.........", ".....kkkkkkkkkkkk.......", ".....kkggggggggkk.......", "...kkggggggggggggkk.....",
		"...kkgLLgggggggggkk.....", ".kkgggLLgggggggggggkk...", ".kkggggggggggggggggkk...", "kkggggggggggggggggggkk..",
		"kkggggggggggggggggggkk..", "kkggggggggggggggggggkk..", "kkGggggggggggggggggGkk..", "kkGGGggggggggggggGGGkk..",
		"kkGGGggggggggggggGGGkk..", ".kkGGGGggggggggGGGGkk...", ".kkGGGGGGGGGGGGGGGGkk...", "...kkGGGGGGGGGGGGkk.....",
		"...kkkkkkkkkkkkkkkk.....", ".....kkkkkkkkkkkk.......", "........................", "........................",
	],
	&"dust": [
		"........................", "........................", "........................", "........................",
		"........................", "........................", "............kk..........", "............kkk.........",
		"........kk..kkk...kk....", ".......kkk..kkkk..kk....", ".......kkk..kkkkk.......", ".....kkkkk..kkkkkk......",
		"...kkkkkkkkkkkkkkkk.....", ".kkkkkkkkkkkkkkkkkkkk...", ".kksssssssssssSSSSSkk...", "kkssssssssssssSSSSSSkk..",
		"kkssssSSssssssSSSSSSkk..", "kksssSSSSssssSSSSSSSkk..", "kkSSSSSSSSSSSSSSSSSSkk..", ".kkSSSSSSSSSSSSSSSSkk...",
		".kkkkkkkkkkkkkkkkkkkk...", "...kkkkkkkkkkkkkkkk.....", "........................", "........................",
	],
	&"essence": [
		".........kkkkkk.........", ".......kkkkkkkkkk.......", ".....kkkkvvvvvvkkkk.....", "...kkkkvvvvvvvvvvkkkk...",
		"...kkvvvVVvvvvvvvvvkk...", "..kkvvvvVVvvvvvvvvvvkk..", "..kkvvLLvvvvvvvvVVvvkk..", ".kkvvvLLvvvvvvvvVVVvkk..",
		".kkvvvvvvvvvvvvvVVVVkk..", "kkvvvvvvvvvvvvvvVVVVkk..", "kkvvvvvvvvvvvvvvVVVVkk..", "kkvvvvvvvvvvvvvVVVVVkk..",
		"kkvvvvvvvvvvvvvVVVVVkk..", "kkvvvvvvvvvvvVVVVVVVkk..", "kkVvvvvvvvvvvVVVVVVVkk..", ".kkVVvvvvvvVVVVVVVVkk...",
		".kkVVVVVVVVVVVVVVVVkk...", "..kkkVVVVVVVVVVVVkkk....", "..kkkVVVVVVVVVVVVkkk....", "...kkkkVVVVVVVVkkkk.....",
		".....kkkkkkkkkkkk.......", ".......kkkkkkkk.........", "........................", "........................",
	],
	&"potion": [
		".........kkkkkk.........", "........kkkkkkkk........", "........kkbbbbkk........", "........kkbbbbkk........",
		"........kkkkkkkk........", ".......kkkkkkkkkk.......", ".......kkwTTTTwkk.......", ".....kkwwTTTTTTwwkk.....",
		".....kkwwTTTTTTwwkk.....", "...kkkwTTTTTTTTTTwkkk...", "...kkTTTTTTTTTTTTTTkk...", ".kkTTTTTTTTTTTTTTTTTkkk.",
		".kkTTTTTLLTTTTTTTTTTtkk.", "kkTTTTTTLLTTTTTTTTTTttkk", "kkTTTTTTTTTTTTTTTTTTttkk", "kkTTTTTTTTTTTTTTTTTtttkk",
		"kkTTTTTTTTTTTTTTTTTtttkk", ".kkTTTTTTTTTTTTTTttttkk.", ".kkTTTTTTTTTTTTTTttttkk.", "...kkTTTTTTTTTTTtttkk...",
		"...kkkkTTTTTTTTTkkkkk...", ".....kkkkTTTTTTkkkk.....", ".......kkkkkkkkkk.......", ".........kkkkkk.........",
	],
	&"bandage": [
		"........................", "........................", "...kkkkkkkkkkkkkkkk.....", ".kkkkkkkkkkkkkkkkkkkk...",
		".kkwwwwwwwwwwwwwwwwkk...", "kkwwwwwwwwwwwwwwwwwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..",
		"kkwwwwwwwwwwwwwwwwwwkk..", "kkwwwwwwwwwwwwwwwwwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..",
		"kkwwwwwwwwwwwwwwwwwwkk..", "kkwwwwwwwwwwwwwwwwwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..", "kkwwkkwwkkwwkkwwkkwwkk..",
		"kkwwwwwwwwwwwwwwwwwwkk..", ".kkwwwwwwwwwwwwwwwwkk...", ".kkkkkkkkkkkkkkkkkkkk...", "...kkkkkkkkkkkkkkkk.....",
		"...kkkwwkkk.............", "....kkwwk...............", "....kkkkk...............", ".....kk.................",
	],
	&"bowl": [
		"........................", "........................", ".......kk...............", ".....kkkkkk.............",
		".....kkookk...kk........", "....kkoooook..kkk.......", "....kkooooook...kk......", "...kkkkoooookk..kkk.....",
		".kkkkkkkkkkkkkkkkkkkk...", "kkkkkkkkkkkkkkkkkkkkkk..", "kkwwwwwwwwwwwwwwwwwwkk..", ".kwwwwwwwwwwwwwwwwwwk...",
		".kkwwwwwwwwwwwwwwwwkk...", "..kkwwwwwwwwwwwwwwkk....", "..kkBBBBBBBBBBBBBBkk....", "...kkBBBBBBBBBBBBkk.....",
		"...kkBBBBBBBBBBBBkk.....", ".....kkBBBBBBBBkk.......", ".....kkkkkkkkkkkk.......", ".......kkkkkkkk.........",
		"........................", "........................", "........................", "........................",
	],
}


static var _cache: Dictionary = {}


## Icon kind for an item: by equipment type, then by words in its id, then by consumable effect.
static func kind_of(item: ItemDefinition) -> StringName:
	if item == null:
		return &"ore"
	var id := String(item.id)
	match item.equipment_slot:
		ItemDefinition.EquipmentSlot.HELMET:
			return &"helmet"
		ItemDefinition.EquipmentSlot.PANTS:
			return &"pants"
		ItemDefinition.EquipmentSlot.BOOTS:
			return &"boots"
		ItemDefinition.EquipmentSlot.NECKLACE:
			return &"necklace"
		ItemDefinition.EquipmentSlot.RING:
			return &"ring"
		ItemDefinition.EquipmentSlot.ACCESSORY:
			return &"charm"
		ItemDefinition.EquipmentSlot.SKIN:
			return &"skin"
		ItemDefinition.EquipmentSlot.PET:
			return &"pet"
	match item.item_type:
		ItemDefinition.ItemType.WEAPON:
			if id.contains("bow"):
				return &"bow"
			if id.contains("dagger"):
				return &"dagger"
			if id.contains("mace") or id.contains("hammer") or id.contains("club"):
				return &"mace"
			return &"sword"
		ItemDefinition.ItemType.ARMOR:
			return &"armor"
		ItemDefinition.ItemType.ACCESSORY:
			return &"ring"
		ItemDefinition.ItemType.CONSUMABLE:
			if id.contains("bandage"):
				return &"bandage"
			if item.heal_ratio > 0.0:
				return &"potion"
			return &"bowl"
	for pair: Array in [["herb", &"herb"], ["meat", &"meat"], ["fang", &"fang"], ["gel", &"gel"], ["dust", &"dust"],
			["essence", &"essence"], ["ore", &"ore"]]:
		if id.contains(pair[0]):
			return StringName(pair[1])
	return &"ore"


## Tint used for an item (its own, or the kind's default).
static func tint_of(item: ItemDefinition) -> Color:
	if item != null and item.tint != Color.WHITE:
		return item.tint
	return KIND_TINT.get(kind_of(item), Color.WHITE)


static func texture(item: ItemDefinition, scale: int = 2) -> Texture2D:
	return texture_of(kind_of(item), tint_of(item), scale)


static func texture_of(kind: StringName, tint: Color, scale: int = 2) -> Texture2D:
	var key := "%s|%s|%d" % [kind, tint.to_html(false), scale]
	if _cache.has(key):
		return _cache[key]
	var palette := PALETTE.duplicate()
	palette["T"] = tint
	palette["t"] = tint.darkened(0.35)
	# 24×24 texels laid out at SIZE × scale px (D71, PixelIcons.build).
	var result := PixelIcons.build(BITMAPS.get(kind, BITMAPS[&"ore"]), palette, scale)
	_cache[key] = result
	return result


static func clear_cache() -> void:
	_cache.clear()
