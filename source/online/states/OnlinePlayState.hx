package states;

import objects.StrumNote;
import backend.Song;
import backend.Section;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import objects.Note;
import objects.*;

class OnlinePlayState extends MusicBeatState
{
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeed(default, set):Float = 1;
	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;

	public var inst:FlxSound;
	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var curSong:String = "";

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	public function new()
	{
		super();
		SONG = Song.loadFromJson("dad-battle");
	}
	
	function connectRoom(){
        ConnectNum++;
        if (ConnectNum > 10){
            trace("重连次数过多，稍后再试");
            return;
        }
        
        trace('正在连接 $ConnectNum');
        
        var client = new Client("wss://online.novaflare.top:2345");
        
        client.joinOrCreate("my_room", [], MyRoomState, function(err, roomResult) {
            if (err != null) {
                trace("连接错误类型: " + Type.getClass(err));
                trace("连接错误详情: " + err.code);
                trace("连接错误信息: " + err.message);
                
                trace('断开房间,尝试重连');
                connectRoom();
                return;
            }
            
            room = roomResult;
            trace("成功加入房间");
            
            ConnectNum = 0;
            
            room.onMessage("__playground_message_types", function(message) {
                //trace("收到服务器消息类型: " + message);
            });
            
            room.onMessage("notice", function(message) {
                //trace("hhh")
            });
            
            room.onMessage("notePressed", function(message) {
                keyPressed(message);
            });
            
            room.onMessage("noteReleased", function(message) {
                keyReleased(message);
            });
            
            room.onMessage("welcome_message", function(message) {
                // 可以处理欢迎消息
            });
            
            room.onMessage("start_game", function(message) {
                trace("start song");
    			startSong();
            });
            
            room.onLeave += () -> {
                trace('断开房间,尝试重连');
                connectRoom();
                return;
            };
        });
    }
	
	override public function create()
	{
		super.create();
		
		persistentUpdate = persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		if (SONG.gfVersion == null || SONG.gfVersion.length < 1)
			SONG.gfVersion = 'gf';
		gf = new Character(0, 0, SONG.gfVersion);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);

		dad = new Character(0, 0, SONG.player2);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		boyfriendGroup.add(boyfriend);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		NoteSplash.init();
		var splash:NoteSplash = new NoteSplash(100, 100);
		splash.setupNoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001;
		add(grpNoteSplashes);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		grpNoteSplashes.cameras = [camHUD];
        opponentStrums.cameras = [camHUD];
        playerStrums.cameras = [camHUD];
        strumLineNotes.cameras = [camHUD];
        
		generateStaticArrows(0);
		generateStaticArrows(1);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		vocals.pitch = playbackRate;
		#end
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed;
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic)
		{
			vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value;
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		#else
		playbackRate = 1.0;
		#end
		return playbackRate;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				keysCheck();
				
				if (notes.length > 0)
				{
					if (startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if (!daNote.mustPress)
								strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if (daNote.mustPress)
							{
								if (cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
								{
									goodNoteHit(daNote);
								}
							}
							else
							{
								if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								{
									opponentNoteHit(daNote);
								}
							}

							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !daNote.ignoreNote && !daNote.hitCausesMiss)
								{
									noteMiss(daNote);
								}
								invalidateNote(daNote);
							}
						});
					}
				}
			}
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
        {
		    if (room != null)
    		{
    			try {
    			    room.send("notePressed", key);
    			}
    	    }
			keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if (cpuControlled || paused || key < 0) return;
		if (!generatedMusic || endingSong || boyfriend.stunned) return;

		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool
		{
			return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0)
		{
			var funnyNote:Note = plrInputNotes[0];
			goodNoteHit(funnyNote);
		}
		else if (!ClientPrefs.data.ghostTapping)
		{
			noteMissPress(key);
		}

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode && key > -1){
		    if (room != null)
    		{
    			try {
    			    room.send("notePressed", key);
    			}
    	    }
			keyReleased(key);
		}
	}

	public function keyReleased(key:Int)
	{
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	public function keysCheck():Void
	{
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		if (controls.controllerMode && pressArray.contains(true))
		{
			for (i in 0...pressArray.length)
				if (pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);
		}

		if (notes.length > 0)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit 
					&& !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
				{
					if (daNote.mustPress)
						goodNoteHit(daNote);
				}
			});
		}

		if (controls.controllerMode && releaseArray.contains(true))
		{
			for (i in 0...releaseArray.length)
				if (releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
		}
	}

	public function noteMiss(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote 
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});
	}

	public function noteMissPress(direction:Int = 1):Void
	{
		if (ClientPrefs.data.ghostTapping) return;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	public function opponentNoteHit(note:Note):Void
	{
		if (songName != 'tutorial') camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;
			if (SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				altAnim = '-alt';

			var char:Character = dad;
			var animToPlay:String = singAnimations[note.noteData] + altAnim;
			if (note.gfNote) char = gf;

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashData.disabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note);
				invalidateNote(note);
				return;
			}

			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[note.noteData];
				var char:Character = boyfriend;
				if (note.gfNote) char = gf;

				if (char != null)
				{
					char.playAnim(animToPlay + note.animSuffix, true);
					char.holdTimer = 0;
				}
			}

			var spr = playerStrums.members[note.noteData];
			if (spr != null) spr.playAnim('confirm', true);
			
			vocals.volume = 1;
			note.wasGoodHit = true;

			if (!note.isSustainNote) invalidateNote(note);
		}
	}

	public function invalidateNote(note:Note):Void
	{
		note.active = false;
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	private function generateSong(dataPath:String):Void
	{
		songSpeed = SONG.speed;

		Conductor.bpm = SONG.bpm;
		curSong = SONG.song;

		vocals = new FlxSound();
		if (SONG.needsVoices) vocals.loadEmbedded(Paths.voices(SONG.song));
		FlxG.sound.list.add(vocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		FlxG.sound.list.add(inst);

		var noteData:Array<SwagSection> = SONG.notes;

		Note.init();

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0) oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = songNotes[3];
				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
					}
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2;
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player == 0 && ClientPrefs.data.middleScroll) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1) playerStrums.add(babyArrow);
			else opponentStrums.add(babyArrow);

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = isDad ? opponentStrums.members[id] : playerStrums.members[id];
		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if (key == noteKey) return i;
			}
		}
		return -1;
	}

	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		super.destroy();
	}
}