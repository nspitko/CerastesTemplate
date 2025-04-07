package game.entities;

import game.modifiers.Modifier.ModifierFlags;
import echo.data.Data.CollisionData;
import echo.Body;

class Enemy extends KinematicEntity
{
	var hp: Int = 1;
	public var oxygen = 1;
	var touchTimer: Float = 0;
	var damageTimer: Float = 0;
	var bx: Int;
	var by: Int;

	public function new(x: Int, y: Int, ?parent)
	{
		bx = x;
		by = y;
		super(parent);
	}

	public function takeDamage( amt: Int )
	{
		hp -= amt;
		if( hp <= 0 )
			die();
	}

	function die()
	{
		if( ( GameState.player.modifierProp.flags & ModifierFlags.AbilityBashOxygen ) != 0 )
			GameState.player.oxygen += oxygen;
		destroy();
	}

	override function onRemove()
	{
		// Lazy hack: If we get removed, we're dead. Bye!
		super.onRemove();
		destroy();
	}

	public function onTouchedByPlayer(a: Body, b: Body, ca: Array<CollisionData>)
	{
	}

	public override function tick(d: Float )
	{
		touchTimer += d;
		super.tick(d);
	}
}