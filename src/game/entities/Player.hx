package game.entities;


import cerastes.SoundManager;
import game.modifiers.Modifier.ModifierStat;
import game.modifiers.Modifier.ModifierProperties;
import echo.data.Data.CollisionData;
import game.entities.EchoObject.BodyGroup;
import echo.Body;
import cerastes.Utils;
import h2d.Bitmap;
import haxe.display.Display.DeterminePackageResult;
import cerastes.c2d.Vec2;
import cerastes.input.ControllerAccess;
import cerastes.App;

import game.entities.EchoEntity;

class Player extends KinematicEntity
{
	var input: ControllerAccess<GameState.GameActions>;

	var speed(get, default): Float = 320; // pixels per second
	var oxygenTotal( get, default ): Float = 35;
	var oxygenRate( get, default ): Float = 1;
	public var oxygen: Float;

	final acceleration: Float = 1000;
	final deceleration: Float = 600;
	final decelerationOverspeed: Float = 1200;
	public final knockbackSpeed: Float = 600;

	public var hook: GrapplingHook;
	var bash: Bash;

	public var gold: Int;

	public var modifierProp: ModifierProperties = new ModifierProperties();

	function get_speed() { return modifierProp.modifyFloat( this.speed, ModifierStat.Speed ); }
	function get_oxygenTotal() { return modifierProp.modifyFloat( this.oxygenTotal, ModifierStat.OxygenTotal ); }
	function get_oxygenRate() { return modifierProp.modifyFloat( this.oxygenRate, ModifierStat.OxygenRate ); }

	public override function createBody()
	{
		cls = Player;

		bodyGroups.push( Player );

		velocity = new Vec2(0,0);
		body = new Body({
			mass: 1,
			x: 0,
			y: 0,
			shape: {
			  type: CIRCLE,
			  radius: 8
			},
			kinematic: true
		});
		body.entity = this;

		input = GameState.input.createAccess();

		var b = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		b.x  = -8;
		b.y  = -8;

		Utils.assert( Level.collision != null  );
		Main.world.listen( body, Level.collision, {
			separate: true,
			enter: kinematicVsStaticCollision,
			stay: kinematicVsStaticCollision
		} );

		bash = new Bash( this, parent );
		hook = new GrapplingHook( this, parent );

		Main.world.listen( body, EchoObject.bodies[BodyGroup.Enemy], {
			enter: onTouchEnemy
		} );
	}

	public function reset()
	{
		for( m in GameState.modifiers )
			modifierProp.addModifier( m );

		oxygen = GameState.lastOxygen > 0 ? GameState.lastOxygen : oxygenTotal;
	}




	public override function tick(d: Float )
	{
		if( isDestroyed() )
			return;

		var dir = new Vec2(
			input.isDown( Right ) ? 1 : input.isDown( Left ) ? -1 : 0,
			input.isDown( Down ) ? 1 : input.isDown( Up ) ? -1 : 0,
		);

		oxygen -= d * oxygenRate;

		if( hook.state != Reeling )
		{

			// Allow us to retain our existing vel
			var maxSpeedSq = Math.max( velocity.lengthSq() - ( decelerationOverspeed * decelerationOverspeed * d ), speed * speed );
			var decel = speed * speed < maxSpeedSq ? decelerationOverspeed : deceleration;
			decel *= d;

			if( dir.lengthSq() > 0 )
			{
				velocity.x += dir.x * acceleration * d;
				velocity.y += dir.y * acceleration * d;

				if( velocity.lengthSq() > maxSpeedSq )
					velocity.normalize().scale( Math.sqrt( maxSpeedSq ) );
			}
			else
			{
				if( velocity.lengthSq() > 0 )
				{
					var desiredLen = Math.max( velocity.length() - decel, 0);
					if( desiredLen == 0 )
						velocity.zero();
					else
						velocity.normalize().scale( desiredLen );
				}
			}
		}

		if( input.isPressed( Hook ) )
		{
			if( hook.ready() )
			{
				var mouse = new Vec2( App.currentScene.s2d.mouseX, App.currentScene.s2d.mouseY );
				App.currentScene.s2d.camera.screenToCamera( mouse );
				hook.shoot( null, mouse );
			}
			else
			{
				hook.detach();
			}
		}

		if( input.isPressed( Bash ) )
		{
			if( bash.ready() )
			{
				var mouse = new Vec2( App.currentScene.s2d.mouseX, App.currentScene.s2d.mouseY );
				App.currentScene.s2d.camera.screenToCamera( mouse );
				bash.bash( mouse );
			}

		}
		super.tick(d);

		if( body.y > GameState.level.levelHeight || oxygen < 0 )
		{
			GameState.finishLevel( Math.ceil( oxygen ) );
			destroy();
		}

	}

	public function takeDamage( amount: Int )
	{
		hook.abort();
		SoundManager.play( "player_hurt" );

		Utils.info('Took $amount damage');

		oxygen -= amount;


	}

	function onTouchEnemy(a: Body, b: Body, ca: Array<CollisionData>)
	{
		var enemy: Enemy = cast b.entity;
		enemy.onTouchedByPlayer(b, a, ca);
	}


}