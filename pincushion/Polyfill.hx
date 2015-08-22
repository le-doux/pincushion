package pincushion;

import luxe.Visual;
import luxe.Color;
import luxe.Vector;
import phoenix.geometry.*;
import phoenix.Batcher;

import nape.geom.Vec2;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;

using pincushion.utilities.PolylineExtender;

class Polyfill extends Visual {
	
	public var points : Array<Vector>;

	public override function new(_options : luxe.options.VisualOptions, points : Array<Vector>) {
		super(_options);

		this.points = points;

		recenter();

		geometry = new Geometry({
			primitive_type : PrimitiveType.triangles,
			batcher : _options.batcher
		});

		generateMesh();
	}

	function generateMesh() {
		//clear the mesh
		geometry.vertices = [];

		//use nape physics engine to triangulate the mesh
		var napePoints = [];
		for (p in points) {
			napePoints.push(new Vec2(p.x, p.y));
		}

		var napePoly = new GeomPoly(napePoints);

		var napeTriList = new GeomPolyList();

		napePoly.triangularDecomposition(true, napeTriList);

		//add vertices calculated by nape to the mesh
		for (napeTri in napeTriList) {
			for (napeVert in napeTri) {
				var v = new Vector(napeVert.x, napeVert.y);
				geometry.add(new Vertex(v));
			}
		}

		//recolor everything correctly
		geometry.color = color;
	}

	function recenter() {
		var c = points.polylineCenter();
		transform.pos.add(c);
		points = points.toLocalSpace(transform);
	}

	public function saveData() {
		return {
			type : "fill",
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

	public static function CreateFromSaveData(saveData : Dynamic) : Polyfill {
		var vecPoints = [];
		var i = 0;
		while (i < saveData.points.length) {
			vecPoints.push(new Vector(saveData.points[i], saveData.points[i+1]));
			i += 2;
		}

		var fill = new Polyfill({
			color : new Color(saveData.color.r, saveData.color.g, saveData.color.b, saveData.color.a),
			depth : saveData.depth,
			batcher : Luxe.renderer.batcher
		},
		vecPoints);

		fill.pos.x = saveData.x;
		fill.pos.y = saveData.y;

		return fill;
	}
}