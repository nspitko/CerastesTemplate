package game.scenes;


import game.entities.Bash;
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
class TestScene extends LDScene
{
	var debug: HeapsDebug;


	@:obj var ctnLevelOffset: h2d.Object;
	@:obj var txtOxygen: h2d.Text;
	@:obj var txtFloor: h2d.Text;
	@:obj var txtGold: h2d.Text;
	@:obj var txtBash: h2d.Text;

	public var scrollRoot: h2d.Object;

	var showDebug = false;

	override function enter()
	{
		ui = hxd.Res.ui.game_base.toObject();
        s2d.add( ui, 2 );

		var root = s2d;
		cerastes.macros.UIPopulator.populateObjects();

		super.enter();


		scrollRoot = new h2d.Object();
		s2d.add(scrollRoot, 0 );

		scrollRoot.addChild( DebugDraw.g );

		GameState.level.generate();
		scrollRoot.addChild( GameState.level );

		GameState.level.levelHeight = cast GameState.level.getBounds().height;

		//l.x = ctnLevel.x;

		debug = new HeapsDebug(scrollRoot);

		h3d.Engine.getCurrent().backgroundColor = 0x555555;

		GameState.player = new Player(GameState.level);
		GameState.player.body.x = 32 * 12;

		GameState.player.reset();

		var uiCamera = new Camera();
		s2d.addCamera( uiCamera );
		// Filter layers
		uiCamera.layerVisible = (idx) -> idx == 2;
		s2d.camera.layerVisible = (idx) -> idx == 0;
		s2d.camera.viewportX = ctnLevelOffset.x;



	}

	override function tick( delta:Float )
	{
		super.tick(delta);


		s2d.camera.y = -hxd.Window.getInstance().height / 2 + GameState.player.y;
		if( s2d.camera.y < 0 )
			s2d.camera.y = 0;
		var maxHeight =  GameState.level.levelHeight - s2d.height;
		if( s2d.camera.y > maxHeight )
		{
			s2d.camera.y = maxHeight;
		}

		txtOxygen.formatLoc( Std.string( Math.floor( GameState.player.oxygen ) ) );
		txtGold.formatLoc( Std.string( GameState.gold ) );
		txtFloor.formatLoc( Std.string( GameState.floor ) );
		txtBash.formatLoc( Std.string( Bash.charges ) );

		if( showDebug )
			debug.draw(Main.world);

		if( hxd.Key.isPressed( Key.NUMBER_9 ) )
		{
			showDebug = !showDebug;
			if( !showDebug )
				debug.clear();
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
