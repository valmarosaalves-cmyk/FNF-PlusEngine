// Example script for Psych Engine 0.7.3 mods using hxCodec API
// This script demonstrates video playback compatibility with hxvlc wrappers

// =====================================================
// EXAMPLE 1: FlxVideo (direct playback)
// =====================================================
function onCreate() {
    // Create a video player
    var video = new FlxVideo();
    video.autoResize = true; // Auto-resize to screen
    
    // Play video (loads and starts immediately)
    video.play('videos/cutscene.mp4', false); // path, loop
    
    // Optional: Listen to events
    video.onOpening.add(function() {
        debugPrint('Video is opening...');
    });
    
    video.onEndReached.add(function() {
        debugPrint('Video finished!');
        video.dispose(); // Clean up
    });
}

// =====================================================
// EXAMPLE 2: FlxVideoSprite (as sprite)
// =====================================================
function onCreate() {
    // Create a video sprite at position (100, 50)
    var videoSprite = new FlxVideoSprite(100, 50);
    
    // Play video
    var success = videoSprite.play('videos/background.mp4', true); // loop enabled
    
    if (success) {
        debugPrint('Video loaded successfully');
        add(videoSprite); // Add to game state
    } else {
        debugPrint('Failed to load video', 0xFFFF0000);
    }
}

// =====================================================
// EXAMPLE 3: Controlling playback
// =====================================================
var myVideo = null;

function onCreate() {
    myVideo = new FlxVideoSprite(0, 0);
    myVideo.play('videos/gameplay.mp4');
    add(myVideo);
}

function onUpdatePost(elapsed) {
    // Pause on spacebar
    if (keyJustPressed('space')) {
        if (myVideo.bitmap.isPlaying) {
            myVideo.pause();
            debugPrint('Video paused');
        } else {
            myVideo.resume();
            debugPrint('Video resumed');
        }
    }
    
    // Stop on escape
    if (keyJustPressed('escape')) {
        myVideo.stop();
        debugPrint('Video stopped');
    }
}

function onDestroy() {
    if (myVideo != null) {
        myVideo.destroy();
    }
}

// =====================================================
// EXAMPLE 4: MP4Handler (legacy compatibility)
// =====================================================
var mp4 = null;

function onCreate() {
    mp4 = new MP4Handler();
    
    mp4.finishCallback = function() {
        debugPrint('MP4 playback finished!');
        startCountdown(); // Continue with song
    };
    
    mp4.playVideo('videos/intro.mp4', false, true); // path, loop, pauseMusic
}

// =====================================================
// EXAMPLE 5: VideoHandler (legacy compatibility)
// =====================================================
var handler = null;

function onCreate() {
    handler = new VideoHandler();
    handler.canUseSound = true;
    handler.canUseAutoResize = true;
    
    handler.finishCallback = function() {
        debugPrint('VideoHandler finished!');
    };
    
    handler.playVideo('videos/cutscene.mp4', false, true);
}

// =====================================================
// NOTES:
// =====================================================
// - All these wrappers work ONLY in SScript mode (Psych 0.7.3 compatibility)
// - They internally use hxvlc 2.2.5 for video playback
// - The API matches hxCodec exactly for backward compatibility
// - For new mods, consider using native hxvlc (HScript mode)
//
// Common methods:
//   - play(path, loop):Bool - Load and play video
//   - pause():Void - Pause playback
//   - resume():Void - Resume playback  
//   - stop():Void - Stop playback
//   - dispose():Void - Clean up resources
//
// Properties:
//   - bitmap.isPlaying:Bool - Check if playing
//   - bitmap.volume:Int - Volume (0-100)
//   - autoResize:Bool - Auto-resize to screen (FlxVideo only)
//
// Events:
//   - onOpening - Video is opening
//   - onEndReached - Video reached end
//   - onFormatSetup - Video format initialized
