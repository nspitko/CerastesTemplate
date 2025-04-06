package game.scenes;


import h2d.Camera;
import cerastes.Scene.UIScene;
import h2d.Object;
import game.entities.Player;
import h3d.Engine;
import cerastes.c2d.tile.Deco;
import hxd.Key;
import cerastes.c2d.DebugDraw;
import echo.Echo;
import echo.World;
import echo.util.Debug;


@:keep
class TitlecardScene extends UIScene
{
	@:obj var txtFloor: h2d.Text;
	@:obj var txtCityName: h2d.Text;

	public var scrollRoot: h2d.Object;

	var time: Float = 0;

	override function enter()
	{
		ui = hxd.Res.ui.floor_titlecard.toObject(s2d);

		var root = s2d;
		cerastes.macros.UIPopulator.populateObjects();

		txtFloor.text = GameState.level.generateFloorNumber();
		txtCityName.text = GameState.level.generateName();

		super.enter();



	}

	override function tick( delta:Float )
	{
		super.tick(delta);

		time += delta;

		if( time > 5 )
		{
			switchToNewScene("game.scenes.TestScene");
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
