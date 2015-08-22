package pincushion.utilities;

import luxe.Entity;

using pincushion.utilities.VectorExtender;
using pincushion.utilities.EntityExtender;
using pincushion.utilities.TransformExtender;

class EntityExtender {
	public static function worldPos(e: Entity) {
		if (e.parent != null) {
			return e.pos.toWorldSpace(e.parent.transform);
		}
		return e.pos;
	}

	public static function setParentButPreserveTransform(e : Entity, parent : Entity) {
		//preserve size and position and rotation
		e.pos = e.worldPos().toLocalSpace(parent.transform);
		e.scale = parent.transform.worldScaleToLocalScale(e.scale);
		e.transform.setRotationZ( parent.transform.worldRotationToLocalRotationZ( e.transform.getRotationZ() ) );

		e.parent = parent;
	}
}