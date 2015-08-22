package pincushion.utilities;

import luxe.Transform;
import luxe.Vector;
import luxe.Quaternion;
import luxe.utils.Maths;

using pincushion.utilities.TransformExtender;
using pincushion.utilities.VectorExtender;

class TransformExtender {
	static public function up(t:Transform) {
		var upV = new Vector(0.0, 1.0);
		upV.applyQuaternion(t.rotation);
		
		var parent = t.parent;
		while (parent != null) {
			upV.applyQuaternion(parent.rotation);
			parent = parent.parent;
		}

		return upV;
	}

	static public function right(t:Transform) {
		var rightV = new Vector(1.0, 0.0);
		rightV.applyQuaternion(t.rotation);

		var parent = t.parent;
		while (parent != null) {
			rightV.applyQuaternion(parent.rotation);
			parent = parent.parent;
		}

		return rightV;
	}

	static public function localUp(t:Transform) {
		var upV = new Vector(0.0, 1.0);
		upV.applyQuaternion(t.rotation);
		return upV;
	}

	static public function localRight(t:Transform) {
		var rightV = new Vector(1.0, 0.0);
		rightV.applyQuaternion(t.rotation);
		return rightV;
	}

	static public function rotate(t:Transform, a:Float) { //rotates right (remember a == radians --- change later?)
		var rot = ( new Quaternion() ).setFromAxisAngle( new Vector(0,0,1), a );
		t.rotation.multiply(rot);
	}

	static public function rotateY(t:Transform, a:Float) { //rotates "inward"
        var rot = ( new Quaternion() ).setFromAxisAngle( new Vector(0,1,0), a );
        t.rotation.multiply(rot);
	}

	static public function setRotationZ(t:Transform, degrees:Float) {
		var rot = ( new Quaternion() ).setFromAxisAngle( new Vector(0,0,1), Maths.radians(degrees) );
		t.rotation = rot;
	}

	static public function getRotationZ(t:Transform) : Float {
		return t.rotation.toeuler().z;
	}

	/*
	static public function convertToLocalScale(t:Transform, scale:Vector) : Vector {
		var localScale = scale.clone().divide(t.scale);
		var parent = t.parent;
		while (parent != null) {
			localScale.divide(parent.scale);
			parent = parent.parent;
		}
		return localScale;
	}
	*/

	static public function worldRotationToLocalRotationZ(t:Transform, rotation_z:Float) : Float {
		var euler = new Vector().setEulerFromQuaternion(t.rotation);
		rotation_z -= Maths.degrees(euler.z);
		if (t.parent != null) {
			rotation_z = t.parent.worldRotationToLocalRotationZ(rotation_z);
		}
		return rotation_z;
	}

	static public function worldScaleToLocalScale(t:Transform, scale:Vector) : Vector {
		scale.x /= t.scale.x;
		scale.y /= t.scale.y;
		if (t.parent != null) scale = t.parent.worldScaleToLocalScale(scale);
		return scale;
	}

	static public function worldVectorToLocalSpace(t:Transform, v:Vector) : Vector {
		return v.toLocalSpace(t);
	}

	static public function localVectorToWorldSpace(t:Transform, v:Vector) : Vector {
		return v.toWorldSpace(t);
	}
}