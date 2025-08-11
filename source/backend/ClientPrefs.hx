package backend;

import backend.extraKeys.ExtraKeysHandler.EKNoteColor;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import states.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables
{
	// General
	public var framerate:Int = 60;
	public var colorblindMode:String = 'None';
	public var lowQuality:Bool = false;
	public var gameQuality:Int = #if mobile 0 #else 1 #end;
	public var antialiasing:Bool = true;
	public var flashing:Bool = true;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var autoPause:Bool = true;
	public var gcFreeZone:Bool = true;
	#if mobile
    public var AutoOrientation:Bool = false;
    #end

	// Gameplay
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var flipChart:Bool = false;
	public var ghostTapping:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var noReset:Bool = false;
	// Opponent s
	public var playOpponent:Bool = false;
	public var opponentCodeFix:Bool = false;
	public var botOpponentFix:Bool = true;
	public var HealthDrainOPPOMult:Float = 0.5;
	public var HealthDrainOPPO:Bool = false;

	// Backend
	// Gameplay backend s
	public var replayBot:Bool = false;
	public var fixLNL:Int = 0; // fix long note length
	public var saveScoreBase:String = 'Score';
	public var mainMusic:String = 'None';
	public var optionMusic:String = 'None';
	public var pauseMusic:String = 'Tea Time';
	public var hitsoundType:String = 'Default';
	public var hitsoundVolume:Float = 0;
	public var oldHscriptVersion:Bool = false;
	public var pauseButton:Bool = #if mobile true #else false #end;
	public var CompulsionPause:Bool = false;
	public var CompulsionPauseNumber:Int = 3;
	public var gameOverVibration:Bool = false;
	public var ratingOffset:Int = 0;
	public var noteOffset:Int = 0;
	public var marvelousWindow:Int = 15;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var marvelousRating:Bool = true;
	public var marvelousSprite:Bool = true;

	// App backend s
	public var discordRPC:Bool = true;
	public var checkForUpdates:Bool = true;
	public var fileLoad:String = 'NovaFlare Engine';
	public var openedFlash:Bool = false;
	public var screensaver:Bool = false;
	public var githubCheck:Bool = false;
	public var filesCheck:Bool = #if ios false #else true #end;

	// Game UI
	// Visble s
	public var hideHud:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;
	public var opponentStrums:Bool = true;
	public var judgementCounter:Bool = false;
	public var keyboardDisplay:Bool = true;
	// TimeBar s
	public var timeBarType:String = 'Time Left';
	// HealthBar s
	public var healthBarAlpha:Float = 1;
	public var oldHealthBarVersion:Bool = false;
	// Combe s
	public var comboStacking:Bool = true;
	public var comboColor:Bool = true;
	public var comboOffsetFix:Bool = true;
	// KeyBoard s
	public var keyboardAlpha:Float = 0.8;
	public var keyboardTimeDisplay:Bool = true;
	public var keyboardTime:Float = 500;
	public var keyboardBGColor:String = 'WHITE';
	public var keyboardTextColor:String = 'BLACK';
	// Camera s
	public var camZooms:Bool = true;
	public var scoreZoom:Bool = true;

	// Skin
	public var noteSkin:String = 'Default';
	public var noteRGB:Bool = true;
	// splash s
	public var splashSkin:String = 'Psych';
	public var splashRGB:Bool = true;
	public var showSplash:Bool = true;
	public var splashAlpha:Float = 0.6;

	// Input
	// Moblie Input Backend s
	public var dynamicColors:Bool = true;
	public var needMobileControl:Bool = true; // work for desktop
	public var hitboxLocation:String = 'Bottom';
	public var controlsAlpha:Float = 0.6;
	public var playControlsAlpha:Float = 0.2;
	public var hideHitboxHints:Bool = false;

	public var extraKey:Int = 4;
	public var extraKeyReturn1:String = 'SPACE';
	public var extraKeyReturn2:String = 'SPACE';
	public var extraKeyReturn3:String = 'SHIFT';
	public var extraKeyReturn4:String = 'SHIFT';

	// User Interface
	public var uiScale:Float = 1; //废弃

	public var CustomFade:String = 'Move';
	public var CustomFadeSound:Float = 0.5;
	public var CustomFadeText:Bool = true;
	public var skipTitleVideo:Bool = false;
	public var audioDisplayQuality:Int = 1;
	public var audioDisplayUpdate:Int = 50;
	public var freeplayOld:Bool = false;
	public var resultsScreen:Bool = true;
	public var loadingScreen:Bool = false;
	public var loadImageTheards:Int = #if mobile 4 #else 8 #end;
	public var loadMusicTheards:Int = #if mobile 2 #else 4 #end;

	// Watermark
	public var showFPS:Bool = true;
	public var showExtra:Bool = true;
	public var rainbowFPS:Bool = false;
	public var memoryType:String = 'Usage';
	public var FPSScale:Float = 1;
	public var WatermarkScale:Float = 1;
	public var showWatermark:Bool = true;

	public var comboOffset:Array<Int> = [0, 0, 0, 0, 530, 470];

	public var language:String = 'English';

	public var developerMode:Bool = false;
	public var DevConScale:Float = #if mobile 1.8 #else 1.5 #end;

	//For Extra Keys (maybe)
	public var showKeybinds:Bool = false;

	/////RelaxState Options\\\\\
	public var NextSongs:String = 'Next';
	public var RelaxAudioDisplayQuality:Int = 2;
	public var RelaxAudioNumber:Int = 3;
	public var RelaxAudioSymmetry:Bool = true;
	
	public var enableRecordRotation:Bool = true;
	public var enableBpmZoom:Bool = true;
	
	//public var theme:Array<String> = ["Circle", "Straight", "None"];
	//public var SongInfo:Array<String> = ["None", "Middle", "topLeft", "downLeft", "topRight", "downRight"];
	public var theme:String = "Circle";
	public var SongInfo:String = "None";
	
	//////////////////////////////////////////////////////////////////////////////////////

	//Psych引擎的箭头RGB可以扔了，已经几乎被PsychEK代替了————卡昔233
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		// -kade
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
}

class ClientPrefs
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_up' => [W, UP],
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_right' => [D, RIGHT],
		'ui_up' => [W, UP],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R],
		'volume_mute' => [#if mobile F10 #else ZERO #end],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN],
		'debug_2' => [EIGHT],
		'fullscreen' => [F11]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up' => [DPAD_UP, Y],
		'note_left' => [DPAD_LEFT, X],
		'note_down' => [DPAD_DOWN, A],
		'note_right' => [DPAD_RIGHT, B],
		'ui_up' => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left' => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down' => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right' => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'accept' => [A, START],
		'back' => [B],
		'pause' => [START],
		'reset' => [BACK]
	];
	public static var mobileBinds:Map<String, Array<FlxMobileInputID>> = [
		'note_up' => [noteUP, UP2],
		'note_left' => [noteLEFT, LEFT2],
		'note_down' => [noteDOWN, DOWN2],
		'note_right' => [noteRIGHT, RIGHT2],
		'ui_up' => [UP, noteUP],
		'ui_left' => [LEFT, noteLEFT],
		'ui_down' => [DOWN, noteDOWN],
		'ui_right' => [RIGHT, noteRIGHT],
		'accept' => [A],
		'back' => [B],
		'pause' => [#if android NONE #else P #end],
		'reset' => [NONE]
	];
	public static var defaultMobileBinds:Map<String, Array<FlxMobileInputID>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) // Null = both, False = Keyboard, True = Controller
	{
		if (controller != true)
			for (key in keyBinds.keys())
				if (defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if (controller != false)
			for (button in gamepadBinds.keys())
				if (defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		var mobileBind:Array<FlxMobileInputID> = mobileBinds.get(key);
		while (keyBind != null && keyBind.contains(NONE))
			keyBind.remove(NONE);
		while (gamepadBind != null && gamepadBind.contains(NONE))
			gamepadBind.remove(NONE);
		while (mobileBind != null && mobileBind.contains(NONE))
			mobileBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
		defaultMobileBinds = mobileBinds.copy();

		var saveDataKeybinds = ExtraKeysHandler.instance.data.keybinds;

		// if resetting keybinds to default doesnt work, hmu
		for (i in 0...saveDataKeybinds.length) {
			var maniaKeybinds = saveDataKeybinds[i];
			var maniaID = '${i}_key';
			for (j in 0...maniaKeybinds.length) {
				var keybindID = '${maniaID}_$j';
				var codes = maniaKeybinds[j];
				defaultKeys.set(keybindID, codes);
			}
		}
	}

	public static function saveSettings()
	{
		for (key in Reflect.fields(data))
			if (key != 'arrowRGB' && key != 'arrowRGBPixel')
			{
				Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
			}
		#if sys
		else if (key == 'arrowRGB')
			saveArrowRGBData('arrowRGB.json', data.arrowRGB);
		else if (key == 'arrowRGBPixel')
			saveArrowRGBData('arrowRGBPixel.json', data.arrowRGBPixel);
		#end

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		// Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.data.mobile = mobileBinds;

		// this was NOT that easy
		var saveDataKeybinds:Array<Array<Array<Int>>> = [];
			//[], [], [], [], [], [], [], [], []

		for (i in 0...ExtraKeysHandler.instance.data.maxKeys+1) {
			saveDataKeybinds.push([]);
		}

		// loads keybinds in a very specific way
		// do NOT put "*key*" in the map or it will die
		for (k in keyBinds.keys()) {
			if (k.contains('key')) {
				trace('EK Keybind detected: $k');
				var storeNum = Std.parseInt(k.split('_')[0]);

				var convertKeycodes = keyBinds.get(k);
				var newKeycodes:Array<Int> = [];
				for (key in convertKeycodes) { newKeycodes.push(key); }

				var index = Std.parseInt(k.split('_')[2]);

				saveDataKeybinds[storeNum].insert(index, newKeycodes);

				//trace('$k saved to $storeNum with codes ${keyBinds.get(k)} and index $index');
			}
		}

		var saveKeybindData:EKKeybindSavedData = new EKKeybindSavedData(saveDataKeybinds);
		var writer = new json2object.JsonWriter<EKKeybindSavedData>();
		var content = writer.write(saveKeybindData, '  ');
		#if sys
		trace('Saved ekkeybinds.json');
		File.saveContent('ekkeybinds.json', content);
		#end

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	#if sys
	public static function saveArrowRGBData(path:String, rgbArray:Array<Array<FlxColor>>)
	{
		var saveArrowRGB:ArrowRGBSavedData;
		var colors:Array<EKNoteColor> = [];
		for (color in rgbArray)
		{
			var inner = color[0];
			var border = color[1];
			var outline = color[2];

			var resultColor = new EKNoteColor();
			resultColor.inner = inner.toHexString(false, false);
			resultColor.border = border.toHexString(false, false);
			resultColor.outline = outline.toHexString(false, false);

			colors.push(resultColor);

			// trace('Saved color ${resultColor.inner} ${resultColor.border} ${resultColor.outline}');
		}

		saveArrowRGB = new ArrowRGBSavedData(colors);
		var writer = new json2object.JsonWriter<ArrowRGBSavedData>();
		var content = writer.write(saveArrowRGB, '    ');
		File.saveContent(path, content);

		trace('Wrote to $path');
	}
	#end

	public static function loadArrowRGBData(path:String, pixel:Bool = false, defaultColors:Array<EKNoteColor>)
	{
		var savedColors:CoolUtil.ArrowRGBSavedData = CoolUtil.getArrowRGB(path, defaultColors);

		if (pixel)
			ClientPrefs.defaultData.arrowRGBPixel = [];
		else
			ClientPrefs.defaultData.arrowRGB = [];

		for (defaultColor in defaultColors)
		{
			var thisNote = [
				CoolUtil.colorFromString(defaultColor.inner),
				CoolUtil.colorFromString(defaultColor.border),
				CoolUtil.colorFromString(defaultColor.outline)
			];
			if (pixel)
				ClientPrefs.defaultData.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.defaultData.arrowRGB.push(thisNote);
		}

		if (pixel)
			ClientPrefs.data.arrowRGBPixel = [];
		else
			ClientPrefs.data.arrowRGB = [];

		for (color in savedColors.colors)
		{
			var thisNote = [
				CoolUtil.colorFromString(color.inner),
				CoolUtil.colorFromString(color.border),
				CoolUtil.colorFromString(color.outline)
			];

			// trace('Loaded color into save: $thisNote, pixel? $pixel');

			if (pixel)
				ClientPrefs.data.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.data.arrowRGB.push(thisNote);
		}
	}

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && 
				key != 'arrowRGB' &&
				key != 'arrowRGBPixel' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
			else if (key == 'arrowRGB') 
			{
				loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
			} 
			else if (key == 'arrowRGBPixel') 
			{
				loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);
			}

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;

		if (FlxG.save.data.framerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if (data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if (save != null)
		{
			if (save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if (keyBinds.exists(control))
						keyBinds.set(control, keys);
			}
			if (save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if (gamepadBinds.exists(control))
						gamepadBinds.set(control, keys);
			}
			if (save.data.mobile != null)
			{
				var loadedControls:Map<String, Array<FlxMobileInputID>> = save.data.mobile;
				for (control => keys in loadedControls)
					if (mobileBinds.exists(control))
						mobileBinds.set(control, keys);
			}

			var savedKeybindJson = CoolUtil.getKeybinds('ekkeybinds.json', ExtraKeysHandler.instance.data.keybinds);
			//trace(savedKeybindJson.keybinds);
			var saveDataKeybinds = savedKeybindJson.keybinds;

			for (i in 0...saveDataKeybinds.length) 
			{
				var maniaKeybinds = saveDataKeybinds[i];
				var maniaID = '${i}_key';
				for (j in 0...maniaKeybinds.length) 
				{
					var keybindID = '${maniaID}_$j';
					var codes = maniaKeybinds[j];
					//trace('Set $keybindID to $codes');

					keyBinds.set(keybindID, codes);
				}
			}

			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue)
			defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : [];
	}
}
