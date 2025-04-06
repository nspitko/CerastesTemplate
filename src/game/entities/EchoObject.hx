package game.entities;
import cerastes.c2d.Vec2;
import h2d.RenderContext;

enum BodyGroup
{
	Player;
	Enemy;
	Pickup;
}

enum Classification
{
	None;
	Enemy;
	Loot;
	Player;
	//World; // Unused level geo is just any body without an ent
}

class EchoObject extends h2d.Object
{
	public var body:echo.Body = null;
	public var bodyGroups: Array<BodyGroup> = [];

	public var disposed(default, null):Bool = false;

	public static var bodies: Map<BodyGroup, Array<echo.Body>> = [
		Player => [],
		Enemy => [],
		Pickup => [],
	];

	var cls: Classification = None;


	public function new( ?parent )
	{
		super(parent);
		init();
		createBody();

	}


	public function init()
	{

	}

	public function createBody()
	{

	}

	inline function setBodyPos( p: Vec2 )
	{
		// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		if( Math.isNaN( p.x ) || Math.isNaN( p.y ) )
			hl.Api.breakPoint();

		body.x = p.x;
		body.y = p.y;
	}

	function setTilePos( p: Vec2 )
	{
		body.x = p.x + 16;
		body.y = p.y + 16;
	}

	function registerBody(body: echo.Body, group: BodyGroup)
	{
		if( !bodies.exists(group))
			bodies[group] = [];

		bodies[group].push(body);
	}

	/**
	 * Override this to perform logic on every update loop.
	 * @param dt elapsed time since the last step.
	 */
	public function step(dt:Float) {}

	/**
	 * Disposes the Entity. DO NOT use the Entity after disposing it, as it could lead to null reference errors.
	 */
	public function dispose() {
		if (disposed) return;
		if( body != null )
		{
			body.dispose();
			body.entity = null;
			body = null;
		}

		disposed = true;
	}

	/**
	 * Overriding to add Entity to `all` array and it's body to the World.
	 */
	override function onAdd()
	{
		super.onAdd();
		if( body != null )
		{
			Main.world.add(body);
			for( g in bodyGroups)
				registerBody(body, g);
		}

	}

	/**
	 * Overriding to remove Entity from `all` array and it's body from the World.
	 */
	override function onRemove()
	{
		super.onRemove();

		for( g in bodyGroups )
			bodies[g].remove(body);

		if( body != null )
		{
			body.remove();
			body = null;
		}
	}

	/**
	 * Overriding to apply the body's transform to the Entity.
	 */
	override function sync(ctx:RenderContext)
	{
		if (body != null)
		{
			if (x != body.x) x = body.x;
			if (y != body.y) y = body.y;
			if (rotation != body.rotation) rotation = body.rotation;
		}

		super.sync(ctx);
	}
}