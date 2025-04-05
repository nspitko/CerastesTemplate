package game.entities;
import h2d.RenderContext;

class EchoObject extends h2d.Object
{
	public var body:echo.Body = null;

	public var disposed(default, null):Bool = false;

	public function new( ?parent )
	{
		super(parent);
		createBody();
		if( body != null )
			Main.world.add(body);
	}

	public function createBody()
	{
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

		//all.push(this);
		// .world.add(body);
	}

	/**
	 * Overriding to remove Entity from `all` array and it's body from the World.
	 */
	override function onRemove()
	{
		super.onRemove();

		//all.remove(this);
		body.remove();
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