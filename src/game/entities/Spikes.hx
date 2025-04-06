package game.entities;


import cerastes.Utils;
import echo.data.Data.CollisionData;
import game.entities.EchoObject.BodyGroup;
import h2d.Bitmap;
import echo.Body;
import cerastes.c2d.Vec2;

class Spikes extends Enemy
{
	var sx: Float;
	var sy: Float;

	var w: Int = 8;
	var h: Int = 8;

	public function new( direction: Int, x: Int, y: Int, ?parent )
	{
		sx = x;
		sy = y;
		// Directions are the OPEN tile, eg "north" means we're on the south tile. Cool huh?
		switch( direction )
		{
			case 2: // north
				sy += 32 - h;
				sx += 32 / 2 + w / 2;
			case 3: // east
				sx += w / 2;
				sy += 32 / 2 + h / 2;
			case 0: // south
				sy += h / 2;
				sx += 32 / 2 + w / 2;
			case 1: // west
				sx += 32 - w / 2;
				sy += 32 / 2 + h / 2;

			default:
				sx = x;
				sy = y;
		}

		super(parent);
	}

	public override function createBody()
	{
		cls = Enemy;
		bodyGroups.push( Enemy );

		body = new Body({
			mass: STATIC,
			x: sx,
			y: sy,
			shape: {
				type: RECT,
				width: w,
				height: h
			},
		});
		body.entity = this;



		var b = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		b.x  = -w;
		b.y  = -h;

		b.scale( ( w * 2 ) / 32 );
		b.color.set(1,0.4,0.3,0.5);
		//b.alpha = 0.2;

	}

	public override function onTouchedByPlayer(a:Body, b:Body, ca:Array<CollisionData>) {

		if( touchTimer < 0.5 )
			return;

		touchTimer = 0;
		Utils.info("Hit spikes!");

		var player: Player = cast b.entity;
		player.takeDamage( 1 );
		player.setVelocity( -ca[0].normal * player.knockbackSpeed );
	}

	public override function destroy()
	{
		super.destroy();
	}
}