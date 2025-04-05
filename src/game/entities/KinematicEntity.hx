package game.entities;

import cerastes.c2d.Vec2;
import echo.data.Data.CollisionData;
import echo.Body;

class KinematicEntity extends EchoEntity
{
	var velocity: Vec2;

	function kinematicVsStaticCollision(a: Body, b: Body, ca: Array<CollisionData>)
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
	}

	public override function tick(d: Float )
	{

		body.x += velocity.x * d;
		body.y += velocity.y * d;
	}
}