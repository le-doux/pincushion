package pincushion;

import luxe.Visual;
import luxe.Color;
import luxe.Vector;
import phoenix.geometry.*;
import phoenix.Batcher;

using pincushion.utilities.PolylineExtender;

class Polystroke extends Visual {
	
	public var points : Array<Vector>;

	public override function new(_options : luxe.options.VisualOptions, points : Array<Vector>) {
		super(_options);

		this.points = points;

		recenter();

		geometry = new Geometry({
			primitive_type: PrimitiveType.line_strip,
			batcher: _options.batcher
		});

		generateMesh();
	}

	//should this be public?
	public function generateMesh() {
		geometry.vertices = [];
		for (p in points) {
			geometry.add(new Vertex(p,color));
		}
	}

	//should this be public?
	public function recenter() {
		var c = points.polylineCenter();
		transform.pos.add(c);
		points = points.toLocalSpace(transform);
	}

	public function saveData() {
		return {
			type : "stroke",
			x : pos.x,
			y : pos.y,
			color : {
				r : color.r,
				g : color.g,
				b : color.b,
				a : color.a
			},
			depth : depth,
			points : points.toFloatArray()
		}
	}

	public static function CreateFromSaveData(saveData : Dynamic) : Polystroke {
		var vecPoints = [];
		var i = 0;
		while (i < saveData.points.length) {
			vecPoints.push(new Vector(saveData.points[i], saveData.points[i+1]));
			i += 2;
		}

		var stroke = new Polystroke({
			color : new Color(saveData.color.r, saveData.color.g, saveData.color.b, saveData.color.a),
			depth : saveData.depth,
			batcher : Luxe.renderer.batcher
		},
		vecPoints);

		stroke.pos.x = saveData.x;
		stroke.pos.y = saveData.y;

		return stroke;
	}
}