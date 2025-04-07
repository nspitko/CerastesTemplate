package data;

import cerastes.Utils;
import cerastes.data.Nodes.NodeDefinition;
import cerastes.flow.Flow;

/**
 * Puts text on the screen
 */
 @:build(cerastes.macros.Callbacks.CallbackGenerator.build())
 @:structInit class DialogueNode extends FlowNode
 {
	/**
	 * Dialogue nodes in the flow file are the canonical english versions.
	 *
	 * for localization, we load a patch file which will lookup nodes by id
	 * so it's important we do our best to avoid changing node IDs once
	 * localization begins!
	 */
	@editor("Dialogue","StringMultiline")
	public var dialogue: String;

	public function getLocalizedDialoge()
	{
		// @todo: actually hook this up
		return dialogue;
	}


	public override function process( runner: FlowRunner )
	{
		var handled = onDialogue( this, runner );

		if( !handled )
			nextAll( runner );
	}

	@:callbackStatic
	public static function onDialogue( node: DialogueNode, runner: FlowRunner );

	 #if hlimgui
	 static final d: NodeDefinition = {
		 name:"Dialogue",
		 kind: Blueprint,
		 color: 0xFF222288,
		 pins: [
			 {
				 id: 0,
				 kind: Input,
				 label: "\uf04e Input",
				 dataType: Node,
			 },
			 {
				 id: 1,
				 kind: Output,
				 label: "Output \uf04b",
				 dataType: Node
			 }
		 ]
	 };

	 override function get_def() { return d; }
	 #end
 }
