package data;

import cerastes.Utils;
import cerastes.data.Nodes.NodeDefinition;
import cerastes.flow.Flow;

/**
 * Puts text on the screen
 */
 class DialogueNode extends FlowNode
 {
	 @editor("Dialogue","StringMultiline")
	 public var dialogue: String;

	 public override function process( runner: FlowRunner )
	 {
		Utils.info( 'Dialogue: ${dialogue}' );
		nextAll(runner);
	 }

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
