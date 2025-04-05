package game;

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

	public static var collision: Array<Body>;

	public function new(seed: Int = 0, ?parent: h2d.Object)
	{
		super(parent);
		this.seed = seed;


		Main.world = Echo.start({
			width: tileWidth * width,
			height: tileHeight * height,
			gravity_y: -10,
			iterations: 5,
			history: 1000
		});

		generate(width, height);
	}

	inline function isSolid(x: Int, y: Int )
	{
		var idx = x + y * width;

		if( idx < 0 || idx > width * height )
			return true;
		return data.get(idx) != 0;
	}

	function generate(width: Int, height: Int32)
	{
		data = new Vector<Int>(width * height, 0);

		var p = new Perlin(5);

		final scale = height * tileHeight;


		// First pass: Noise
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

				var n = p.noise2d(x / scale, y / scale, 7, 4, 0.92, 3.3 );
				// Dim starting tiles to ensure we don't start trapped.
				var sf: Float =  Math.min( y/10, 1  );
				n = ((n + 1) * sf ) - 1;

				if( n > 0 )
				{
					data[i] = 1;
					continue;
				}

			}
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
			if( Std.random(3) == 1 )
			{
				currentX += Std.random(2) == 0 ? 1 : -1;
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
		var tilemap = echo.util.TileMap.generate(data.toArray(), tileWidth, tileHeight, width, height, x, y);
		for (b in tilemap) world.add(b);

		generateTiles();


		// Release memory
		data = null;

		collision = tilemap;


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