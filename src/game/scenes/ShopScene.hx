package game.scenes;


import cerastes.ui.Button;
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
class ShopScene extends UIScene
{
	@:obj var btnContinue: Button;
	@:obj var btnTestOxygen: Button;

	var time: Float = 0;

	override function enter()
	{
		ui = hxd.Res.ui.shop.toObject(s2d);

		var root = s2d;
		cerastes.macros.UIPopulator.populateObjects();

		super.enter();

		btnTestOxygen.onActivate = (e) -> {
			GameState.modifiers.push( new game.modifiers.OxygenTank() );
			btnTestOxygen.visible = false;
		}

		btnContinue.onActivate = (e) -> {
			switchToNewScene("game.scenes.TitlecardScene");
		}



	}

	override function tick( delta:Float )
	{
		super.tick(delta);


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
