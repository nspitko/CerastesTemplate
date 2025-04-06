package game.modifiers;

enum ModifierStat
{
	OxygenTotal;
	OxygenRate;
	Speed;
	HookCooldown;
	BashCooldown;
}

// Given more time I'd solve this with macros.
class Modifier
{
	public function modifyFloat( input: Float, stat: ModifierStat ) { return input; }

	public var duration: Float = 0; // 0 means forever!

	public function new(){}
}

class ModifierProperties
{
	var modifiers: Array<Modifier> = [];

	public function new(){}

	public function addModifier( m: Modifier )
	{
		modifiers.push(m);
	}

	public function modifyFloat( ref: Float, stat: ModifierStat )
	{
		for( m in modifiers )
			ref = m.modifyFloat( ref, stat );

		return ref;
	}
}