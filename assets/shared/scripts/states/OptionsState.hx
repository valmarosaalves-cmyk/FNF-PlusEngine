// Default engine implementation of OptionsState — loaded by ScriptableState.
// Mods can override this by placing their own copy at:
//   mods/{yourMod}/scripts/states/OptionsState.hx
//
// Variables injected by ScriptableState:
//   add / remove / insert / openSubState — FlxState helpers
//   game             — the ScriptableState host
//   controls         — Controls.instance

var options:Array<String> = [];
var grpOptions;
var curSelected:Int = 0;
var lerpSelected:Float = 0;
var selectorLeft;
var selectorRight;
var exiting:Bool = false;

function create() {
    options = [];
    if (!ClientPrefs.data.colorQuantization) options.push('Note Colors');
    options.push('Controls');
    options.push('Adjust Delay and Combo');
    options.push('Graphics');
    options.push('Visuals');
    options.push('Gameplay');
    options.push('Legacy');

    var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.color = 0xFFea71fd;
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    grpOptions = new FlxTypedGroup();
    add(grpOptions);

    for (i in 0...options.length) {
        var optionText = new Alphabet(0, 0, Language.getPhrase('options_' + options[i], options[i]), true);
        optionText.targetY = i;
        optionText.isMenuItem = true;
        grpOptions.add(optionText);
    }

    selectorLeft = new Alphabet(0, 0, '>', true);
    add(selectorLeft);
    selectorRight = new Alphabet(0, 0, '<', true);
    add(selectorRight);

    lerpSelected = curSelected;
    changeSelection(0);
    ClientPrefs.saveSettings();

    for (i in 0...grpOptions.members.length) {
        var item = grpOptions.members[i];
        var targetY = item.targetY - lerpSelected;
        item.screenCenter(X);
        item.y = (FlxG.height * 0.2) + (targetY * 50);
        item.alpha = 0.6;
        if (item.targetY == curSelected) {
            item.alpha = 1;
            selectorLeft.x = item.x - 63;
            selectorLeft.y = item.y;
            selectorRight.x = item.x + item.width + 15;
            selectorRight.y = item.y;
        }
    }
}

function openSelectedSubstate(label:String) {
    persistentUpdate = false;
    switch (label) {
        case 'Note Colors':
            openSubState(new NotesColorSubState());
        case 'Controls':
            openSubState(new ControlsSubState());
        case 'Graphics':
            openSubState(new GraphicsSettingsSubState());
        case 'Visuals':
            openSubState(new VisualsSettingsSubState());
        case 'Gameplay':
            openSubState(new GameplaySettingsSubState());
        case 'Legacy':
            openSubState(new LegacySettingsSubState());
        case 'Adjust Delay and Combo':
            MusicBeatState.switchState(new NoteOffsetState());
    }
}

function changeSelection(change:Int = 0) {
    curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
    for (i in 0...grpOptions.members.length)
        grpOptions.members[i].targetY = i;
    if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
}

function closeSubState() {
    ClientPrefs.saveSettings();
    controls.isInSubstate = false;
    persistentUpdate = true;
    changeSelection(0);
}

function update(elapsed:Float) {
    lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

    for (i in 0...grpOptions.members.length) {
        var item = grpOptions.members[i];
        var targetY = item.targetY - lerpSelected;
        item.screenCenter(X);
        item.y = FlxMath.lerp((FlxG.height * 0.2) + (targetY * 50), item.y, Math.exp(-elapsed * 10.2));
        item.alpha = 0.6;
        if (item.targetY == curSelected) {
            item.alpha = 1;
            selectorLeft.x = item.x - 63;
            selectorLeft.y = item.y;
            selectorRight.x = item.x + item.width + 15;
            selectorRight.y = item.y;
        }
    }

    if (!exiting) {
        if (controls.UI_UP_P)   changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.BACK) {
            exiting = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (OptionsState.onPlayState) {
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.music.volume = 0;
            } else {
                MusicBeatState.switchState(new MainMenuState());
            }
        } else if (controls.ACCEPT) {
            openSelectedSubstate(options[curSelected]);
        }
    }
}

function destroy() {
    ClientPrefs.loadPrefs();
}

