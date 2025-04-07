package game.modifiers;

import cerastes.Utils;

enum ModifierStat
{
	OxygenTotal;
	OxygenRate;
	Speed;
	HookCooldown;
	BashCooldown;
	BashDuration;
	BashCharges;
}

enum abstract ModifierFlags(Int) from Int to Int
{
	var AbilityHook = 1 << 0;
	var AbilityBashOxygen = 1 << 1;
}

class ModifierFile
{
	@serializeType("haxe.ds.StringMap")
	public var modifiers: Map<String, ModifierDef> = [];
}

class ModifierStatDef
{
	public var stat: ModifierStat;
	public var val: Float;
}

class ModifierDef
{
	@serializeType("game.modifiers.ModifierStatDef")
	public var add: Array<ModifierStatDef> = [];
	@serializeType("game.modifiers.ModifierStatDef")
	public var mul: Array<ModifierStatDef> = [];
	public var flags: Int;
	public var prerequisite: String;
	public var cost: Int = 0;
}

class DataDrivenModifier extends Modifier
{
	public var def: ModifierDef;

	public function new( id: String, d: ModifierDef )
	{
		super(id);
		def = d;
		flags = d.flags;
		cost = d.cost;
		prerequisite = d.prerequisite;
	}

	public override function multiply( input: Float, stat: ModifierStat )
	{
		if( def.mul == null )
			return input;

		for( s in def.mul )
		{
			if( s.stat == stat )
				return input * s.val;
		}

		return input;
	}

	public override function add( input: Float, stat: ModifierStat )
	{
		if( def.add == null )
			return input;

		for( s in def.add )
		{
			if( s.stat == stat )
				return input + s.val;
		}

		return input;
	}
}

// Given more time I'd solve this with macros.
class Modifier
{
	public var duration: Float = 0; // 0 means forever!
	public var flags: Int = 0;
	public var prerequisite: String;
	public var id: String;
	public var cost: Int = 0;

	public function multiply( input: Float, stat: ModifierStat ) { return input; }
	public function add( input: Float, stat: ModifierStat ) { return input; }

	public function new(id: String ){ this.id = id;}
}

class ModifierProperties
{

	public static var allModifiers: Map<String,Modifier> = [];

	var modifiers: Array<Modifier> = [];
	public var flags: Int = 0;

	public function new(){}

	public static function init()
	{
		var data: ModifierFile = cerastes.file.CDParser.parse( hxd.Res.data.modifiers.entry.getText(), ModifierFile );
		for( k => v in data.modifiers)
		{
			var m = new DataDrivenModifier( k, v );
			allModifiers.set(k, m);
		}
	}

	public static function getModifier( m: String )
	{
		var m = allModifiers.get(m);
		if( !Utils.verify( m != null ) )
		{
			return null ;
		}
		return m;
	}

	public function addModifier( m: String )
	{
		var m = allModifiers.get(m);
		if( !Utils.verify( m != null ) )
		{
			return;
		}
		modifiers.push(m);
		flags |= m.flags;
	}

	public function modifyFloat( ref: Float, stat: ModifierStat )
	{
		var mul: Float = 1;
		var add: Float = 0;
		for( m in modifiers )
		{
			mul = m.multiply( mul, stat );
			add = m.add( add, stat );
		}

		ref += add;
		ref *= mul;

		return ref;
	}

	public inline function modifyInt( ref: Int, stat: ModifierStat ) : Int
	{
		return Math.round( modifyFloat( ref, stat ) );
	}

	public function hasModifier( id: String )
	{
		for( m in modifiers )
		{
			if( m.id == id )
				return true;
		}

		return false;
	}
}