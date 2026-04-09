package funkin.play.substates;

import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import funkin.data.Difficulty;
import funkin.data.story.level.WeekData;
import funkin.save.Highscore;
import funkin.ui.Language;
import funkin.ui.components.md3.MaterialDialog;

class ResetScoreSubState extends MusicBeatSubstate
{
	var dialog:MaterialDialog;
	var onReset:Void->Void;

	var song:String;
	var difficulty:Int;
	var week:Int;

	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:Int = -1, ?onReset:Void->Void)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;
		this.onReset = onReset;
		super();
	}

	override function create():Void
	{
		super.create();

		var name:String = song;
		if (week > -1)
		{
			name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		}

		var body:String = Language.getPhrase('reset_score_dialog_body', 'This will remove the saved score and accuracy for {1} ({2}).', [name, Difficulty.getString(difficulty)]);
		dialog = new MaterialDialog(
			Language.getPhrase('reset_score', 'Reset score'),
			body,
			Language.getPhrase('Yes', 'Yes'),
			Language.getPhrase('No', 'No'),
			confirmReset,
			close
		);
		add(dialog);
		dialog.open();
		dialog.focusConfirm();

		addTouchPad('LEFT_RIGHT', 'A_B');
		addTouchPadCamera();
	}

	override function update(elapsed:Float):Void
	{
		if (controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft.justPressed))
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			dialog.focusDismiss();
		}
		else if (controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight.justPressed))
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			dialog.focusConfirm();
		}
		else if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			ClientPrefs.saveSettings();
			close();
		}
		else if (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed))
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			dialog.activateFocused();
		}

		if (touchPad == null)
		{
			addTouchPad('LEFT_RIGHT', 'A_B');
			addTouchPadCamera();
		}

		super.update(elapsed);
	}

	function confirmReset():Void
	{
		if (week == -1)
		{
			Highscore.resetSong(song, difficulty);
		}
		else
		{
			Highscore.resetWeek(WeekData.weeksList[week], difficulty);
		}

		if (onReset != null) onReset();
		ClientPrefs.saveSettings();
		close();
	}

	override function destroy():Void
	{
		dialog = FlxDestroyUtil.destroy(dialog);
		onReset = null;
		super.destroy();
	}
}
