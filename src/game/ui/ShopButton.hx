package game.ui;
import cerastes.SoundManager;
import h2d.Interactive;
import haxe.EnumTools.EnumValueTools;
import game.modifiers.Modifier.DataDrivenModifier;
import cerastes.LocalizationManager;
import game.modifiers.Modifier.ModifierProperties;
import cerastes.ui.Button;
import h3d.Vector;

import h2d.Anim;
import cerastes.Utils;
import cerastes.fmt.CUIResource;
import h2d.Object;
import h2d.Bitmap;
import cerastes.Timer;
import cerastes.fmt.CUIResource.CUIObject;
import cerastes.ui.UIEntity;

#if hlimgui
import imgui.ImGuiMacro.wref;
import cerastes.tools.ImguiTools.IG;
#end


@:structInit class ShopButtonDef extends CUIObject
{
	public var modifier: String = "";
}


@:build(cerastes.macros.UIEntityBuilder.build( ShopButtonDef ))
@:build(cerastes.macros.Callbacks.CallbackGenerator.build())
class ShopButton extends UIEntity
{
	//
	//
	//

//	@:callbackStatic public static function onExit();

	@:obj var txtName:h2d.Text;
	@:obj var txtStats:h2d.Text;
	@:obj var txtDesc:h2d.Text;
	@:obj var txtCost:h2d.Text;
	@:obj var intButton:Interactive;


	public override function initialize( root: h2d.Object )
	{
		super.initialize(root);
		cerastes.macros.UIPopulator.populateObjects();

	}

	public function setModifier( m: String, onBuy: Void -> Void )
	{
		def.modifier = m;
		var m = ModifierProperties.getModifier( def.modifier );

		txtName.text = LocalizationManager.localize( m.id );
		var dd: DataDrivenModifier = Std.downcast( m, DataDrivenModifier );
		txtStats.text = "";
		txtCost.text = '${dd.cost}';
		if( dd != null )
		{
			if( dd.def.add != null )
			{
				for( s in dd.def.add )
				{
					txtStats.text += LocalizationManager.localize('${ s.val > 0 ? '+' : '-' }${s.val} ${LocalizationManager.localize('stat_${EnumValueTools.getName(s.stat)}')}');
				}
			}
			if( dd.def.mul != null )
			{
				for( s in dd.def.mul )
				{
					txtStats.text += LocalizationManager.localize('${ s.val > 1 ? '+' : '' }${Math.round( s.val * 100 - 100 ) }% ${LocalizationManager.localize('stat_${EnumValueTools.getName(s.stat)}')}');
				}
			}
			if(txtStats.text.length == 0 )
			{
				txtStats.visible = false;
				txtDesc.visible = true;
				txtDesc.text = LocalizationManager.localize('${m.id}_desc');
			}
		}

		intButton.onPush = (e) -> {
			if( GameState.gold < m.cost )
			{
				SoundManager.play("ui_no");
				return;
			}
			SoundManager.play("shop_buy");
			GameState.gold -= m.cost;
			GameState.modifiers.push( m );
			onBuy();
			remove();

		}
	}

}