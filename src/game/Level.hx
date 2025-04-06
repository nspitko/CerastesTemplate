package game;

import cerastes.LocalizationManager;
import cerastes.misc.Random;
import cerastes.Utils;
import cerastes.c2d.Vec2;
import game.entities.EchoObject;
import echo.Body;
import h2d.Tile;
import h2d.TileGroup;
import haxe.Int32;
import echo.Echo;
import haxe.ds.Vector;
import cerastes.misc.Perlin;

enum abstract TileIndices(Int) to Int
{
	var Top = 0;
	var TopRight;
	var Center;
	//var RightCorner;
	var Right;
	var BottomRight;
	var Bottom;
	var InnerCorner;
	var Empty;

	var Missing;
}

class Level extends EchoObject
{

	final tileLayout = [
		Top, TopRight, Empty,
		Center, TopRight, Missing,
		Empty, Empty, Empty,
		Bottom, BottomRight, InnerCorner
	];

	final tileWidth: Int = 32;
	final tileHeight: Int = 32;
	var data: Vector<Int>;

	var width: Int = 24;
	var height: Int = 300;

	var seed: Int = 0;

	var tiles: Map<TileIndices, Array<h2d.Tile>>;
	var sheet: Tile;

	var floor: Int;
	public var levelHeight: Int;

	public static var collision: Array<Body>;

	public function new(seed: Int = 0, floor: Int, ?parent: h2d.Object)
	{
		super(parent);
		this.seed = seed;
		this.floor = floor;


		reset();
	}

	public function advanceFloor()
	{
		floor++;
		reset();
	}

	inline function isSolid(x: Int, y: Int )
	{
		var idx = x + y * width;

		if( idx < 0 || idx > width * height )
			return true;
		return data.get(idx) != 0;
	}

	public function reset()
	{
		removeChildren();

		if( Main.world != null )
			Main.world.dispose();

		Main.world = Echo.start({
			width: tileWidth * width,
			height: tileHeight * height,
			gravity_y: 25,
			iterations: 5,
		});

		// Reduce Quadtree depths - our World is very small, so not many subdivisions of the Quadtree are actually needed.
		// This can help with performance by limiting the Quadtree's overhead on simulations with small Body counts!
		//Main.world.quadtree.max_depth = 3;
		//Main.world.static_quadtree.max_depth = 3;

		// Increase max contents per Quadtree depth - can help reduce Quadtree subdivisions in smaller World sizes.
		// Tuning these Quadtree settings can be very useful when optimizing for performance!
		Main.world.quadtree.max_contents = 20;
		Main.world.static_quadtree.max_contents = 20;
	}

	public function restart()
	{
		seed = Std.random(3000);
		floor = 1;
		reset();
	}

	public function generate()
	{
		data = new Vector<Int>(width * height, 0);

		var p = new Perlin( seed + 1000 * floor );

		final scale = height * tileHeight;
		var rand = new Random( seed + 1000 * floor );


		// First pass: Noise
		var dark = 0;
		var light = 0;
		var contrast: Float = 0;
		var threshold: Float = 0;
		var valid = true;
		do
		{
			valid = true;
			for(y in 0 ... height )
			{

				for( x in 0 ... width)
				{
					var i = y * width + x;
					if( x == 0 || x == width - 1)
					{
						data[i] = 1;
						continue;
					}

					// Hard stop
					if( y < 2 )
						continue;

					var n = p.noise2d(x / scale, y / scale, 7, 4, 0.92, 3.3 );
					// Dim starting tiles to ensure we don't start trapped.
					var sf: Float =  Math.min( y/10, 1  );
					n = ((n + 1) * sf ) - 1;

					if( n > threshold )
					{
						dark++;
						data[i] = 1;
						continue;
					}
					data[i] = 0;
					light++;

				}
			}

			contrast = dark / light;
			if( contrast > 2.5 )
			{
				threshold += 0.2;
				valid = false;
				Utils.info('Contrast too dark ($contrast), increasing threshold');
			}
			if( contrast < 0.2 )
			{
				threshold -= 0.1;
				valid = false;
				Utils.info('Contrast too light ($contrast), decreasing threshold');
			}

		}
		while(!valid);

		Utils.info('Level gen complete, final contrast = $contrast');


		// Block out the last floor
		for( x in 0 ... width )
		{
			data[(height-1) * width + x] = 1;
		}


		// Second pass: Hard carve to ensure levels can be traversed
		var currentX: Int = Math.floor( width / 2 );
		for(y in 0 ... height )
		{
			if( !isSolid(currentX, y+1) )
				continue;

			// Can we move left to a safe position?
			var found = false;
			for(x in currentX ... width-2)
			{
				if( isSolid(x, y ) )
					break;
				if( !isSolid(x, y+1) )
				{
					currentX = x;
					found = true;
					break;
				}
			}
			// ...Right?
			var x = currentX;
			while(x > 1)
			{
				if( isSolid(x, y ) )
					break;
				if( !isSolid(x, y+1) )
				{
					currentX = x;
					found = true;
					break;
				}
				x--;
			}

			if( found )
				continue;

			// No?? Carve!
			data[y * width + currentX] = 0;
			data[(y+1) * width + currentX] = 0;

			// Chance to wiggle our path
			if( rand.getUpTo(2) == 1 )
			{
				currentX += rand.getUpTo(1) == 0 ? 1 : -1;
				if( currentX == 0 )
					currentX += 2;
				if(currentX == width-1 )
					currentX -= 2;

				data[y * width + currentX] = 0;
				data[(y+1) * width + currentX] = 0;
			}
		}

		// Third pass: Remove any tile that isn't adjacent to any other tile
		for(y in 1 ... height-1 )
		{
			for( x in 0 ... width)
			{
				var c = 0;
				if( isSolid( x+1, y ) ) c++;
				if( isSolid( x-1, y ) ) c++;
				if( isSolid( x, y+1 ) ) c++;
				if( isSolid( x, y-1 ) ) c++;

				if( c == 0 )
					data[y * width + x] = 0;

			}
		}

		var world = Main.world;

		// Generate an optimized Array of Bodies from Tilemap data
		collision = echo.util.TileMap.generate(data.toArray(), tileWidth, tileHeight, width, height, x, y);
		for (b in collision) world.add(b);

		// Tileset...
		generateTiles();

		// Generate loot.
		var q: Int = cast height / 4;
		var lootDepths = [
			Math.floor( q),
			Math.floor( 2 * q ),
			Math.floor( 3 * q  ),
			Math.floor( 4 * q - 5 ),
		];

		for( d in lootDepths)
		{
			var placed = false;
			for(y in d ... height )
			{

				for( x in 1 ... width - 1 )
				{
					if( isSolid(x, y ) && !isSolid(x, y-1 ) )
					{
						var l = new game.entities.Pickup( floor, this );
						l.body.x = x * tileWidth;
						l.body.y = y * tileHeight;
						placed = true;
						break;
					}
				}
				if( placed )
					break;
			}

		}

		// Generate spikes
		for(y in 1 ... height )
		{
			var spikeChance = 15;
			for( x in 1 ... width-1)
			{
				if( isSolid(x, y))
					continue;

				var north = isSolid( x, y-1 );
				var east = isSolid( x+1, y );
				var south = isSolid( x, y+1 );
				var west = isSolid( x-1, y );

				var count = 0;
				if( north ) count++;
				if( east ) count++;
				if( south ) count++;
				if( west ) count++;
				if( count > 1 )
					continue;

				if( north && rand.getUpTo( spikeChance ) == 0 )
				{
					var s = new game.entities.Spikes( 0, x * tileWidth, y * tileHeight, this  );
					continue;
				}
				if( east && rand.getUpTo( spikeChance ) == 0 )
				{
					var s = new game.entities.Spikes( 1, x * tileWidth, y * tileHeight, this  );
					continue;
				}
				if( south && rand.getUpTo( spikeChance ) == 0 )
				{
					var s = new game.entities.Spikes( 2, x * tileWidth, y * tileHeight, this  );
					continue;
				}
				if( west && rand.getUpTo( spikeChance ) == 0 )
				{
					var s = new game.entities.Spikes( 3, x * tileWidth, y * tileHeight, this  );
					continue;
				}
			}
		}

		// Generate enemies
		var wantToPlaceShark = false;
		for(y in 1 ... height )
		{
			if( !wantToPlaceShark && y > 25 && rand.getUpTo(10) == 0 ) wantToPlaceShark = true;

			for( x in 1 ... width-1)
			{
				if( wantToPlaceShark && canPlace( x, y, 3, 2 ) )
				{
					wantToPlaceShark = false;
					var s = new game.entities.WanderingEnemy( this );
					s.body.x = x * tileWidth;
					s.body.y = y * tileHeight;
				}
			}
		}

		// Release memory
		data = null;

	}

	function canPlace(x: Int, y: Int, w: Int, h: Int )
	{
		for( i in 0 ... h )
		{
			for( j in  0 ... w )
			{
				if( isSolid( x+j, y+i ) )
					return false;
			}
		}

		return true;
	}

	inline function idxToTile(idx: Int)
	{
		final w = 3;
		final h = 4;

		var x: Int = idx % w;
		var y: Int = cast idx / w;

		return sheet.sub( x * tileWidth, y * tileHeight, tileWidth, tileHeight );
	}

	inline function select(g: Array<Tile> )
	{
		return g[Std.random(g.length)];
	}

	function generateTiles()
	{
		sheet = hxd.Res.sheets.geo.toTile();
		tiles = new Map<TileIndices, Array<h2d.Tile>>();

		tiles[Top] = [ idxToTile( 0) ];
		tiles[TopRight] = [ idxToTile(1) ];
		tiles[Empty] = [ idxToTile(2) ]; // Shouldn't ever need this....
		tiles[Center] = [ idxToTile(3) ];
		//tiles[RightCorner] = [ idxToTile(ts, 4) ]; // directly below a TopRight
		tiles[Right] = [ idxToTile(4) ]; // directly below a TopRight
		tiles[Bottom] = [ idxToTile(9) ]; // directly below a TopRight
		tiles[BottomRight] = [ idxToTile(10) ]; // directly below a TopRight
		tiles[InnerCorner] = [ idxToTile(11) ];

		tiles[Missing] = [ idxToTile(5) ];



		var tg = new TileGroup( sheet, this );
		for(y in 0 ... height )
		{
			for( x in 0 ... width)
			{
				var tx = x * tileWidth;
				var ty = y * tileHeight;

				if( !isSolid(x, y ) )
					continue;
				var top = isSolid(x, y-1 );
				var left = isSolid(x-1, y );
				var right = isSolid(x+1, y );

				if( !top )
				{
					if( right && left )
						tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Top]) );
					else if( left )
						tg.addTransform( tx, ty, 1, 1, 0, select(tiles[TopRight]) );
					else if( right )
						tg.addTransform( tx + tileHeight, ty, -1, 1, 0, select(tiles[TopRight]) );
					else
						tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Missing]) );
				}
				else
				{
					var bottom = isSolid(x, y+1 );
					if( !bottom )
					{
						if( right && left )
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Bottom]) );
						else if( left )
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[BottomRight]) );
						else if( right )
							tg.addTransform( tx + tileHeight, ty, -1, 1, 0, select(tiles[BottomRight]) );
						else
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Missing]) );
					}
					else
					{
						// We have a top and a bottom so...
						if( right && left )
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Center]) );
						else if( left )
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Right]) );
						else if( right )
							tg.addTransform( tx + tileHeight, ty, -1, 1, 0, select(tiles[Right]) );
						else
							tg.addTransform( tx, ty, 1, 1, 0, select(tiles[Missing]) );
					}
				}






			}
		}

	}

	public function generateName(): String
	{
		var rand = new Random( seed );

        var prefixes = ["Atl", "Aqua", "Ner", "Mar", "Hydr", "Pose", "Oce", "Fer", "Nol", "Phy", "Cen", "Sha"];
        var roots = ["lant", "dora", "thys", "mara", "phor", "lyth", "tide"];
        var suffixes = ["ia", "is", "os", "on", "ium", "ar", "ea"];
        var modifiers = ["Lost", "Sunken", "Ancient", "Forgotten", "Hidden", "Forsaken", "Abandoned", "Decrepit", "Shattered"];

        var prefix = prefixes[rand.getUpTo(prefixes.length-1)];
        var root = roots[rand.getUpTo(roots.length-1)];
        var suffix = suffixes[rand.getUpTo(suffixes.length-1)];
        var modifier = modifiers[rand.getUpTo(modifiers.length-1)];

        return '$modifier $prefix$root$suffix';
    }

	public function generateFloorNumber()
	{
		return LocalizationManager.localize("titlecard_floor", numberToWords(floor));
	}

	// Boring i18n stuff haxe doesn't support, ai slop sorry not sorry.
	static function numberToWords(number:Int):String {
        var absNumber: Int = cast Math.abs(number); // Handle negatives

		if (absNumber == 1) return "first";
        if (absNumber == 2) return "second";
        if (absNumber == 3) return "third";
        if (absNumber == 5) return "fifth";

        // Convert number to words
        var words:String = convertToWords(absNumber);

        // Add ordinal suffix
        words += getOrdinalSuffix(absNumber);

        return words;
    }

    static function convertToWords(number:Int):String {
        var belowTwenty:Array<String> = [
            "zero", "one", "two", "three", "four", "five",
            "six", "seven", "eight", "nine", "ten",
            "eleven", "twelve", "thirteen", "fourteen",
            "fifteen", "sixteen", "seventeen",
            "eighteen", "nineteen"
        ];

        var tens:Array<String> = [
            "", "", "twenty", "thirty",
            "forty", "fifty", "sixty",
            "seventy", "eighty", "ninety"
        ];

        if (number < 20) {
            return belowTwenty[number];
        } else if (number < 100) {
            var remainder = number % 10;
            return tens[cast number / 10] + (remainder > 0 ? " " + belowTwenty[remainder] : "");
        } else if (number < 1000) {
            var remainder = number % 100;
            return belowTwenty[cast number / 100] + " hundred" + (remainder > 0 ? " " + convertToWords(remainder) : "");
        } else {
            return Std.string(number); // For simplicity, handle large numbers as-is
        }
    }

    static function getOrdinalSuffix(number:Int):String {
        if (number % 100 >= 11 && number % 100 <= 13) {
            return "th";
        }

        switch (number % 10) {
            case 1: return "st";
            case 2: return "nd";
            case 3: return "rd";
            default: return "th";
        }
    }


	function getMask( x: Int, y: Int )
	{
		var m = 0;
		if( isSolid(x-1, y-1) ) 	m |= 1 << 0;
		if( isSolid(x  , y-1) ) 	m |= 1 << 1;
		if( isSolid(x+1, y-1) ) 	m |= 1 << 2;

		if( isSolid(x-1, y  ) ) 	m |= 1 << 3;
		if( isSolid(x  , y  ) ) 	m |= 1 << 4;
		if( isSolid(x+1, y  ) ) 	m |= 1 << 5;

		if( isSolid(x-1, y+1) ) 	m |= 1 << 6;
		if( isSolid(x  , y+1) ) 	m |= 1 << 7;
		if( isSolid(x+1, y+1) ) 	m |= 1 << 8;

		return m;
	}

	function makeMask( a, b, c, d, e, f, g, h, i)
	{
		return Std.int(a) |
				Std.int(b) << 1 |
				Std.int(c) << 2 |
				Std.int(d) << 3 |
				Std.int(e) << 4 |
				Std.int(f) << 5 |
				Std.int(g) << 6 |
				Std.int(h) << 7 |
				Std.int(i) << 8;
	}

}