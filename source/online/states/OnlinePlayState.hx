package online.states;

import objects.StrumNote;
import backend.Song;
import backend.Section;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.util.FlxSort;
import objects.Note;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;

import backend.Section.SwagSection;
import backend.Song.SwagSong;

import io.colyseus.Client;
import io.colyseus.Room;

class OnlinePlayState extends MusicBeatState
{
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

    var finishTimer:FlxTimer = null;
    
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	public static var SONG:SwagSong = null;
	var startingSong:Bool = true;

	public var generatedMusic:Bool = false;
	
	var vocals:FlxSound;
    var opponentVocals:FlxSound;
    var inst:FlxSound;

	private var curSong:String = "";

	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	// 键盘控制相关
	public var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	// 网络连接相关
	public var room:Room<Dynamic>;
	public var ConnectNum:Int = 0;

	public function new()
	{
		super();
		
		SONG = Song.loadFromJson("dad-battle-hard","dad-battle");
		generateSong(SONG.song);
		connectRoom();
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
		
		addMobileControls(false);
		mobileControls.visible = true;
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		// Gameplay settings
		songSpeed = SONG.speed;
		songSpeedType = "multiplicative";
		
		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		
		generateStaticArrows(0);
		generateStaticArrows(1);
	}
	
	function startSong():Void
    {
        inst.play();
        if (SONG.needsVoices) {
            vocals.play();
            opponentVocals.play();
        }
        
        FlxG.sound.music = inst;
        
        vocals.volume = 1;
        opponentVocals.volume = 1;
        inst.volume = 1;
        FlxG.sound.music.onComplete = finishSong;
        
        startingSong = false;
    }

	override public function destroy()
    {
        if (vocals != null) vocals.destroy();
        if (opponentVocals != null) opponentVocals.destroy();
        if (inst != null) inst.destroy();
        
        super.destroy();
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
    }

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (key > -1)
		{
			// 发送按键按下消息到服务器
			if (room != null)
			{
			    try {
			        room.send("notePressed", key);
			    }
			}
			keyPressed(key);
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (key > -1)
		{
			// 发送按键释放消息到服务器
			if (room != null)
			{
				try {
			        room.send("noteReleased", key);
			    }
			}
			keyReleased(key);
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
					if (key == noteKey)
						return i;
			}
		}
		return -1;
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
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed);
		return value;
	}
	
	private function keyReleased(key:Int)
	{
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	private function keyPressed(key:Int)
	{
		if (key < 0)
			return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if (Conductor.songPosition >= 0)
			Conductor.songPosition = FlxG.sound.music.time;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note) return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit
			&& !n.blockHit && !n.isSustainNote && n.noteData == key);

		plrInputNotes.sort(PlayState.sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (plrInputNotes.length != 0)
		{ // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			// trace('✡⚐🕆☼ 💣⚐💣');

			if (plrInputNotes.length > 1)
			{
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData)
				{
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			goodNoteHit(funnyNote);
		}

		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}
	
	function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit)
			return;

		note.wasGoodHit = true;
		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

		if (note.hitCausesMiss)
		{
			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);

			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.isSustainNote)
		{
			combo++;
			if (combo > 9999)
				combo = 9999;
			popUpScore(note);
		}

		var spr:StrumNote = playerStrums.members[note.noteData];
		if (spr != null)
			spr.playAnim('confirm', true);
		vocals.volume = 1;

		if (!note.isSustainNote)
			invalidateNote(note);
	}
	
	function opponentNoteHit(note:Note):Void
	{
		if (SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

		var strum:StrumNote = opponentStrums.members[Std.int(Math.abs(note.noteData))];
		if (strum != null)
		{
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote)
			invalidateNote(note);
	}
	
	public function invalidateNote(note:Note):Void
	{
		notes.remove(note, true);
		note.destroy();
	}

	private function generateSong(dataPath:String):Void
	{
		songSpeed = SONG.speed;
		songSpeedType = "multiplicative";

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		Note.init();

		var noteData:Array<SwagSection> = songData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = songNotes[3] != null ? songNotes[3] : "";

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

						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.updateHitbox();
							}
						}
					}
				}

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2;
				else if (ClientPrefs.data.middleScroll)
					swagNote.x += 310;
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
		
        if (SONG.needsVoices) {
            vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
            opponentVocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song, "Opponent"));
        } else {
            vocals = new FlxSound();
            opponentVocals = new FlxSound();
        }
        
        FlxG.sound.list.add(vocals);
        FlxG.sound.list.add(opponentVocals);
        
        inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
        FlxG.sound.list.add(inst);
        
        vocals.volume = 0;
        opponentVocals.volume = 0;
        inst.volume = 0;
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
			if (player == 0 && ClientPrefs.data.middleScroll)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
				opponentStrums.add(babyArrow);

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function update(elapsed:Float)
	{
		if (#if !android virtualPad.buttonP.justPressed
			|| #end FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end)
		{
			mobileControls.visible = false;
			endSong();
			super.update(elapsed);
			return;
		}

		if (!startingSong)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
        }

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		keysCheck();
		if (notes.length > 0)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if (!daNote.mustPress)
					strumGroup = opponentStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if (daNote.isSustainNote && strum.sustainReduce)
					daNote.clipToStrumNote(strum);

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}
		super.update(elapsed);
	}
	
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			if (controls.controllerMode)
			{
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if (pressArray[i])
					keyPressed(i);

		// rewritten inputs???
		if (notes.length > 0)
		{
			for (n in notes)
			{ // I can't do a filter here, that's kinda awesome
				var canHit:Bool = (n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

				if (guitarHeroSustains)
					canHit = canHit && n.parent != null && n.parent.wasGoodHit;

				if (canHit && n.isSustainNote)
				{
					var released:Bool = !holdArray[n.noteData];

					if (!released)
						goodNoteHit(n);
				}
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if (releaseArray[i])
					keyReleased(i);
	}
	
	public function finishSong():Void
	{
		if (ClientPrefs.data.noteOffset <= 0)
		{
			endSong();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endSong();
			});
		}
	}

	public function endSong()
	{
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if (finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		MusicBeatState.switchState(new states.MainMenuState());
	}
}