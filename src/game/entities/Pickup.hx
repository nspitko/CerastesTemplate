package game.entities;

import echo.data.Data.CollisionData;
import game.entities.EchoObject.BodyGroup;
import h2d.Bitmap;
import echo.Body;
import cerastes.c2d.Vec2;

class Pickup extends EchoEntity
{
	var value: Int = 10;
	var bx: Int;
	var by: Int;
	public function new( x: Int, y: Int, floor: Int, ?parent )
	{
		bx = x;
		by = y;

		super(parent);
		value = 10 + Std.random(10);
		value = cast Math.pow(value, floor);
	}

	public override function createBody()
	{
		cls = Loot;
		bodyGroups.push( Pickup );

		body = new Body({
			mass: 1,
			x: bx + 16,
			y: by + 16,
			shape: {
				type: RECT,
				width: 32,
				height: 32
			},
		});
		body.entity = this;


		var b = new Bitmap( hxd.Res.textures.editor.__TB_empty.toTile(), this );
		b.x  = -16;
		b.y  = -16;

		b.color.set(0,1,0,1);

		Main.world.listen( body, Level.collision, {
			separate: true,
		} );



		Main.world.listen( body, EchoObject.bodies[BodyGroup.Player], {
			enter: onPickup
		} );
	}

	function onPickup(a: Body, b: Body, ca: Array<CollisionData>)
	{
		if( isDestroyed() )
			return;


		GameState.gold += value;
		// @todo
		destroy();
	}

	public override function destroy()
	{
		super.destroy();
	}
}