package pincushion.utilities;

import luxe.Vector;
import phoenix.Batcher;
import luxe.Scene;

using utilities.PolygonGroupExtender;

class PolygonGroupExtender {
	static public function center(pGroup:Array<Polygon>) : Vector {
		var center = new Vector(0,0);

		for (poly in pGroup) {
			center.add( poly.transform.pos );
		}

		center.divideScalar( pGroup.length );

		return center;
	}

	static public function createFromJson(pGroup:Array<Polygon>, data:Dynamic, ?batcher:Batcher, ?scene:Scene, ?depthStart:Float, ?depthIncrement:Float) : Array<Polygon> {
		if (batcher == null) batcher = Luxe.renderer.batcher;
		if (scene == null) scene = Luxe.scene;
		if (depthStart == null) depthStart = 0;
		if (depthIncrement == null) depthIncrement = 1;

		var polygonList : Array<Polygon> = [];

		trace(batcher);

		if (data.layers != null) {

			for (l in cast(data.layers, Array<Dynamic>)) {
	        	var p = new Polygon({batcher: batcher, scene: scene, depth: depthStart}, [], l);
	        	polygonList.push( p );

	        	depthStart += depthIncrement;
	        }

		}
		
        pGroup = polygonList; //assign list

        return pGroup; //AND return list
	}

	static public function swap(pGroup:Array<Polygon>, i:Int, j:Int) : Array<Polygon> {
		var tmp = pGroup[i];
		pGroup[i] = pGroup[j];
		pGroup[j] = tmp;
		return pGroup;
	}

	static public function setDepths(pGroup:Array<Polygon>, baseDepth:Float, depthIncrement:Float) : Array<Polygon> {
		var i = 0;
		for (layer in pGroup) {
			layer.depth = baseDepth + ( depthIncrement * i );
			i++;
		}
		return pGroup;
	}

	static public function setDepthsRecursive(pGroup:Array<Polygon>, baseDepth:Float, depthIncrement:Float) : Float {
		var curDepth = baseDepth;

		for (layer in pGroup) {
			layer.depth = curDepth;

			if (layer.children.length > 0) {
				curDepth = layer.getChildrenAsPolys().setDepthsRecursive(curDepth, depthIncrement);
			}

			curDepth += depthIncrement;
		}

		return curDepth;
	}

	static public function setDepthsInRange(pGroup:Array<Polygon>, minDepth:Float, maxDepth:Float) : Array<Polygon> {
		var depthIncrement = (maxDepth - minDepth) / pGroup.length;
		return pGroup.setDepths(minDepth, depthIncrement);
	}

	static public function jsonRepresentation(pGroup:Array<Polygon>) {
		var jsonObj = {layers: []}
		for (p in pGroup) {
			jsonObj.layers.push(p.jsonRepresentation());
		}
		return jsonObj;
	}
}