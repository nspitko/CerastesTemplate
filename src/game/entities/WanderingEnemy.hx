package game.entities;

import cerastes.Utils;
import echo.data.Data.CollisionData;
import cerastes.c2d.DebugDraw;
import cerastes.CMath;
import echo.Line;
import cerastes.c2d.Vec2;
import game.entities.EchoObject.BodyGroup;
import h2d.Bitmap;
import echo.Body;

class WanderingEnemy extends Enemy
{
	var w: Int = 32;
	var h: Int = 32;
	var speed: Float = 100;
	var acceleration = 800;

	var sprite: Bitmap;

	var moveDir: Vec2;



	public override function init()
	{
		sprite = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		sprite.color.set( 0xFF00FF );

		sprite.x -= sprite.tile.width / 2;
		sprite.y -= sprite.tile.height / 2;

		moveDir = new Vec2( Std.random(2) == 0 ? -1 : 1, 0 );

	}

	public override function createBody()
	{
		cls = Enemy;
		bodyGroups.push( Enemy );

		body = new Body({
			mass: 1,
			x: 0,
			y: 0,
			kinematic: true,
			shape: {
				type: RECT,
				width: w,
				height: h
			},
		});
		body.entity = this;

		Main.world.listen( body, Level.collision, {
			separate: true,
			enter: kinematicVsStaticCollision
		} );
	}

	public override function tick(d: Float)
	{
		var tries = 0;
		while( !isDirSafe( moveDir ) && tries++ < 5 )
		{
			// We want to change direction here.
			moveDir = -moveDir;
			rotateRandom( moveDir, 20);
			moveDir.normalize();
		}

		velocity.x += moveDir.x * acceleration * d;
		velocity.y += moveDir.y * acceleration * d;

		var maxSpeedSq = speed * speed;

		if( velocity.lengthSq() > maxSpeedSq )
			velocity.normalize().scale( Math.sqrt( maxSpeedSq ) );

		super.tick(d);

		var maxY = GameState.level.levelHeight - 32;

		if( body.y > maxY )
			body.y = maxY;

	}

	function isDirSafe( dir: Vec2 )
	{
		var lookAhead = speed * 0.5;

		var start = new Vec2(x + w / 2, y + h / 2);
		var end = start + dir * lookAhead;
		var l = Line.get_from_vectors( start, end );

		var targets = Level.collision;

		var hit = l.linecast( targets, Main.world );

		//if( hit != null )
		//	DebugDraw.line(start, end, 0xFF0000, 5);

		return hit == null;
	}

	function rotateRandom( v: Vec2, deg: Float )
	{
		var r = CMath.DEG_RAD * deg;
		var ang = (Math.random() * 2 - 1) * r;
		var ca = Math.cos(ang);
		var sa = Math.sin(ang);

		v.x = v.x * ca - v.y * sa;
		v.y = v.x * sa + v.y * ca;
	}


	public override function onTouchedByPlayer(a:Body, b:Body, ca:Array<CollisionData>) {

		if( touchTimer < 0.5 )
			return;

		touchTimer = 0;

		var player: Player = cast b.entity;
		player.takeDamage( 3 );
		player.setVelocity( -ca[0].normal * player.knockbackSpeed );
	}
}