package game.entities;

import game.modifiers.Modifier.ModifierStat;
import cerastes.SoundManager;
import cerastes.c2d.DebugDraw;
import echo.data.Data.CollisionData;
import game.entities.EchoObject.BodyGroup;
import echo.Line;
import cerastes.Utils;
import h2d.Bitmap;
import echo.Body;
import cerastes.c2d.Vec2;

enum GrappleState
{
	Idle;
	Shooting;
	Latch;
	Reeling;
	ReelingLoot;
	Finish;
	Reloading;
}

class GrapplingHook extends Ability
{
	var targetEnt: EchoEntity = null;
	var targetPos: Vec2 = null;

	public var state(default, null): GrappleState = Idle;
	var stateDuration: Float = 0;

	var sensor: echo.Body;

	final shootSpeed: Float = 3000;
	final reelSpeed: Float = 700;
	final radius: Float = 1;
	var hookSprite: Bitmap;

	final reloadSpeed = 1;

	public override function createBody()
	{
		velocity = new Vec2(0,0);
		body = new Body({
			mass: 1,
			x: -100,
			y: -100,
			shape: {
				type: CIRCLE,
				radius: radius
			},
			kinematic: true
		});

		Utils.assert( Level.collision != null  );

		var b = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		b.x  = -8;
		b.y  = -8;
		b.alpha = 0.3;

		b.scale(  0.5 );
		b.color.set( 0x00FF00 );

		hookSprite = b;

		Utils.assert( Level.collision != null  );

		Main.world.listen( body, Level.collision, {
			separate: true,
			enter: onHitWorld,
		} );

		Main.world.listen( body, owner.body, {
			separate: false,
			enter: onHitPlayer,
		} );
	}

	public function detach()
	{
		// Try to reject spam pressing
		if( state == Shooting && stateDuration < 0.3 )
			return;

		state = Reloading;
	}

	function onHitWorld(a: Body, b: Body, ca: Array<CollisionData>)
	{
		for( c in ca )
		{
			var penetration = c.normal * c.overlap;
			trace(penetration);
			body.x -= penetration.x;
			body.y -= penetration.y;

			var tangent = new Vec2(-c.normal.y, c.normal.x);
			velocity = tangent * velocity.dot(tangent);
		}
		if( state == Shooting )
		{
			setState( Latch );
		}
	}

	function onHitPlayer(a: Body, b: Body, ca: Array<CollisionData>)
	{
		if( state != Reeling )
			return;

		setState( Finish );
	}

	public override function abort()
	{
		if( state == Idle || state == Reloading )
			return;

		setState( Reloading );
	}


	public function shoot( ?targetEntity: EchoEntity, ?targetPosition: Vec2 )
	{
		targetEnt = null;
		// Ensure only one is specified
		Utils.assert( ( targetEntity == null || targetPosition == null ) && !( targetEntity != null && targetPosition != null ) );

		setBodyPos( new Vec2(owner.x, owner.y) );

		// Trace to the closest object
		if( targetPosition != null )
		{
			targetPos = targetPosition;
			var start = new Vec2(owner.x, owner.y);
			var dir = ( targetPos - start ).normalized();
			var end = start + dir * 850;
			var l = Line.get_from_vectors( start, end );

			var targets = Level.collision
				.concat( EchoObject.bodies[BodyGroup.Enemy] )
				.concat( EchoObject.bodies[BodyGroup.Pickup] );

			var hit = l.linecast( targets, Main.world );
			//DebugDraw.line( start, end, 0x00FF00, 5 );
			if( hit == null )
				return; // ??????

			DebugDraw.x( hit.closest.hit, 5, 0xFF0000, 5 );

			// Did we hit something?
			if( hit.body.entity != null )
				targetEnt = hit.body.entity;
			else
				targetPos = hit.closest.hit;
		}
		else
			targetEnt = targetEntity;

		setState(Shooting);
	}

	function getTargetPos()
	{
		if( targetEnt != null && !targetEnt.isDestroyed() )
			return new Vec2( targetEnt.x, targetEnt.y );
		return targetPos;
	}

	public override function tick( d: Float )
	{
		if( owner.isDestroyed() )
		{
			destroy();
			return;
		}

		stateDuration += d;
		switch( state )
		{
			case Idle:
				hookSprite.visible = false;

			case Shooting:
				hookSprite.visible = true;

				var target = getTargetPos();
				var p = new Vec2(body.x, body.y);

				DebugDraw.line( p, target );

				var finished = p.approach( target, shootSpeed, d, radius );
				setBodyPos(p);
				if( finished )
				{
					setState( Latch );
					return;
				}
				default:

			case Latch:
				if( stateDuration > 0.1 )
				{
					if( targetEnt != null && targetEnt.cls == Loot )
						setState( ReelingLoot );
					else
						setState(Reeling);
				}


			case Reeling:
				var target = new Vec2( body.x, body.y );
				var p = new Vec2(owner.body.x, owner.body.y);


				DebugDraw.line( p, target, 0x00FF00 );

				var finished = p.approach( target, reelSpeed, d );
				//owner.setBodyPos(p);

				if( finished )
				{
					setState( Finish );
					return;
				}
				else
				{
					var dir = ( target - p ).normalized();
					owner.setVelocity( dir * reelSpeed );
					var newPos = new Vec2( owner.body.x, owner.body.y ) + (dir * reelSpeed) * d;
					owner.setBodyPos( newPos );
				}

			case ReelingLoot:
				if( targetEnt.isDestroyed() )
				{
					setState( Finish );
					return;
				}

				var target = new Vec2( owner.body.x, owner.body.y );
				var p = new Vec2(targetEnt.body.x, targetEnt.body.y);

				DebugDraw.line( p, target, 0x00FF00 );

				p.approach( target, reelSpeed, d );
				targetEnt.setBodyPos(p);

			case Finish:
				// Adds extra damage frames
				if( stateDuration > 0.3 )
				{
					setState(Reloading);
				}

			case Reloading:
				var player: Player = cast owner;
				if( stateDuration > player.modifierProp.modifyFloat( reloadSpeed, ModifierStat.HookCooldown ) )
				{
					setState(Idle);
					SoundManager.play("hook_reload");
				}



		}


	}

	function setState( newState: GrappleState )
	{
		Utils.assert( newState != state );
		stateDuration = 0;
		state = newState;
		switch( newState )
		{
			case Idle | Reloading:
				hookSprite.visible = false;
			case Shooting:
				SoundManager.play( "hook_shoot" );
			case Reeling | ReelingLoot:
				SoundManager.play( "hook_impact" );

			default:
		}
	}

	public override function ready()
	{
		return state == Idle;
	}
}