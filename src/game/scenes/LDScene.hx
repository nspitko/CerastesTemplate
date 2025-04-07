package game.scenes;

#if hlimgui
import cerastes.tools.ImguiTool.ImGuiToolManager;
#end
import cerastes.SoundManager;
import cerastes.flow.Flow.FlowRunner;
import data.Flow.DialogueNode;
import cerastes.Tween;
import cerastes.Timer;
import tweenxcore.Tools.Easing;
import cerastes.Utils;
import cerastes.pass.TransitionFilter;
import cerastes.Scene;

class LDScene extends Scene
{
	final transitionSpeed = 0.4;
	final transitionDelay = 0.15;

	var transitionTween: Tween;
	var ui: h2d.Object;


	public override function enter()
	{
		super.enter();

		trackCallback(
			DialogueNode.registerOnDialogue(this, onDialogue ),
			DialogueNode.unregisterOnDialogue
		);
	}

	var dialogueLines: Array<String> = [];
	var dialogueComplete: Void->Void = null;

	function onDialogue(node: DialogueNode, runner: FlowRunner, handled: Bool )
	{
		onDialogueStart();
		dialogueLines = node.dialogue.split("\n");
		dialogueComplete = () -> {
			if( ui != null )
			{

				var r = ui.createTimelineRunner("dialogue_complete");
				if( r != null )
				{
					r.play();
				}


			}

			node.nextAll( runner );

			if( !runner.busy )
				onDialogueComplete();
		}

		processLine();

		return handled;
	}

	function onDialogueComplete()
	{

	}

	function onDialogueStart()
	{

	}

	function processLine()
	{
		var line = dialogueLines.shift();
		if( line == null || line.length == 0 )
		{
			dialogueComplete();
			return;
		}

		/*
		if( dialogueObject == null )
		{
			dialogueObject = hxd.Res.ui.popup.toObject(s2d);
			var int: h2d.Interactive = cast dialogueObject.getObjectByName("int_popup");
			int.onClick = (e) -> {
				dialoguePopup();
			}

			var r = dialogueObject.createTimelineRunner("appear");
			r.play();
		}
		*/

		var s: h2d.Text = cast ui.getObjectByName("txt_speaker");
		var t: h2d.Text = cast ui.getObjectByName("txt_dialogue");
		if( !Utils.verify(t != null,"Popup missing text") )
		{
			dialogueComplete();
			return;
		}

		var idx = line.indexOf(':');
		if( idx != -1 )
		{
			s.text = line.substr(0,idx);
			line = line.substr(idx+1);
		}
		else
			s.visible = false;



		t.text = line;// StringTools.replace(line,"*","\n");

	}

    public override function fadeOut( onComplete: Void -> Void )
	{
		if(transitionTween != null )
			transitionTween.abort();

		var transition = new TransitionFilter({ texture: "shd/transition_swipe.png" });
		s2d.filter = transition;
		transitionTween = new Tween( transitionSpeed, 0, 1, (v) -> { transition.pass.phase = v; }, Easing.linear, () -> {
			new Timer( transitionDelay, onComplete );
		});
	}

	public override function fadeIn( onComplete: Void -> Void )
	{
		var transition = new TransitionFilter({ texture: "shd/transition_swipe.png" });
		s2d.filter = transition;

		transitionTween = new Tween( transitionSpeed, 1, 0, (v) -> { transition.pass.phase = v; }, Easing.linear, () -> {  onComplete(); } );
	}

	// Lets just pretend this code doesn't exist and isn't working around some horrifying context clip bug
	public override function render(e:h3d.Engine)
	{
		var oldW = e.width;
		var oldH = e.height;

		@:privateAccess
		{
			#if js
			e.width = 1280;
			e.height = 720;
			#else
			e.width = s2d.width;
			e.height = s2d.height;
			#end
			s2d.render(e);
			e.width = oldW;
			e.height = oldH;
		}
	}


    function initError( e: String )
    {
        Utils.error('UI Init errror: $e');
    }
}