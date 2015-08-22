package pincushion;

import luxe.Input;
import luxe.Color;
import luxe.Vector;
import luxe.Entity;
import luxe.States;
import luxe.Camera;
import luxe.Scene;
import phoenix.Batcher;
import snow.types.Types;
import luxe.Parcel;

import mint.render.luxe.LuxeMintRender;
import mint.render.luxe.Convert;
import mint.layout.margins.Margins;

#if desktop
import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;
#end

import haxe.io.Path;

using pincushion.utilities.EntityExtender;
using pincushion.utilities.TransformExtender;
using pincushion.utilities.VectorExtender;

//for now
import pincushion.components.TestComponent;
import pincushion.components.TestRotationComponent;

//TODO
// - figure out to fix this: flags : ['--macro include("components", true)'],
// - excise "goToFrame2"
// - mouse based panning & zooming
// - auto save
// - undo / redo

class Pincushion extends luxe.Game {

	//singleton
	public static var instance : Pincushion;

	//state machine
    static var machine : States;

    //rendering
    public static var pinBatcher : Batcher;
    public static var uiBatcher : Batcher;
    var uiCamera : Camera;

	//constants
	static var rotationIncrement = 10;
	static var scaleIncrement = 0.1;
	static var zoomIncrement = 0.2;
	static var panIncrement = 20;

    //mint ui
    public static var mintCanvas : mint.Canvas;
    static var mintRender : LuxeMintRender;
    public static var mintLayout : Margins;

    var isInterfaceVisible = true;

    //saving / loading
    public static var currentScenePath : String; //last file saved or opened

    //building
    var isReleaseBuild = false;
    var startScene : String;

    override function ready() {

    	instance = this;

        Luxe.snow.window.title = "Pincushion";

        //states
    	machine = new States({name:"editor_state_machine"});
        machine.add(new DrawingState({name:"drawing"}));
    	machine.add(new PinningState({name:"pinning"}));
    	machine.add(new AnimationState({name:"animation"}));
        machine.add(new ComponentState({name:"component"}));
        machine.add(new PlayState({name:"play"}));

        //rendering & camera
        Luxe.renderer.clear_color = new ColorHSV(250, 0.5, 0.3); //blue
        Luxe.renderer.state.lineWidth(2); //do this just for pins later

    	pinBatcher = Luxe.renderer.create_batcher({name:"pinBatcher", layer:2, camera:Luxe.camera.view});

        var uiScene = new Scene("uiScene");
        uiCamera = new Camera({name:"uiCamera", scene: uiScene});
        uiCamera.size = Luxe.screen.size;
        uiCamera.size_mode = SizeMode.contain;
        uiBatcher = Luxe.renderer.create_batcher({name: "uiBatcher", layer: 10, camera: uiCamera.view});

        keepViewCenteredOnWindowResize();

        //mint ui
        mintRender = new LuxeMintRender({batcher:uiBatcher});
        mintLayout = new Margins();
        mintCanvas = new mint.Canvas({
            rendering: mintRender,
            x: 0, y:0, w: 960, h: 640
        });

        Luxe.events.listen("start_game", on_start_game);

        if (isReleaseBuild) {
            hideUI();

            //this version only works on desktop
            /*
            var localPath = "assets/" + startScene + ".csh/";
            var path = Luxe.io.app_path + "/" + localPath;
            
            var files = sys.FileSystem.readDirectory(path);
            var pinFiles = files.filter(function(f) { 
                return Path.extension(f).toLowerCase() == "pin";
            });

            var jsonFiles = [];
            for (i in 0 ... pinFiles.length) {
                jsonFiles.push({id: localPath + pinFiles[i]});
            }
            */

            //hacky version that might work everywhere
            var sceneFiles = AssetPaths.all.filter( function(f) return f.indexOf(startScene + ".csh") != -1 );
            var pinFiles = sceneFiles.filter( function(f) return Path.extension(f).toLowerCase() == "pin" );
            var jsonFiles = pinFiles.map( function (f) return {id:f} );

            trace(pinFiles);

            var parcel = new Parcel({
                jsons: jsonFiles
            });

            new luxe.ParcelProgress({
                parcel: parcel,
                background  : new Color(1,1,1,0.85),
                oncomplete  : scene_loaded
            });

            parcel.load();
        }
        else {
            machine.set("drawing", null);
        }
    } //ready

    function scene_loaded(p : Parcel) {
        for (j in p.loaded) {
            Pin.CreateFromSaveData(Luxe.resources.json(j).asset.json);
        }

        switchEditorState("play", null);
    }

    function on_start_game(e : Dynamic) {}

    override function onrender() {
        mintCanvas.render();
    }

    #if desktop
    override function onevent(e:SystemEvent) {
        if (e.type == SystemEventType.file) {
            if (e.file.type == FileEventType.modify) {

                //get input from file
                var input = File.read(e.file.path, false);
                var inStr = ""; 
                while (!input.eof()) { //I need to stop copy-pasting this shit
                    inStr += input.readLine();
                }
                var inObj = haxe.Json.parse(inStr);

                //get pin name
                var splitPath = e.file.path.split("/");
                var fileName = splitPath[splitPath.length - 1];
                var pinName = fileName.substring(0, fileName.indexOf(".json"));

                //get pin
                var curPin = null;
                for (pin in getAllPins()) {
                    if (pin.name == pinName) curPin = pin;
                }

                //update component information
                if (curPin != null) {
                    for (componentName in Reflect.fields(inObj)) {
                        curPin.replaceComponentData(componentName, Reflect.getProperty(inObj, componentName));
                    }
                }
            }
        }

        //OLD CODE: keeping this as reminder to implement auto save
        /*
        else if (e.type == SystemEventType.window) {
            //hack for error: snow.types.WindowEventType should be Null<snow.types.WindowEvent>
            if (e.window.type == WindowEventType.focus_lost) {
                autoSaveOn = false;
            }
            else if (e.window.type == WindowEventType.focus_gained) {
                autoSaveOn = true;
            }
        }
        */
    }
    #end

    override function onkeydown( e:KeyEvent ) {
        mintCanvas.keydown( Convert.key_event(e) );

        #if desktop

            if (e.keycode == Key.key_s && e.mod.meta) {

                if (e.mod.shift) {
                    save( currentScenePath ); //save
                }
                else {
                    save( Luxe.core.app.io.module.dialog_save() ); //save as
                }

                //watch component settings
                Luxe.core.app.io.module.watch_add(currentScenePath + "/_component_settings");
            }
            else if (e.keycode == Key.key_o && e.mod.meta) {
                open( Luxe.core.app.io.module.dialog_folder() ); //open file

                //watch component settings
                Luxe.core.app.io.module.watch_add(currentScenePath + "/_component_settings");
            }

        #end
        
        if (e.keycode == Key.key_h && e.mod.ctrl) { //show / hide UI
            if (isInterfaceVisible) {
                hideUI();
            }
            else {
                showUI();
            }
            isInterfaceVisible = !isInterfaceVisible;
        }
    }

    override function onkeyup( e:KeyEvent ) {
        mintCanvas.keyup( Convert.key_event(e) );

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function ontextinput(e:luxe.Input.TextEvent) {
        mintCanvas.textinput( Convert.text_event(e) );
    }

    override function update(dt:Float) {
        mintCanvas.update(dt);

        if (Luxe.renderer.batchers.indexOf(uiBatcher) != -1) { //optimization for play mode
            drawGrid();
        }
    } //update

    override function onmousedown( e:MouseEvent ) {
        mintCanvas.mousedown( Convert.mouse_event(e) );
    }

    override function onmousemove( e:MouseEvent ) {
        mintCanvas.mousemove( Convert.mouse_event(e) );
    }

    override function onmousewheel(e) {
        mintCanvas.mousewheel( Convert.mouse_event(e) );
    }

    override function onmouseup( e:MouseEvent ) {
        mintCanvas.mouseup( Convert.mouse_event(e) );
    }

    override function onwindowresized(e) {
        uiCamera.size = Luxe.screen.size; 
    }

    ////
    ////

    public static function switchEditorState(name : String, focusPin : Pin) {
    	machine.set(name, focusPin);
    }

    public static function switchStateInput(e : KeyEvent, focusPin : Pin) {
        //STATE CHANGES
        if (e.keycode == Key.key_1 && machine.current_state.name != "drawing") {
            switchEditorState("drawing", focusPin);
        }
        else if (e.keycode == Key.key_2 && machine.current_state.name != "pinning") {
            switchEditorState("pinning", focusPin);
        }
        else if (e.keycode == Key.key_3 && machine.current_state.name != "animation") {
            switchEditorState("animation", focusPin);
        }
        else if (e.keycode == Key.key_4 && machine.current_state.name != "component") {
            switchEditorState("component", focusPin);
        }
        else if (e.keycode == Key.key_5 && machine.current_state.name != "play") {
            switchEditorState("play", focusPin);
        }
    }

    public static function getRootPins() : Array<Pin> {
    	var pins : Array<Pin> = [];

    	for (e in Luxe.scene.entities) {
    		if (Std.is(e, Pin)) {
    			pins.push(cast e);
    		}
    	}

    	return pins;
    }

    public static function getAllPins() : Array<Pin> {
    	var pins : Array<Pin> = [];

    	var searchList : Array<Pin> = getRootPins();

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

    public static function touchPin(pos : Vector) : Pin {
    	var pin = null;

    	for (p in getAllPins()) {

			if ( (Vector.Subtract(p.worldPos(), pos)).length < 10 ) {
				pin = p;
			}

		}

		return pin;
    }

    public static function editPin(e : KeyEvent, focusPin : Pin) : Pin {
		if (e.keycode == Key.left) { //rotation
			focusPin.rotation_z -= rotationIncrement;
		}
		else if (e.keycode == Key.right) {
			focusPin.rotation_z += rotationIncrement;
		}
		else if (e.keycode == Key.up) { //scale
			focusPin.scale.add(new Vector(scaleIncrement, scaleIncrement));
		}
		else if (e.keycode == Key.down) {
			focusPin.scale.subtract(new Vector(scaleIncrement, scaleIncrement));
		}
		else if (e.keycode == Key.backspace) {
			focusPin.destroy();
			focusPin = null;
		}

		return focusPin;
    }

    public static function panScene(e : KeyEvent) {
    	if (e.keycode == Key.left) {
    		Luxe.camera.pos.add(new Vector(-panIncrement, 0));
    	}
    	else if (e.keycode == Key.right) {
    		Luxe.camera.pos.add(new Vector(panIncrement, 0));
    	}

    	if (e.keycode == Key.up) {
    		Luxe.camera.pos.add(new Vector(0, -panIncrement));
    	}
    	else if (e.keycode == Key.down) {
    		Luxe.camera.pos.add(new Vector(0, panIncrement));
    	}
    }

    public static function zoomScene(e : KeyEvent) {
    	if (e.keycode == Key.minus) {
    		Luxe.camera.zoom -= zoomIncrement;
    	}
    	else if (e.keycode == Key.equals) {
    		Luxe.camera.zoom += zoomIncrement;
    	}
    }

    function keepViewCenteredOnWindowResize() {
        //this keeps the screen centered nicely on resize
        Luxe.camera.size = Luxe.screen.size;
    }

    function drawGrid() {
        var totalPanDist = Luxe.camera.pos;
        
        var baseGridSize = 50.0;
        var gridSize = baseGridSize;

        var x = (-totalPanDist.x * Luxe.camera.zoom) % gridSize;
        var y = (-totalPanDist.y * Luxe.camera.zoom) % gridSize;

        while (x < Luxe.screen.w) {
            Luxe.draw.line({
                p0 : new Vector(x, 0),
                p1 : new Vector(x, Luxe.screen.h),
                color : new Color(1,1,1,0.15),
                immediate : true,
                batcher : uiBatcher
            });
            x += gridSize;
        }

        while (y < Luxe.screen.h) {    
            Luxe.draw.line({
                p0 : new Vector(0, y),
                p1 : new Vector(Luxe.screen.w, y),
                color : new Color(1,1,1,0.15),
                immediate : true,
                batcher : uiBatcher
            }); 
            y += gridSize;
        }
    }

    public static function hideUI() {
        Luxe.renderer.remove_batch(pinBatcher);
        Luxe.renderer.remove_batch(uiBatcher);
    }
    
    public static function showUI() {
        Luxe.renderer.add_batch(pinBatcher);
        Luxe.renderer.add_batch(uiBatcher);
    }

    public static function save(path : String) {

        //saving and opening only works on desktop (fail silently otherwise)
        #if desktop

            var rootPins = getRootPins();

            //var rawPath = Luxe.core.app.io.module.dialog_save().split(".");
            //var path = rawPath[0];
            path = path.split(".")[0];
            path += ".csh";

            //save pins
            sys.FileSystem.createDirectory(path);

            for (pin in rootPins) {
                var output = File.write(path + "/" + pin.name + ".pin", false);
                var outStr = haxe.Json.stringify( pin.saveData() );
                output.writeString(outStr);
                output.close();
            }

            //save components
            var compDirPath = path  + "/_component_settings";
            sys.FileSystem.createDirectory(compDirPath);

            for (pin in rootPins) {
                sys.FileSystem.createDirectory(compDirPath + "/" + pin.name);

                var compData = pin.componentSaveData();
                var compStr = haxe.Json.stringify(compData, null, "    ");

                if (compData != null) {
                    var output = File.write(compDirPath + "/" + pin.name + "/" + pin.name + ".json");
                    output.writeString(compStr);
                    output.close();
                }

                //some copy and pasting here
                for (child in pin.allChildPins()) {
                    compData = child.componentSaveData();
                    compStr = haxe.Json.stringify(compData, null, "    ");

                    if (compData != null) {
                        var output = File.write(compDirPath + "/" + pin.name + "/" + child.name + ".json");
                        output.writeString(compStr);
                        output.close();
                    }
                }
            }

            currentScenePath = path;

        #end
    }

    public static function open(path : String) {

        #if desktop

            var pinFiles = sys.FileSystem.readDirectory(path);

            for (fileName in pinFiles) {

                if (fileName.substring(fileName.length - 4) == ".pin") {

                    var input = File.read(path + "/" + fileName);

                    //read all - regardless of how many lines it is
                    var inStr = "";

                    while (!input.eof()) {
                        inStr += input.readLine();
                    }

                    var inObj = haxe.Json.parse(inStr);

                    Pin.CreateFromSaveData(inObj);

                    input.close();

                }

            }

            currentScenePath = path;

        #end

    }
}