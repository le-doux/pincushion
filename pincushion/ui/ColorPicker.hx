package pincushion.ui;

import luxe.Input;
import luxe.Visual;
import luxe.Color;
import luxe.Vector;
import luxe.utils.Maths;
import phoenix.geometry.*;

using pincushion.utilities.VectorExtender;

class ColorPicker extends Visual {
	public var pickedColor (default, set) : ColorHSV = new ColorHSV(0, 0, 1);

	var _steps : Int = 360;
	var _radius : Float;

	var _selector : RingGeometry;

	public var onColorChange : Dynamic;

	override public function new(_options : luxe.options.VisualOptions) {
		super(_options);

		_radius = scale.x; //this of course breaks if it's not a circle

		//generate circle geometry
		geometry = Luxe.draw.circle({
			r : 1,
			steps: _steps,
			batcher: _options.batcher
		});

		//color the circle geometry like a rainbow
		for (i in 0 ... _steps) {
			var curH = (cast(i,Float) / _steps) * 360.0;
    		var nextH = ((cast(i,Float) + 1.0) / _steps) * 360.0;

			geometry.vertices[i*3].color = new ColorHSV(0, 0, 1);
			geometry.vertices[(i*3) + 1].color = new ColorHSV(curH, 1, 1);
			geometry.vertices[(i*3) + 2].color = new ColorHSV(nextH, 1, 1);
		}

		_selector = Luxe.draw.ring({
			r : 0.1,
			color : new Color(0,0,0),
			depth : this.depth + 1,
			steps : _steps,
			batcher: _options.batcher
		});
		//_selector.transform.pos = new Vector(0,0);
		_selector.transform.parent = this.transform;
	}

	override function onmousedown(e : MouseEvent) {
		if (visible) {
			if (pos.distance(e.pos) < _radius) { //replace with collision shape?
				updatePickedColor(e.pos);
				_selector.transform.pos = Vector.Divide(Vector.Subtract(e.pos, pos), _radius);
			}
		}
	}

	override function onmousemove(e : MouseEvent) {
		if (visible && Luxe.input.mousedown(1)) {
			if (pos.distance(e.pos) < _radius) { //replace with collision shape?
				updatePickedColor(e.pos);
				_selector.transform.pos = Vector.Divide(Vector.Subtract(e.pos, pos), _radius);
			}
		}
	}

	function updatePickedColor(point : Vector) {
		var hueVector = point.clone().subtract(pos);

		pickedColor.h = Maths.degrees(Math.atan2(hueVector.normalized.y, hueVector.normalized.x)) + 90.0;
		pickedColor.s = Math.min(hueVector.length, _radius) / _radius;

		if (onColorChange != null) onColorChange();
	}

	public function set_pickedColor(c:ColorHSV) : ColorHSV {
		pickedColor.h = c.h;
		pickedColor.s = c.s;
		pickedColor.v = c.v;
		return pickedColor;
	}

	public function setV(v) {
		pickedColor.v = v;
		//updateColorWheelValue();
	}

	public function setA(a) {
		pickedColor.a = a;
	}

	function updateColorWheelValue() {
        for (v in geometry.vertices) {
            var tmp = v.color.toColorHSV();
            tmp.v = Math.max(pickedColor.v, 0.01); //hack to stop color from defaulting to white when the slider goes to zero
            v.color = tmp.toColor();
        }
    }

    override public function set_visible(isVisible:Bool) : Bool {
    	super.set_visible(isVisible);
    	_selector.visible = isVisible;
    	return visible;
    }
}