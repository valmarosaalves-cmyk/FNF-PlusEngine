/*
 * Copyright (C) 2026 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package funkin.mobile.backend;

import flixel.system.scaleModes.BaseScaleMode;

/**
 * ...
 * @author: Karim Akra
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowInfinityDisplay(default, set):Bool = true;
	
	// Base game resolution for mod compatibility
	public static final BASE_GAME_WIDTH:Int = 1280;
	public static final BASE_GAME_HEIGHT:Int = 720;
	
	// Track screen dimensions for offset calculations
	static var screenWidth:Float = 0;
	static var screenHeight:Float = 0;
	
	/**
	 * Calculate vertical offset for infinity display mode
	 * @return Offset in pixels to center controls on extended screen
	 */
	public static function getVerticalOffset():Float
	{
		if (!ClientPrefs.data.infinityDisplay || !allowInfinityDisplay)
			return 0;
		
		if (screenWidth == 0 || screenHeight == 0)
			return 0;
			
		// Calculate how much the screen extends beyond 16:9
		var screenRatio:Float = screenWidth / screenHeight;
		var targetRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT; // ~1.777 (16:9)
		
		if (screenRatio >= targetRatio)
		{
			// Screen is wider or equal to 16:9 - no vertical extension
			return 0;
		}
		
		// Screen is taller than 16:9 (mobile infinity display)
		// Calculate the extended height in game coordinates
		var scaledHeight:Float = FlxG.height;
		var baseHeightAtCurrentScale:Float = (screenWidth / FlxG.width) * BASE_GAME_HEIGHT;
		var extraHeight:Float = scaledHeight - baseHeightAtCurrentScale;
		
		return Math.max(0, extraHeight / 2);
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		screenWidth = Width;
		screenHeight = Height;
		
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
		{
			// Infinity Display: Use full screen while maintaining aspect ratio
			// This will letterbox/pillarbox and center automatically
			super.updateGameSize(Width, Height);
		}
		else
		{
			// Standard 16:9 locked mode
			var ratio:Float = FlxG.width / FlxG.height;
			var realRatio:Float = Width / Height;

			var scaleY:Bool = realRatio < ratio;

			if (scaleY)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
	}

	override function updateGamePosition():Void
	{
		// Always center the game
		super.updateGamePosition();
	}

	@:noCompletion
	private static function set_allowInfinityDisplay(value:Bool):Bool
	{
		if (allowInfinityDisplay == value)
			return value;
			
		allowInfinityDisplay = value;

		if (Std.isOfType(FlxG.scaleMode, MobileScaleMode))
		{
			if (FlxG.game != null)
			{
				FlxG.resizeGame(FlxG.width, FlxG.height);
			}
		}
		
		return value;
	}
}
