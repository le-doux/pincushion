package pincushion;

import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import sys.FileSystem;

using StringTools;
/**
 * ...
 * @author Kevin
 */
class AssetPathsMacro
{

	macro public static function build(path:String = 'assets/'):Array<Field>
	{
		path = Path.addTrailingSlash(path);
		path = Context.resolvePath(path);
		
		var files = readDirectory(path);
		
		
		
		var fields:Array<Field> = Context.getBuildFields();
			
		for (f in files)
		{
			// create new field based on file references!
			fields.push({
				name: f.name,
				doc: f.value,
				access: [APublic, AStatic, AInline],
				kind: FVar(macro:String, macro $v{ f.value }),
				pos: Context.currentPos()
			});
		}
		
		fields.push({
			name: "all",
			doc: "A list of all asset paths",
			access: [APublic, AStatic],
			kind: FVar(macro:Array<String>, macro $a{files.map(function(f) return macro $v{f.value})}),
			pos: Context.currentPos(),
		});
		
		return fields;
	}
	
	private static function readDirectory(path:String)
	{
		path = Path.addTrailingSlash(path);
		
		var result = [];
		
		for(f in FileSystem.readDirectory(path))
		{
			var fullpath = path + f;
			if (FileSystem.isDirectory(fullpath)) 
				result = result.concat(readDirectory(fullpath));
			else
				result.push({name:convertPathToVarName(fullpath), value:fullpath});
		}
		
		return result;
	}
	
	private static function convertPathToVarName(path:String)
	{
		return path.replace("/", "__").replace(".", "_").replace(" ", "_").replace("-", "_");
	}
}