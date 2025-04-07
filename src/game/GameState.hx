package game;


import game.entities.Player;
import cerastes.App;
import cerastes.StrictInterp.InterpVariable;
import haxe.io.Path;
import cerastes.file.CDPrinter;
import cerastes.file.CDParser;
import cerastes.flow.Flow.FlowContext;
import cerastes.ui.Console.GlobalConsole;
import cerastes.SoundManager;
import cerastes.SoundManager.SoundCue;
import cerastes.c2d.Vec2;
import cerastes.LocalizationManager;

import hxd.Key;
import cerastes.c3d.Vec3;
import cerastes.flow.Flow.FlowRunner;
import cerastes.collision.CollisionManager;
import cerastes.butai.ButaiNodeManager;
import tweenxcore.Tools.Easing;
import cerastes.Tween;
import cerastes.input.Controller;


import cerastes.Utils;

enum abstract CollisionGroup(Int) from Int to Int
{
	var None = 0;			// Nadda
	var Player = 1;			// The player
	var Enemy = 2;			// Things that want the player dead
	var Max = 3;			// Things that want the player dead
}


enum GameActions
{
	Left;
	Right;
	Up;
	Down;
	Hook;
	Bash;

}

@:structInit class GameConfig
{
	public var screenWidth: Int = 1280;
	public var screenHeight: Int = 720;

	public var localizationFiles: Array<String> = [];

	@serializeType("cerastes.InterpVariable")
	public var interpVariables: Array<InterpVariable> = [];

	//
	public var music = true;

}

@:structInit class SettingsData
{


}

@:structInit class SaveData
{
	public var kv = new haxe.ds.Map<String,Dynamic>();
	public var timestamp: Float = -1;

}



@:keep
@:build(cerastes.macros.Callbacks.CallbackGenerator.build())
class GameState
{

	public static var config: GameConfig = {};
	public static var data: SaveData;
	public static var settings: SettingsData;

	public static var flow: FlowRunner;

	public static var timeScale: Float = 1;

	public static var input: Controller<GameActions>;

	public static var floor: Int = 1;
	public static var level: Level;
	public static var player: Player;

	public static var lastOxygen: Int = 0;

	public static var modifiers = new Array<game.modifiers.Modifier>();

	public static var shopIdx: Int = 0;
	public static var gold: Int = 0;

	// game-specific
	public static function setup()
	{
		input = new cerastes.input.Controller( GameActions );
		input.bindKeyboard( Up, [ Key.W, Key.UP ] );
		input.bindKeyboard( Left, [ Key.A, Key.LEFT ] );
		input.bindKeyboard( Down, [ Key.S, Key.DOWN ] );
		input.bindKeyboard( Right, [ Key.D, Key.RIGHT ] );

		input.bindKeyboard( Bash, [ Key.SPACE, Key.MOUSE_LEFT ] );
		input.bindKeyboard( Hook, [ Key.CTRL, Key.MOUSE_RIGHT ] );

		FlowRunner.registerOnContextCreated(GameState, onFlowRunnerCreated );

		config = cerastes.file.CDParser.parse( hxd.Res.data.config.entry.getText(), GameConfig );


		var d = Std.random(3333);

		level = new Level( d );
		trace(d);

		#if debug
		GlobalConsole.console.addCommand("test", "runs a test. Optional argument for the test name, else runs all.", [{ name : "Key", t : AString, opt: true }], consoleRunTest );
		#end
	}

	public static function finishLevel( oxygen: Int )
	{
		lastOxygen = oxygen;
		if( lastOxygen > 0 )
		{
			level.advanceFloor();
			App.currentScene.switchToNewScene('game.scenes.TitlecardScene');
		}
		else
		{
			level.restart();
			App.currentScene.switchToNewScene('game.scenes.ShopScene');
		}



	}


	#if debug
	static function consoleRunTest( name: String )
	{
		cerastes.Test.run( name );
	}
	#end


	static function consoleJumpFile( f: String )
	{
		flow.jumpFile(f);
	}


	static function onFlowRunnerCreated( context: FlowContext, handled: Bool )
	{

		ensureInterpVariables();

		for( val in config.interpVariables )
		{
			context.interp.variables.set( val.name, data.kv[val.name] );
		}

		context.interp.variables.set("floor", GameState.floor);
		context.interp.variables.set("gold", GameState.gold);


		return handled;
	}

	static function ensureInterpVariables()
	{
		for( val in config.interpVariables )
		{
			// Ensure it exists, else create
			if( !data.kv.exists( val.name ) )
			{
				switch( val.type )
				{
					case IVTInt: data.kv[val.name] = 0;
					case IVTFloat: data.kv[val.name] = 0.0;
					case IVTString: data.kv[val.name] = "";
					case IVTBool: data.kv[val.name] = false;
				}
			}

		}
	}


	public static function reset()
	{
		data = {};


	}

	public static function get(key: String) : Dynamic
	{
		return @:privateAccess flow.context.interp.variables.get(key);
	}

	public static function set(key: String, value: Dynamic)
	{
		@:privateAccess flow.context.interp.variables.set(key, value);
	}


}