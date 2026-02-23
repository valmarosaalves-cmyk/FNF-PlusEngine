// ModState HScript Template
// This template shows you how to create custom states with HScript for mods
// Place your script in: mods/your-mod-name/states/YourStateName.hx

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;

function onCreate()
{
    // Called when the state is created
    // Initialize your variables and objects here
    
    // Example: Create a background
    var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(100, 100, 100));
    add(bg);
    
    // Example: Create a text
    var text = new FlxText(0, 0, FlxG.width, "Custom ModState Example", 32);
    text.setFormat(null, 32, FlxColor.WHITE, "center");
    text.screenCenter();
    add(text);
    
    // ===== MOBILE/TOUCHPAD CONTROLS =====
    // Add a touchpad for mobile controls
    // DPad modes: 'NONE', 'UP_DOWN', 'LEFT_RIGHT', 'FULL', 'RIGHT_FULL', 'LEFT_FULL'
    // Action modes: 'NONE', 'A', 'B', 'A_B', 'A_B_C', etc.
    
    // Example 1: Simple touchpad with UP/DOWN and A/B buttons
    addTouchPad('UP_DOWN', 'A_B');
    
    // Example 2: Full touchpad with all directions
    // addTouchPad('FULL', 'A_B_C');
    
    // Example 3: Add mobile controls (Hitbox/TouchPad based on user settings)
    // This respects the user's mobile control preferences
    // addMobileControls();
    
    // Example 4: Add a camera for the touchpad (makes it always visible)
    // addTouchPadCamera(false); // false = not default draw target
    
    trace('ModState created successfully!');
}

function onUpdate(elapsed:Float)
{
    // Called every frame
    // Handle input and update logic here
    
    // Example: Check touchpad input
    if (touchPad != null) {
        if (touchPad.buttonA != null && touchPad.buttonA.justPressed) {
            trace('Button A pressed!');
        }
        
        if (touchPad.buttonB != null && touchPad.buttonB.justPressed) {
            trace('Button B pressed!');
            // Example: Go back to main menu
            // FlxG.switchState(new funkin.ui.mainmenu.MainMenuState());
        }
        
        if (touchPad.buttonUp != null && touchPad.buttonUp.pressed) {
            trace('Moving up!');
        }
        
        if (touchPad.buttonDown != null && touchPad.buttonDown.pressed) {
            trace('Moving down!');
        }
    }
    
    // Example: Check mobile controls (Hitbox/TouchPad)
    if (mobileControls != null) {
        // Access buttons through the instance
        var controls = mobileControls.instance;
        if (controls != null) {
            if (controls.buttonLeft != null && controls.buttonLeft.justPressed) {
                trace('Left button pressed!');
            }
        }
    }
    
    // Example: Keyboard controls
    if (controls.BACK) {
        FlxG.switchState(new funkin.ui.mainmenu.MainMenuState());
    }
}

function onDestroy()
{
    // Called when the state is destroyed
    // Clean up your objects here
    
    // TouchPad and MobileControls are automatically removed
    // But you can manually remove them if needed:
    // removeTouchPad();
    // removeMobileControls();
    
    trace('ModState destroyed!');
}

// ===== VARIABLE MANAGEMENT =====
// ModState provides several variable systems for data persistence:

// 1. State Variables (only this state)
// setStateVar('myVar', 'value');
// var value = getStateVar('myVar', 'default');

// 2. Shared Variables (persist across state changes in same mod)
// setSharedVar('progress', 5);
// var progress = getSharedVar('progress', 0);
// var exists = hasSharedVar('progress');
// removeSharedVar('progress');
// clearSharedVars(); // Clear all shared vars

// 3. Public Variables (shared between scripts in same state)
// setPublicVar('scriptData', {count: 0});
// var data = getPublicVar('scriptData');

// 4. Static Variables (persist across ALL states and mods)
// setStaticVar('globalScore', 1000);
// var score = getStaticVar('globalScore', 0);

// ===== TOUCHPAD EXAMPLES =====

// Example: Custom button layout
function createCustomTouchPad()
{
    // Remove existing touchpad
    removeTouchPad();
    
    // Create new touchpad with specific layout
    addTouchPad('LEFT_FULL', 'A_B_C');
    
    // Optional: Make touchpad always visible with camera
    addTouchPadCamera();
}

// Example: Dynamic touchpad based on game state
function updateTouchPadForMenu()
{
    removeTouchPad();
    addTouchPad('UP_DOWN', 'A'); // Simple menu navigation
}

function updateTouchPadForGameplay()
{
    removeTouchPad();
    addMobileControls(); // Full gameplay controls
}

// Example: Access individual touchpad buttons
function customizeButtonColors()
{
    if (touchPad != null) {
        // Change button colors (if accessible)
        // Note: Button customization depends on implementation
        if (touchPad.buttonA != null) {
            touchPad.buttonA.alpha = 0.8;
        }
    }
}

// ===== ADDITIONAL NOTES =====
// - TouchPad modes are strings like 'FULL', 'UP_DOWN', 'LEFT_RIGHT', etc.
// - Action modes are strings like 'A', 'A_B', 'A_B_C', 'A_B_C_D', etc.
// - Use addMobileControls() to respect user's mobile control preferences
// - Use addTouchPad() for custom touchpad layouts
// - TouchPads are automatically cleaned up when the state is destroyed
// - All mobile functions are safe to call on desktop (they simply won't do anything)
