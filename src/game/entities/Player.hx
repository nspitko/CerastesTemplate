package game.entities;


import cerastes.Tween;
import cerastes.Timer;
import game.modifiers.Modifier.ModifierFlags;
import cerastes.c2d.DebugDraw;
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
	public final knockbackSpeed: Float = 450;

	public var hook: GrapplingHook;
	var bash: Bash;

	var sensor: echo.Body;

	var bestTarget: EchoEntity;
	var targetingDistMax = 64;

	//public var modifierProp: ModifierProperties = new ModifierProperties();

	function get_speed() { return modifierProp.modifyFloat( this.speed, ModifierStat.Speed ); }
	function get_oxygenTotal() { return modifierProp.modifyFloat( this.oxygenTotal, ModifierStat.OxygenTotal ); }
	function get_oxygenRate() { return modifierProp.modifyFloat( this.oxygenRate, ModifierStat.OxygenRate ); }

	public override function init()
	{
	}

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

		sensor = new Body({
			mass: 1,
			x: -500, // Dumb hack to fix bug where this would push static geo away at spawn
			y: -500,
			shape: {
				type: CIRCLE,
				radius: targetingDistMax / 2
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
			separate: false,
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
			modifierProp.addModifier( m.id );

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

		//
		// Movement
		//
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

		// Targeting
		var mouse = new Vec2( App.currentScene.s2d.mouseX, App.currentScene.s2d.mouseY );
		App.currentScene.s2d.camera.screenToCamera( mouse );

		sensor.x = mouse.x;
		sensor.y = mouse.y;
		var targets = EchoObject.bodies[BodyGroup.Enemy].concat( EchoObject.bodies[BodyGroup.Pickup] );
		Main.world.check( sensor, targets, { separate: false, enter: onMouseHover } );

		if( bestTarget != null )
		{
			if( !bestTarget.isDestroyed() )
			{
				var pos = bestTarget.getBodyPos();
				// Add a bit of stickyness
				if( pos.distanceSq( mouse ) > targetingDistMax * targetingDistMax * 1.1 )
					bestTarget = null;
			}
			else
				bestTarget = null;

		}

		if( bestTarget != null && ( GameState.player.modifierProp.flags & ModifierFlags.AbilityHook ) != 0 )
		{
			DebugDraw.x( bestTarget.getBodyPos(), 10, 0x00FF00 );
		}


		// Ability: Hook
		if( input.isPressed( Hook ) && ( GameState.player.modifierProp.flags & ModifierFlags.AbilityHook ) != 0 )
		{
			if( hook.ready() && bestTarget != null )
			{
				hook.shoot( bestTarget );
			}
			else if( hook.state != Idle )
			{
				hook.detach();
			}
			else
			{
				SoundManager.play("ability_no");
			}
		}

		// Ability: Bash
		if( input.isPressed( Bash ) )
		{
			if( bash.ready() )
			{
				bash.bash( mouse );
			}
			else
				SoundManager.play("ability_no");

		}
		super.tick(d);

		if( body.y > GameState.level.levelHeight || oxygen < 0 )
		{
			if( oxygen > 0 )
			{
				SoundManager.play("level_advance");
				new Timer(1.5, () -> { GameState.finishLevel( Math.ceil( oxygen ) ); });
			}
			else
			{
				SoundManager.play("level_abort");
				GameState.finishLevel( 0 );
			}

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
		if( hook.state == Reeling || hook.state == Finish )
		{
			enemy.takeDamage( 10 );
			Main.hitStop = 0.1;
			SoundManager.play("bash_impact");
		}
		else
			enemy.onTouchedByPlayer(b, a, ca);
	}

	function onMouseHover(a: Body, b: Body, ca: Array<CollisionData>)
	{
		var ent: EchoEntity = Std.downcast( b.entity, EchoEntity );
		if( ent == null )
			return;

		var mouse = new Vec2( App.currentScene.s2d.mouseX, App.currentScene.s2d.mouseY );
		App.currentScene.s2d.camera.screenToCamera( mouse );

		if( bestTarget == null || bestTarget.isDestroyed() )
		{
			bestTarget = ent;
			return;
		}

		var curDistSq = bestTarget.getBodyPos().distanceSq( mouse );
		var newDist = ent.getBodyPos().distanceSq( mouse );

		// Bit of stickyness for our current target
		if( newDist < curDistSq * 0.9 )
			bestTarget = ent;
	}


}