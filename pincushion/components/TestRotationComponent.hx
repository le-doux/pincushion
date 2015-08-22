package pincushion.components;

import pincushion.components.EditorComponent;
import luxe.Component;

class TestRotationComponent extends EditorComponent {

	@editor(10)
	public var rotationSpeed : Float;

	override function init() {
	}

	override function update(dt : Float) {
		cast(entity, luxe.Visual).rotation_z += rotationSpeed * dt;
	}

	override function onremoved() {
	}
}
