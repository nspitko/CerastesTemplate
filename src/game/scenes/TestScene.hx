package game.scenes;


import cerastes.c3d.q3bsp.Q3BSPFile;
import cerastes.c3d.World;
import cerastes.c3d.q3bsp.Q3BSPBrush;
import cerastes.c3d.q3bsp.Q3BSPWorld;
import hxd.Key;
import cerastes.c2d.DebugDraw;


@:keep
class TestScene extends cerastes.Scene
{
	var world: World;

	override function enter()
	{
		super.enter();

		// Disable ambient lighting
		cast(s3d.lightSystem, h3d.scene.fwd.LightSystem).ambientLight.set(0,0,0);

		world = new World(s3d);
		var map = new Q3BSPFile("maps/movement_test.bsp");
		map.load();
		map.addToWorld( world );

	}

	override function tick( delta:Float )
	{
		super.tick(delta);
		world.tick( delta );

		DebugDraw.text('${ Math.round( hxd.Timer.fps() )} fps');

		if( Key.isPressed(Key.F))
		{
			hxd.Window.getInstance().vsync = !hxd.Window.getInstance().vsync;
		}
	}

	override function exit()
	{
		super.exit();
	}


	override function preload()
	{
		super.preload();
	}
}
