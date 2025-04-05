package game.entities;


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

	final speed: Float = 320; // pixels per second

	final acceleration: Float = 1000;
	final deceleration: Float = 600;


	public override function createBody()
	{
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
	}



	public override function tick(d: Float )
	{
		var dir = new Vec2(
			input.isDown( Right ) ? 1 : input.isDown( Left ) ? -1 : 0,
			input.isDown( Down ) ? 1 : input.isDown( Up ) ? -1 : 0,
		);

		if( dir.lengthSq() > 0 )
		{
			velocity.x += dir.x * acceleration * d;
			velocity.y += dir.y * acceleration * d;

			if( velocity.lengthSq() > speed*speed )
				velocity.normalize().scale( speed );
		}
		else
		{
			if( velocity.lengthSq() > 0 )
			{
				var decel = deceleration * d;
				var desiredLen = Math.max( velocity.length() - decel, 0);
				if( desiredLen == 0 )
					velocity.zero();
				else
					velocity.normalize().scale( desiredLen );
			}
		}

		if( input.isPressed( Hook ) )
		{
			
		}

		super.tick(d);
	}
}