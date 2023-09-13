package data;

class Config
{

	public static function init()
	{
		#if hlimgui

		#if flow
		cerastes.Config.flowEditorNodes["Dialogue"] = Type.resolveClass("data.DialogueNode");
		#end

		#end
	}

}