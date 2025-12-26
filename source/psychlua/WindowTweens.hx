package psychlua;

import openfl.Lib;
import openfl.system.Capabilities;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.util.FlxColor;
import states.PlayState;

#if windows
import winapi.WindowsAPI;
#end

// Thanks Slushi for these functions =p

class WindowTweens {
    public static function winTweenX(tag:String, targetX:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startX = window.x;
        var variables = MusicBeatState.getVariables();
        if(tag != null) {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');
            variables.set(tag, FlxTween.num(startX, targetX, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.x = Std.int(FlxMath.lerp(startX, targetX, tween.percent));
                },
                onComplete: function(_) {
                    variables.remove(tag);
                    if (onComplete != null) onComplete();
                    if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.x']);
                }
            }));
            return tag;
        } else {
            FlxTween.num(startX, targetX, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.x = Std.int(FlxMath.lerp(startX, targetX, tween.percent));
                },
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
        }
        #end
        return null;
    }

    public static function winTweenY(tag:String, targetY:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startY = window.y;
        var variables = MusicBeatState.getVariables();
        if(tag != null) {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');
            variables.set(tag, FlxTween.num(startY, targetY, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.y = Std.int(FlxMath.lerp(startY, targetY, tween.percent));
                },
                onComplete: function(_) {
                    variables.remove(tag);
                    if (onComplete != null) onComplete();
                    if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.y']);
                }
            }));
            return tag;
        } else {
            FlxTween.num(startY, targetY, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.y = Std.int(FlxMath.lerp(startY, targetY, tween.percent));
                },
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
        }
        #end
        return null;
    }
    
    public static function setWindowBorderless(enable:Bool) {
    #if windows
    var window = Lib.current.stage.window;
    window.borderless = enable;
    #end
    }

    public static function setWindowX(x:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.x = x;
        #end
    }

    public static function setWindowY(y:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.y = y;
        #end
    }

    public static function setWindowSize(width:Int, height:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.resize(width, height);
        #end
    }

    public static function getWindowX():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.x;
        #else
        return 0;
        #end
    }

    public static function getWindowY():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.y;
        #else
        return 0;
        #end
    }

    public static function getWindowWidth():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.width;
        #else
        return FlxG.width;
        #end
    }

    public static function getWindowHeight():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.height;
        #else
        return FlxG.height;
        #end
    }

    public static function centerWindow() {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Capabilities.screenResolutionX;
        var screenHeight = Capabilities.screenResolutionY;
        window.x = Std.int((screenWidth - window.width) / 2);
        window.y = Std.int((screenHeight - window.height) / 2);
        #end
    }

    public static function setWindowTitle(title:String) {
        #if windows
        var window = Lib.current.stage.window;
        window.title = title;
        #end
    }

    public static function getWindowTitle():String {
        #if windows
        var window = Lib.current.stage.window;
        return window.title;
        #else
        return "";
        #end
    }

    public static function setWindowIcon(iconPath:String) {
        #if windows
        try {
            var window = Lib.current.stage.window;
            var iconBitmap = openfl.display.BitmapData.fromFile(iconPath);
            if (iconBitmap != null) {
                window.setIcon(lime.graphics.Image.fromBitmapData(iconBitmap));
            }
        } catch (e:Dynamic) {
            trace('Error setting window icon: $e');
        }
        #end
    }

    public static function setWindowResizable(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.resizable = enable;
        #end
    }

    public static function randomizeWindowPosition(minX:Int = 0, maxX:Int = -1, minY:Int = 0, maxY:Int = -1) {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Capabilities.screenResolutionX;
        var screenHeight = Capabilities.screenResolutionY;
        
        // Use screen bounds if not specified
    if (maxX == -1) maxX = Std.int(screenWidth - window.width);
    if (maxY == -1) maxY = Std.int(screenHeight - window.height);
        
        // Ensure mins don't exceed maxs
        minX = Std.int(Math.min(minX, maxX));
        minY = Std.int(Math.min(minY, maxY));
        
        var randomX = Std.int(minX + Math.random() * (maxX - minX));
        var randomY = Std.int(minY + Math.random() * (maxY - minY));
        
        window.x = randomX;
        window.y = randomY;
        #end
    }

    public static function getScreenResolution():{width:Int, height:Int} {
        return {
            width: Std.int(Capabilities.screenResolutionX),
            height: Std.int(Capabilities.screenResolutionY)
        };
    }

    public static function setWindowFullscreen(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.fullscreen = enable;
        #end
    }

    public static function isWindowFullscreen():Bool {
        #if windows
        var window = Lib.current.stage.window;
        return window.fullscreen;
        #else
        return false;
        #end
    }

    public static function saveWindowState():String {
        #if windows
        var window = Lib.current.stage.window;
        var state = {
            x: window.x,
            y: window.y,
            width: window.width,
            height: window.height,
            borderless: window.borderless,
            resizable: window.resizable,
            title: window.title
        };
        return haxe.Json.stringify(state);
        #else
        return "{}";
        #end
    }

    public static function loadWindowState(stateJson:String) {
        #if windows
        try {
            var state = haxe.Json.parse(stateJson);
            var window = Lib.current.stage.window;
            
            if (state.x != null) window.x = state.x;
            if (state.y != null) window.y = state.y;
            if (state.width != null && state.height != null) {
                window.resize(state.width, state.height);
                FlxG.resizeGame(state.width, state.height);
            }
            if (state.borderless != null) window.borderless = state.borderless;
            if (state.resizable != null) window.resizable = state.resizable;
            if (state.title != null) window.title = state.title;
        } catch (e:Dynamic) {
            trace('Error loading window state: $e');
        }
        #end
    }

    public static function winTweenSize(targetW:Int, targetH:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startW = window.width;
        var startH = window.height;

        // Cambia el modo de escala para que el juego se estire con la ventana
        FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode();

        FlxTween.num(0, 1, duration, {
            ease: LuaUtils.getTweenEaseByString(ease),
            onUpdate: function(tween:FlxTween) {
                window.resize(
                    Std.int(FlxMath.lerp(startW, targetW, tween.percent)),
                    Std.int(FlxMath.lerp(startH, targetH, tween.percent))
                );
                FlxG.resizeGame(window.width, window.height);
            },
            onComplete: function(_) {
                if (onComplete != null) onComplete();
            }
        });
        #end
    }

    public static function winResizeCenter(width:Int, height:Int, ?skip:Bool = false, ?markAsResized:Bool = true) {
        #if windows
        if (markAsResized && PlayState.instance != null) {
            PlayState.instance.windowResizedByScript = true;
        }
        var window = Lib.application.window;
        var winYRatio = 1;
        var winY = height * winYRatio;
        var winX = width * winYRatio;

        FlxTween.cancelTweensOf(window);
        if (!skip) {
            FlxTween.tween(window, {
                width: winX,
                height: winY,
                y: Math.floor((Capabilities.screenResolutionY / 2) - (winY / 2)),
                x: Math.floor((Capabilities.screenResolutionX / 2) - (winX / 2)) + (Capabilities.screenResolutionX * Math.floor(window.x / (Capabilities.screenResolutionX)))
            }, 0.4, {
                ease: FlxEase.quadInOut,
                onComplete: function(_) {
                    if (PlayState.instance != null && PlayState.instance.camHUD != null) {
                        PlayState.instance.camHUD.fade(FlxColor.BLACK, 0, true);
                    }
                }
            });
        } else {
            FlxG.resizeWindow(width, height);
            window.y = Math.floor((Capabilities.screenResolutionY / 2) - (winY / 2));
            window.x = Std.int(Math.floor((Capabilities.screenResolutionX / 2) - (winX / 2)) + (Capabilities.screenResolutionX * Math.floor(window.x / (Capabilities.screenResolutionX))));
        }
        FlxG.scaleMode = new RatioScaleMode(true);
        window.resizable = width == 1280;
        #end
    }

    public static function getWindowState():String {
        #if windows
        try {
            // Función simplificada sin acceso directo a Windows API
            var window = Lib.current.stage.window;
            if (window.fullscreen) return "fullscreen";
            return "normal";
        } catch (e:Dynamic) {
            trace('Error getting window state: $e');
            return "error";
        }
        #else
        return "normal";
        #end
    }

    public static function setDesktopWallpaper(path:String) {
        #if windows
        try {
            WindowsAPI.setWallpaper(path);
        } catch (e:Dynamic) {
            trace('Error setting wallpaper: $e');
        }
        #end
    }

    public static function hideDesktopIcons(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideDesktopIcons(hide);
        } catch (e:Dynamic) {
            trace('Error hiding desktop icons: $e');
        }
        #end
    }

    public static function hideTaskBar(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideTaskbar(hide);
        } catch (e:Dynamic) {
            trace('Error hiding taskbar: $e');
        }
        #end
    }

    public static function moveDesktopElements(x:Int, y:Int) {
        #if windows
        try {
            WindowsAPI.moveDesktopWindowsInXY(x, y);
        } catch (e:Dynamic) {
            trace('Error moving desktop elements: $e');
        }
        #end
    }

    public static function setDesktopTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setDesktopWindowsAlpha(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting desktop transparency: $e');
        }
        #end
    }

    public static function setTaskBarTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setTaskBarAlpha(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting taskbar transparency: $e');
        }
        #end
    }

    public static function getCursorPosition():{x:Int, y:Int} {
        #if windows
        try {
            return {
                x: WindowsAPI.getCursorPositionX(),
                y: WindowsAPI.getCursorPositionY()
            };
        } catch (e:Dynamic) {
            trace('Error getting cursor position: $e');
            return {x: 0, y: 0};
        }
        #else
        return {x: 0, y: 0};
        #end
    }

    public static function getSystemRAM():Int {
        #if windows
        try {
            return WindowsAPI.obtainRAM();
        } catch (e:Dynamic) {
            trace('Error getting system RAM: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function showNotification(title:String, message:String) {
        #if windows
        try {
            WindowsAPI.sendWindowsNotification(title, message);
        } catch (e:Dynamic) {
            trace('Error showing notification: $e');
        }
        #end
    }

    public static function resetSystemChanges() {
        #if windows
        try {
            WindowsAPI.resetWindowsFuncs();
        } catch (e:Dynamic) {
            trace('Error resetting system changes: $e');
        }
        #end
    }

    public static function getDesktopWindowsXPos():Int {
        #if windows
        try {
            return WindowsAPI.getDesktopWindowsXPos();
        } catch (e:Dynamic) {
            trace('Error getting desktop X position: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function getDesktopWindowsYPos():Int {
        #if windows
        try {
            return WindowsAPI.getDesktopWindowsYPos();
        } catch (e:Dynamic) {
            trace('Error getting desktop Y position: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function setWindowBorderColor(r:Int, g:Int, b:Int) {
        #if windows
        try {
            WindowsAPI.setWindowBorderColor(r, g, b);
        } catch (e:Dynamic) {
            trace('Error setting window border color: $e');
        }
        #end
    }

    public static function setWindowOpacity(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setWindowOppacity(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting window opacity: $e');
        }
        #end
    }

    public static function getWindowOpacity():Float {
        #if windows
        try {
            return WindowsAPI.getWindowOppacity();
        } catch (e:Dynamic) {
            trace('Error getting window opacity: $e');
            return 1.0;
        }
        #else
        return 1.0;
        #end
    }

    public static function setWindowVisible(visible:Bool) {
        #if windows
        try {
            WindowsAPI.setWindowVisible(visible);
        } catch (e:Dynamic) {
            trace('Error setting window visibility: $e');
        }
        #end
    }

    public static function showMessageBox(message:String, caption:String, icon:String = "WARNING") {
        #if windows
        try {
            var iconType = switch(icon.toUpperCase()) {
                case "ERROR": winapi.WindowsAPI.MessageBoxIcon.ERROR;
                case "QUESTION": winapi.WindowsAPI.MessageBoxIcon.QUESTION;
                case "INFORMATION": winapi.WindowsAPI.MessageBoxIcon.INFORMATION;
                default: winapi.WindowsAPI.MessageBoxIcon.WARNING;
            }
            WindowsAPI.showMessageBox(message, caption, iconType);
        } catch (e:Dynamic) {
            trace('Error showing message box: $e');
        }
        #end
    }

    public static function changeWindowsWallpaper(path:String) {
        #if windows
        try {
            WindowsAPI.changeWindowsWallpaper(path);
        } catch (e:Dynamic) {
            trace('Error changing wallpaper: $e');
        }
        #end
    }

    public static function saveCurrentWallpaper() {
        #if windows
        try {
            WindowsAPI.saveCurrentWindowsWallpaper();
        } catch (e:Dynamic) {
            trace('Error saving current wallpaper: $e');
        }
        #end
    }

    public static function restoreOldWallpaper() {
        #if windows
        try {
            WindowsAPI.setOldWindowsWallpaper();
        } catch (e:Dynamic) {
            trace('Error restoring old wallpaper: $e');
        }
        #end
    }

    public static function reDefineMainWindowTitle(title:String) {
        #if windows
        try {
            WindowsAPI.reDefineMainWindowTitle(title);
        } catch (e:Dynamic) {
            trace('Error redefining main window title: $e');
        }
        #end
    }

    public static function allocConsole() {
        #if windows
        try {
            WindowsAPI.allocConsole();
        } catch (e:Dynamic) {
            trace('Error allocating console: $e');
        }
        #end
    }

    public static function clearTerminal() {
        #if windows
        try {
            WindowsAPI.clearTerminal();
        } catch (e:Dynamic) {
            trace('Error clearing terminal: $e');
        }
        #end
    }

    public static function hideMainWindow() {
        #if windows
        try {
            WindowsAPI.hideMainWindow();
        } catch (e:Dynamic) {
            trace('Error hiding main window: $e');
        }
        #end
    }

    public static function setConsoleTitle(title:String) {
        #if windows
        try {
            WindowsAPI.setConsoleTitle(title);
        } catch (e:Dynamic) {
            trace('Error setting console title: $e');
        }
        #end
    }

    public static function setConsoleWindowIcon(path:String) {
        #if windows
        try {
            WindowsAPI.setConsoleWindowIcon(path);
        } catch (e:Dynamic) {
            trace('Error setting console window icon: $e');
        }
        #end
    }

    public static function centerConsoleWindow() {
        #if windows
        try {
            WindowsAPI.centerConsoleWindow();
        } catch (e:Dynamic) {
            trace('Error centering console window: $e');
        }
        #end
    }

    public static function disableResizeConsoleWindow() {
        #if windows
        try {
            WindowsAPI.disableResizeConsoleWindow();
        } catch (e:Dynamic) {
            trace('Error disabling console resize: $e');
        }
        #end
    }

    public static function disableCloseConsoleWindow() {
        #if windows
        try {
            WindowsAPI.disableCloseConsoleWindow();
        } catch (e:Dynamic) {
            trace('Error disabling console close: $e');
        }
        #end
    }

    public static function maximizeConsoleWindow() {
        #if windows
        try {
            WindowsAPI.maximizeConsoleWindow();
        } catch (e:Dynamic) {
            trace('Error maximizing console window: $e');
        }
        #end
    }

    public static function getConsoleWindowWidth():Int {
        #if windows
        try {
            return WindowsAPI.getConsoleWindowWidth();
        } catch (e:Dynamic) {
            trace('Error getting console width: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function getConsoleWindowHeight():Int {
        #if windows
        try {
            return WindowsAPI.getConsoleWindowHeight();
        } catch (e:Dynamic) {
            trace('Error getting console height: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function setConsoleCursorPosition(x:Int, y:Int) {
        #if windows
        try {
            WindowsAPI.setConsoleCursorPosition(x, y);
        } catch (e:Dynamic) {
            trace('Error setting console cursor position: $e');
        }
        #end
    }

    public static function getConsoleCursorPositionX():Int {
        #if windows
        try {
            return WindowsAPI.getConsoleCursorPositionInX();
        } catch (e:Dynamic) {
            trace('Error getting console cursor X: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function getConsoleCursorPositionY():Int {
        #if windows
        try {
            return WindowsAPI.getConsoleCursorPositionInY();
        } catch (e:Dynamic) {
            trace('Error getting console cursor Y: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function setConsoleWindowPositionX(posX:Int) {
        #if windows
        try {
            WindowsAPI.setConsoleWindowPositionX(posX);
        } catch (e:Dynamic) {
            trace('Error setting console X position: $e');
        }
        #end
    }

    public static function setConsoleWindowPositionY(posY:Int) {
        #if windows
        try {
            WindowsAPI.setConsoleWindowPositionY(posY);
        } catch (e:Dynamic) {
            trace('Error setting console Y position: $e');
        }
        #end
    }

    public static function hideConsoleWindow() {
        #if windows
        try {
            WindowsAPI.hideConsoleWindow();
        } catch (e:Dynamic) {
            trace('Error hiding console window: $e');
        }
        #end
    }
}