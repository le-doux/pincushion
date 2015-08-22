package pincushion;

import luxe.States;
import luxe.Input;
import luxe.Color;

import mint.types.Types.TextAlign;
import mint.layout.margins.Margins;

class ComponentState extends State {

	var curPin : Pin;

	var defaultPinColor = new Color(255,255,255);
	var selectedPinColor = new Color(0,0,255);

	//mint ui
	var componentWindow : mint.Window;
	var componentList : mint.List;

	override function init() {

		componentWindow = new mint.Window({
			parent: Pincushion.mintCanvas,
			name: 'componentWindow',
			title: 'Pin Name',
            x:160, y:10, w:256, h: 400,
            w_min: 256, h_min:256,
            closable: false
		});

		
		var _addComponentButton = new mint.Button({
			parent: componentWindow, name: 'button_add',
        	x: 4+4, y:28, w:124-4, h:18,
        	text: 'add component', 
        	onclick: function(e,c) {
        		if (curPin != null) loadComponent();
        	}
		});

		var _editComponentsButton = new mint.Button({
			parent: componentWindow, name: 'button_add',
        	x: 4+124+4, y:28, w:124-4, h:18,
        	text: 'edit components', 
        	onclick: function(e,c) {
            #if desktop
          		if (curPin != null && curPin.componentNames.length > 0 && Pincushion.currentScenePath != null) {
          			//open or focus Sublime Text
          			Sys.command("open '/Applications/Sublime Text 3.app/Contents/SharedSupport/bin/subl'");
          			//open this file in Sublime Text
              		Sys.command(
              			"'/Applications/Sublime Text 3.app/Contents/SharedSupport/bin/subl' " + 
  			                Pincushion.currentScenePath + "/_component_settings/" + curPin.rootPin().name + "/" + curPin.name + ".json");
          		}
            #end
        	}
		});

		componentWindow.close();
    } //init

    function loadComponent() {
    	
      #if desktop
        //load
        var rawOpenFileName = Luxe.core.app.io.module.dialog_open( "Load Component", [{extension:"hx"}] ).split(".");
        var openFileName = rawOpenFileName[0];
        var fileNameSplit = openFileName.split("/"); //need to change for other OSs?
        var className = fileNameSplit[fileNameSplit.length-1];
        curPin.registerComponent(className);
      #end
    }

    override function onenter<T>( _focusPin:T ) {
   		if (_focusPin != null) {
   			curPin = cast _focusPin;	
   			curPin.color = defaultPinColor.clone();

   			componentWindow.title.text = curPin.name;
   			refreshComponentList();
   		}

   		componentWindow.open();
   	}

   	override function onleave<T>( _focusPin:T ) {
   		componentWindow.close();
   	}

   	override function update(dt:Float) {
   		if (curPin != null) curPin.drawOutline(selectedPinColor);

   		if (curPin != null) {
   			if (componentList.items.length != curPin.componentNames.length) {
   				refreshComponentList();
   			}
   		}
   	}

   	override function onmousedown( e:MouseEvent ) {
   		var mouseWorldPos = Luxe.camera.screen_point_to_world(e.pos);

   		//select pin
   		if (Luxe.input.keydown(Key.lctrl)) {
	    	curPin = Pincushion.touchPin(mouseWorldPos); 
	    	if (curPin != null) {
	    		componentWindow.title.text = curPin.name;	
	    		refreshComponentList();
	    	}
   		}
   	}

   	override function onmousemove( e:MouseEvent ) {
   	}

   	override function onmouseup( e:MouseEvent ) {
   	}

   	override function onkeydown( e:KeyEvent ) {
   		//STATE CHANGES
   		/*
   		if (e.keycode == Key.key_1) {
   			Pincushion.switchEditorState("drawing", curPin);
   		}
   		else if (e.keycode == Key.key_2) {
   			Pincushion.switchEditorState("pinning", curPin);
   		}
   		else if (e.keycode == Key.key_3) {
   			Pincushion.switchEditorState("animation", curPin);
   		}
   		*/

   		Pincushion.switchStateInput(e, curPin);
   	}

    function refreshComponentList() {
    	if (componentList != null) {
    		componentList.clear();
    	}

    	if (curPin != null) {

	    	componentList = new mint.List({
	            parent: componentWindow,
	            name: 'list1',
	            x: 4, y: 28+18+4, w: 248, h: 400-28-4-18-4
	        });

	        for (c in curPin.componentNames) {
	        	var li = componentListItem(c, componentList);
	        	componentList.add_item(li, 0, 0);
	        }

	        Pincushion.mintLayout.margin(componentList, left, fixed, 4);
    	}
    }

    function componentListItem(name : String, _list : mint.List) : mint.Panel {
    	var _panel = new mint.Panel({
    		parent: _list,
            name: 'panel_${name}',
            x:2, y:4, w:236, h:26,
    	});

    	Pincushion.mintLayout.margin(_panel, right, fixed, 8);

    	var _title = new mint.Label({
            parent: _panel, name: 'label_${name}',
            mouse_input:true, x:4, y:4, w:148, h:18, text_size: 16,
            align: TextAlign.left, align_vertical: TextAlign.top,
            text: name,
        });

        var _removeButton = new mint.Button({
        	parent: _panel, name: 'button_${name}',
        	x: 150, y:4, w:50, h:18,
        	text: 'remove', 
        	onclick: function(e,c) { 
        		if (curPin != null) {
        			curPin.unregisterComponent(name);
        		}
        	}
        });

    	return _panel;
    }
}