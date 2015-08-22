package pincushion;

import luxe.Visual;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;
import phoenix.Batcher;
import luxe.tween.*;
import luxe.utils.Maths;
import luxe.Component;

import haxe.rtti.Meta;

using pincushion.utilities.EntityExtender;
using pincushion.utilities.TransformExtender;

typedef Pose = {
	public var x : Float;
	public var y : Float;
	public var rotation_z : Float;
	public var scale : Float;
};

typedef Frame = {
	public var percent : Float; //total percent into animation
	public var poseChanges : Map<String, Pose>;
};

typedef Animation = {
	public var name : String;
	public var time : Float; //how long the animation runs
	public var frames : Array<Frame>;
};

class Pin extends Visual {

	//pin data
	@:isVar public var data (get, set) : Pose;

	//animation
	var startPose : Pose; //where this pin starts for all animations (what about its children?)
	public var animations : Map<String, Animation> = new Map<String, Animation>();
	public var animationNames (get, null) : Array<String>;
	public var curAnimation : String;
	var animationDelta (default, set) : Float;

	//children accessors
	public var childPins (get, null) : Array<Pin>; //rename this shit
	public var visualChildren (get, null) : Array<Visual>;

	//components
	var componentData : Map<String, Dynamic> = new Map<String, Dynamic>();
	public var componentNames (get, null) : Array<String>;
	
	override public function new(_options : luxe.options.VisualOptions) {
		super(_options);

		geometry = Luxe.draw.circle({
			r : 10,
			batcher : Pincushion.pinBatcher
		});
		geometry.color = _options.color;

		//init pin data
		startPose = data;
	}

	override public function update(dt: Float) {
		if (Luxe.renderer.batchers.indexOf(Pincushion.pinBatcher) != -1) { //optimization for play mode
			drawPinPoint();
			if (parent != null) drawParentConnection();
		}
	}

	//a bit of a hack - rethink this interface later?
	public function replaceComponentData(className : String, data : Dynamic) {
		componentData.set(className, data);
	}

	public function registerComponent(className : String) {
		var classData = {
			name : className
		};

		//load class metadata
		//var metadata = Meta.getFields(Type.resolveClass("pincushion.components." + className));
		var metadata = Meta.getFields(Type.resolveClass("components." + className));
		//var metadata = Meta.getFields(Type.resolveClass(className));

		//populate editor fields
		for (fieldName in Reflect.fields(metadata)) {
			var field = Reflect.field(metadata, fieldName);

			if (Reflect.hasField(field, "editor")) { //make sure we're looking at the right type of meta property
				if (field.editor != null && field.editor.length > 0) { //use default value
					Reflect.setField(classData, fieldName, Reflect.field(metadata, fieldName).editor[0]);
				}
				else { //has no default value
					Reflect.setField(classData, fieldName, null);
				}
			}
		}

		componentData.set(className, classData);
	}

	public function unregisterComponent(className : String) {
		componentData.remove(className);
	}

	public function startComponents() {
		for (className in componentData.keys()) {
			var data = componentData.get(className);
			//var component : Component = Type.createInstance(Type.resolveClass("pincushion.components." + className), [data]);
			var component : Component = Type.createInstance(Type.resolveClass("components." + className), [data]);
			//var component : Component = Type.createInstance(Type.resolveClass(className), [data]);
			add(component);
		}
	}

	public function stopComponents() {
		for (className in componentData.keys()) {
			if (has(className)) remove(className);
		}
	}

	function get_componentNames() : Array<String> {
		var names = [];
		for (n in componentData.keys()) {
			names.push(n);
		}
		return names;
	}

	//falling animation
	public function pushAnimation() {
		geometry.color.a = 0;
		Actuate.tween(geometry.color, 0.3, {a: 1});

		//falling animation
		var fallDist = 20;
		pos.y -= fallDist;
		return Actuate.tween(pos, 0.5, {y: pos.y + fallDist}).ease(luxe.tween.easing.Elastic.easeOut);
	}

	function drawPinPoint() {
		Luxe.draw.line({
			p0 : worldPos(),
			p1 : Vector.Add( worldPos(), transform.up().multiplyScalar( 20 * data.scale ) ),
			color : geometry.color,
			immediate : true,
			batcher : Pincushion.pinBatcher
		});
	}

	public function drawOutline(c : Color) {
		Luxe.draw.ring({
			x : worldPos().x,
			y : worldPos().y,
			r : 15 * data.scale,
			depth : 1000, //hack
			color : c,
			immediate : true,
			batcher : Pincushion.pinBatcher
		});
	}

	function drawParentConnection() {
		Luxe.draw.line({
			p0 : worldPos(),
			p1 : parent.worldPos(),
			immediate : true,
			batcher : Pincushion.pinBatcher
		});
	}

	function get_animationNames() : Array<String> {
		var a = [];
		for (anim in animations) {
			a.push(anim.name);
		}
		return a;
	}

	public function animate(name : String, ?time : Float) {
		if (time == null) time = animations.get(name).time;

		curAnimation = null; //hack to keep animation delta from updating the position immediately (stops flashing on reverse)
		animationDelta = 0.0; //without the hack, this causes flashing w/ reverse animations
		curAnimation = name;

		return Actuate.tween(this, time, {animationDelta : 1.0});
	}

	public function setStartPose() {
		startPose = data;
	}

	public function resumeStartPose() {
		data = startPose;

		for (p in childPins) {
			p.resumeStartPose();
		}
	}

	public function newAnimation(animationName : String, time : Float) {
		animations.set(animationName, {
			name : animationName,
			time : time,
			frames : []
		});

		newFrame(animationName, 0);
	}

	public function goToFrame(animationName : String, index : Int) {
		var frame = animations.get(animationName).frames[index];

		pose(frame.poseChanges.get(name));

		for (p in allChildPins()) {
			p.pose(frame.poseChanges.get(p.name));
		}
	}

	public function goToFrame2(frame : Frame) {
		pose(frame.poseChanges.get(name));

		for (p in allChildPins()) {
			p.pose(frame.poseChanges.get(p.name));
		}
	}

	function sortFrames(animationName : String) {
		var anim = animations.get(animationName);
		anim.frames.sort(function (f1, f2) {
			if (f1.percent > f2.percent) {
				return 1;
			}
			else if (f1.percent < f2.percent) {
				return -1;
			}
			else {
				return 0;
			}
		});
	}

	public function newFrame(animationName : String, d : Float) : Frame {
		var prevFrameIndex = -1;
		for (f in animations.get(animationName).frames) {
			if (f.percent >= d) break;
			prevFrameIndex++;
		}

		if (prevFrameIndex == -1) {
			resumeStartPose();
		}
		else {
			goToFrame(animationName, prevFrameIndex);
		}

 		var frame = {
 			percent : d,
 			poseChanges : generateFrameDataFromCurrentPose()
 		}

 		animations.get(animationName).frames.push(frame);

 		sortFrames(animationName);

 		return frame;
	}

	//public function moveFrame(animationName : String, index : Int, d : Float) {
	//	var frame = animations.get(animationName).frames[index];
	public function moveFrame(animationName : String, frame : Frame, d : Float) {
		frame.percent = d;

		sortFrames(animationName);
	}

	//public function updateFrame(animationName : String, index : Int) {
	//	var frame = animations.get(animationName).frames[index];
	public function updateFrame(animationName : String, frame : Frame) {
		frame.poseChanges = generateFrameDataFromCurrentPose();
	}

	function set_animationDelta(d : Float) : Float {
		animationDelta = d;
		if (curAnimation != null) {
			animationLerp(curAnimation, animationDelta);
		}
		return animationDelta; //part of a hack for reverse animations (will this kill other things?)

		//well who cares because the hack works!!!!11!!!

		//old code that is probably smarter and better
		/*else {
			return -1;
		}*/
	}

	function generateFrameDataFromCurrentPose() : Map<String, Pose> {
		var changes = new Map<String, Pose>();

		changes.set(name, distanceFromStartPose());

		for (p in allChildPins()) {
			changes.set(p.name, p.distanceFromStartPose());
		}

		return changes;
	}

	public function distanceFromStartPose(?pose : Pose) : Pose {
		if (pose == null) pose = data;
		return {
			x : pose.x - startPose.x,
			y : pose.y - startPose.y,
			rotation_z : pose.rotation_z - startPose.rotation_z,
			scale : pose.scale - startPose.scale
		}
	}

	public function pose(poseChange : Pose) {
		data = {
			x : startPose.x + poseChange.x,
			y : startPose.y + poseChange.y,
			rotation_z : startPose.rotation_z + poseChange.rotation_z,
			scale : startPose.scale + poseChange.scale
		}
	}

	function animationLerp(animationName : String, totalDelta : Float) {

		var curAnimation = animations.get(animationName).frames;
		for (i in 1 ... curAnimation.length) {
			var frameStart = curAnimation[i - 1];
			var frameEnd = curAnimation[i];

			
			if (frameStart.percent <= totalDelta && frameEnd.percent >= totalDelta) {
				
				var d = (totalDelta - frameStart.percent) / (frameEnd.percent - frameStart.percent);

				
				pose( poseLerp(frameStart.poseChanges.get(name), frameEnd.poseChanges.get(name), d) );

				for (p in allChildPins()) {
					p.pose( poseLerp(frameStart.poseChanges.get(p.name), frameEnd.poseChanges.get(p.name), d) );
				}

				break;
			}

		}
	}

	function poseLerp(p1 : Pose, p2 : Pose, d : Float) : Pose {
		return {
			x : Maths.lerp(p1.x, p2.x, d),
			y : Maths.lerp(p1.y, p2.y, d),
			rotation_z : Maths.lerp(p1.rotation_z, p2.rotation_z, d),
			scale : Maths.lerp(p1.scale, p2.scale, d)
		};
	}

	function get_data() : Pose {
		return {
			x : pos.x,
			y : pos.y,
			rotation_z : rotation_z,
			scale : scale.x
		}; 
	}

	function set_data(d : Pose) : Pose {

		pos.x = d.x;
		pos.y = d.y;
		rotation_z = d.rotation_z;
		scale.x = d.scale;
		scale.y = d.scale;

		return d;
	}

	function get_childPins() : Array<Pin> {
		var pins : Array<Pin> = [];
		for (c in children) {
			if (Std.is(c, Pin)) {
				pins.push(cast c);
			}
		}
		return pins;
	} 

	public function allChildPins() : Array<Pin> {
		var pins : Array<Pin> = [];

    	var searchList : Array<Pin> = childPins;

    	while (searchList.length > 0) {
    		var pin = searchList[0];

    		for (c in pin.childPins) {
    			searchList.push(c);
    		}

    		searchList.remove(pin);
    		pins.push(pin);
    	}

    	return pins;
	}

	function get_visualChildren() : Array<Visual> {
		var visuals : Array<Visual> = [];
		for (c in children) {
			if (Std.is(c, Visual) && !Std.is(c, Pin)) {
				visuals.push(cast c);
			}
		}
		return visuals;
	}

	public function rootPin() : Pin {
		if (parent == null || !Std.is(parent, Pin)) {
			return this;
		}
		else {
			return rootPin();
		}
	}

	public function saveData() : Dynamic {
		var childrenSaveData = [];
		for (pin in childPins) {
			childrenSaveData.push( pin.saveData() );
		}

		var visualSaveData = [];
		for (vis in visualChildren) {
			if (Std.is(vis, Polystroke)) {
				visualSaveData.push( cast(vis, Polystroke).saveData() );
			}
			else if (Std.is(vis, Polyfill)) {
				visualSaveData.push( cast(vis, Polyfill).saveData() );
			}
		}

		return {
			name : name,
			startPose : startPose,
			children : childrenSaveData,
			visuals : visualSaveData,
			animations : animations,
			componentData : componentData
		};
	}

	public function componentSaveData() : Dynamic {
		if (componentNames.length > 0) {
			return componentData;
		}
		else {
			return null;
		}
	}

	public static function CreateFromSaveData(saveData : Dynamic) : Pin {

		//create pin
		var newPin = new Pin({
			name : saveData.name,
			pos : new Vector(saveData.startPose.x, saveData.startPose.y),
			rotation_z : saveData.startPose.rotation_z,
			//scale : new Vector(saveData.startPose.scale, saveData.startPose.scale),
			color : new Color(255,255,255)
		});

		//hack - for some reason replacing the scale with a vector fucks up the transform
		//when children try to access it
		newPin.scale.x = saveData.startPose.scale;
		newPin.scale.y = saveData.startPose.scale;

		//create visual children
		for (visData in cast(saveData.visuals, Array<Dynamic>)) {
			if (visData.type == "stroke") {
				var newStroke = Polystroke.CreateFromSaveData(visData);
				newStroke.parent = newPin;
			}
			else if (visData.type == "fill") {
				var newFill = Polyfill.CreateFromSaveData(visData);
				newFill.parent = newPin;
			}
		}

		//create pin children (recursive)
		for (childData in cast(saveData.children, Array<Dynamic>)) {
			var childPin = Pin.CreateFromSaveData(childData);
			childPin.parent = newPin;
		}

		//assign animation data (recreate two levels of Maps - sad but true)
		//newPin.animations = saveData.animations;
		for (animationName in Reflect.fields(saveData.animations)) {
			var anim = Reflect.getProperty(saveData.animations, animationName);

			for (f in cast(anim.frames, Array<Dynamic>)) {
				var poseMap = new Map<String, Pose>();

				for (poseName in Reflect.fields(f.poseChanges)) {
					var pose = Reflect.getProperty(f.poseChanges, poseName);
					poseMap.set(poseName, pose);
				}

				f.poseChanges = poseMap;
			}

			newPin.animations.set(animationName, anim);
		}

		//assign component data (recreate the Map)
		for (componentName in Reflect.fields(saveData.componentData)) {
			newPin.componentData.set(componentName, Reflect.getProperty(saveData.componentData, componentName));
		}

		return newPin;
	}
}