package funkin.modding.scripting;

/**
 * Per-session, in-memory cache for script file contents.
 *
 * Eliminates redundant disk reads when the same script is loaded more than once
 * in a session (e.g., after a Game Over retry).  Both FunkinLua and HScript go
 * through this class instead of calling File.getContent / LuaL.dofile directly.
 *
 * The cache is session-scoped: it should be cleared when PlayState is destroyed.
 * Individual entries can be evicted when a mod overrides a file at runtime.
 */
class ScriptCache
{
	static var _cache:Map<String, String> = [];

	/**
	 * Returns the UTF-8 content of the file at `path`.
	 * - If the content is already cached, returns it immediately (no disk I/O).
	 * - Otherwise reads from disk, stores in the cache, and returns the content.
	 * - Returns `null` if the file does not exist.
	 */
	public static function get(path:String):Null<String>
	{
		if (_cache.exists(path))
			return _cache.get(path);

		#if sys
		if (!sys.FileSystem.exists(path))
			return null;
		var content:String = sys.io.File.getContent(path);
		#else
		var content:String = lime.utils.Assets.getText(path);
		if (content == null) return null;
		#end

		_cache.set(path, content);
		return content;
	}

	/**
	 * Pre-populates cache entries for the given paths.
	 * Call this during the loading screen so that PlayState.create() does not
	 * block on disk I/O for any of the listed scripts.
	 */
	public static function warmUp(paths:Array<String>):Void
	{
		for (path in paths) get(path);
	}

	/** Removes a single entry from the cache (e.g. after a hot-reload). */
	public static function evict(path:String):Void
		_cache.remove(path);

	/** Drops the entire cache.  Call from PlayState.destroy(). */
	public static function clear():Void
		_cache.clear();
}
