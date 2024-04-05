package game.scenes;


import hxd.Key;
import cerastes.c2d.DebugDraw;


@:keep
class TestScene extends cerastes.Scene
{
	override function enter()
	{
		super.enter();

	}

	override function tick( delta:Float )
	{
		super.tick(delta);

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
