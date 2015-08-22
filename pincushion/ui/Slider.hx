package pincushion.ui;

import luxe.Input;
import luxe.Visual;
import luxe.Color;
import luxe.Vector;
import luxe.utils.Maths;
import phoenix.geometry.*;

using pincushion.utilities.VectorExtender;

class Slider extends Visual {
	public var value (default, set) : Float;
	public var onSliderMove : Dynamic;

	var _isVertical : Bool;

	//var _sliderOutline : RectangleGeometry;

	var _sliderControl : CircleGeometry;
	//var _sliderControlOutline : RingGeometry;
	var _radius : Float;
	var _isDraggingSlider : Bool;

	override public function new(_options : luxe.options.VisualOptions) {
		super(_options);

		//is this a vertical or horizontal slider?
		_isVertical = size.y > size.x;

		//color the rectangle
		color = _options.color; //new Color(255,255,255);

		//center the rectangle
		geometry.transform.pos.x = size.x * -0.5;
		geometry.transform.pos.y = size.y * -0.5;

		//create outline for rectangle
		/*
		_sliderOutline = Luxe.draw.rectangle({
			color : new Color(255,255,255),
			w: size.x,
			h: size.y,
			x: size.x * -0.5,
			y: size.y * -0.5
		});
		_sliderOutline.transform.parent = this.transform;
		*/

		//create slider control
		_radius = (_isVertical ? (size.x * 2) : (size.y * 2));
		_sliderControl = Luxe.draw.circle({
			r : _radius,
			color : color,
			batcher: _options.batcher
		});
		/*
		_sliderControlOutline = Luxe.draw.ring({
			r : _radius + 1,
			color : new Color(255,255,255)
		});
		_sliderControlOutline.transform.parent = _sliderControl.transform;
		*/
		_sliderControl.transform.parent = this.transform;
		_sliderControl.transform.pos.y = size.y * 0.5;
	}

	override function onmousedown(e : MouseEvent) {
		if (visible) {
			var localPos = e.pos.clone().subtract(pos); //is there a way to do this conversion automatically with luxe?

			if (localPos.distance(_sliderControl.transform.pos) < _radius) { //replace with collision shape?
				_isDraggingSlider = true;
			}
		}
	}

	override function onmousemove(e : MouseEvent) {
		if (visible) {
			if (_isDraggingSlider) {
				var localPos = e.pos.clone().subtract(pos);

				if (_isVertical) {
					_sliderControl.transform.pos.y = Maths.clamp(localPos.y, -0.5 * size.y, 0.5 * size.y);
					value = (_sliderControl.transform.pos.y / size.y) + 0.5;
				}
				else {
					_sliderControl.transform.pos.x = Maths.clamp(localPos.x, -0.5 * size.x, 0.5 * size.x);
					value = (_sliderControl.transform.pos.x / size.x) + 0.5;
				}

				onSliderMove();
			}
		}	
	}

	override function onmouseup(e : MouseEvent) {
		if (visible) {
			_isDraggingSlider = false;
		}
	}

	public function setOutlineHue(hue : Float) {
		//_sliderControlOutline.color = new ColorHSV(hue, 1, 1);
		//_sliderOutline.color = new ColorHSV(hue, 1, 1);
		color = new ColorHSV(hue, 1, 1);
		_sliderControl.color = new ColorHSV(hue, 1, 1);
	}

	public function set_value(v:Float) : Float {
		value = v;
		_sliderControl.transform.pos.y = (-0.5 + value) * size.y;
		return value;
	}

	//override to set all components of the slider invisible
	override public function set_visible(isVisible:Bool) : Bool {
		super.set_visible(isVisible);

		_sliderControl.visible = visible;
		//_sliderOutline.visible = visible;
		//_sliderControlOutline.visible = visible;

		if (_isDraggingSlider && !visible) _isDraggingSlider = false;

		return visible;
	}
}