package funkin.ui.freeplay;

import funkin.graphics.shaders.BlurEffect;
import funkin.data.stage.StageData;
import funkin.data.story.level.WeekData;
import funkin.save.Highscore;
import funkin.data.song.Song;
import funkin.play.HealthIcon;
import funkin.ui.MusicPlayer;
import funkin.ui.options.GameplayChangersSubstate;
import funkin.play.substates.ResetScoreSubState;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import openfl.utils.Assets;

#if MODS_ALLOWED
import sys.FileSystem;
#end

#if mobile
import funkin.mobile.backend.StorageUtil;
#end

import haxe.Json;

class FreeplayState extends MusicBeatState {
    // Instance reference
    public static var instance:FreeplayState;
    public var songs:Array<SongMetadata> = [];
    
    // Selection variables
    public static var curSelected:Int = 0;
    var lerpSelected:Float = 0;
    var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = Difficulty.getDefault();
    
    // Score tracking
    var lerpScore:Int = 0;
    var lerpRating:Float = 0;
    var intendedScore:Int = 0;
    var intendedRating:Float = 0;
    
    // State variables
    private var curPlaying:Bool = false;
    var inDifficultySelect:Bool = false;
    var songsOffsetX:Float = 0;
    public static var viewingOpponentScores:Bool = false;
    var instPlaying:Int = -1;
    var holdTime:Float = 0;
    var stopMusicPlay:Bool = false;
    
    // Background animation
    var bgZoom:Float = 1;
    var defaultBgZoom:Float = 1;
    
    // Color management
    var intendedColor:Int;
    
    // Audio
    public static var vocals:FlxSound = null;
    public static var opponentVocals:FlxSound = null;
    
    // Touch support
    #if mobile
    var touchScroll:funkin.mobile.backend.TouchScroll;
    var difficultyScroll:funkin.mobile.backend.TouchScroll;
    #end
    
    // Icon arrays for songs
    private var iconArray:Array<HealthIcon> = [];
    
    // Drawing optimization
    var _drawDistance:Int = 4;
    var _lastVisibles:Array<Int> = [];
    
    // UI Elements (existing)
    var bg:FlxSprite;
    var blackOverlay:FlxSprite;
    var dinamic:FlxSprite;
    var album:FlxSprite;
    var uiprincipal:FlxSprite;
    var list:FlxSprite;
    var cardsGroup:FlxTypedGroup<FlxSprite>;
    var cardSongText:FlxTypedGroup<FlxText>;
    var cardModText:FlxTypedGroup<FlxText>;
    var diffsGroup:FlxTypedGroup<FlxSprite>;
    var diffsTextGroup:FlxTypedGroup<FlxText>;
    var barsGroup:FlxTypedGroup<FlxSprite>;
    var blurEffect:BlurEffect;
    //var diff:Array<FlxSpriteGroup>;

    var accuracyIcon:FlxSprite;
    var bpmIcon:FlxSprite;
    var fireIcon:FlxSprite;
    var gamesettingsIcon:FlxSprite;
    var medalIcon:FlxSprite;
    var playIcon:FlxSprite;
    var searchIcon:FlxSprite;
    var settingsIcon:FlxSprite;
    var speedIcon:FlxSprite;
    var starIcon:FlxSprite;
    var starFullIcon:FlxSprite;
    var timerIcon:FlxSprite;
    var trophyIcon:FlxSprite;

    var freeplayText:FlxText;

    var speedText:FlxText;
    var timerText:FlxText;
    var bpmText:FlxText;

    var scoreText:FlxText;
    var scoreData:FlxText;
    var accuracyText:FlxText;
    var accuracyData:FlxText;
    var comboText:FlxText;
    var comboData:FlxText;
    var ratingText:FlxText;
    var ratingData:FlxText;

    var playText:FlxText;
    var diffText:FlxText;
    var modText:FlxText;
    var notesText:FlxText;
    var noteDiffText:FlxText;
    var themeText:FlxText;
    var songsText:FlxText;
    var searchtipText:FlxText;
    var todayText:FlxText;
    var totalSongsText:FlxText;
    var modsLoadedText:FlxText;
    var searchTipText:FlxText;

    var allLevels:FlxText;
    var favorites:FlxText;
    
    // Additional UI elements
    var opponentModeText:FlxText;
    var missingTextBG:FlxSprite;
    var missingText:FlxText;
    var bottomString:String;
    var bottomText:FlxText;
    
    // Music player
    var player:MusicPlayer;
    
    // Difficulty selector
    var difficultySelector:DifficultySelector;

    override public function create():Void {
        super.create();

        // Initialize instance
        instance = this;
        persistentUpdate = true;
        PlayState.isStoryMode = false;
        WeekData.reloadWeekFiles(false);

        #if DISCORD_ALLOWED
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Menus", null);
        #end

        // Load songs from weeks
        loadSongsFromWeeks();
        
        // Load StepMania files
        loadStepManiaFiles();

        Cursor.show();

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		// Apply Gaussian blur effect to background using shader
		blurEffect = new BlurEffect();
		blurEffect.strength = 5.0; // 1-10 for good blur effect
		bg.shader = blurEffect.shader;
		//bgZoom = defaultBgZoom = 1;

        blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.5;
		add(blackOverlay);

        freeplayText = new FlxText(45, 28, 0, 'Freeplay');
        freeplayText.setFormat(Paths.font('inter-bold.otf'), 32, FlxColor.PURPLE, 'left');
        add(freeplayText);

        dinamic = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/dinamic'));
		dinamic.antialiasing = ClientPrefs.data.antialiasing;
		dinamic.setGraphicSize(FlxG.width, FlxG.height);
		dinamic.updateHitbox();
		add(dinamic);

        album = new FlxSprite().loadGraphic(Paths.image('albumRoll/example'));
        album.x = 49;
        album.y = 98;
        album.antialiasing = ClientPrefs.data.antialiasing;
        album.setGraphicSize(206, 206);
        album.updateHitbox();
        add(album);

        uiprincipal = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/uiprin'));
        uiprincipal.antialiasing = ClientPrefs.data.antialiasing;
        uiprincipal.setGraphicSize(FlxG.width, FlxG.height);
        uiprincipal.updateHitbox();
        add(uiprincipal);

        list = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/list'));
        list.antialiasing = ClientPrefs.data.antialiasing;
        list.setGraphicSize(FlxG.width, FlxG.height);
        list.updateHitbox();
        add(list);

        searchIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/search'));
        searchIcon.x = 895;
        searchIcon.y = 170;
        searchIcon.color = FlxColor.GRAY;
        searchIcon.antialiasing = ClientPrefs.data.antialiasing;
        searchIcon.setGraphicSize(16, 16);
        searchIcon.updateHitbox();
        add(searchIcon);

        searchTipText = new FlxText(920, 169, 0, 'Search here..');
        searchTipText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.GRAY, 'center');
        add(searchTipText);

        playIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/play'));
        playIcon.x = 80.8;
        playIcon.y = 566.7;
        playIcon.antialiasing = ClientPrefs.data.antialiasing;
        playIcon.setGraphicSize(30, 30);
        playIcon.updateHitbox();
        add(playIcon);

        playText = new FlxText(115, 565, 0, 'Play');
        playText.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.PURPLE, 'left');
        add(playText);

        starIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/star'));
        starIcon.x = 299.8;
        starIcon.y = 570.5;
        starIcon.antialiasing = ClientPrefs.data.antialiasing;
        starIcon.setGraphicSize(24, 24);
        starIcon.updateHitbox();
        add(starIcon);

        trophyIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/trophy'));
        trophyIcon.x = 54;
        trophyIcon.y = 350;
        trophyIcon.antialiasing = ClientPrefs.data.antialiasing;
        trophyIcon.setGraphicSize(16.5, 16.5);
        trophyIcon.updateHitbox();
        add(trophyIcon);

        scoreText = new FlxText(74.8, 349, 0, 'High Score');
        scoreText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(scoreText);

        scoreData = new FlxText(54, 375, 0, '123,456');
        scoreData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(scoreData);

        accuracyIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/accuracy'));
        accuracyIcon.x = 224.6;
        accuracyIcon.y = 350;
        accuracyIcon.antialiasing = ClientPrefs.data.antialiasing;
        accuracyIcon.setGraphicSize(16.5, 16.5);
        accuracyIcon.updateHitbox();
        add(accuracyIcon);

        accuracyText = new FlxText(244.6, 349, 0, 'Accuracy');
        accuracyText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(accuracyText);

        accuracyData = new FlxText(224.6, 375, 0, '98.5%');
        accuracyData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(accuracyData);

        fireIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/fire'));
        fireIcon.x = 395.6;
        fireIcon.y = 350;
        fireIcon.antialiasing = ClientPrefs.data.antialiasing;
        fireIcon.setGraphicSize(16.5, 16.5);
        fireIcon.updateHitbox();
        add(fireIcon);

        comboText = new FlxText(415.6, 349, 0, 'Max Combo');
        comboText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(comboText);

        comboData = new FlxText(395.6, 375, 0, '456x');
        comboData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(comboData);

        medalIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/medal'));
        medalIcon.x = 566.1;
        medalIcon.y = 350;
        medalIcon.antialiasing = ClientPrefs.data.antialiasing;
        medalIcon.setGraphicSize(16.5, 16.5);
        medalIcon.updateHitbox();
        add(medalIcon);

        ratingText = new FlxText(586.1, 349, 0, 'Rating');
        ratingText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(ratingText);

        ratingData = new FlxText(566.1, 375, 0, 'S++');
        ratingData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(ratingData);

        speedIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/speed'));
        speedIcon.x = 296.2;
        speedIcon.y = 193;
        speedIcon.antialiasing = ClientPrefs.data.antialiasing;
        speedIcon.setGraphicSize(16, 16);
        speedIcon.updateHitbox();
        add(speedIcon);

        speedText = new FlxText(316.2, 192.5, 0, '1.0x');
        speedText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(speedText);

        timerIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/timer'));
        timerIcon.x = 394.8;
        timerIcon.y = 193;
        timerIcon.antialiasing = ClientPrefs.data.antialiasing;
        timerIcon.setGraphicSize(16, 16);
        timerIcon.updateHitbox();
        add(timerIcon);

        timerText = new FlxText(413.8, 192.5, 0, '1:23');
        timerText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(timerText);

        bpmIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/bpm'));
        bpmIcon.x = 476.1;
        bpmIcon.y = 193;
        bpmIcon.antialiasing = ClientPrefs.data.antialiasing;
        bpmIcon.setGraphicSize(16, 16);
        bpmIcon.updateHitbox();
        add(bpmIcon);

        bpmText = new FlxText(494.1, 192.5, 0, '120 BPM');
        bpmText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(bpmText);

        themeText = new FlxText(294.2, 230, 0, 'Example Theme');
        themeText.setFormat(Paths.font('inter-bold.otf'), 36, FlxColor.BLACK, 'left');
        add(themeText);

        modText = new FlxText(294.2, 275.5, 0, 'Friday Night Funkin\'');
        modText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.GRAY, 'left');
        add(modText);

        todayText = new FlxText(1126, 38, 0, '20:14\n28/02/2026');
        todayText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.BLACK, 'center');
        add(todayText);

        notesText = new FlxText(417, 470, 0, 'Notes Density');
        notesText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.BLACK, 'left');
        add(notesText);

        noteDiffText = new FlxText(613.2, 473.8, 0, '(Hard) 123 notes');
        noteDiffText.setFormat(Paths.font('inter-bold.otf'), 10, FlxColor.GRAY, 'left');
        add(noteDiffText);

        diffText = new FlxText(42.5, 454.2, 0, 'Select Difficulty');
        diffText.setFormat(Paths.font('inter-bold.otf'), 17, FlxColor.BLACK, 'left');
        add(diffText);

        songsText = new FlxText(883, 124, 0, 'Songs List');
        songsText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.BLACK, 'left');
        add(songsText);

        totalSongsText = new FlxText(990, 40, 0, 'TOTAL SONGS\n123');
        totalSongsText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.BLACK, 'right');
        add(totalSongsText);

        modsLoadedText = new FlxText(890, 40, 0, 'MODS LOADED\n5');
        modsLoadedText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.BLACK, 'right');
        add(modsLoadedText);

        allLevels = new FlxText(890, 210, 0, 'All Levels');
        allLevels.setFormat(Paths.font('inter-bold.otf'), 16, FlxColor.PURPLE, 'center');
        add(allLevels);

        favorites = new FlxText(980, 210, 0, 'Favorites');
        favorites.setFormat(Paths.font('inter-bold.otf'), 16, FlxColor.GRAY, 'center');
        add(favorites);

        diffsGroup = new FlxTypedGroup<FlxSprite>();
        add(diffsGroup);
        
        diffsTextGroup = new FlxTypedGroup<FlxText>();
        add(diffsTextGroup);

        // Create difficulty icons (will be updated dynamically)
        // Start with placeholder - will update based on actual difficulties
        updateDifficultyDisplay();

        cardsGroup = new FlxTypedGroup<FlxSprite>();
        add(cardsGroup);
        
        cardSongText = new FlxTypedGroup<FlxText>();
        add(cardSongText);

        cardModText = new FlxTypedGroup<FlxText>();
        add(cardModText);

        // Create cards dynamically for all songs
        for (i in 0...songs.length) {
            // Validate song data
            if (songs[i] == null || songs[i].songName == null || songs[i].songName == "") {
                trace('Skipping invalid song at index $i');
                continue;
            }
            
            try {
                // Create card
                var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/card'));
                card.x = 880;
                card.y = 275 + (i * 74);
                card.antialiasing = ClientPrefs.data.antialiasing;
                card.color = songs[i].color; // Dynamic color from song
                card.updateHitbox();
                card.ID = i;
                cardsGroup.add(card);
                
                // Create song name text
                var songText:FlxText = new FlxText(0, 0, 0, songs[i].songName);
                songText.setFormat(Paths.font('inter-bold.otf'), 14, FlxColor.BLACK, 'left');
                songText.x = 950;
                songText.y = 290 + (i * 74);
                songText.ID = i;
                cardSongText.add(songText);

                // Create mod name text
                var modName:String = songs[i].folder;
                if (modName == null || modName == '') {
                    modName = 'Base Game';
                }
                var modTextItem:FlxText = new FlxText(0, 0, 0, modName);
                modTextItem.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.GRAY, 'left');
                modTextItem.x = 950;
                modTextItem.y = 310 + (i * 74);
                modTextItem.ID = i;
                cardModText.add(modTextItem);
                
                // Load icon for each song
                var characterName = songs[i].songCharacter;
                if (characterName == null || characterName == "") {
                    characterName = 'face';
                }
                
                var icon:HealthIcon = new HealthIcon(characterName, false, false);
                icon.x = 920;
                icon.y = 285 + (i * 74);
                iconArray.push(icon);
                add(icon);
                
            } catch (e:Dynamic) {
                trace('Error creating card for song ${songs[i].songName}: $e');
                continue;
            }
        }

        var barsGroup = new FlxTypedGroup<FlxSprite>();
        add(barsGroup);
        
        for (i in 0...10) {
            var bar:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/card'));
            bar.color = FlxColor.PURPLE; // Set bar color to purple
            bar.angle = 90; // Rotate the bar to be horizontal
            bar.scale.set(1 + Std.int((i - 1) * (66 / 6)), 1); // Make the bar thinner
            bar.x = 275 + (i * 20); // Position to the right of the difficulty icons
            bar.y = 554; // Position below the mod text
            bar.setGraphicSize(10, 10); // Make the bar wider and thinner
            barsGroup.add(bar);
        }
        
        // Initialize color
        if(curSelected >= songs.length) curSelected = 0;
        if(songs.length > 0) {
            bg.color = songs[curSelected].color;
            intendedColor = bg.color;
            dinamic.color = intendedColor;
        }
        lerpSelected = curSelected;
        
        curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
        
        // Bottom tips text
        final space:String = (controls.mobileC) ? "X" : "SPACE";
        final control:String = (controls.mobileC) ? "C" : "CTRL";
        final reset:String = (controls.mobileC) ? "Y" : "RESET";
        
        var leText:String = Language.getPhrase("freeplay_tip", "Press {1} to listen to the Song / Press {2} to open the Gameplay Changers Menu / Press {3} to Reset your Score and Accuracy.", [space, control, reset]);
        bottomString = leText;
        var size:Int = 16;
        bottomText = new FlxText(0, FlxG.height - 24, FlxG.width, leText, size);
        bottomText.setFormat(Paths.font("inter-bold.otf"), size, FlxColor.WHITE, CENTER);
        bottomText.scrollFactor.set();
        add(bottomText);
        
        // Opponent Mode indicator
        opponentModeText = new FlxText(FlxG.width * 0.68, 5, 0, "", 20);
        opponentModeText.setFormat(Paths.font("inter-bold.otf"), 20, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        opponentModeText.borderSize = 1.5;
        opponentModeText.visible = false;
        add(opponentModeText);
        
        // Missing text overlay
        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        missingTextBG.alpha = 0.6;
        missingTextBG.visible = false;
        add(missingTextBG);
        
        missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
        missingText.setFormat(Paths.font("inter-bold.otf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        missingText.scrollFactor.set();
        missingText.visible = false;
        add(missingText);
        
        // Music player
        player = new MusicPlayer(this);
        add(player);
        
        // Difficulty selector
        difficultySelector = new DifficultySelector();
        add(difficultySelector.cards);
        add(difficultySelector.items);
        add(difficultySelector.scoreTexts);
        
        // Initial selection update
        changeSelection();
        updateTexts();
        updateDynamicData();
        
        #if mobile
        addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
        addTouchPadCamera();
        if(touchPad != null) {
            touchPad.visible = true;
            touchPad.updateTrackedButtons();
        }
        #end
    }
    
    /**
     * Load songs from all weeks
     */
    function loadSongsFromWeeks():Void {
        final accept:String = (controls.mobileC) ? "A" : "ACCEPT";
        final reject:String = (controls.mobileC) ? "B" : "BACK";

        if(WeekData.weeksList.length < 1) {
            FlxTransitionableState.skipNextTransIn = true;
            persistentUpdate = false;
            MusicBeatState.switchState(new funkin.ui.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject + " to return to Main Menu.",
                function() MusicBeatState.switchState(new funkin.ui.debug.MasterEditorMenu()),
                function() MusicBeatState.switchState(new funkin.ui.mainmenu.MainMenuState())));
            return;
        }

        for (i in 0...WeekData.weeksList.length) {
            if(weekIsLocked(WeekData.weeksList[i])) continue;

            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            var leSongs:Array<String> = [];
            var leChars:Array<String> = [];

            for (j in 0...leWeek.songs.length) {
                leSongs.push(leWeek.songs[j][0]);
                leChars.push(leWeek.songs[j][1]);
            }

            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs) {
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                    colors = [146, 113, 253];
                var songColor:Int = FlxColor.fromRGB(colors[0], colors[1], colors[2]);
                addSong(song[0], i, song[1], songColor);
            }
        }
        Mods.loadTopMod();
    }
    
    /**
     * Add a song to the list
     */
    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int) {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
    }
    
    /**
     * Check if week is locked
     */
    function weekIsLocked(name:String):Bool {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!funkin.ui.story.StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !funkin.ui.story.StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }
    
    /**
     * Update function - main game loop
     */
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        updateTexts(elapsed);
        
        if(WeekData.weeksList.length < 1)
            return;

        if (FlxG.sound.music.volume < 0.7)
            FlxG.sound.music.volume += 0.5 * elapsed;
        
        Conductor.songPosition = FlxG.sound.music.time;
        
        // Background zoom animation
        bgZoom = FlxMath.lerp(defaultBgZoom, bgZoom, Math.exp(-elapsed * 3.125));
        bg.scale.set(bgZoom, bgZoom);
        bg.updateHitbox();
        bg.screenCenter();

        // Score lerping
        lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
        lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

        if (Math.abs(lerpScore - intendedScore) <= 10)
            lerpScore = intendedScore;
        if (Math.abs(lerpRating - intendedRating) <= 0.01)
            lerpRating = intendedRating;

        // Update score displays
        updateDynamicData();

        var shiftMult:Int = 1;
        if((FlxG.keys.pressed.SHIFT || (touchPad != null && touchPad.buttonZ.pressed)) && !player.playingMusic) 
            shiftMult = 3;

        if (!player.playingMusic) {
            if (!inDifficultySelect) {
                // Song navigation
                if(controls.UI_UP_P) {
                    changeSelection(-shiftMult);
                    holdTime = 0;
                }
                if(controls.UI_DOWN_P) {
                    changeSelection(shiftMult);
                    holdTime = 0;
                }
                
                // Holding navigation
                if(controls.UI_DOWN || controls.UI_UP) {
                    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                    holdTime += elapsed;
                    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

                    if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                        changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
                }
                
                // Enter difficulty selection
                if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
                    enterDifficultySelect();
                }
            } else {
                // Difficulty navigation
                if(controls.UI_LEFT_P) {
                    changeDifficultySelection(-1);
                }
                if(controls.UI_RIGHT_P) {
                    changeDifficultySelection(1);
                }
            }
        }
        
        // Toggle opponent mode
        if (FlxG.keys.justPressed.TAB && !player.playingMusic) {
            viewingOpponentScores = !viewingOpponentScores;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            
            #if !switch
            intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
            intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
            #end
            
            if (viewingOpponentScores) {
                opponentModeText.text = "OPPONENT MODE";
                opponentModeText.visible = true;
            } else {
                opponentModeText.visible = false;
            }
        }

        // Back button
        if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed)) {
            if (player.playingMusic) {
                FlxG.sound.music.stop();
                destroyFreeplayVocals();
                FlxG.sound.music.volume = 0;
                instPlaying = -1;
                player.playingMusic = false;
                player.switchPlayMusic();
            } else if (inDifficultySelect) {
                exitDifficultySelect();
            } else {
                persistentUpdate = false;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new funkin.ui.mainmenu.MainMenuState());
            }
        }

        // Gameplay changers
        if((FlxG.keys.justPressed.CONTROL || (touchPad != null && touchPad.buttonC.justPressed)) && !player.playingMusic) {
            persistentUpdate = false;
            removeTouchPad();
            openSubState(new GameplayChangersSubstate());
        }
        
        // Music preview
        if(FlxG.keys.justPressed.SPACE || (touchPad != null && touchPad.buttonX.justPressed)) {
            if(instPlaying != curSelected && !player.playingMusic) {
                // Play music (implementation needed)
            } else if (instPlaying == curSelected && player.playingMusic) {
                player.playingMusic = false;
                player.switchPlayMusic();
            }
        }
        
        // Accept/Play song
        if ((controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed)) && !player.playingMusic) {
            if (!inDifficultySelect) {
                enterDifficultySelect();
            } else {
                // Play the song
                playSong();
            }
        }
        
        // Reset score
        if((controls.RESET || (touchPad != null && touchPad.buttonY.justPressed)) && !player.playingMusic) {
            persistentUpdate = false;
            removeTouchPad();
            openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }
    
    /**
     * Update dynamic data displays (scores, BPM, etc.)
     */
    function updateDynamicData():Void {
        if(songs.length == 0) return;
        
        var ratingPercent:Float = CoolUtil.floorDecimal(lerpRating * 100, 2);
        var ratingSplit:Array<String> = Std.string(Math.abs(ratingPercent)).split('.');
        if(ratingSplit.length < 2) ratingSplit.push('');
        while(ratingSplit[1].length < 2) ratingSplit[1] += '0';
        var ratingDisplay:String = ratingSplit.join('.');
        if(ratingPercent < 0) ratingDisplay = '-' + ratingDisplay;
        
        // Update score data
        scoreData.text = Std.string(lerpScore);
        accuracyData.text = ratingDisplay + '%';
        
        // Get max combo from highscore
        #if !switch
        var maxCombo:Int = 0; // This would need to be tracked in Highscore
        comboData.text = maxCombo + 'x';
        
        // Calculate rating letter based on accuracy
        var ratingLetter:String = 'N/A';
        if(lerpRating >= 1.0) ratingLetter = 'S++';
        else if(lerpRating >= 0.95) ratingLetter = 'S+';
        else if(lerpRating >= 0.90) ratingLetter = 'S';
        else if(lerpRating >= 0.85) ratingLetter = 'A';
        else if(lerpRating >= 0.75) ratingLetter = 'B';
        else if(lerpRating >= 0.65) ratingLetter = 'C';
        else if(lerpRating >= 0.50) ratingLetter = 'D';
        else ratingLetter = 'F';
        ratingData.text = ratingLetter;
        #end
        
        // Update song info
        themeText.text = songs[curSelected].songName;
        modText.text = songs[curSelected].folder != '' ? songs[curSelected].folder : 'Friday Night Funkin\'';
        
        // Update total stats
        totalSongsText.text = 'TOTAL SONGS\n' + songs.length;
        
        // Count loaded mods
        var modsCount:Int = 0;
        #if MODS_ALLOWED
        if(Mods.parseList() != null) {
            modsCount = Mods.parseList().enabled.length;
        }
        #end
        modsLoadedText.text = 'MODS LOADED\n' + modsCount;
        
        // Update difficulty count
        diffText.text = 'Select Difficulty (' + Difficulty.list.length + ')';
        
        // Update time/date
        var now = Date.now();
        var hours = now.getHours();
        var minutes = now.getMinutes();
        var day = now.getDate();
        var month = now.getMonth() + 1;
        var year = now.getFullYear();
        
        var timeStr = (hours < 10 ? '0' : '') + hours + ':' + (minutes < 10 ? '0' : '') + minutes;
        var dateStr = (day < 10 ? '0' : '') + day + '/' + (month < 10 ? '0' : '') + month + '/' + year;
        todayText.text = timeStr + '\n' + dateStr;
        
        // Update difficulty display
        updateDifficultyDisplay();
    }
    
    /**
     * Update difficulty icons display
     */
    function updateDifficultyDisplay():Void {
        diffsGroup.clear();
        diffsTextGroup.clear();
        
        // Show up to 3 difficulties (or all if less than 3)
        var diffsToShow:Int = Std.int(Math.min(3, Difficulty.list.length));
        
        for (i in 0...diffsToShow) {
            var diffIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/diff'));
            diffIcon.x = 42.5 + (i * 85);
            diffIcon.y = 485.2;
            diffIcon.antialiasing = ClientPrefs.data.antialiasing;
            diffIcon.color = getDifficultyColorForIcon(Difficulty.getString(i));
            diffIcon.updateHitbox();
            diffIcon.ID = i;
            diffsGroup.add(diffIcon);
            
            var diffText:FlxText = new FlxText(0, 0, 0, Difficulty.getString(i));
            diffText.setFormat(Paths.font('inter-bold.otf'), 14, FlxColor.BLACK, 'center');
            diffText.x = 47.5 + (i * 90) + (18 - diffText.width / 2); 
            diffText.y = 495.5;
            diffText.ID = i;
            diffsTextGroup.add(diffText);
        }
        
        // Highlight current difficulty
        if(curDifficulty < diffsGroup.length && curDifficulty >= 0) {
            diffsGroup.members[curDifficulty].alpha = 1.0;
            if(diffsTextGroup.members[curDifficulty] != null) {
                diffsTextGroup.members[curDifficulty].setBorderStyle(OUTLINE, FlxColor.YELLOW, 2);
            }
        }
    }
    
    /**
     * Get difficulty color for icon display
     */
    function getDifficultyColorForIcon(diffName:String):Int {
        var lowerName = diffName.toLowerCase();
        
        if (lowerName.contains('easy'))
            return 0x8FD9A8;
        else if (lowerName.contains('normal'))
            return 0xFFE69C;
        else if (lowerName.contains('hard'))
            return 0xFFB3BA;
        else if (lowerName.contains('erect'))
            return 0xFFB5E8;
        else if (lowerName.contains('nightmare'))
            return 0xC7A3FF;
        else
            return 0xCCCCCC; // Default gray
    }
    
    /**
     * Change song selection
     */
    function changeSelection(change:Int = 0, playSound:Bool = true):Void {
        if (player.playingMusic || songs.length == 0)
            return;

        curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
        
        _updateSongLastDifficulty();
        if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        var newColor:Int = songs[curSelected].color;
        if(newColor != intendedColor) {
            intendedColor = newColor;
            FlxTween.cancelTweensOf(bg);
            FlxTween.color(bg, 1, bg.color, intendedColor);
            FlxTween.cancelTweensOf(dinamic);
            FlxTween.color(dinamic, 1, dinamic.color, intendedColor);
        }

        // Update card visibility and highlighting
        for (i in 0...cardsGroup.members.length) {
            if(i < songs.length) {
                cardsGroup.members[i].color = songs[i].color;
                cardsGroup.members[i].alpha = (i == curSelected) ? 1.0 : 0.6;
            }
        }

        if (!songs[curSelected].isStepMania) {
            Mods.currentModDirectory = songs[curSelected].folder;
        } else {
            Mods.currentModDirectory = '';
        }
        
        PlayState.storyWeek = songs[curSelected].week;
        
        if (!songs[curSelected].isStepMania) {
            Difficulty.loadFromWeek();
        }
        
        detectAndLoadAllDifficulties();
        
        if (Difficulty.list == null || Difficulty.list.length == 0) {
            Difficulty.list = ['Normal'];
        }
        
        var savedDiff:String = songs[curSelected].lastDifficulty;
        var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
        
        if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
            curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
        else if(lastDiff > -1)
            curDifficulty = lastDiff;
        else if(Difficulty.list.contains(Difficulty.getDefault()))
            curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
        else
            curDifficulty = 0;

        changeDiff();
        _updateSongLastDifficulty();
    }
    
    /**
     * Change difficulty
     */
    function changeDiff(change:Int = 0):Void {
        if (player.playingMusic || Difficulty.list.length == 0)
            return;

        curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
        
        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        #end

        lastDifficultyName = Difficulty.getString(curDifficulty, false);

        missingText.visible = false;
        missingTextBG.visible = false;
    }
    
    /**
     * Enter difficulty selection mode
     */
    function enterDifficultySelect():Void {
        inDifficultySelect = true;
        FlxG.sound.play(Paths.sound('scrollMenu'));

        difficultySelector.loadDifficulties();
        difficultySelector.curSelected = curDifficulty;
        difficultySelector.lerpSelected = curDifficulty;

        FlxTween.tween(this, {songsOffsetX: -1000}, 0.3, {ease: FlxEase.expoOut});
        FlxTween.tween(blackOverlay, {alpha: 0.6}, 1.0, {ease: FlxEase.sineInOut});
        FlxTween.tween(difficultySelector, {enterProgress: 1}, 0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
        
        #if mobile
        difficultyScroll = new funkin.mobile.backend.TouchScroll(true);
        #end
    }

    /**
     * Exit difficulty selection mode
     */
    function exitDifficultySelect():Void {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        inDifficultySelect = false;

        #if mobile
        if (touchScroll != null) touchScroll.reset();
        if (difficultyScroll != null) {
            difficultyScroll.destroy();
            difficultyScroll = null;
        }
        #end

        FlxTween.tween(difficultySelector, {enterProgress: 0}, 0.25, {
            ease: FlxEase.expoIn,
            onComplete: function(twn:FlxTween) {
                difficultySelector.clearDifficulties();
            }
        });
        
        FlxTween.tween(this, {songsOffsetX: 0}, 0.3, {ease: FlxEase.expoOut});
        FlxTween.tween(blackOverlay, {alpha: 0.5}, 1.0, {ease: FlxEase.sineInOut});
    }

    /**
     * Change difficulty in selector
     */
    function changeDifficultySelection(change:Int = 0):Void {
        difficultySelector.changeSelection(change);
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        
        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, difficultySelector.curSelected, viewingOpponentScores);
        intendedRating = Highscore.getRating(songs[curSelected].songName, difficultySelector.curSelected, viewingOpponentScores);
        #end
        
        difficultySelector.updateScoreTexts();
    }
    
    /**
     * Play selected song
     */
    function playSong():Void {
        curDifficulty = difficultySelector.curSelected;
        
        persistentUpdate = false;
        var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
        var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
        
        try {
            PlayState.SONG = Song.loadFromJson(poop, songLowercase);
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = curDifficulty;
            
            trace('Loading song: $poop');
        } catch(e:Dynamic) {
            trace('ERROR LOADING SONG: $e');
            missingText.text = 'ERROR WHILE LOADING CHART:\n$e';
            missingText.screenCenter(Y);
            missingText.visible = true;
            missingTextBG.visible = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }
        
        @:privateAccess
        if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
            Paths.clearUnusedMemory();
            Mods.loadTopMod();
        }
        
        LoadingState.prepareToSong();
        LoadingState.returnState = new FreeplayState();
        LoadingState.loadAndSwitchState(new PlayState());
        #if !SHOW_LOADING_SCREEN 
        FlxG.sound.music.stop(); 
        #end
        stopMusicPlay = true;
        destroyFreeplayVocals();
    }
    
    /**
     * Detect all available difficulties for current song
     */
    public function detectAndLoadAllDifficulties():Void {
        if(songs.length == 0) return;
        
        if (songs[curSelected].isStepMania) {
            if (songs[curSelected].smDifficulties != null && songs[curSelected].smDifficulties.length > 0) {
                Difficulty.list = songs[curSelected].smDifficulties;
            } else {
                Difficulty.list = ['Normal'];
                trace('StepMania song has no difficulties, using default');
            }
            return;
        }
        
        var songName:String = Paths.formatToSongPath(songs[curSelected].songName);
        var availableDiffs:Array<String> = [];
        
        for (diff in Difficulty.list) {
            availableDiffs.push(diff);
        }
        
        var erectDiffs:Array<String> = ['Erect', 'Nightmare'];
        for (diff in erectDiffs) {
            if (!availableDiffs.contains(diff)) {
                var diffFile:String = Highscore.formatSong(songName, Difficulty.list.indexOf(diff));
                var path:String = Paths.getPath('data/$songName/$diffFile.json', TEXT);
                
                #if MODS_ALLOWED
                if(FileSystem.exists(path) || Assets.exists(path)) {
                    availableDiffs.push(diff);
                }
                #else
                if(Assets.exists(path)) {
                    availableDiffs.push(diff);
                }
                #end
            }
        }
        
        Difficulty.list = availableDiffs;
    }
    
    inline private function _updateSongLastDifficulty():Void {
        if(songs.length > 0 && curSelected < songs.length)
            songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
    }
    
    /**
     * Update visual elements
     */
    public function updateTexts(elapsed:Float = 0.0):Void {
        lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
        
        // Update card positions and visibility based on selection
        for (i in 0...cardsGroup.members.length) {
            var card = cardsGroup.members[i];
            if(i < songs.length) {
                card.visible = true;
                var difference:Float = i - lerpSelected;
                card.y = 275 + (difference * 74);
                
                // Fade out cards that are too far
                var distanceFade:Float = Math.abs(difference);
                if(distanceFade > _drawDistance) {
                    card.alpha = 0;
                } else {
                    card.alpha = (i == curSelected) ? 1.0 : 0.6;
                }
                
                // Update corresponding text positions and visibility
                if(i < cardSongText.members.length && cardSongText.members[i] != null) {
                    cardSongText.members[i].y = 290 + (difference * 74);
                    cardSongText.members[i].visible = card.visible;
                    cardSongText.members[i].alpha = card.alpha;
                }
                
                if(i < cardModText.members.length && cardModText.members[i] != null) {
                    cardModText.members[i].y = 310 + (difference * 74);
                    cardModText.members[i].visible = card.visible;
                    cardModText.members[i].alpha = card.alpha;
                }
                
                // Update icon positions
                if(i < iconArray.length && iconArray[i] != null) {
                    iconArray[i].y = 285 + (difference * 74);
                    iconArray[i].visible = card.visible;
                    iconArray[i].alpha = card.alpha;
                }
            } else {
                card.visible = false;
            }
        }
        
        // Update color transitions
        dinamic.color = FlxColor.interpolate(dinamic.color, intendedColor, elapsed * 5);
        
        // Update difficulty selector if active
        if (inDifficultySelect || difficultySelector.enterProgress > 0) {
            difficultySelector.update(elapsed);
        }
    }
    
    /**
     * Load StepMania files from sm/ folder
     */
    function loadStepManiaFiles():Void {
        #if sys
        #if mobile
        var smDir = StorageUtil.getSMDirectory();
        #else
        var smDir = './sm/';
        #end
        
        if (!sys.FileSystem.exists(smDir)) {
            trace('SM folder not found, creating it...');
            sys.FileSystem.createDirectory(smDir);
            return;
        }
        
        trace('Scanning for StepMania files...');
        
        for (folder in sys.FileSystem.readDirectory(smDir)) {
            var folderPath = smDir + folder;
            
            if (!sys.FileSystem.isDirectory(folderPath)) continue;
            
            var smFile:String = null;
            for (file in sys.FileSystem.readDirectory(folderPath)) {
                if (file.endsWith('.sm')) {
                    smFile = file;
                    break;
                }
            }
            
            if (smFile == null) {
                trace('No .sm file found in $folder');
                continue;
            }
            
            var fullPath = folderPath + '/' + smFile;
            
            try {
                // SM parsing would go here
                trace('Found SM file: $fullPath');
            } catch (e:Dynamic) {
                trace('Error loading SM file $fullPath: $e');
            }
        }
        
        #else
        trace('StepMania support not available on this platform');
        #end
    }
    
    /**
     * Destroy freeplay vocals
     */
    public static function destroyFreeplayVocals():Void {
        if(vocals != null) vocals.stop();
        vocals = FlxDestroyUtil.destroy(vocals);

        if(opponentVocals != null) opponentVocals.stop();
        opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
    }
    
    /**
     * Close substate handler
     */
    override function closeSubState():Void {
        changeSelection(0, false);
        persistentUpdate = true;
        super.closeSubState();
        
        #if mobile
        removeTouchPad();
        addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
        addTouchPadCamera();
        if(touchPad != null) {
            touchPad.visible = true;
            touchPad.updateTrackedButtons();
        }
        #end
    }
    
    /**
     * Beat hit animation
     */
    override public function beatHit():Void {
        super.beatHit();
        
        if (curBeat % 2 == 0) {
            bgZoom += 0.015;
        }
    }
    
    /**
     * Destroy handler
     */
    override function destroy():Void {
        #if mobile
        if (difficultyScroll != null) {
            difficultyScroll.destroy();
            difficultyScroll = null;
        }
        
        if (touchScroll != null) {
            touchScroll.destroy();
            touchScroll = null;
        }
        funkin.mobile.backend.TouchUtil.clearScrollHandler();
        #end
        
        super.destroy();

        FlxG.autoPause = ClientPrefs.data.autoPause;
        if (!FlxG.sound.music.playing && !stopMusicPlay)
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
    }
}

// Song Metadata Class
class SongMetadata {
    public var songName:String = "";
    public var week:Int = 0;
    public var songCharacter:String = "";
    public var color:Int = -7179779;
    public var folder:String = "";
    public var lastDifficulty:String = null;
    public var isStepMania:Bool = false;
    public var smFolder:String = "";
    public var smDifficulties:Array<String> = [];

    public function new(song:String, week:Int, songCharacter:String, color:Int) {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Mods.currentModDirectory;
        if(this.folder == null) this.folder = '';
    }
}

// Difficulty Selector Class
class DifficultySelector {
    public var items:FlxTypedGroup<FlxText>;
    public var cards:FlxTypedGroup<FlxSprite>;
    public var scoreTexts:FlxTypedGroup<FlxText>;
    public var curSelected:Int = 0;
    public var lerpSelected:Float = 0;
    public var enterProgress:Float = 0;
    
    private var baseXOffset:Float = 300;
    private var slideDistance:Float = 500;
    private var selectionTween:FlxTween;
    
    public function new() {
        items = new FlxTypedGroup<FlxText>();
        cards = new FlxTypedGroup<FlxSprite>();
        scoreTexts = new FlxTypedGroup<FlxText>();
    }
    
    public function loadDifficulties():Void {
        items.clear();
        cards.clear();
        scoreTexts.clear();
        
        if (FreeplayState.instance != null && FreeplayState.instance.songs[FreeplayState.curSelected] != null) {
            if (!FreeplayState.instance.songs[FreeplayState.curSelected].isStepMania) {
                Difficulty.loadFromWeek();
            }
            FreeplayState.instance.detectAndLoadAllDifficulties();
        }
        
        for (i in 0...Difficulty.list.length) {
            var diffText:FlxText = new FlxText(0, 0, 500, Difficulty.getString(i), 48);
            diffText.setFormat(Paths.font("inter-bold.otf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            diffText.borderSize = 2;
            diffText.ID = i;
            diffText.alpha = 0;
            items.add(diffText);
            
            var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/card'));
            card.setGraphicSize(470, 110);
            card.updateHitbox();
            card.alpha = 0;
            card.color = getDifficultyColor(Difficulty.getString(i));
            cards.add(card);
            
            var scoreInfoText:FlxText = new FlxText(0, 0, 450, "", 18);
            scoreInfoText.setFormat(Paths.font("inter-bold.otf"), 18, FlxColor.WHITE, CENTER);
            scoreInfoText.ID = i;
            scoreInfoText.alpha = 0;
            scoreTexts.add(scoreInfoText);
        }
        
        updateScoreTexts();
    }
    
    public function clearDifficulties():Void {
        items.clear();
        cards.clear();
        scoreTexts.clear();
    }
    
    public function updateScoreTexts():Void {
        if (FreeplayState.instance == null) return;
        
        for (i in 0...scoreTexts.members.length) {
            var scoreText:FlxText = scoreTexts.members[i];
            if (scoreText == null) continue;
            
            var diffIndex:Int = scoreText.ID;
            var songName:String = FreeplayState.instance.songs[FreeplayState.curSelected].songName;
            
            #if !switch
            var score:Int = Highscore.getScore(songName, diffIndex, FreeplayState.viewingOpponentScores);
            var accuracy:Float = Highscore.getRating(songName, diffIndex, FreeplayState.viewingOpponentScores);
            var accSystem:String = Highscore.getAccuracySystem(songName, diffIndex, FreeplayState.viewingOpponentScores);
            
            var accPercent:String = '';
            if (accuracy > 0) {
                var ratingPercent:Float = CoolUtil.floorDecimal(accuracy * 100, 2);
                accPercent = ' | ' + Std.string(ratingPercent) + '%';
            } else {
                accPercent = ' | 0.00%';
            }
            
            if (score > 0) {
                scoreText.text = 'Score: ' + score + accPercent;
            } else {
                scoreText.text = 'No record';
            }
            #else
            scoreText.text = '';
            #end
        }
    }
    
    private function getDifficultyColor(diffName:String):Int {
        var lowerName = diffName.toLowerCase();
        var normalizedName = normalizeDifficultyName(lowerName);
        
        if (normalizedName == 'easy')
            return 0x8FD9A8;
        else if (normalizedName == 'normal')
            return 0xFFE69C;
        else if (normalizedName == 'hard')
            return 0xFFB3BA;
        else if (normalizedName == 'erect')
            return 0xFFB5E8;
        else if (normalizedName == 'nightmare')
            return 0xC7A3FF;
        else {
            var hash:Int = 0;
            for (i in 0...diffName.length) {
                hash = diffName.charCodeAt(i) + ((hash << 5) - hash);
            }
            
            var r:Int = Std.int(Math.abs((hash >> 16) & 0xFF));
            var g:Int = Std.int(Math.abs((hash >> 8) & 0xFF));
            var b:Int = Std.int(Math.abs(hash & 0xFF));
            
            r = Std.int((r + 255) / 2);
            g = Std.int((g + 255) / 2);
            b = Std.int((b + 255) / 2);
            
            return FlxColor.fromRGB(r, g, b);
        }
    }
    
    private function normalizeDifficultyName(diffName:String):String {
        var lower = diffName.toLowerCase();
        
        var easyTranslated = Language.getPhrase('difficulty_Easy', 'Easy').toLowerCase();
        var normalTranslated = Language.getPhrase('difficulty_Normal', 'Normal').toLowerCase();
        var hardTranslated = Language.getPhrase('difficulty_Hard', 'Hard').toLowerCase();
        var erectTranslated = Language.getPhrase('difficulty_Erect', 'Erect').toLowerCase();
        var nightmareTranslated = Language.getPhrase('difficulty_Nightmare', 'Nightmare').toLowerCase();
        
        if (lower == easyTranslated || lower == 'easy')
            return 'easy';
        if (lower == normalTranslated || lower == 'normal')
            return 'normal';
        if (lower == hardTranslated || lower == 'hard')
            return 'hard';
        if (lower == erectTranslated || lower == 'erect')
            return 'erect';
        if (lower == nightmareTranslated || lower == 'nightmare')
            return 'nightmare';
        
        return lower;
    }
    
    public function changeSelection(change:Int = 0):Void {
        curSelected = FlxMath.wrap(curSelected + change, 0, Difficulty.list.length - 1);
        
        if (selectionTween != null) selectionTween.cancel();
        
        selectionTween = FlxTween.tween(this, {lerpSelected: curSelected}, 0.25, {
            ease: FlxEase.expoOut
        });
    }
    
    public function update(elapsed:Float):Void {
        for (i in 0...items.members.length) {
            var item:FlxText = items.members[i];
            var card:FlxSprite = cards.members[i];
            var scoreText:FlxText = scoreTexts.members[i];
            
            if(item == null || card == null) continue;
            
            var difference:Float = i - lerpSelected;
            var targetX:Float = FlxG.width / 2 + (difference * slideDistance) - baseXOffset;
            var targetY:Float = FlxG.height / 2 - 55;
            
            item.x = FlxMath.lerp(targetX, item.x, Math.exp(-elapsed * 12));
            item.y = targetY;
            
            card.x = item.x - 35;
            card.y = item.y - 10;
            
            if(scoreText != null) {
                scoreText.x = card.x + 10;
                scoreText.y = card.y + 80;
            }
            
            var targetAlpha:Float = enterProgress * (1.0 - (Math.abs(difference) * 0.3));
            if(Math.abs(difference) > 2) targetAlpha = 0;
            
            item.alpha = FlxMath.lerp(targetAlpha, item.alpha, Math.exp(-elapsed * 8));
            card.alpha = item.alpha;
            if(scoreText != null) scoreText.alpha = item.alpha;
            
            var targetScale:Float = (i == Math.round(lerpSelected)) ? 1.1 : 1.0;
            item.scale.set(targetScale, targetScale);
            card.scale.set(targetScale, targetScale);
        }
    }
    
    public function destroy():Void {
        if(selectionTween != null) {
            selectionTween.cancel();
            selectionTween = null;
        }
    }
}