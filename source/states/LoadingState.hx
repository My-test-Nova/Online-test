package states;

import haxe.Json;

import lime.utils.Assets;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import openfl.display.Shape;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.FlxState;

import states.FreeplayState;

import backend.Song;
import backend.StageData;
import backend.Rating;

import sys.thread.Thread;
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;



class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0; //已经加载的数量
	public static var loadMax:Int = 0; //总体需要加载的数量

	static var requestedBitmaps:Map<String, BitmapData> = []; //储存下加载的纹理，再最后进入playstate的时候输出总结

	static var soundThread:FixedThreadPool = null; //音乐线程池
	static var sounMutex:Mutex = new Mutex(); //音乐锁

	static var imageThread:FixedThreadPool = null; //图片线程池
	static var imageMutex:Mutex = new Mutex(); //图片锁

	static var prepareMutex:Mutex = new Mutex(); //准备资源锁，这是为了防止数据提前被主线程接收

	static var isPlayState:Bool = false; //如果是要进入playstate
	static var allowPrepare:Bool = false; //允许执行prepare事件
	static var allowLoad:Bool = false; //允许执行加载




	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		var doPrecache:Bool = false; //
		if (ClientPrefs.data.loadingScreen)
		{
			if (intrusive)
			{
				if (allowPrepare)
					return new LoadingState(target, stopMusic);
			}
			else
				doPrecache = true;
		}

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (doPrecache)
		{
			startThreads();
			while (true)
			{
				if (checkLoaded())
				{
					imagesToPrepare = [];
					soundsToPrepare = [];
					musicToPrepare = [];
					songsToPrepare = [];
					if (imageThread != null) imageThread.shutdown(); // kill all workers safely
					imageThread = null;
					if (soundThread != null) soundThread.shutdown(); // kill all workers safely
					soundThread = null;
					break;
				}
				else
					Sys.sleep(0.01);
			}
		}
		return target;
	}

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		loaded = 0;
		super();
	}

	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var filePath:String = 'menuExtend/LoadingState/';

	var bar:FlxSprite;

	var button:LoadButton;
	var barHeight:Int = 10;

	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var precentText:FlxText;
	var JustSay:FlxText;
	var loads:FlxSprite;

	override public function create()
	{
		Paths.clearStoredMemory();

		var bg = new FlxSprite().loadGraphic(Paths.image(filePath + 'loadScreen'));
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		add(bg);

		loads = new FlxSprite().loadGraphic(Paths.image(filePath + 'loadIcon'));
		loads.antialiasing = ClientPrefs.data.antialiasing;
		loads.updateHitbox();
		loads.x = FlxG.width - loads.width - 2;
		loads.y = 5;
		add(loads);

		var bg:FlxSprite = new FlxSprite(0, FlxG.height - barHeight).makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, barHeight);
		bg.updateHitbox();
		bg.alpha = 0.4;
		bg.screenCenter(X);
		add(bg);

		bar = new FlxSprite(0, FlxG.height - barHeight).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, barHeight);
		bar.alpha = 0.6;
		bar.updateHitbox();
		add(bar);

		button = new LoadButton(0, 0, 35, barHeight);
		button.y = FlxG.height - button.height;
		button.antialiasing = ClientPrefs.data.antialiasing;
		button.updateHitbox();
		add(button);

		precentText = new FlxText(520, 600, 400, '0%', 30);
		precentText.setFormat(Paths.font("loadScreen.ttf"), 25, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.TRANSPARENT);
		precentText.borderSize = 0;
		precentText.antialiasing = ClientPrefs.data.antialiasing;
		add(precentText);
		precentText.x = FlxG.width - precentText.width - 2;
		precentText.y = FlxG.height - precentText.height - barHeight - 2;

		JustSay = new FlxText(0, 600, FlxG.width, '', 30);
		JustSay.setFormat(Paths.font(Language.get('fontName', 'ma') + '.ttf'), 25, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.TRANSPARENT);
		JustSay.antialiasing = ClientPrefs.data.antialiasing;
		add(JustSay);

		JustSay.y = FlxG.height - precentText.height - barHeight - 2;
		JustSay.x = 10;

		try
		{
			var filename:String = 'language/JustSay/JustSay-' + Language.get('justsayLang', 'ma') + '.txt';
			var file:String = File.getContent(Paths.getSharedPath(filename));
			var lines:Array<String> = file.split('\n');
			var randomIndex:Int = FlxG.random.int(0, lines.length);
			var randomLine:String = lines[randomIndex];
			JustSay.text = 'Tags: ' + randomLine;
		}
		catch (e:Dynamic)
		{
			JustSay.text = Std.string(e);
		}

		super.create();

		Thread.create(() ->
		{
			prepareMutex.acquire();
			startPrepare();
			prepareMutex.release();
		});
	}


	public static var imagesToPrepare:Array<String> = [];
	public static var soundsToPrepare:Array<String> = [];
	public static var musicToPrepare:Array<String> = [];
	public static var songsToPrepare:Array<String> = [];

	public static var events:Array<Array<Dynamic>> = [];

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null)
			imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null)
			soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null)
			musicToPrepare = musicToPrepare.concat(music);
	}
	

	static var dontPreloadDefaultVoices:Bool = false;

	public static function prepareToSong()
	{
		if (!ClientPrefs.data.loadingScreen)
			return;

		clearInvalids();

		isPlayState = true;
		allowPrepare = true;
		allowLoad = false;
	}

	static function startPrepare()
	{
		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(song.song);
		try
		{
			var path:String = Paths.json('$folder/preload');
			var json:Dynamic = null;

			#if MODS_ALLOWED
			var moddyFile:String = Paths.modsJson('$folder/preload');
			if (FileSystem.exists(moddyFile))
				json = Json.parse(File.getContent(moddyFile));
			else if (FileSystem.exists(path))
				json = Json.parse(File.getContent(path));
			#else
			json = Json.parse(Assets.getText(path));
			#end

			if (json != null)
				prepare((!ClientPrefs.data.lowQuality || json.images_low) ? json.images : json.images_low, json.sounds, json.music);
		}
		catch (e:Dynamic)
		{
		}

		if (song.stage == null || song.stage.length < 1)
			song.stage = StageData.vanillaSongStage(folder);

		var stageData:StageFile = StageData.getStageFile(song.stage);
		if (stageData != null)
		{
			var imgs:Array<String> = [];
			var snds:Array<String> = [];
			var mscs:Array<String> = [];
			if(stageData.preload != null)
			{
				for (asset in Reflect.fields(stageData.preload))
				{
					var filters:Int = Reflect.field(stageData.preload, asset);
					var asset:String = asset.trim();

					if(filters < 0 || StageData.validateVisibility(filters))
					{
						if(asset.startsWith('images/'))
							imgs.push(asset.substr('images/'.length));
						else if(asset.startsWith('sounds/'))
							snds.push(asset.substr('sounds/'.length));
						else if(asset.startsWith('music/'))
							mscs.push(asset.substr('music/'.length));
					}
				}
			}
			
			if (stageData.objects != null)
			{
				for (sprite in stageData.objects)
				{
					if(sprite.type == 'sprite' || sprite.type == 'animatedSprite')
						if((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
							imgs.push(sprite.image);
				}
			}
			prepare(imgs, snds, mscs);
		}

		songsToPrepare.push('$folder/Inst');

		var player1:String = song.player1;
		var player2:String = song.player2;
		var gfVersion:String = song.gfVersion;
		var needsVoices:Bool = song.needsVoices;
		var prefixVocals:String = needsVoices ? '$folder/Voices' : null;
		if (gfVersion == null)
			gfVersion = 'gf';

		dontPreloadDefaultVoices = false;
			preloadCharacter(player1, prefixVocals);

		if (!dontPreloadDefaultVoices && prefixVocals != null)
		{
			songsToPrepare.push('$prefixVocals-Player');
			songsToPrepare.push('$prefixVocals-Opponent');
			if(Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
				songsToPrepare.push(prefixVocals);
		}

		if (player2 != player1)
			preloadCharacter(player2, prefixVocals);
		if (stageData != null && !stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
			preloadCharacter(gfVersion);

		events = [];
		for (event in PlayState.SONG.events) // Event Notes
			events.push(event);

		preloadMisc();
		preloadScript();

		allowPrepare = false;
		allowLoad = true;
	}

	

	public static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if(!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if(i == 0) st = '';
	
					if(Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						//trace('found Sprite PNG');
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end

			imagesToPrepare.push('icons/' + char);
			imagesToPrepare.push('icons/icon-' + char);

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				if (char == PlayState.SONG.player1)
					dontPreloadDefaultVoices = true;
			}
			startScriptNamed('characters/' + char + '.lua');
		}
		catch (e:Dynamic)
		{
		}
	}

	static function preloadMisc()
	{
		var ratingsData:Array<Rating> = Rating.loadDefault();
		var stageData:StageFile = StageData.getStageFile(PlayState.SONG.stage);

		var uiPrefix:String = '';
		var uiSuffix:String = '';

		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		PlayState.stageUI = 'normal'; // fix
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			PlayState.stageUI = stageData.stageUI;
		else
		{
			if (stageData.isPixelStage)
				PlayState.stageUI = "pixel";
		}
		if (PlayState.stageUI != "normal")
		{
			uiPrefix = PlayState.stageUI + 'UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
		{
			imagesToPrepare.push(uiPrefix + rating.image + uiSuffix);
		}

		for (i in 0...10)
			imagesToPrepare.push(uiPrefix + 'num' + i + uiSuffix);

		imagesToPrepare.push(uiPrefix + 'ready' + uiSuffix);
		imagesToPrepare.push(uiPrefix + 'set' + uiSuffix);
		imagesToPrepare.push(uiPrefix + 'go' + uiSuffix);
		imagesToPrepare.push('healthBar');
	}

	static function preloadScript()
	{
		#if ((LUA_ALLOWED || HSCRIPT_ALLOWED) && sys)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					scriptFilesCheck(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					scriptFilesCheck(folder + file);
				#end
			}

		var songName = PlayState.SONG.song;
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					scriptFilesCheck(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					scriptFilesCheck(folder + file);
				#end
			}

		startScriptNamed('stages/' + PlayState.SONG.stage + '.lua');
		startScriptNamed('stages/' + PlayState.SONG.stage + '.hx');

		for (event in events)
		{
			startScriptNamed('custom_events/' + event + '.lua');
			startScriptNamed('custom_events/' + event + '.hx');
		}
		#end
	}

	static function startScriptNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaToLoad))
		#end
		{
			scriptFilesCheck(luaToLoad);
		}
	}

	static function scriptFilesCheck(path:String)
	{
		var input:String = File.getContent(path);
		var lines = input.split("\n");

		for (line in lines)
		{
			line = line.trim();
			if (line.startsWith('makeLuaSprite'))
			{
				var keyValue = line.split(",");
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace("'", '');
				imagesToPrepare.push(pushData);
			}
			if (line.startsWith('makeAnimatedLuaSprite'))
			{
				var keyValue = line.split(",");
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace("'", '');
				imagesToPrepare.push(pushData);
			}
			if (line.startsWith("precacheImage('"))
			{
				var keyValue = line.split("('");
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace("'", '');
				pushData = pushData.replace(")", '');
				imagesToPrepare.push(pushData);
			}
			else if (line.startsWith('precacheImage("'))
			{
				var keyValue = line.split('("');
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace('"', '');
				pushData = pushData.replace(")", '');
				imagesToPrepare.push(pushData);
			}
			if (line.startsWith("addLuaScript('"))
			{
				var keyValue = line.split("('");
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace("'", '');
				pushData = pushData.replace(")", '');
				imagesToPrepare.push(pushData);
			}
			else if (line.startsWith('addLuaScript("'))
			{
				var keyValue = line.split('("');
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace('"', '');
				pushData = pushData.replace(")", '');
				imagesToPrepare.push(pushData);
			}
			if (line.startsWith("addCharacterToList"))
			{
				var keyValue = line.split(",");
				var pushData:String = keyValue[0].trim();
				pushData = pushData.replace("addCharacterToList(", '');
				pushData = pushData.replace("'", '');
				pushData = pushData.replace('"', '');
				imagesToPrepare.push(pushData);
			}
			if (line.startsWith("precacheSound"))
			{
				var keyValue = line.split("('");
				var pushData:String = keyValue[1].trim();
				pushData = pushData.replace("'", '');
				pushData = pushData.replace(")", '');
				imagesToPrepare.push(pushData);
			}
		}
	}

	//上面为数据准备部分
	///////////////////////////////////////////
	//下面开始游戏加载流程

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		loads.angle += 1.5;
		if (dontUpdate)
			return;

		if (allowLoad)
			startThreads();
		
		if (allowPrepare) return;

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001)
				curPercent = intendedPercent;
			else
				curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = button.width / 2 + (FlxG.width - button.width) * curPercent;
			button.x = FlxG.width * curPercent - button.width * curPercent;
			bar.updateHitbox();
			button.updateHitbox();
			var precent:Float = Math.floor(curPercent * 10000) / 100;
			if (precent % 1 == 0)
				precentText.text = precent + '.00%';
			else if ((precent * 10) % 1 == 0)
				precentText.text = precent + '0%';
			else
				precentText.text = precent + '%'; // 修复显示问题
		};

		if (curPercent == 1)
		{
			onLoad();
			return;
		}
		intendedPercent = loaded / loadMax;
	}

	function onLoad() //加载完毕进行跳转
	{
		checkLoaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if (FreeplayState.vocals != null)
			FreeplayState.destroyFreeplayVocals();

		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];

		if (isPlayState)
		{
			isPlayState = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new PlayState());
		}
		else
		{
			requestedBitmaps.clear();
			MusicBeatState.switchState(target);
		}
	}

	static function checkLoaded():Bool
	{
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(key, bitmap, false) != null)
				trace('finished preloading image $key');
			else
				trace('failed to cache image $key');
		}
		return (loaded == loadMax);
	}

	public static function startThreads()
	{
		allowLoad = false;

		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		imageThread = new FixedThreadPool(ClientPrefs.data.loadImageTheards);
		soundThread = new FixedThreadPool(ClientPrefs.data.loadMusicTheards);

		for (sound in soundsToPrepare)
			initThread(() -> Paths.sound(sound, true), 'sound $sound');
		for (music in musicToPrepare)
			initThread(() -> Paths.music(music, true), 'music $music');
		for (song in songsToPrepare)
			initThread(() -> Paths.returnSound(null, song, 'songs', true), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare) {
			imageThread.run(() ->
			{
				try
				{	
					var bitmap:BitmapData;
					var file:String = null;

					#if MODS_ALLOWED
					file = Paths.modsImages(image);
					if (Cache.currentTrackedAssets.exists(file))
					{
						addLoadCount();
						return;
					}
					else if (FileSystem.exists(file)) {
						bitmap = BitmapData.fromFile(file);
					}
					else
					#end
					{
						file = Paths.getPath('images/$image.png', IMAGE);
						if (Cache.currentTrackedAssets.exists(file))
						{
							addLoadCount();
							return;
						}
						else if (OpenFlAssets.exists(file, IMAGE)) {
							bitmap = OpenFlAssets.getBitmapData(file);
						}
						else
						{
							trace('no such image $image exists');
							addLoadCount();
							return;
						}
					}

					if (bitmap != null) {
						imageMutex.acquire();
						requestedBitmaps.set(file, bitmap);
						imageMutex.release();
					}
					else
						trace('oh no the image is null NOOOO ($image)');		
				}
				catch (e:Dynamic)
				{
					Sys.sleep(0.001);
					trace('ERROR! fail on preloading image $image');
				}
				addLoadCount();
			});
		}
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		soundThread.run(() ->
		{
			try
			{
				var ret:Dynamic = func();

				if (ret != null)
					trace('finished preloading $traceData');
				else
					trace('ERROR! fail on preloading $traceData');
			}
			catch (e:Dynamic)
			{
				Sys.sleep(0.001);
				trace('ERROR! fail on preloading $traceData');
			}
			addLoadCount();
		});
	}

	static var countMutex:Mutex = new Mutex();
	static function addLoadCount() {
		countMutex.acquire();
		loaded++;
		countMutex.release();
		Sys.sleep(0.001);
	}

	//////////////////////////////////////////////

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', ' .${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND);

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?library:String = null)
	{
		for (i in 0...arr.length)
		{
			var folder:String = arr[i];
			if (folder.trim().endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$folder'))
					for (file in FileSystem.readDirectory(subfolder))
						if (file.endsWith(ext))
							arr.push(folder + file.substr(0, file.length - ext.length));
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			// if(library == 'songs') myKey = '$member$ext';

			//trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, library) && (doTrace = true)))
			{
				arr.remove(member);
				//if (doTrace)
					//trace('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
	}

	static public function loadCache() {
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null) {
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				FlxG.bitmap.add(newGraphic, false, key);
			}
		}
		requestedBitmaps.clear();
	}
	
	//////////////////////////////////////////////

	
}

class LoadButton extends FlxSprite
{
	public function new(x:Float, y:Float, Width:Int, Height:Int)
	{
		super(x, y);
		makeGraphic(Width, Height, 0x00);

		var shape:Shape = new Shape();
		shape.graphics.beginFill(color);
		shape.graphics.drawRoundRect(0, 0, Width, Height, Std.int(Height / 1), Std.int(Height / 1));
		shape.graphics.endFill();

		var BitmapData:BitmapData = new BitmapData(Width, Height, 0x00);
		BitmapData.draw(shape);

		pixels = BitmapData;
		setGraphicSize(Width, Height);
	}
}
