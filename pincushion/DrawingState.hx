package pincushion;

import luxe.States;
import luxe.Input;
import luxe.Color;
import luxe.Vector;
import luxe.Entity;
import luxe.Visual;
import luxe.tween.*;

import pincushion.ui.ColorPicker;
import pincushion.ui.Slider;

using pincushion.utilities.EntityExtender;
using pincushion.utilities.TransformExtender;
using pincushion.utilities.VectorExtender;
using pincushion.utilities.PolylineExtender;

class DrawingState extends State {

	var currentVisuals : Array<Visual> = [];

	var points : Array<Vector>;
	var isDrawing : Bool;

	var tool = 0; //0 - stroke, 1 - fill
	var minDist = 10;

	//pin
	var pin : Pin;
	var defaultPinColor = new Color(255,255,255);
	var selectedPinColor = new Color(0,255,0);

	//ui
	var picker : ColorPicker;
	var vSlider : Slider; //value
	var aSlider : Slider; //alpha

	var curColor = new Color(255,0,255);

	override function init() {
		picker = new ColorPicker({
			scale : new Vector(200,200),
			batcher : Pincushion.uiBatcher
		});
		picker.visible = false;
		curColor = picker.pickedColor;

		vSlider = new Slider({
            size : new Vector(10, 200),
            batcher: Pincushion.uiBatcher,
            color : new Color(255,255,255)
        });
        vSlider.onSliderMove = function() {
            picker.setV(vSlider.value);
        };
        vSlider.visible = false;

        aSlider = new Slider({
            size : new Vector(10, 200),
            batcher: Pincushion.uiBatcher,
            color : new Color(0,0,0)
        });
        aSlider.onSliderMove = function() {
            picker.setA(aSlider.value);
        };
        aSlider.visible = false;

    } //init

    override function onenter<T>( _focusPin:T ) {
    	if (_focusPin != null) {
   			pin = cast _focusPin;
   			currentVisuals = pin.visualChildren;
   		}
   		else {
   			currentVisuals = [];
   		}
   	}

   	override function onleave<T>( _focusPin:T ) {
   		if (pin == null) {
   			for (vis in currentVisuals) {
   				vis.destroy();
   			}
   		}
   		currentVisuals = [];

   		pin = null;
   	}

	override function update(dt:Float) {
		if (tool == 0) {
			Luxe.draw.ring({
				x : Luxe.screen.cursor.pos.x,
				y : Luxe.screen.cursor.pos.y,
				r : 6,
				color : curColor,
				batcher : Pincushion.uiBatcher,
				immediate : true
			});
		}
		else if (tool == 1) {
			Luxe.draw.circle({
				x : Luxe.screen.cursor.pos.x,
				y : Luxe.screen.cursor.pos.y,
				r : 6,
				color : curColor,
				batcher : Pincushion.uiBatcher,
				immediate : true
			});
		}

		if (isDrawing) {
			for (i in 0 ... points.length - 1) {
				Luxe.draw.line({
					p0 : points[i],
					p1 : points[i+1],
					color : curColor,
					immediate : true,
					depth : 1000 //hack to keep the line on top
				});
			}
		}

		if (pin != null) {
   			pin.drawOutline(selectedPinColor);
   		}

   		Luxe.draw.circle({
   			r : 15,
   			x : 20,
   			y : 20,
   			color : curColor,
   			batcher : Pincushion.uiBatcher,
   			immediate : true
   		});
   	}

   	override function onmousedown( e:MouseEvent ) {
   		var mouseWorldPos = Luxe.camera.screen_point_to_world(e.pos);

   		if (picker.visible) {
   			//don't do anything
   		}
   		else if (Luxe.input.keydown(Key.lctrl)) {
   			//pin floating visuals
   			if (currentVisuals.length > 0 && pin == null) {
   				var newPin = new Pin({pos: mouseWorldPos, batcher: Luxe.renderer.batcher, name:"Pin", name_unique:true, color: defaultPinColor.clone()});
   				for (vis in currentVisuals) {
   					vis.setParentButPreserveTransform(newPin);
   				}
   				currentVisuals = [];
   				newPin.pushAnimation();
   			}
   		}
   		else if (Luxe.input.keydown(Key.lalt)) {
   			//clear current visuals
   			for (vis in currentVisuals) {
   				if (vis.parent == null) {
   					vis.destroy();
   				}
   			}
   			currentVisuals = [];

   			//select pin
   			pin = Pincushion.touchPin(mouseWorldPos);
   			if (pin != null) {
   				currentVisuals = pin.visualChildren;
   			}
   		}
   		else {
   			//draw
	   		if (!isDrawing) {
		   		isDrawing = true;
		   		points = [];
		   		points.push(mouseWorldPos);
	   		}
	   		else {
	   			if (tool == 1) {
		   			points.push(mouseWorldPos);
	   				checkFillComplete();
	   			}
	   		}
   		}

   	}

   	override function onmousemove( e:MouseEvent ) {
   		var mouseWorldPos = Luxe.camera.screen_point_to_world(e.pos);

   		if (isDrawing && Luxe.input.mousedown(1)) {
   			if (points[points.length - 1].distance(mouseWorldPos) >= minDist) {
   				points.push(mouseWorldPos);
   			}

   			if (tool == 1) {
   				checkFillComplete();
   			}
   		}
   	}

   	override function onmouseup( e:MouseEvent ) {
   		var mouseWorldPos = Luxe.camera.screen_point_to_world(e.pos);

   		if (isDrawing) {
   			if (tool == 0) {
	   			if (points[points.length - 1].distance(mouseWorldPos) >= minDist) {
	   				points.push(mouseWorldPos);
	   			}
	   			isDrawing = false;

	   			addStroke();
   			}
   		}
   	}

   	override function onkeydown( e:KeyEvent ) {

   		//STATE CHANGES
   		/*
   		if (e.keycode == Key.key_2) {
   			Pincushion.switchEditorState("pinning", pin);
   		}
   		else if (e.keycode == Key.key_3) {
   			Pincushion.switchEditorState("animation", pin);
   		}
   		else if (e.keycode == Key.key_4) {
   			Pincushion.switchEditorState("component", pin);
   		}
   		*/

   		Pincushion.switchStateInput(e, pin);

   		//swap tools
   		if (e.keycode == Key.tab) {
   			tool = (tool + 1) % 2;
   		}

   		//delete visual
   		if (e.keycode == Key.backspace) {
   			if (currentVisuals.length > 0) {
   				var vis = currentVisuals[currentVisuals.length - 1];
   				currentVisuals.remove(vis);
   				vis.destroy();
   			}
   		}

   		//color picker
   		if (e.keycode == Key.key_c) {
   			if (!picker.visible) {
   				picker.visible = true;
   				picker.pos = Luxe.screen.cursor.pos.clone();

   				//animate picker
   				picker.scale.x = 0;
   				picker.scale.y = 0;
   				Actuate.tween(picker.scale, 0.5, {x : 200, y : 200})
   					.ease(luxe.tween.easing.Elastic.easeOut)
   					.onComplete(function() {
   						if (picker.visible) {
	   						vSlider.pos = Vector.Add(picker.pos, new Vector(230, 0));
	   						vSlider.visible = true;

	   						aSlider.pos = Vector.Add(picker.pos, new Vector(-230, 0));
	   						aSlider.visible = true;
   						}
   					});
   			}
   		}
   	}

   	override function onkeyup( e:KeyEvent ) {
   		//color picker
   		if (e.keycode == Key.key_c) {
   			if (picker.visible) {
   				picker.visible = false;
   				vSlider.visible = false;
   				aSlider.visible = false;
   			}
   		}
   	}

   	function checkFillComplete() {
		var test = points.polylineIntersections();

		if (test.intersects) {
			isDrawing = false;

			points = points.polylineSplit(test.intersectionList[0]).closedLine;

			addFill();
		}
   	}

   	function addFill() {
   		var fill = new Polyfill(
   		{
   			color : curColor.clone(), 
   			batcher : Luxe.renderer.batcher,
   			depth : cast(currentVisuals.length, Float) //keep new drawings on top
   		}, 
   		points);

		currentVisuals.push(fill);
		if (pin != null) {
			fill.setParentButPreserveTransform(pin);
		}
   	}

   	function addStroke() {
		var stroke = new Polystroke(
		{
			color : curColor.clone(), 
			batcher : Luxe.renderer.batcher,
   			depth : cast(currentVisuals.length, Float) 
		}, 
		points);

		currentVisuals.push(stroke);
		if (pin != null) {
			stroke.setParentButPreserveTransform(pin);
		}
   	}
}