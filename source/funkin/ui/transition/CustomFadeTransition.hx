package funkin.ui.transition;

import flixel.util.FlxGradient;
import funkin.ui.debug.TraceDisplay;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

import funkin.modding.scripting.psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;
	
	// CustomFadeTransition specific scripts
	#if LUA_ALLOWED
	public static var customTransitionLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var customTransitionScript:HScript = null;
	#end
	
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));
		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		if(isTransIn)
			transGradient.y = transBlack.y - transBlack.height;
		else
			transGradient.y = -transGradient.height;

		super.create();
		
		// Set 'this' in scripts for access to transition instance
		setScriptInstance();
		
		// Call scripts onCreate
		callOnCustomTransitionScript('onCreate', [isTransIn, duration]);
	}

	override function update(elapsed:Float) {
		// Call script update - if returns Function_Stop, skip default transition behavior
		var scriptResult = callOnCustomTransitionScript('onUpdate', [elapsed, isTransIn]);
		
		super.update(elapsed);

		// If script handled update completely, skip default behavior
		if(scriptResult == LuaUtils.Function_Stop) return;
		
		final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
		if(duration > 0)
			transGradient.y += (height + targetPos) * elapsed / duration;
		else
			transGradient.y = (targetPos) * elapsed;

		if(isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;

		if(transGradient.y >= targetPos)
		{
			// Call script before finishing
			callOnCustomTransitionScript('onFinish', [isTransIn]);
			
			close();
			if(finishCallback != null) finishCallback();
			finishCallback = null;
		}
	}
	
	public static function initCustomTransitionScript():Void
	{
		// Try to load Lua script first
		#if (LUA_ALLOWED && sys)
		if(customTransitionLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/CustomFadeTransition.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/CustomFadeTransition.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/CustomFadeTransition.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading CustomFadeTransition Lua Script from: $luaPath');
				customTransitionLuaScript = new FunkinLua(luaPath);
				trace('CustomFadeTransition (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript
		if(customTransitionScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/CustomFadeTransition.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/CustomFadeTransition.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/CustomFadeTransition.hx');
		#end
		
		if(scriptPath == null || !FileSystem.exists(scriptPath))
		{
			trace('No CustomFadeTransition script found');
			return;
		}
		
		#if HSCRIPT_ALLOWED
		try
		{
			trace('CustomFadeTransition: Loading script from: $scriptPath');
			customTransitionScript = new HScript(null, scriptPath, null, true);
			
			if(customTransitionScript == null)
			{
				trace('CustomFadeTransition: Failed to create HScript instance');
				return;
			}
			
			// Parse and execute
			customTransitionScript.parse(true);
			customTransitionScript.execute();
			
			trace('CustomFadeTransition script initialized successfully');
		}
			catch(e:IrisError)
			{
				try {
					var errorMsg = Printer.errorToString(e, false);
					trace('CustomFadeTransition Script Error: $errorMsg');
					if(TraceDisplay.instance != null)
						TraceDisplay.addHScriptError(errorMsg, scriptPath);
				} catch(printerError:Dynamic) {
					trace('CustomFadeTransition: Error while processing IrisError: $printerError');
				}
			}
			catch(e:Dynamic)
			{
				trace('CustomFadeTransition Script Error (unexpected): $e');
				#if HSCRIPT_ALLOWED
				if(TraceDisplay.instance != null)
					TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
				#end
			}
		#end
	}
	
	// Set this instance in scripts
	public function setScriptInstance():Void
	{
		#if LUA_ALLOWED
		if(customTransitionLuaScript != null)
		{
			customTransitionLuaScript.set('this', this);
		}
		#end
		
		#if HSCRIPT_ALLOWED
		if(customTransitionScript != null)
		{
			customTransitionScript.set('this', this);
		}
		#end
	}
	
	public function callOnCustomTransitionScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on Lua script first
		#if LUA_ALLOWED
		if(customTransitionLuaScript != null)
		{
			var ret:Dynamic = customTransitionLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on HScript
		#if HSCRIPT_ALLOWED
		if(customTransitionScript != null && customTransitionScript.exists(funcToCall))
		{
			try {
				var callValue = customTransitionScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('CustomFadeTransition Script Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = customTransitionScript.origin != null ? customTransitionScript.origin : "CustomFadeTransition";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}
}
