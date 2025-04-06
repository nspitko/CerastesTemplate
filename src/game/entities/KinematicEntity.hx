package game.entities;

import cerastes.c2d.Vec2;
import echo.data.Data.CollisionData;
import echo.Body;

class KinematicEntity extends EchoEntity
{
	var velocity: Vec2 = new Vec2(0,0);

	function kinematicVsStaticCollision(a: Body, b: Body, ca: Array<CollisionData>)
	{
		for( c in ca )
		{
			var penetration = c.normal * c.overlap;
			body.x -= penetration.x;
			body.y -= penetration.y;

			var tangent = new Vec2(-c.normal.y, c.normal.x);

			// Decompose
			var vNormal: Vec2 = c.normal * velocity.dot( c.normal );
			var vTangent: Vec2 = tangent * velocity.dot( tangent );

			var restitutionNormal: Vec2 = vNormal * -0.01;

			velocity = vTangent + restitutionNormal;

			//velocity = tangent * velocity.dot(tangent);
		}
	}

	public function setVelocity( vel: Vec2 )
	{
		velocity = vel;
	}

	public override function tick(d: Float )
	{
		body.x += velocity.x * d;
		body.y += velocity.y * d;
	}
}