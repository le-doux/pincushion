package pincushion.components;

import pincushion.components.EditorComponent;
import luxe.Component;
import luxe.Vector;

class TestComponent extends EditorComponent {
	public var testMessage = "you've found the right type!";

	@editor(30)
	public var speed : Float;

	@editor
	public var otherValue : Int;

	override function init() {
		trace("test component created!");
	}

	override function update(dt : Float) {
		trace("update " + dt);
		var v = new Vector(0, speed);
		pos.add(Vector.Multiply(v, dt));
	}

	override function onremoved() {
		trace("test component removed!");
	}
}
