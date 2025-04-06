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


enum BashState
{
	Idle;
	Bashing;
	Reloading;
}

class Bash extends Ability
{
	final damage = 10;
	var stateDuration: Float = 0;
	var state: BashState = Idle;

	var sensor: echo.Body;
	var effect: Bitmap;
	var hitBodies: Array<echo.Body>;
	final reloadSpeed = 1;

	final bashDuration = 0.5;

	public override function createBody()
	{
		final radius = 45;

		body = new Body({
			mass: 1,
			x: -500,
			y: -500,
			shape: {
				type: CIRCLE,
				radius: radius
			},
			kinematic: true
			});

		effect = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		effect.x  = -radius;
		effect.y  = -radius;
		effect.alpha = 0.3;

		effect.scale( ( radius * 2 ) / 32 );
		effect.color.set( 0xFFFF00 );

		effect.visible = false;


		Utils.assert( Level.collision != null  );
	}

	function onBashTouch(a: Body, b: Body, ca: Array<CollisionData>)
	{
		if( hitBodies.contains( b ) )
			return;

		hitBodies.push( b );
		var enemy: Enemy = cast b.entity;
		enemy.takeDamage( 10 );
		Main.hitStop = 0.1;
		SoundManager.play("bash_impact");
	}

	public function bash(targetPos: Vec2 )
	{
		if( state == Idle )
		{
			setState(Bashing);

			var p: Player = cast owner;
			if( p.hook.state == Idle )
			{
				var start = new Vec2(owner.x, owner.y);
				var dir = ( targetPos - start ).normalized();
				owner.setVelocity( dir * 600 );
			}


		}
	}

	public override function tick( d: Float )
	{
		stateDuration += d;
		switch( state )
		{
			case Idle:
				cooldownTimer += d;
			case Bashing:
				body.x = owner.x;
				body.y = owner.y;

				var targets = EchoObject.bodies[BodyGroup.Enemy];

				Main.world.check( body, targets, { enter: onBashTouch } );

				if( stateDuration > bashDuration )
					setState( Reloading );

			case Reloading:
				var player: Player = cast owner;
				if( stateDuration > player.modifierProp.modifyFloat( reloadSpeed, ModifierStat.BashCooldown ) )
				{
					setState(Idle);
					SoundManager.play("bash_reload");
				}


			default:
		}
	}

	function setState( newState: BashState )
	{
		Utils.assert( newState != state );
		stateDuration = 0;
		state = newState;
		switch( newState )
		{
			case Idle | Reloading:
				effect.visible = false;

			case Bashing:
				SoundManager.play( "bash_start" );
				effect.visible = true;
				hitBodies = [];

				if( stateDuration > bashDuration )
					setState( Reloading );


			default:
		}
	}

	public override function ready()
	{
		return state == Idle;
	}

}