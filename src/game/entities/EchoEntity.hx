package game.entities;

import cerastes.Entity;

class EchoEntity extends EchoObject implements Entity
{
	// used by the client to find entities
	public var lookupId: String = "";

	public var initialized(get, never): Bool;

	function get_initialized()
	{
		return true;
	}

	public function new( ?parent  )
	{
		super(parent);
		EntityManager.instance.register(this);
	}

	public function destroy()
	{
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
		return false;
	}

	public override function toString(): String
	{
		return '${Type.getClassName(Type.getClass(this))} (${super.toString()})';
	}
}