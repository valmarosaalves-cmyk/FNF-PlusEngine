package lenin.slushithings.windows;

import sys.*;
#if windows
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import lime.app.Application;
import lenin.slushithings.windows.WindowsCPP;
#end

/**
 * API wrapper for Windows native functionality
 * Based on Slushi Engine implementation
 */
class WindowsAPI
{
	#if windows
	static var closingTween:NumTween;
	static var isClosing:Bool = false;
	#end

	/**
	 * Captures a screenshot and saves it to the specified path
	 * @param path Absolute path where to save the screenshot
	 */
	public static function capture(path:String):Void
	{
		#if windows
		WindowsCPP.captureFullScreen(path);
		#else
		trace("[Screenshot]: Screenshot capture is only available on Windows");
		#end
	}

	/**
	 * Sets the window as layered to enable transparency effects
	 * Must be called before using setWindowOppacity
	 */
	public static function setWindowLayered():Void
	{
		#if windows
		WindowsCPP.setWindowLayered();
		#else
		trace("[WindowsAPI]: Window transparency is only available on Windows");
		#end
	}

	/**
	 * Sets the window opacity/transparency
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function setWindowOppacity(alpha:Float):Void
	{
		#if windows
		WindowsCPP.setWindowAlpha(alpha);
		#else
		trace("[WindowsAPI]: Window transparency is only available on Windows");
		#end
	}

	/**
	 * Gets the current window opacity/transparency
	 * @return Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function getWindowOppacity():Float
	{
		#if windows
		return WindowsCPP.getWindowAlpha();
		#else
		trace("[WindowsAPI]: Window transparency is only available on Windows");
		return 1.0;
		#end
	}

	public static function fadeOutAndExit(duration:Float = 0.6, exitCode:Int = 0):Void
	{
		#if windows
		if (isClosing)
		{
			return;
		}

		isClosing = true;
		Application.current.window.onClose.cancel();

		if (closingTween != null)
		{
			closingTween.cancel();
		}

		var startAlpha:Float = 1.0; // Window always starts fully opaque

		var tween:NumTween = FlxTween.num(startAlpha, 0, duration, {
			onComplete: function(twn:FlxTween)
			{
				closingTween = null;
				isClosing = false;
				Sys.exit(exitCode);
			}
		});
		
		tween.onUpdate = function(twn:FlxTween)
		{
			setWindowOppacity(tween.value);
		};

		closingTween = tween;
		#else
		Sys.exit(exitCode);
		#end
	}

	/**
	 * Sets the window border color (Windows 11 only)
	 * @param r Red component (0-255)
	 * @param g Green component (0-255)
	 * @param b Blue component (0-255)
	 */
	public static function setWindowBorderColor(r:Int, g:Int, b:Int):Void
	{
		#if windows
		WindowsCPP.setWindowBorderColor(r, g, b);
		#else
		trace("[WindowsAPI]: Window border color is only available on Windows");
		#end
	}
}
