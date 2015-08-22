package pincushion;

import luxe.States;
import luxe.Input;
import luxe.Color;
import luxe.Vector;
import luxe.Entity;

using pincushion.utilities.EntityExtender;
using pincushion.utilities.TransformExtender;
using pincushion.utilities.VectorExtender;

class PinningState extends State {

	var curPin : Pin;
	var isPinDraggable : Bool;

	var defaultPinColor = new Color(255,255,255);
	var selectedPinColor = new Color(255,0,0);

	override function init() {
    } //init

    override function onenter<T>( _focusPin:T ) {
   		if (_focusPin != null) {
   			curPin = cast _focusPin;	
   			curPin.color = defaultPinColor.clone();
   		}
   	}

   	override function onleave<T>( _focusPin:T ) {
   	}

   	override function update(dt:Float) {
   		if (curPin != null) {
   			curPin.setStartPose();
   			curPin.drawOutline(selectedPinColor);
   		}
   	}

   	override function onmousedown( e:MouseEvent ) {
   		var mouseWorldPos = Luxe.camera.screen_point_to_world(e.pos);

   		if (Luxe.input.keydown(Key.lctrl)) {  		
	    	//create new pin
	    	curPin = new Pin({pos: mouseWorldPos, name:"Pin", name_unique:true, color: defaultPinColor.clone()});
    		curPin.pushAnimation();
    	}
    	else if (Luxe.input.keydown(Key.lalt)) {
    		//parent pin
    		if (curPin != null) {
    			var parentPin = Pincushion.touchPin(mouseWorldPos);

    			if (parentPin != null) {
    				curPin.setParentButPreserveTransform(parentPin);
    				curPin.setStartPose();
    			}
    		}
    	}
    	else {
	    	//select pin
    		curPin = Pincushion.touchPin(mouseWorldPos); 
    		if (curPin != null) isPinDraggable = true;
    	}

   	}

   	override function onmousemove( e:MouseEvent ) {
   		if (isPinDraggable) {
   			var dragPos = Luxe.camera.screen_point_to_world(e.pos);
   			if (curPin.parent != null) dragPos = curPin.parent.transform.worldVectorToLocalSpace(dragPos);
   			curPin.pos = dragPos;
   		}
   	}

   	override function onmouseup( e:MouseEvent ) {
   		isPinDraggable = false;
   	}

   	override function onkeydown( e:KeyEvent ) {

   		//STATE CHANGES
   		/*
   		if (e.keycode == Key.key_1) {
   			Pincushion.switchEditorState("drawing", curPin);
   		}
   		else if (e.keycode == Key.key_3) {
   			Pincushion.switchEditorState("animation", curPin);
   		}
   		else if (e.keycode == Key.key_4) {
   			Pincushion.switchEditorState("component", curPin);
   		}
   		*/
   		Pincushion.switchStateInput(e, curPin);

   		if (curPin != null) {
   			curPin = Pincushion.editPin(e, curPin);
   		}

   		if (e.mod.shift) {
   			Pincushion.panScene(e);
   		}

   		if (e.mod.meta) {
   			Pincushion.zoomScene(e);
   		}
   	}
}