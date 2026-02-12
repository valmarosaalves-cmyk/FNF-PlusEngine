package funkin.util;

#if android
import lime.system.JNI;
#end

/**
 * Android-specific memory queries.
 *
 * Notes:
 * - `getPss()` returns memory in kB (PSS), which matches what Android often shows as app memory.
 * - This is usually closer to Android "Task mem" than RSS from `/proc`.
 */
class AndroidMemory
{
	#if android
	private static var __getPss:Dynamic;
	private static var __getNativeHeapAllocatedSize:Dynamic;
	#end

	/**
	 * Returns current process PSS in bytes.
	 */
	public static function getPssBytes():Float
	{
		#if android
		try
		{
			if (__getPss == null)
			{
				// public static long android.os.Debug.getPss()
				__getPss = JNI.createStaticMethod("android/os/Debug", "getPss", "()J");
			}

			var kb:Float = Std.parseFloat(Std.string(__getPss()));
			if (!Math.isNaN(kb) && kb > 0)
			{
				return kb * 1024.0;
			}
		}
		catch (e:Dynamic)
		{
			// Ignore and fall back to other methods
		}
		#end

		return 0.0;
	}

	/**
	 * Returns native heap allocated size in bytes.
	 * This is not the total app memory, but it can be useful for debugging.
	 */
	public static function getNativeHeapAllocatedBytes():Float
	{
		#if android
		try
		{
			if (__getNativeHeapAllocatedSize == null)
			{
				// public static long android.os.Debug.getNativeHeapAllocatedSize()
				__getNativeHeapAllocatedSize = JNI.createStaticMethod("android/os/Debug", "getNativeHeapAllocatedSize", "()J");
			}

			var bytes:Float = Std.parseFloat(Std.string(__getNativeHeapAllocatedSize()));
			if (!Math.isNaN(bytes) && bytes > 0)
			{
				return bytes;
			}
		}
		catch (e:Dynamic)
		{
			// Ignore
		}
		#end

		return 0.0;
	}
}
