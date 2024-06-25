package game.entities;

#if bullet

import cerastes.c3d.Model.ModelDef;
import h3d.scene.Object;
import cerastes.c3d.Entity;
import cerastes.c3d.entities.PlayerController;
import cerastes.c3d.entities.ThirdPersonCameraController.ThirdPersonPlayerController;
import cerastes.c3d.Entity.EntityData;
import bullet.Constants.CollisionFlags;
import h3d.scene.RenderContext;
import h3d.col.Point;
import cerastes.c3d.Vec3;

@qClass(
	{
		name: "info_player_start",
		desc: "Player Start",
		type: "PointClass",
		base: ["PlayerClass", "Angle"]
	}
)
class PlayerStart extends Entity
{
	override function onCreated( def: EntityData )
	{
		super.onCreated( def );

		var p = world.createEntityClass( Player, def );

	}
}



class Player extends cerastes.c3d.entities.Player
{

	var model: Object;

	public override function onCreated(  def: EntityData )
	{

		eyePos = new Vec3(0,0,32);

		controller = cast world.createEntityClass( ThirdPersonPlayerController, def );
/*
		var modelDef = cerastes.file.CDParser.parse( hxd.Res.loader.load("models/placeholder/vanguard.model").entry.getText(), ModelDef );

		model = modelDef.toObject(this);

		var animations= modelDef.getAnimations();
		model.playAnimation( animations[0] );
*/
		super.onCreated( def );

	}

	public override function sync( ctx: RenderContext )
	{
		super.sync(ctx);
	}

	public override function jump()
	{
		velocity.z += 270;
	}
}

#end
