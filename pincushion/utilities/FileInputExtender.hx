package pincushion.utilities;

import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;

import phoenix.Batcher;
import luxe.Scene;

using utilities.PolygonGroupExtender;

//TODO: Fix NULLs for old files
class FileInputExtender {
	static public function readScene(input:FileInput, ?batcher:Batcher, ?scene:Scene, ?depthStart:Float, ?depthIncrement:Float) : Array<Polygon> {
		
		/*
		if (batcher == null) batcher = Luxe.renderer.batcher;
		if (depthStart == null) depthStart = 0;
		if (depthIncrement == null) depthIncrement = 1;
		*/

		//var polygonList : Array<Polygon> = [];
		

		var inStr = "";
        while (!input.eof()) {
            inStr += input.readLine();
        }

        var inObj = haxe.Json.parse(inStr);

        trace(inObj);

        /*
        for (l in cast(inObj.layers, Array<Dynamic>)) {2
        	var p = new Polygon({batcher: batcher, depth: depthStart}, [], l);
        	polygonList.push( p );

        	depthStart += depthIncrement;
        }

        return polygonList;
        */

        //return inObj.jsonToScene(batcher, depthStart, depthIncrement);
        //return DynamicExtender.jsonToScene(inObj, batcher, scene, depthStart, depthIncrement);

        /*
        var scene : Array<Polygon>;
        scene.createFromJson(inObj, batcher, scene, depthStart, depthIncrement);
        return scene;
        */

        return (new Array<Polygon>()).createFromJson(inObj, batcher, scene, depthStart, depthIncrement);
	}
}