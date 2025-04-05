import echo.World;
#if hlimgui
import cerastes.tools.ImguiTool.ImGuiToolManager;
#end


class Main extends cerastes.App
{

	public static var world:World;


	function new()
	{
		super();
	}

	override function init()
	{
		super.init();
		cerastes.App.currentScene.switchToNewScene("game.scenes.PreloadScene");
	}


	override function update(dt:Float)
	{
		if( world != null )
			world.step(dt);
		super.update(dt);
	}


	static function main() {
		#if !js
		//hl.UI.closeConsole();
		data.Config.init();
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		#end

		#if pbr
		h3d.mat.MaterialSetup.current = new h3d.mat.PbrMaterialSetup();
		#end

		cerastes.App.instance = new Main();
	}
}
