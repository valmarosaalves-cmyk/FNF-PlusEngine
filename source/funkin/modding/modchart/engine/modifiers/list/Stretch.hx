package funkin.modding.modchart.engine.modifiers.list;

import funkin.modding.modchart.backend.core.ModifierParameters;
import funkin.modding.modchart.backend.core.VisualParameters;

/**
 * Stretch modifier: vertically elongates notes and horizontally compresses them.
 * Based on the Troll Engine ScaleModifier stretch sub-mod formula.
 *
 * scaleX *= lerp(1, 0.5, stretch)   → at stretch=1: 0.5x wide, at stretch=3: -0.5x (flipped)
 * scaleY *= lerp(1, 2,   stretch)   → at stretch=1: 2x tall, at stretch=3: 4x tall
 *
 * Usage: set("stretch", beat, 3) to stretch, ease back to 0 to restore.
 */
class Stretch extends Modifier {
	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		var lane = Std.string(params.lane);
		var player = params.player;

		var v = getPercent('stretch', player) + getPercent('stretch' + lane, player);
		if (v == 0)
			return data;

		// Troll Engine lerp formula: stretchX = lerp(1, 0.5, v), stretchY = lerp(1, 2, v)
		var stretchX = 1.0 + (0.5 - 1.0) * v; // = 1 - 0.5*v
		var stretchY = 1.0 + (2.0 - 1.0) * v; // = 1 + v

		data.scaleX *= stretchX;
		data.scaleY *= stretchY;

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		var lane = Std.string(params.lane);
		return getPercent('stretch', params.player) != 0 || getPercent('stretch' + lane, params.player) != 0;
	}
}
