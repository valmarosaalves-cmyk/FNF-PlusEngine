package funkin.ui;

import flixel.FlxState;
import funkin.graphics.PsychCamera;
import funkin.ui.debug.TraceDisplay;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end

import funkin.modding.scripting.psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

class MusicBeatState extends FlxState
{
	public var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	
	// Global scripts system
	#if LUA_ALLOWED
	public static var globalLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var globalScript:HScript = null;
	public static var publicVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var staticVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end
	
	// MusicBeatState specific scripts (run on all MusicBeatState instances but not substates)
	#if LUA_ALLOWED
	public static var musicBeatStateLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var musicBeatStateScript:HScript = null;
	#end
	
	// Global variables storage that persists across all states
	public static var globalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	// State scripting system
	public var stateScripts:Array<Dynamic> = [];
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	// Optional constructor used by ModState to pass script configuration
	public function new(?scriptsAllowed:Bool = false, ?scriptName:String = null)
	{
		super();
		this.scriptsAllowed = scriptsAllowed;
		this.scriptName = scriptName;
	}
	
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if(touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);
		
		// Fallback to NONE if extraMode is null
		if (extraMode == null)
			extraMode = NONE;

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: // LEFT_FULL
				mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: // CUSTOM
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: // HITBOX
				mobileControls = new Hitbox(extraMode);
			case 4: // HITBOX_ARROWS
				mobileControls = new Hitbox(NONE, true);
		}

		// Ensure instance is set before using it
		if (mobileControls != null && mobileControls.instance != null)
		{
			mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
			mobileControlsCam = new FlxCamera();
			mobileControlsCam.bgColor.alpha = 0;
			FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

			mobileControls.instance.cameras = [mobileControlsCam];
			mobileControls.instance.visible = false;
			add(mobileControls.instance);
		}
		else
		{
			trace('Warning: Failed to create mobile controls! extraButtons: ${ClientPrefs.data.extraButtons}, mode: ${MobileData.mode}');
		}
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}

	override function destroy()
	{
		removeTouchPad();
		removeMobileControls();
		
		// TraceDisplay cleanup if this is the last instance
		if(traceDisplay != null) {
			// Only destroy if there are no other active states
			// In practice, TraceDisplay should persist across states
		}
		
		super.destroy();
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var videoHandlers:Map<String, Dynamic> = new Map<String, Dynamic>(); // Separar videos de variables normales

	public static var traceDisplay:TraceDisplay;
	
	// Helper functions for PlayState mod scripts (simple system)
	public static function getVariables()
		return getState().variables;
		
	public static function getVideoHandlers()
		return getState().videoHandlers;

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();
		
		// Initialize TraceDisplay if it doesn't exist
		if(traceDisplay == null && TraceDisplay.instance == null) {
			traceDisplay = new TraceDisplay();
			if(FlxG.stage != null) {
				FlxG.stage.addChild(traceDisplay);
			}
		} else if (TraceDisplay.instance != null) {
			// Reuse existing instance
			traceDisplay = TraceDisplay.instance;
		}

		super.create();

		if(!skip) {
			// Call scripts before fade in - if they return Function_Stop, they handle their own transition
			var globalResult = callOnGlobalScript('onFadeIn');
			var stateResult = callOnMusicBeatStateScript('onFadeIn');
			
			// Only use default transition if scripts didn't stop it
			if(globalResult != LuaUtils.Function_Stop && stateResult != LuaUtils.Function_Stop) {
				openSubState(new CustomFadeTransition(0.7, true));
			}
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = funkin.util.WindowMode.borderlessFullscreen;
		
		// Screenshot support with F5
		#if desktop
		if (FlxG.keys.justPressed.F5)
		{
			funkin.util.Screenshot.capture();
		}
		#end
		
		// Call global script update
		callOnGlobalScript('onUpdate', [elapsed]);
		// Call MusicBeatState-specific script
		callOnMusicBeatStateScript('onUpdate', [elapsed]);
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		// Call scripts before switching - they can stop the default transition
		var globalResult = callOnGlobalScript('onSwitchState', [Type.getClassName(Type.getClass(nextState))]);
		var stateResult = callOnMusicBeatStateScript('onSwitchState', [Type.getClassName(Type.getClass(nextState))]);
		
		// If scripts stopped the transition, they handle it themselves
		if(globalResult == LuaUtils.Function_Stop || stateResult == LuaUtils.Function_Stop) {
			// Script is handling the transition, just switch without custom transition
			FlxG.switchState(nextState);
			return;
		}
		
		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		// Call scripts before resetting - they can stop the default transition
		var globalResult = callOnGlobalScript('onResetState');
		var stateResult = callOnMusicBeatStateScript('onResetState');
		
		// If scripts stopped the transition, they handle it themselves
		if(globalResult == LuaUtils.Function_Stop || stateResult == LuaUtils.Function_Stop) {
			// Script is handling the transition, just reset without custom transition
			FlxG.resetState();
			return;
		}
		
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		// Call scripts when transition starts - if they return Function_Stop, they handle their own transition
		var isReset:Bool = (nextState == FlxG.state);
		var globalResult = callOnGlobalScript('onStartTransition', [isReset, Type.getClassName(Type.getClass(nextState))]);
		var stateResult = callOnMusicBeatStateScript('onStartTransition', [isReset, Type.getClassName(Type.getClass(nextState))]);
		
		// If scripts stopped it, they're handling the transition themselves
		if(globalResult == LuaUtils.Function_Stop || stateResult == LuaUtils.Function_Stop) {
			// Script handles the transition, just switch/reset directly
			if(isReset)
				FlxG.resetState();
			else
				FlxG.switchState(nextState);
			return;
		}
		
		FlxG.state.openSubState(new CustomFadeTransition(0.7, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	// Get current substate if any
	public function getSubstate():flixel.FlxSubState {
		return subState;
	}

	public function stepHit():Void
	{
		// Call global scripts first
		callOnGlobalScript('onStepHit', [curStep]);
		// Call MusicBeatState-specific script
		callOnMusicBeatStateScript('onStepHit', [curStep]);
		
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		// Call global scripts first
		callOnGlobalScript('onBeatHit', [curBeat]);
		// Call MusicBeatState-specific script
		callOnMusicBeatStateScript('onBeatHit', [curBeat]);
		
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		// Call global scripts first
		callOnGlobalScript('onSectionHit', [curSection]);
		// Call MusicBeatState-specific script
		callOnMusicBeatStateScript('onSectionHit', [curSection]);
		
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
	
	// Global Script Management
	public static function clearAllSharedVars():Void
	{
		globalVariables.clear();
		trace('MusicBeatState: All shared vars cleared globally');
	}
	
	public static function clearModSharedVars(modName:String):Void
	{
		var keysToRemove:Array<String> = [];
		for(key in globalVariables.keys())
		{
			if(key.startsWith('${modName}_'))
				keysToRemove.push(key);
		}
		
		for(key in keysToRemove)
		{
			globalVariables.remove(key);
			trace('MusicBeatState: Removed shared var: $key');
		}
	}
	
	public static function initGlobalScript():Void
	{
		#if MODS_ALLOWED
		Mods.loadTopMod();
		#end
		
		// Try to load Lua GlobalScript first
		#if (LUA_ALLOWED && sys)
		if(globalLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/GlobalScript.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/GlobalScript.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/GlobalScript.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading Global Lua Script from: $luaPath');
				globalLuaScript = new FunkinLua(luaPath);
				trace('GlobalScript (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript GlobalScript
		if(globalScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/GlobalScript.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/GlobalScript.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/GlobalScript.hx');
		#end
		
		if(scriptPath == null) {
			trace('GlobalScript: scriptPath is null, Paths may not be initialized yet');
			return;
		}
		
		if(FileSystem.exists(scriptPath))
		{
			try
			{
				trace('GlobalScript: Loading script from: $scriptPath');
				
				// Create the script in manual mode so we can inject globals before parsing
				// This avoids parse-time errors like "Unknown variable" inside functions.
				globalScript = new HScript(null, scriptPath, null, true);
				
				if(globalScript == null) {
					trace('GlobalScript: Failed to create HScript instance');
					return;
				}
				
				trace('GlobalScript: HScript created successfully');
				
				// Initialize Maps if null (safety check)
				if(globalVariables == null) {
					trace('GlobalScript: WARNING - globalVariables was null, initializing...');
					globalVariables = new Map<String, Dynamic>();
				}
				#if HSCRIPT_ALLOWED
				if(staticVariables == null) {
					trace('GlobalScript: WARNING - staticVariables was null, initializing...');
					staticVariables = new Map<String, Dynamic>();
				}
				if(publicVariables == null) {
					trace('GlobalScript: WARNING - publicVariables was null, initializing...');
					publicVariables = new Map<String, Dynamic>();
				}
				#end
				
				trace('GlobalScript: Setting up global functions...');
				
				// Global variables functions
				try {
					globalScript.set('setGlobalVar', function(name:String, value:Dynamic) {
						if(globalVariables != null) {
							globalVariables.set(name, value);
							trace('GlobalScript: Global var set - $name = $value');
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setGlobalVar: $e');
				}
				
				try {
					globalScript.set('getGlobalVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						if (globalVariables != null && globalVariables.exists(name)) {
							return globalVariables.get(name);
						}
						return defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getGlobalVar: $e');
				}
				
				try {
					globalScript.set('hasGlobalVar', function(name:String):Bool {
						return globalVariables != null && globalVariables.exists(name);
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting hasGlobalVar: $e');
				}
				
				try {
					globalScript.set('removeGlobalVar', function(name:String):Bool {
						if (globalVariables != null && globalVariables.exists(name)) {
							globalVariables.remove(name);
							return true;
						}
						return false;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting removeGlobalVar: $e');
				}
				
				// Static variables access
				#if HSCRIPT_ALLOWED
				try {
					globalScript.set('setStaticVar', function(name:String, value:Dynamic) {
						if(staticVariables != null) {
							staticVariables.set(name, value);
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setStaticVar: $e');
				}
				
				try {
					globalScript.set('getStaticVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						return (staticVariables != null && staticVariables.exists(name)) ? staticVariables.get(name) : defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getStaticVar: $e');
				}
				
				// Public variables access
				try {
					globalScript.set('setPublicVar', function(name:String, value:Dynamic) {
						if(publicVariables != null) {
							publicVariables.set(name, value);
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setPublicVar: $e');
				}
				
				try {
					globalScript.set('getPublicVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						return (publicVariables != null && publicVariables.exists(name)) ? publicVariables.get(name) : defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getPublicVar: $e');
				}
				
				trace('GlobalScript: Functions configured successfully');
				
				// Now parse and execute the script with the injected globals available
				globalScript.parse(true);
				globalScript.execute();
				trace('GlobalScript: Script parsed and executed successfully');
				
				// Call onCreate if it exists (like PlayState and ModState do)
				try {
					if (globalScript.exists('onCreate')) {
						globalScript.call('onCreate');
						trace('GlobalScript: onCreate() called successfully');
					} else {
						trace('GlobalScript: No onCreate() function found');
					}
				} catch(e:Dynamic) {
					trace('GlobalScript: Error calling onCreate: $e');
				}
				
				trace('GlobalScript initialized successfully from: $scriptPath');
			}
			catch(e:IrisError)
			{
				trace('GlobalScript IrisError caught');
				try {
					var errorMsg = Printer.errorToString(e, false);
					trace('GlobalScript Error: $errorMsg');
					if(TraceDisplay.instance != null)
						TraceDisplay.addHScriptError(errorMsg, scriptPath);
				} catch(printerError:Dynamic) {
					trace('GlobalScript: Error while processing IrisError: $printerError');
					trace('GlobalScript: Original error object: $e');
				}
			}
			catch(e:Dynamic)
			{
				trace('GlobalScript Error (unexpected): $e');
				trace('GlobalScript Error Type: ${Type.typeof(e)}');
				#if HSCRIPT_ALLOWED
				try {
					if(TraceDisplay.instance != null)
						TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
				} catch(displayError:Dynamic) {
					trace('GlobalScript: Could not add error to TraceDisplay: $displayError');
				}
				#end
			}
		}
		else
		{
			trace('No GlobalScript found at: $scriptPath');
		}
		#end
	}
	
	public static function callOnGlobalScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on global Lua script first
		#if LUA_ALLOWED
		if(globalLuaScript != null)
		{
			var ret:Dynamic = globalLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on global HScript
		#if HSCRIPT_ALLOWED
		if(globalScript != null && globalScript.exists(funcToCall))
		{
			try {
				var callValue = globalScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('GlobalScript Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = globalScript.origin != null ? globalScript.origin : "GlobalScript";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}
	
	public static function initMusicBeatStateScript():Void
	{
		// Try to load Lua MusicBeatState script first
		#if (LUA_ALLOWED && sys)
		if(musicBeatStateLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/MusicBeatState.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/MusicBeatState.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/MusicBeatState.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading MusicBeatState Lua Script from: $luaPath');
				musicBeatStateLuaScript = new FunkinLua(luaPath);
				trace('MusicBeatState (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript MusicBeatState script
		if(musicBeatStateScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/MusicBeatState.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/MusicBeatState.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/MusicBeatState.hx');
		#end
		
		if(scriptPath == null || !FileSystem.exists(scriptPath))
		{
			trace('No MusicBeatState script found');
			return;
		}
		
		#if HSCRIPT_ALLOWED
		try
		{
			trace('MusicBeatState: Loading script from: $scriptPath');
			musicBeatStateScript = new HScript(null, scriptPath, null, true);
			
			if(musicBeatStateScript == null)
			{
				trace('MusicBeatState: Failed to create HScript instance');
				return;
			}
			
			// Set up helper functions
			musicBeatStateScript.set('import', function(className:String) {
				trace('MusicBeatState: Import is built-in, $className should already be available');
			});
			
			// Parse and execute
			musicBeatStateScript.parse(true);
			musicBeatStateScript.execute();
			
			// Call onCreate if it exists
			if (musicBeatStateScript.exists('onCreate'))
			{
				musicBeatStateScript.call('onCreate');
				trace('MusicBeatState: onCreate() called successfully');
			}
			
			trace('MusicBeatState script initialized successfully');
		}
		catch(e:IrisError)
		{
			try {
				var errorMsg = Printer.errorToString(e, false);
				trace('MusicBeatState Script Error: $errorMsg');
				if(TraceDisplay.instance != null)
					TraceDisplay.addHScriptError(errorMsg, scriptPath);
			} catch(printerError:Dynamic) {
				trace('MusicBeatState: Error while processing IrisError: $printerError');
			}
		}
		catch(e:Dynamic)
		{
			trace('MusicBeatState Script Error (unexpected): $e');
			#if HSCRIPT_ALLOWED
			if(TraceDisplay.instance != null)
				TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
			#end
		}
		#end
	}
	
	public static function callOnMusicBeatStateScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on Lua script first
		#if LUA_ALLOWED
		if(musicBeatStateLuaScript != null)
		{
			var ret:Dynamic = musicBeatStateLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on HScript
		#if HSCRIPT_ALLOWED
		if(musicBeatStateScript != null && musicBeatStateScript.exists(funcToCall))
		{
			try {
				var callValue = musicBeatStateScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('MusicBeatState Script Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = musicBeatStateScript.origin != null ? musicBeatStateScript.origin : "MusicBeatState";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}
}