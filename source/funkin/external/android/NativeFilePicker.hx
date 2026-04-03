package funkin.external.android;

/**
 * Native Android file picker — lets the user pick a JSON or XML file
 * from device storage using the system document picker (ACTION_OPEN_DOCUMENT).
 *
 * Usage:
 *   1. Call NativeFilePicker.open() to launch the picker.
 *   2. Poll NativeFilePicker.getPickedPath() in your update loop (returns ""
 *      while waiting, a path once the user picks a file, or stays "" if cancelled).
 *   3. Call NativeFilePicker.clear() after you have handled the result so the
 *      next open() starts fresh.
 *
 * Example:
 *   NativeFilePicker.open();
 *
 *   // later, in update():
 *   var path = NativeFilePicker.getPickedPath();
 *   if (path != "") {
 *       trace("User picked: " + path);
 *       NativeFilePicker.clear();
 *   }
 */
class NativeFilePicker
{
  static inline final CLASS = 'com/leninasto/plusengine/PlusEngineExtension';

  /**
   * Opens the system file picker dialog.
   * Only JSON and XML files are selectable by the user.
   */
  public static function open():Void
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'openFilePicker', '()V');
    if (jni != null)
      jni();
    else
      trace('NativeFilePicker: Failed to bind openFilePicker');
    #else
    trace('NativeFilePicker.open() is only available on Android');
    #end
  }

  /**
   * Returns the absolute path of the file selected by the last open() call.
   * Returns "" while the picker is open, if cancelled, or before any pick.
   */
  public static function getPickedPath():String
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'getPickedFilePath', '()Ljava/lang/String;');
    if (jni != null)
      return (jni() : String) ?? '';
    return '';
    #else
    return '';
    #end
  }

  /**
   * Clears the internally stored path.
   * Call this after handling getPickedPath() so getPickedPath() returns ""
   * until the user makes a new selection.
   */
  public static function clear():Void
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'clearPickedFile', '()V');
    if (jni != null)
      jni();
    #end
  }

  /**
   * Request code sent to onActivityResult for the file picker.
   * Matches CallbackUtil pattern; can be used to detect when the picker closes.
   */
  public static inline final REQUEST_CODE:Int = 2001;
}
