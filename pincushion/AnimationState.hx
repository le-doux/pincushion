package pincushion;

import luxe.States;
import luxe.Input;
import luxe.Color;
import luxe.Vector;
import luxe.Entity;

using pincushion.utilities.TransformExtender;

class AnimationState extends State {

	var animPin : Pin;
	var curPin : Pin;
	var isPinDraggable : Bool;

	var curAnimation : String;
	var curFrame : Pin.Frame;
	var isFrameDraggable : Bool;
	var isAnimating : Bool;

	var defaultPinColor = new Color(255,255,255);
	var selectedPinColor = new Color(255,0,0);
	var animPinColor = new Color(255,0,255);
	
	override function init() {
    } //init

    override function onenter<T>( _focusPin:T ) {
   		if (_focusPin != null) {
   			animPin = cast _focusPin;
			animPin.color = animPinColor.clone();

   			curPin = animPin;

   			if (animPin.animationNames.length > 0) {
   				curAnimation = animPin.animationNames[0];
   				curFrame = animPin.animations.get(curAnimation).frames[0];
   				animPin.goToFrame2(curFrame);
   			}
   		}
   	}

   	override function onleave<T>( _focusPin:T ) {
   		if (animPin != null) animPin.color = defaultPinColor.clone();

   		curAnimation = null;
   		curFrame = null;

   		for (p in Pincushion.getRootPins()) {
   			p.resumeStartPose();
   		}
   	}

   	override function update(dt:Float) {   	
		if (curAnimation != null) {

			Luxe.draw.text({
	            color: new Color(255,255,255),
	            pos : new Vector(30, 560),
	            point_size : 20,
	            text : curAnimation,
	            immediate : true,
	            batcher : Pincushion.uiBatcher
			});

    		Luxe.draw.line({
    			p0 : new Vector(30, 600),
    			p1 : new Vector(30 + 800, 600),
    			batcher : Pincushion.uiBatcher,
    			immediate : true
    		});

    		for (f in animPin.animations.get(curAnimation).frames) {
    			Luxe.draw.circle({
    				x : 30 + (800 * f.percent),
    				y : 600,
    				r : 10,
    				batcher : Pincushion.uiBatcher,
    				immediate : true,
    				color : (f == curFrame ? new Color(0,255,0) : new Color(255,255,255))
    			});
    		}

    		if (curFrame != null && !isAnimating) animPin.updateFrame(curAnimation, curFrame);
		}

		if (curPin != null && !isAnimating) {
   			curPin.drawOutline(selectedPinColor);
		}
   	}

   	override function onmousedown( e:MouseEvent ) {
   		if (e.pos.y > 580) { //hack
   			if (animPin != null && curAnimation != null) {		
				if (Luxe.input.keydown(Key.lctrl)) {
					//NEW FRAME
					if (e.pos.x >= 30 && e.pos.x <= 830) {
						var d = (e.pos.x - 30) / 800;
						curFrame = animPin.newFrame(curAnimation, d);
					}
				}
				else {
					//SELECT FRAME
					for (f in animPin.animations.get(curAnimation).frames) {
						if (Math.abs(e.pos.x - (30 + (f.percent * 800))) < 10) {
							curFrame = f;
							animPin.goToFrame2(curFrame);
							isFrameDraggable = true;
						}
					}
				}
   			}
		}
		else {
	    	//select pin
    		curPin = Pincushion.touchPin(Luxe.camera.screen_point_to_world(e.pos));
    		if (curPin != null) isPinDraggable = true;
		}
   	}

   	override function onmousemove( e:MouseEvent ) {
		if (isFrameDraggable && curFrame != null) {
			animPin.moveFrame(curAnimation, curFrame, (e.pos.x - 30) / 800);
		}

   		if (isPinDraggable) {
   			var dragPos = Luxe.camera.screen_point_to_world(e.pos);
   			if (curPin.parent != null) dragPos = curPin.parent.transform.worldVectorToLocalSpace(dragPos);
   			curPin.pos = dragPos;
   		}
    }

    override function onmouseup( e:MouseEvent ) {
    	isFrameDraggable = false;
    	isPinDraggable = false;
    }

   	override function onkeydown( e:KeyEvent ) {
   		//STATE CHANGES
   		/*
   		if (e.keycode == Key.key_1) {
   			Pincushion.switchEditorState("drawing", animPin);
   		}
   		else if (e.keycode == Key.key_2) {
   			Pincushion.switchEditorState("pinning", animPin);
   		}
   		else if (e.keycode == Key.key_4) {
   			Pincushion.switchEditorState("component", curPin);
   		}
   		*/

   		Pincushion.switchStateInput(e, animPin);

   		if (animPin != null) {

   			//BASIC PIN EDITTING
   			curPin = Pincushion.editPin(e, curPin);

   			//ADD ANIMATION
   			if (e.keycode == Key.key_y) {
				curAnimation = "animation" + animPin.animationNames.length;
				animPin.newAnimation(curAnimation, 5);
				curFrame = animPin.animations.get(curAnimation).frames[0];
			}

			//SWITCH ANIMATION
			if (e.keycode == Key.key_j) {
				var nextIndex = (animPin.animationNames.indexOf(curAnimation) + 1) % animPin.animationNames.length;
				curAnimation = animPin.animationNames[nextIndex];
				backToFirstFrame();
			}
			else if (e.keycode == Key.key_h) {
				var nextIndex = (animPin.animationNames.indexOf(curAnimation) - 1) % animPin.animationNames.length;
				if (nextIndex < 0) nextIndex = animPin.animationNames.length - 1; //why doesn't mod work right? D':
				curAnimation = animPin.animationNames[nextIndex];
				backToFirstFrame();
			}

   			if (curAnimation != null) {

   				//PLAY ANIMATION
				if (e.keycode == Key.key_u) {
					isAnimating = true;
					animPin.animate(curAnimation).onComplete(function() { 
						isAnimating = false; 
						backToFirstFrame();
					});
				}
   			}
   		}
   	}

   	function backToFirstFrame() {
		curFrame = animPin.animations.get(curAnimation).frames[0];
		animPin.goToFrame2(curFrame);
   	}
}