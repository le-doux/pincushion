package pincushion;

import luxe.States;
import luxe.Input;

class PlayState extends State {

	var editorPin : Pin;

	override function init() {} //init

   override function onenter<T>( _focusPin:T ) {

      Luxe.events.fire("start_game");

      if (_focusPin != null) {
      	editorPin = cast _focusPin;
      }

		Pincushion.hideUI();

		for (pin in Pincushion.getAllPins()) {
			pin.startComponents();
		}   		
      
   }

	override function onleave<T>( _focusPin:T ) {
		Pincushion.showUI();

		for (pin in Pincushion.getAllPins()) {
			pin.stopComponents();
		}

		for (pin in Pincushion.getRootPins()) {
			pin.resumeStartPose();
		}
	}

	override function update(dt:Float) {
	}

	override function onmousedown( e:MouseEvent ) {
	}

	override function onmousemove( e:MouseEvent ) {
	}

	override function onmouseup( e:MouseEvent ) {
	}

	override function onkeydown( e:KeyEvent ) {
		Pincushion.switchStateInput(e, editorPin);
	}
}