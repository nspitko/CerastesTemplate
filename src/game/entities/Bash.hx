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

	var reloadSpeed(get, null): Float = 2;
	var bashDuration(get, null): Float = 0.5;
	public static var charges: Int = 3;
	var chargesMax(get, null): Int = 3;

	function get_reloadSpeed() { return owner.modifierProp.modifyFloat( reloadSpeed, HookCooldown ); }
	function get_bashDuration() { return owner.modifierProp.modifyFloat( bashDuration, BashDuration ); }
	function get_chargesMax() { return owner.modifierProp.modifyInt( chargesMax, BashCharges ); }

	var reloadTimer: Float = 0;
	final radius = 45;

	public override function createBody()
	{
		body = new Body({
			mass: 1,
			x: -500, // Dumb hack to fix bug where this would push static geo away at spawn
			y: -500,
			shape: {
				type: CIRCLE,
				radius: radius
			},
			kinematic: true
			});

		Utils.assert( Level.collision != null  );
	}

	public override function init()
	{
		effect = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		effect.x  = -radius;
		effect.y  = -radius;
		effect.alpha = 0.3;

		effect.scale( ( radius * 2 ) / 32 );
		effect.color.set( 0xFFFF00 );

		effect.visible = false;


		charges = chargesMax;
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

		if( charges == chargesMax )
			reloadTimer = 0;

		charges--;

		setState(Bashing);

		var p: Player = cast owner;
		if( p.hook.state == Idle )
		{
			var start = new Vec2(owner.x, owner.y);
			var dir = ( targetPos - start ).normalized();
			owner.setVelocity( dir * 750 );
		}



	}

	public override function tick( d: Float )
	{
		if( owner.isDestroyed() )
		{
			destroy();
			return;
		}


		stateDuration += d;
		reloadTimer += d;

		if( reloadTimer > reloadSpeed && charges < chargesMax )
		{
			charges++;
			reloadTimer = 0;
		}

		switch( state )
		{
			case Idle:
				cooldownTimer += d;
			case Bashing:
				body.x = owner.x;
				body.y = owner.y;

				var targets = EchoObject.bodies[BodyGroup.Enemy];

				Main.world.check( body, targets, {separate: false, enter: onBashTouch } );

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
			case Reloading:
				effect.visible = false;

				if( charges > 0 )
					setState(Idle);


			case Idle:
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
		return charges > 0;
	}

}