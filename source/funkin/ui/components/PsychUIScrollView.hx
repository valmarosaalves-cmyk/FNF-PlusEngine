package funkin.ui.components;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

/**
 * A lightweight vertical scroll view for Flixel UI.
 *
 * How it works:
 * - Creates a dedicated camera with a viewport (x, y, width, height).
 * - Everything added to this group is rendered through that camera.
 * - Drag with touch/mouse to scroll, with optional inertia.
 */
class PsychUIScrollView extends FlxSpriteGroup
{
	public final viewCamera:FlxCamera;

	public var scrollY(default, null):Float = 0;
	public var contentHeight:Float = 0;

	public var wheelStep:Float = 80;
	public var dragEnabled:Bool = true;
	public var inertiaEnabled:Bool = true;
	public var friction:Float = 0.92; // Applied per-frame at 60fps

	private var dragging:Bool = false;
	private var lastPointerY:Float = 0;
	private var velocityY:Float = 0;
	private var pointerWasDown:Bool = false;
	private var pointerId:Int = -1;

	public function new(viewX:Float, viewY:Float, viewWidth:Int, viewHeight:Int)
	{
		super(0, 0);

		viewCamera = new FlxCamera(Std.int(viewX), Std.int(viewY), viewWidth, viewHeight);
		viewCamera.bgColor = 0x00000000;
		FlxG.cameras.add(viewCamera, false);
		cameras = [viewCamera];
	}

	override public function update(elapsed:Float)
	{
		handleInput(elapsed);
		viewCamera.scroll.y = scrollY;
		super.update(elapsed);
	}

	/**
	 * Sets the total height of scrollable content (in world pixels).
	 */
	public function setContentHeight(value:Float):Void
	{
		contentHeight = Math.max(0, value);
		clampScroll(true);
	}

	/**
	 * Utility to compute content height based on children bounds.
	 * Call this after you finish adding/removing elements.
	 */
	public function refreshContentHeightFromChildren(paddingBottom:Float = 0):Void
	{
		var maxBottom:Float = 0;
		for (member in members)
		{
			if (member == null) continue;
			var bottom = member.y + member.height;
			if (bottom > maxBottom) maxBottom = bottom;
		}
		setContentHeight(maxBottom + paddingBottom);
	}

	private inline function maxScroll():Float
	{
		return Math.max(0, contentHeight - viewCamera.height);
	}

	private function clampScroll(stopVelocity:Bool):Void
	{
		var clamped = FlxMath.bound(scrollY, 0, maxScroll());
		if (clamped != scrollY)
		{
			scrollY = clamped;
			if (stopVelocity) velocityY = 0;
		}
	}

	private inline function isScreenPointInsideViewport(screenX:Float, screenY:Float):Bool
	{
		return (screenX >= viewCamera.x
			&& screenY >= viewCamera.y
			&& screenX <= viewCamera.x + viewCamera.width
			&& screenY <= viewCamera.y + viewCamera.height);
	}

	private function handleInput(elapsed:Float):Void
	{
		if (!dragEnabled)
		{
			applyInertia(elapsed);
			return;
		}

		// Prefer touch on mobile when available
		var pointerDown = false;
		var pointerX:Float = 0;
		var pointerY:Float = 0;

		#if mobile
		var touch = (pointerId >= 0) ? FlxG.touches.getByID(pointerId) : FlxG.touches.getFirst();
		if (touch != null)
		{
			pointerDown = touch.pressed;
			pointerX = touch.screenX;
			pointerY = touch.screenY;
			if (pointerId < 0) pointerId = touch.id;
		}
		#else
		pointerDown = FlxG.mouse.pressed;
		pointerX = FlxG.mouse.screenX;
		pointerY = FlxG.mouse.screenY;
		#end

		var inside = isScreenPointInsideViewport(pointerX, pointerY);

		// Mouse wheel scrolling (desktop/testing)
		#if !mobile
		if (inside && FlxG.mouse.wheel != 0)
		{
			scrollY -= FlxG.mouse.wheel * wheelStep;
			clampScroll(true);
		}
		#end

		// Drag start
		if (!pointerWasDown && pointerDown && inside)
		{
			dragging = true;
			lastPointerY = pointerY;
			velocityY = 0;
		}

		// Drag update
		if (dragging && pointerDown)
		{
			var dy = pointerY - lastPointerY;
			lastPointerY = pointerY;

			// Move content opposite to finger direction
			scrollY -= dy;
			if (elapsed > 0) velocityY = (-dy) / elapsed;
			clampScroll(false);
		}

		// Drag end
		if (dragging && !pointerDown)
		{
			dragging = false;
			pointerId = -1;
			clampScroll(false);
		}

		pointerWasDown = pointerDown;
		applyInertia(elapsed);
	}

	private function applyInertia(elapsed:Float):Void
	{
		if (!inertiaEnabled) return;
		if (dragging) return;

		if (Math.abs(velocityY) < 1)
		{
			velocityY = 0;
			return;
		}

		scrollY += velocityY * elapsed;
		// Convert per-frame friction to elapsed time (~60fps baseline)
		var frameFactor = Math.pow(friction, elapsed * 60);
		velocityY *= frameFactor;
		clampScroll(true);
	}

	override public function destroy():Void
	{
		super.destroy();
		if (FlxG.cameras != null)
		{
			FlxG.cameras.remove(viewCamera, true);
		}
		FlxDestroyUtil.destroy(viewCamera);
	}
}
