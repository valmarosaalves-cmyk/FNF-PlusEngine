package funkin.ui;

import flixel.FlxG;
import openfl.Lib;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;

class GlobalLoadingOverlay
{
	static var display:GlobalLoadingOverlayDisplay;

	public static function pulse(?holdTime:Float = 0.32):Void
	{
		ensureDisplay();
		display.show(false, holdTime);
	}

	public static function showPersistent():Void
	{
		ensureDisplay();
		display.show(true, 0);
	}

	public static function hide(?immediate:Bool = false):Void
	{
		if (display != null)
			display.hide(immediate);
	}

	public static function stateReady():Void
	{
		hide();
	}

	static function ensureDisplay():Void
	{
		if (display == null)
			display = new GlobalLoadingOverlayDisplay();
		display.attach();
	}
}

private class GlobalLoadingOverlayDisplay extends Sprite
{
	static inline var PANEL_WIDTH:Float = 112;
	static inline var PANEL_HEIGHT:Float = 56;
	static inline var PANEL_RADIUS:Float = 28;
	static inline var TOP_MARGIN:Float = 12;
	static inline var HIDDEN_OFFSET:Float = -84;
	static inline var ICON_SIZE:Float = 34;
	static inline var SPIN_SPEED:Float = 248.0;
	static inline var SHAPE_MORPH_PORTION:Float = 0.36;
	static inline var TAU:Float = 6.283185307179586;

	static var LOBES:Array<Int> = [0, 4, 6, 7, 3, 5, 8, 3];
	static var AMPLITUDES:Array<Float> = [0.00, 0.16, 0.12, 0.10, 0.08, 0.12, 0.14, 0.09];
	static var SECONDARY:Array<Float> = [0.00, 0.02, 0.03, 0.02, 0.01, 0.03, 0.04, 0.01];
	static var SOFTNESS:Array<Float> = [1.00, 0.94, 0.96, 0.97, 0.98, 0.92, 0.90, 0.99];
	static var PHASE_OFF:Array<Float> = [0.00, 0.78, 0.35, 0.18, 0.00, 0.64, 0.30, 0.00];
	static var SCALE_X:Array<Float> = [1.00, 1.00, 1.18, 0.96, 1.00, 1.22, 0.92, 1.00];
	static var SCALE_Y:Array<Float> = [1.00, 1.00, 0.78, 1.08, 1.00, 0.74, 1.14, 1.00];
	static var TRIANGLE_MIX:Array<Float> = [0.00, 0.10, 0.00, 0.14, 0.78, 0.00, 0.22, 0.60];

	var container:Sprite;
	var shadow:Shape;
	var panel:Shape;
	var outline:Shape;
	var iconHolder:Sprite;
	var icon:Shape;

	var currentY:Float = HIDDEN_OFFSET;
	var targetY:Float = HIDDEN_OFFSET;
	var currentAlpha:Float = 0;
	var targetAlpha:Float = 0;
	var hideDeadline:Float = -1;
	var persistent:Bool = false;
	var spinTravel:Float = 0;
	var lastTime:Float = 0;

	public function new()
	{
		super();
		mouseEnabled = false;
		mouseChildren = false;
		visible = false;

		container = new Sprite();
		addChild(container);

		shadow = new Shape();
		container.addChild(shadow);

		panel = new Shape();
		container.addChild(panel);

		outline = new Shape();
		container.addChild(outline);

		iconHolder = new Sprite();
		iconHolder.scrollRect = new Rectangle(0, 0, ICON_SIZE, ICON_SIZE);
		iconHolder.x = (PANEL_WIDTH - ICON_SIZE) * 0.5;
		iconHolder.y = (PANEL_HEIGHT - ICON_SIZE) * 0.5;
		container.addChild(iconHolder);

		icon = new Shape();
		icon.x = ICON_SIZE * 0.5;
		icon.y = ICON_SIZE * 0.5;
		iconHolder.addChild(icon);

		redrawChrome();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function attach():Void
	{
		if (Lib.current == null || Lib.current.stage == null)
			return;

		if (FlxG.game != null)
		{
			var gameHost:Sprite = cast FlxG.game;
			if (parent != gameHost)
			{
				if (parent != null)
					parent.removeChild(this);
				gameHost.addChild(this);
			}
			else
			{
				gameHost.setChildIndex(this, gameHost.numChildren - 1);
			}
		}
		else
		{
			var stageHost:Dynamic = Lib.current.stage;
			if (parent != stageHost)
			{
				if (parent != null)
					parent.removeChild(this);
				stageHost.addChild(this);
			}
			else
			{
				stageHost.setChildIndex(this, stageHost.numChildren - 1);
			}
		}

		resize();
	}

	public function show(keepVisible:Bool, holdTime:Float):Void
	{
		attach();
		persistent = keepVisible;
		hideDeadline = keepVisible ? -1 : (nowSeconds() + holdTime);
		targetY = TOP_MARGIN;
		targetAlpha = 1;
		visible = true;
	}

	public function hide(?immediate:Bool = false):Void
	{
		persistent = false;
		hideDeadline = -1;

		if (immediate)
		{
			currentY = HIDDEN_OFFSET;
			targetY = HIDDEN_OFFSET;
			currentAlpha = 0;
			targetAlpha = 0;
			alpha = 0;
			visible = false;
			return;
		}

		targetY = HIDDEN_OFFSET;
		targetAlpha = 0;
	}

	function onEnterFrame(_:Event):Void
	{
		if (stage == null)
			return;

		var now = nowSeconds();
		if (lastTime <= 0)
			lastTime = now;
		var elapsed = now - lastTime;
		lastTime = now;

		resize();

		if (!persistent && hideDeadline > 0 && now >= hideDeadline)
			hide();

		currentY = approach(currentY, targetY, elapsed * 14);
		currentAlpha = approach(currentAlpha, targetAlpha, elapsed * 16);
		alpha = currentAlpha;
		visible = currentAlpha > 0.01;
		container.y = currentY;

		spinTravel += elapsed * SPIN_SPEED;
		redrawIndicator();
	}

	function resize():Void
	{
		if (stage == null)
			return;
		if (FlxG.game != null && parent == FlxG.game)
			x = Math.round(((stage.stageWidth - PANEL_WIDTH) * 0.5) - FlxG.game.x);
		else
			x = Math.round((stage.stageWidth - PANEL_WIDTH) * 0.5);
		y = 0;
	}

	function redrawChrome():Void
	{
		shadow.graphics.clear();
		shadow.graphics.beginFill(0x000000, 0.18);
		shadow.graphics.drawRoundRect(0, 4, PANEL_WIDTH, PANEL_HEIGHT, PANEL_RADIUS, PANEL_RADIUS);
		shadow.graphics.endFill();

		panel.graphics.clear();
		panel.graphics.beginFill(0xFF171A22, 0.96);
		panel.graphics.drawRoundRect(0, 0, PANEL_WIDTH, PANEL_HEIGHT, PANEL_RADIUS, PANEL_RADIUS);
		panel.graphics.endFill();

		outline.graphics.clear();
		outline.graphics.lineStyle(1, 0xFFFFFF, 0.16);
		outline.graphics.drawRoundRect(0.5, 0.5, PANEL_WIDTH - 1, PANEL_HEIGHT - 1, PANEL_RADIUS, PANEL_RADIUS);
	}

	function redrawIndicator():Void
	{
		var turn:Int = Std.int(spinTravel / 360) % LOBES.length;
		var previous:Int = ((turn - 1) + LOBES.length) % LOBES.length;
		var turnT:Float = (spinTravel % 360) / 360;
		var morphT:Float = turnT <= SHAPE_MORPH_PORTION ? smoothstep(turnT / SHAPE_MORPH_PORTION) : 1.0;

		var lobes:Float = lerp(LOBES[previous], LOBES[turn], morphT);
		var amplitude:Float = lerp(AMPLITUDES[previous], AMPLITUDES[turn], morphT);
		var secondary:Float = lerp(SECONDARY[previous], SECONDARY[turn], morphT);
		var softness:Float = lerp(SOFTNESS[previous], SOFTNESS[turn], morphT);
		var phaseOffset:Float = lerp(PHASE_OFF[previous], PHASE_OFF[turn], morphT);
		var scaleX:Float = lerp(SCALE_X[previous], SCALE_X[turn], morphT);
		var scaleY:Float = lerp(SCALE_Y[previous], SCALE_Y[turn], morphT);
		var triangleMix:Float = lerp(TRIANGLE_MIX[previous], TRIANGLE_MIX[turn], morphT);

		icon.rotation = spinTravel % 360;
		icon.graphics.clear();
		icon.graphics.beginFill(0xFFD9C2FF, 1);

		var baseRadius:Float = ICON_SIZE * 0.27;
		var steps:Int = 96;

		for (i in 0...steps + 1)
		{
			var t:Float = i / steps;
			var angle:Float = t * TAU;
			var primaryWave:Float = lobes <= 0.01 ? 0.0 : Math.sin(angle * lobes + phaseOffset);
			var secondaryWave:Float = lobes <= 0.01 ? 0.0 : Math.sin(angle * lobes * 0.5 + phaseOffset * 1.7);
			var normalizedPrimary:Float = primaryWave >= 0 ? Math.pow(primaryWave, softness) : -Math.pow(-primaryWave, softness);
			var organicRadius:Float = baseRadius * (1.0 + normalizedPrimary * amplitude + secondaryWave * secondary);
			var triangleRadius:Float = getTriangleRadius(angle, baseRadius * 1.08);
			var radius:Float = organicRadius * (1.0 - triangleMix) + triangleRadius * triangleMix;
			var px:Float = clamp(Math.cos(angle) * radius * scaleX, -ICON_SIZE * 0.5 + 1, ICON_SIZE * 0.5 - 1);
			var py:Float = clamp(Math.sin(angle) * radius * scaleY, -ICON_SIZE * 0.5 + 1, ICON_SIZE * 0.5 - 1);

			if (i == 0)
				icon.graphics.moveTo(px, py);
			else
				icon.graphics.lineTo(px, py);
		}

		icon.graphics.endFill();
	}

	function getTriangleRadius(angle:Float, baseRadius:Float):Float
	{
		var sector:Float = TAU / 3;
		var local:Float = angle % sector;
		if (local < 0) local += sector;
		local -= sector * 0.5;

		var denom:Float = Math.cos(local);
		if (Math.abs(denom) < 0.001)
			denom = denom < 0 ? -0.001 : 0.001;

		var triangleRadius:Float = (baseRadius * Math.cos(Math.PI / 3)) / denom;
		return clamp(triangleRadius, baseRadius * 0.52, baseRadius * 1.18);
	}

	inline function approach(current:Float, target:Float, speed:Float):Float
	{
		return current + (target - current) * (1 - Math.exp(-speed));
	}

	inline function lerp(a:Float, b:Float, t:Float):Float
	{
		return a + (b - a) * t;
	}

	inline function clamp(value:Float, min:Float, max:Float):Float
	{
		return value < min ? min : (value > max ? max : value);
	}

	inline function smoothstep(value:Float):Float
	{
		var clamped:Float = clamp(value, 0, 1);
		return clamped * clamped * (3 - 2 * clamped);
	}

	inline function nowSeconds():Float
	{
		return Lib.getTimer() / 1000;
	}
}