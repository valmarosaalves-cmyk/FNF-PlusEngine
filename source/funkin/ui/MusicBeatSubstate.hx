package funkin.ui;

import flixel.FlxSubState;
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

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;
	
	// Variables map for substate-specific data
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	// MusicBeatSubstate specific scripts (run on all MusicBeatSubstate instances)
	#if LUA_ALLOWED
	public static var musicBeatSubstateLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var musicBeatSubstateScript:HScript = null;
	#end

	public function new()
	{
		instance = this;
		controls.isInSubstate = true;
		super();
	}

	public var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;
	
	// Get the current substate instance
	public static function getSubstate():MusicBeatSubstate {
		return instance;
	}
	
	// Get the parent MusicBeatState
	public function getParentState():MusicBeatState {
		if(FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			return cast(FlxG.state, MusicBeatState);
		return null;
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
		controls.isInSubstate = false;
		removeTouchPad();
		removeMobileControls();
		
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

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

		// Call global script update
		MusicBeatState.callOnGlobalScript('onSubstateUpdate', [elapsed]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onUpdate', [elapsed]);

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

	public function stepHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateStepHit', [curStep]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onStepHit', [curStep]);
		
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateBeatHit', [curBeat]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onBeatHit', [curBeat]);
	}
	
	public function sectionHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateSectionHit', [curSection]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onSectionHit', [curSection]);
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
	
	public static function initMusicBeatSubstateScript():Void
	{
		// Try to load Lua MusicBeatSubstate script first
		#if (LUA_ALLOWED && sys)
		if(musicBeatSubstateLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/MusicBeatSubState.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/MusicBeatSubState.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/MusicBeatSubState.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading MusicBeatSubState Lua Script from: $luaPath');
				musicBeatSubstateLuaScript = new FunkinLua(luaPath);
				trace('MusicBeatSubState (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript MusicBeatSubstate script
		if(musicBeatSubstateScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/MusicBeatSubState.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/MusicBeatSubState.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/MusicBeatSubState.hx');
		#end
		
		if(scriptPath == null || !FileSystem.exists(scriptPath))
		{
			trace('No MusicBeatSubState script found');
			return;
		}
		
		#if HSCRIPT_ALLOWED
		try
		{
			trace('MusicBeatSubState: Loading script from: $scriptPath');
			musicBeatSubstateScript = new HScript(null, scriptPath, null, true);
			
			if(musicBeatSubstateScript == null)
			{
				trace('MusicBeatSubState: Failed to create HScript instance');
				return;
			}
			
			// Set up helper functions
			musicBeatSubstateScript.set('import', function(className:String) {
				trace('MusicBeatSubState: Import is built-in, $className should already be available');
			});
			
			// Parse and execute
			musicBeatSubstateScript.parse(true);
			musicBeatSubstateScript.execute();
			
			// Call onCreate if it exists
			if (musicBeatSubstateScript.exists('onCreate'))
			{
				musicBeatSubstateScript.call('onCreate');
				trace('MusicBeatSubState: onCreate() called successfully');
			}
			
			trace('MusicBeatSubState script initialized successfully');
		}
		catch(e:IrisError)
		{
			try {
				var errorMsg = Printer.errorToString(e, false);
				trace('MusicBeatSubState Script Error: $errorMsg');
				if(TraceDisplay.instance != null)
					TraceDisplay.addHScriptError(errorMsg, scriptPath);
			} catch(printerError:Dynamic) {
				trace('MusicBeatSubState: Error while processing IrisError: $printerError');
			}
		}
		catch(e:Dynamic)
		{
			trace('MusicBeatSubState Script Error (unexpected): $e');
			#if HSCRIPT_ALLOWED
			if(TraceDisplay.instance != null)
				TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
			#end
		}
		#end
	}
	
	public static function callOnMusicBeatSubstateScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on Lua script first
		#if LUA_ALLOWED
		if(musicBeatSubstateLuaScript != null)
		{
			var ret:Dynamic = musicBeatSubstateLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on HScript
		#if HSCRIPT_ALLOWED
		if(musicBeatSubstateScript != null && musicBeatSubstateScript.exists(funcToCall))
		{
			try {
				var callValue = musicBeatSubstateScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('MusicBeatSubState Script Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = musicBeatSubstateScript.origin != null ? musicBeatSubstateScript.origin : "MusicBeatSubState";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}
}
