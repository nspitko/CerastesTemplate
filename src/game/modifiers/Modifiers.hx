package game.modifiers;

import game.modifiers.Modifier.ModifierStat;

class OxygenTank extends Modifier
{
	public override function add( val: Float, stat: ModifierStat )
	{
		if( stat != OxygenTotal ) return val;
		return val + 25;
	}
}

class