/*
 * Copyright (C) 2026 Lenin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software.
 *
 * This Software may not be claimed as the original work of any other
 * individual or entity.
 *
 * Attribution to the original author is appreciated, but is not required.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 *
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package funkin.mobile.backend.native;

#if android
import haxe.Json;
import lime.system.JNI;

/**
 * JNI bridge for Android native MD3 dropdown component.
 */
class AndroidNativeDropDown
{
	public static inline var NO_SELECTION:Int = -1;
	public static inline var CANCELED:Int = -2;

	@:noCompletion private static var _initialized:Bool = false;
	@:noCompletion private static var _showDropDown_jni:Dynamic = null;
	@:noCompletion private static var _pollSelection_jni:Dynamic = null;
	@:noCompletion private static var _isDialogVisible_jni:Dynamic = null;

	@:noCompletion
	private static function ensureInit():Bool
	{
		if (_initialized)
			return _showDropDown_jni != null && _pollSelection_jni != null && _isDialogVisible_jni != null;

		_initialized = true;
		try
		{
			_showDropDown_jni = JNI.createStaticMethod(
				'com/leninasto/plusengine/components/DropDown',
				'showDropDown',
				'(Ljava/lang/String;Ljava/lang/String;I)Z'
			);

			_pollSelection_jni = JNI.createStaticMethod(
				'com/leninasto/plusengine/components/DropDown',
				'pollSelection',
				'()I'
			);

			_isDialogVisible_jni = JNI.createStaticMethod(
				'com/leninasto/plusengine/components/DropDown',
				'isDialogVisible',
				'()Z'
			);
		}
		catch (e:Dynamic)
		{
			trace('[AndroidNativeDropDown] JNI init failed: ' + e);
		}

		return _showDropDown_jni != null && _pollSelection_jni != null && _isDialogVisible_jni != null;
	}

	public static function show(title:String, items:Array<String>, selectedIndex:Int):Bool
	{
		if (items == null || items.length == 0)
			return false;

		if (!ensureInit())
			return false;

		try
		{
			return _showDropDown_jni(title, Json.stringify(items), selectedIndex);
		}
		catch (e:Dynamic)
		{
			trace('[AndroidNativeDropDown] show failed: ' + e);
		}

		return false;
	}

	public static function pollSelection():Int
	{
		if (!ensureInit())
			return NO_SELECTION;

		try
		{
			return _pollSelection_jni();
		}
		catch (e:Dynamic)
		{
			trace('[AndroidNativeDropDown] pollSelection failed: ' + e);
		}

		return NO_SELECTION;
	}

	public static function isDialogVisible():Bool
	{
		if (!ensureInit())
			return false;

		try
		{
			return _isDialogVisible_jni();
		}
		catch (e:Dynamic)
		{
			trace('[AndroidNativeDropDown] isDialogVisible failed: ' + e);
		}

		return false;
	}
}
#else
class AndroidNativeDropDown
{
	public static inline var NO_SELECTION:Int = -1;
	public static inline var CANCELED:Int = -2;

	public static function show(title:String, items:Array<String>, selectedIndex:Int):Bool
		return false;

	public static function pollSelection():Int
		return NO_SELECTION;

	public static function isDialogVisible():Bool
		return false;
}
#end