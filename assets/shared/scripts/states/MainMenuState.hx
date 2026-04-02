// Default engine implementation of MainMenuState -- loaded by ScriptableState.
// Mods can override by placing their own at:  mods/{yourMod}/scripts/states/MainMenuState.hx
//
// Note: spectral visualizer (funkin.vis) and mobile-specific features are omitted.
// Inject them in your own override if needed.

var optionShit:Array<String> = ['story_mode', 'freeplay', 'mods', 'credits'];
var leftOption:String  = 'achievements';
var rightOption:String = 'options';

var menuItems;
var leftItem;
var rightItem;
var magenta;
var camFollow;

var curSelected:Int = 0;
// column: 0 = CENTER, 1 = LEFT, 2 = RIGHT
var curColumn:Int = 0;
var selectedSomethin:Bool = false;

function create() {
    Mods.pushGlobalMods();
    Mods.loadTopMod();
    persistentUpdate = persistentDraw = true;

    var bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.scrollFactor.set(0, 0.25);
    bg.setGraphicSize(Std.int(bg.width * 1.175));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    camFollow = new FlxObject(0, 0, 1, 1);
    add(camFollow);

    magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
    magenta.antialiasing = ClientPrefs.data.antialiasing;
    magenta.scrollFactor.set(0, 0.25);
    magenta.setGraphicSize(Std.int(magenta.width * 1.175));
    magenta.updateHitbox();
    magenta.screenCenter();
    magenta.visible = false;
    magenta.color = 0xFFfd719b;
    add(magenta);

    menuItems = new FlxTypedGroup();
    add(menuItems);

    for (i in 0...optionShit.length) {
        var item = createMenuItem(optionShit[i], 0, (i * 140) + 90);
        item.y += (4 - optionShit.length) * 70;
        item.screenCenter(X);
    }

    if (leftOption != null)
        leftItem = createMenuItem(leftOption, 60, 490);

    if (rightOption != null) {
        rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
        rightItem.x -= rightItem.width;
    }

    var psychVer = new FlxText(12, FlxG.height - 44, 0, 'Psych Engine v' + MainMenuState.psychEngineVersion, 12);
    psychVer.scrollFactor.set();
    psychVer.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(psychVer);

    var fnfVer = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + MainMenuState.fnfVersion, 12);
    fnfVer.scrollFactor.set();
    fnfVer.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(fnfVer);

    changeItem(0);
    FlxG.camera.follow(camFollow, null, 0.15);
}

function createMenuItem(name:String, x:Float, y:Float) {
    var menuItem = new FlxSprite(x, y);
    menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + name);
    menuItem.animation.addByPrefix('idle',     name + ' idle',     24, true);
    menuItem.animation.addByPrefix('selected', name + ' selected', 24, true);
    menuItem.animation.play('idle');
    menuItem.updateHitbox();
    menuItem.antialiasing = ClientPrefs.data.antialiasing;
    menuItem.scrollFactor.set();
    menuItems.add(menuItem);
    return menuItem;
}

function changeItem(change:Int = 0) {
    if (change != 0) curColumn = 0;
    curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
    FlxG.sound.play(Paths.sound('scrollMenu'));

    for (item in menuItems.members) {
        item.animation.play('idle');
        item.centerOffsets();
    }

    var selectedItem;
    if      (curColumn == 1) selectedItem = leftItem;
    else if (curColumn == 2) selectedItem = rightItem;
    else                     selectedItem = menuItems.members[curSelected];

    if (selectedItem != null) {
        selectedItem.animation.play('selected');
        selectedItem.centerOffsets();
        camFollow.y = selectedItem.getGraphicMidpoint().y;
    }
}

function selectOption(option:String, item) {
    FlxG.sound.play(Paths.sound('confirmMenu'));
    selectedSomethin = true;
    Cursor.hide();
    if (ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

    FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick) {
        switch (option) {
            case 'story_mode':   MusicBeatState.switchState(new StoryMenuState());
            case 'freeplay':     MusicBeatState.switchState(new FreeplayState());
            case 'mods':         MusicBeatState.switchState(new ModsMenuState());
            case 'achievements': MusicBeatState.switchState(new AchievementsMenuState());
            case 'credits':      MusicBeatState.switchState(new CreditsState());
            case 'options':
                MusicBeatState.switchState(new OptionsState());
                OptionsState.onPlayState = false;
                if (PlayState.SONG != null) {
                    PlayState.SONG.arrowSkin  = null;
                    PlayState.SONG.splashSkin = null;
                    PlayState.stageUI = 'normal';
                }
            default:
                selectedSomethin = false;
                item.visible = true;
        }
    });

    for (memb in menuItems.members)
        if (memb != item) FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
}

function update(elapsed:Float) {
    if (FlxG.sound.music.volume < 0.8)
        FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

    if (!selectedSomethin) {
        if (controls.UI_UP_P)   changeItem(-1);
        if (controls.UI_DOWN_P) changeItem(1);

        switch (curColumn) {
            case 0: // CENTER
                if (controls.UI_LEFT_P  && leftOption  != null) { curColumn = 1; changeItem(0); }
                else if (controls.UI_RIGHT_P && rightOption != null) { curColumn = 2; changeItem(0); }
            case 1: if (controls.UI_RIGHT_P) { curColumn = 0; changeItem(0); }
            case 2: if (controls.UI_LEFT_P)  { curColumn = 0; changeItem(0); }
        }

        if (controls.BACK) {
            selectedSomethin = true;
            Cursor.hide();
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new TitleState());
        } else if (controls.ACCEPT) {
            var option:String;
            var item;
            if      (curColumn == 1) { option = leftOption;              item = leftItem; }
            else if (curColumn == 2) { option = rightOption;             item = rightItem; }
            else                     { option = optionShit[curSelected]; item = menuItems.members[curSelected]; }
            selectOption(option, item);
        }
    }
}

