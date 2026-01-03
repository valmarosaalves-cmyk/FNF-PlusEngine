package options;

class CompatibilitySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('compatibility_menu', 'Compatibility Settings');
		rpcTitle = 'Compatibility Settings Menu';

		// SScript Compatibility Option
		var option:Option = new Option('Use SScript for Psych 0.7.3 Mods',
			"If checked, uses SScript instead of hscript-iris for running Haxe code.\nEnable this if you're using mods from Psych Engine 0.6.x - 0.7.3\nthat have compatibility issues with hscript-iris.",
			'useSScriptCompat',
			BOOL);
		addOption(option);

		super();
	}
}

