package game.scenes;


import game.entities.Player;
import h3d.Engine;
import cerastes.c2d.tile.Deco;
import cerastes.c3d.q3bsp.Q3BSPFile;
import cerastes.c3d.World;
import cerastes.c3d.q3bsp.Q3BSPBrush;
import cerastes.c3d.q3bsp.Q3BSPWorld;
import hxd.Key;
import cerastes.c2d.DebugDraw;
import echo.Echo;
import echo.World;
import echo.util.Debug;


@:keep
class TestScene extends cerastes.Scene
{
	var l: Level;
	var debug: HeapsDebug;

	var player: Player;

	override function enter()
	{
		super.enter();

		l = new Level( s2d );

		debug = new HeapsDebug(s2d);

		h3d.Engine.getCurrent().backgroundColor = 0x555555;

		player = new Player(s2d);
		player.body.x = 200;


	}

	override function tick( delta:Float )
	{
		super.tick(delta);

		debug.draw(Main.world);

		s2d.camera.y = -hxd.Window.getInstance().height / 2 + player.y;


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
