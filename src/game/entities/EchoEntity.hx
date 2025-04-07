package game.entities;

import game.modifiers.Modifier.ModifierProperties;
import cerastes.Entity;

class EchoEntity extends EchoObject implements Entity
{
	// used by the client to find entities
	public var lookupId: String = "";

	public var initialized(get, never): Bool;
	var destroyed = false;
	public var modifierProp: ModifierProperties = new ModifierProperties();

	function get_initialized()
	{
		return true;
	}

	public function hasModifier(k: String )
	{
		return modifierProp.hasModifier(k);
	}

	public function new( ?parent  )
	{
		super(parent);
		EntityManager.instance.register(this);
	}

	public function destroy()
	{
		destroyed = true;
		dispose();
		remove();
	}

	public function tick( delta: Float )
	{
	}

	function schedule(time: Float, func: Void->Void )
	{
		EntityManager.instance.schedule( haxe.Timer.stamp() + time, func );
	}

	public function isDestroyed()
	{
		return destroyed;
	}

	public override function toString(): String
	{
		return '${Type.getClassName(Type.getClass(this))} (${super.toString()})';
	}
}