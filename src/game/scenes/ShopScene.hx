package game.scenes;


import game.ui.ShopButton;
import game.modifiers.Modifier.ModifierProperties;
import cerastes.ui.Reference;
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
class ShopScene extends LDScene
{
	@:obj var btnContinue: Button;
	@:obj var refButton: Reference;
	@:obj var flowButtons: h2d.Flow;
	@:obj var intDialogue: h2d.Interactive;
	@:obj var txtGold: h2d.Text;


	var time: Float = 0;

	override function enter()
	{
		ui = hxd.Res.ui.shop.toObject(s2d);

		var root = s2d;
		cerastes.macros.UIPopulator.populateObjects();

		super.enter();

		refButton.remove();

		btnContinue.onActivate = (e) -> {
			switchToNewScene("game.scenes.TitlecardScene");
		}

		for( k => v in ModifierProperties.allModifiers )
		{
			var found = false;
			var owned = false;
			for( m in GameState.modifiers )
			{
				if( m.id == k )
					owned = true;
				if( v.prerequisite != null && m.id == v.prerequisite)
					found = true;
			}
			if( owned )
				continue;

			if( v.prerequisite != null && !found )
				continue;

			var button:ShopButton = cast refButton.make( flowButtons );
			button.setModifier( k, () -> { txtGold.formatLoc( Std.string( GameState.gold ) ); } );

		}

		intDialogue.visible = false;
		intDialogue.onPush = (e) -> {
			processLine();
		}

		txtGold.formatLoc( Std.string( GameState.gold ) );

		GameState.shopIdx++;

		GameState.flow.context.interp.variables.set("floor", GameState.floor);
		GameState.flow.context.interp.variables.set("gold", GameState.gold);
		GameState.flow.jumpFile( "data/shop.flow" );



	}

	override function onDialogueComplete()
	{
		intDialogue.visible = false;
	}

	override function tick( delta:Float )
	{
		super.tick(delta);


	}

	override function onDialogueStart()
	{
		intDialogue.visible = true;
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
