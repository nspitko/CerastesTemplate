package game.entities;

import game.modifiers.Modifier.ModifierProperties;

class Ability extends KinematicEntity
{
	var owner: KinematicEntity;

	var cooldownDuration: Float = 1;
	var cooldownTimer: Float = 0;

	public override function new( o: KinematicEntity, ?parent: h2d.Object )
	{
		owner = o;
		super(parent);
	}

	public function ready()
	{
		return cooldownTimer > cooldownDuration;
	}

	public function abort()
	{}

}