package online.states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;
import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import backend.Song;
import backend.Conductor;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;

import objects.KeybindShowcase;
import utils.StrumBoundaries;

import backend.Section.SwagSection;
import backend.Song.SwagSong;

import io.colyseus.Client;
import io.colyseus.Room;

class OnlinePlayState extends MusicBeatState
{
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	
	public static var SONG:SwagSong;
	public var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	
	public var inst:FlxSound;
	public var vocals:FlxSound;
	
	private var keysArray:Array<String>;
	
	static var room:Room<Dynamic>;
    static var isConnect:Bool = false;
    static var ConnectNum:Int = 0;
	
	public var paused:Bool = false;
	public var canPause:Bool = true;
	public var gameStarted:Bool = false; // 等待服务器消息才开始游戏
	
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var noteGroup:FlxTypedGroup<FlxBasic>;
	
	// 添加摄像机
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	
	// 添加其他必要变量
	public var songSpeed:Float = 1;
	public var noteKillOffset:Float = 350;

	public function new()
	{
		super();
		
		SONG = Song.loadFromJson("dad-battle-hard","dad-battle");
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
        isConnect = true;
        
        client.joinOrCreate("my_room", [], MyRoomState, function(err, roomResult) {
            if (err != null) {
                trace("连接错误类型: " + Type.getClass(err));
                trace("连接错误详情: " + err.code);
                trace("连接错误信息: " + err.message);
                
                trace('断开房间,尝试重连');
                connectRoom();
                isConnect = true;
                return;
            }
            
            room = roomResult;
            trace("成功加入房间");
            
            ConnectNum = 0;
            isConnect = false;
            
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
                startGame();
            });
            
            room.onLeave += () -> {
                trace('断开房间,尝试重连');
                connectRoom();
                isConnect = true;
                return;
            };
        });
    }
	
	override public function create()
	{
		super.create();
		
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		keysArray = [];
		for (i in 0...SONG.mania + 1)
		{
			keysArray.push(SONG.mania + '_key_$i');
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		generatedMusic = false;
	
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);
		noteGroup.cameras = [camHUD];
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		noteGroup.add(grpNoteSplashes);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(strumLineNotes);
		
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		
		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);
        
		generateSong(SONG.song);
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		paused = true;
		canPause = false;
		
		addMobileControls(false);
	}
	
	public function startGame():Void
	{
		trace("收到服务器开始游戏消息");
		gameStarted = true;
		paused = false;
		canPause = true;
		startSong();
	}
	
	function generateSong(dataPath:String):Void
	{
		Conductor.bpm = SONG.bpm;
		
		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(SONG.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);
		
		vocals = new FlxSound();
		try
		{
			if (SONG.needsVoices)
				vocals.loadEmbedded(Paths.voices(SONG.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(vocals);
		
		generateStaticArrows(0);
		generateStaticArrows(1);
		
		var noteData:Array<SwagSection> = SONG.notes;
		
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % (SONG.mania + 1));
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > SONG.mania)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

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

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2;
					}
				}

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2;
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
    	
    	for (i in 0...SONG.mania + 1)
    	{
    		var targetAlpha:Float = 1;
    		if (player < 1)
    		{
    			if (!ClientPrefs.data.opponentStrums)
    				targetAlpha = 0;
    			else if (ClientPrefs.data.middleScroll)
    				targetAlpha = 0.35;
    		}
    
    		var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
    		babyArrow.downScroll = ClientPrefs.data.downScroll;
    		babyArrow.alpha = targetAlpha;
    
    		if (player == 1)
    			playerStrums.add(babyArrow);
    		else
    		{
    			if (ClientPrefs.data.middleScroll)
    			{
    				babyArrow.x += 310;
    				if (i > 1) // Up and Right
    					babyArrow.x += FlxG.width / 2 + 25;
    			}
    			opponentStrums.add(babyArrow);
    		}
    
    		strumLineNotes.add(babyArrow);
    		babyArrow.postAddedToGroup();
    	}
    	
    	adaptStrumline(opponentStrums);
    	adaptStrumline(playerStrums);
    
    	if (ClientPrefs.data.showKeybinds)
    	{
    		for (i in 0...playerStrums.members.length)
    		{
    			var keyShowcase = new KeybindShowcase(playerStrums.members[i].x,
    				ClientPrefs.data.downScroll ? playerStrums.members[i].y - 30 : playerStrums.members[i].y + playerStrums.members[i].height + 5,
    				ClientPrefs.keyBinds.get(keysArray[i]), FlxG.camera, playerStrums.members[i].width / 2, SONG.mania);
    			keyShowcase.onComplete = function()
    			{
    				remove(keyShowcase);
    			}
    			add(keyShowcase);
    		}
    	}
    }
    
    public function adaptStrumline(strumline:FlxTypedGroup<StrumNote>)
    {
    	var strumLineWidth:Float = 0;
    	var strumLineIsBig:Bool = false;
    
    	for (note in strumline.members)
    		strumLineWidth += note.width;
    	strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
    
    	while (strumLineIsBig)
    	{
    		strumLineWidth = 0;
    		for (note in strumline.members)
    		{
    			note.retryBound();
    			strumLineWidth += note.width;
    		}
    		trace('Strumline is too big! Shrinking and retrying.');
    		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
    	}
    }
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (gameStarted && !paused)
		{
			Conductor.songPosition += elapsed * 1000;
			
			if (generatedMusic)
			{
				if (unspawnNotes[0] != null)
                {
                    var time:Float = 2000;
                    if (songSpeed < 1)
                        time /= songSpeed;
                        
                    noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed);
                    
                    while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
                    {
                        var dunceNote:Note = unspawnNotes[0];
                        notes.insert(0, dunceNote);
                        dunceNote.spawned = true;

                        dunceNote.visible = true;
                        dunceNote.active = true;
                
                        var index:Int = unspawnNotes.indexOf(dunceNote);
                        unspawnNotes.splice(index, 1);
                    }
                }
				
				notes.forEachAlive(function(daNote:Note)
                {
                    daNote.visible = true;
                    daNote.active = true;
                    
                    var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
                    if (!daNote.mustPress)
                        strumGroup = opponentStrums;
                
                    var strum:StrumNote = strumGroup.members[daNote.noteData];
                    daNote.followStrumNote(strum, (60 / SONG.bpm) * 1000, songSpeed);
                
                    if (daNote.mustPress)
                    {
                        if (daNote.canBeHit && daNote.strumTime <= Conductor.songPosition)
                            goodNoteHit(daNote);
                    }
                    else
                    {
                        if (daNote.strumTime <= Conductor.songPosition)
                            opponentNoteHit(daNote);
                    }
                
                    if (Conductor.songPosition > daNote.strumTime + noteKillOffset)
                    {
                        if (daNote.mustPress && !daNote.wasGoodHit)
                            noteMiss(daNote);
                            
                        daNote.active = false;
                        daNote.visible = false;
                        
                        if (daNote.tooLate || daNote.wasGoodHit)
                        {
                            notes.remove(daNote, true);
                            daNote.destroy();
                        }
                    }
                });
			}
			
			if (startingSong && Conductor.songPosition >= 0)
				startSong();
			else if (!startingSong)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
	}
	
	function startSong():Void
	{
		startingSong = false;
		inst.play();
		vocals.play();
	}
	
	public function onKeyPress(event:KeyboardEvent):Void
	{
		if (!gameStarted || paused) return;
		
		var eventKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		
		if (key > -1) {
			keyPressed(key);
			room.send('notePressed', key);
		}
	}
	
	private function keyPressed(key:Int)
    {
        var spr:StrumNote = playerStrums.members[key];
        if (spr != null)
        {
            spr.playAnim('confirm');
            spr.resetAnim = 0;
        }
    
        if (generatedMusic)
        {
            var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool
            {
                return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.isSustainNote && n.noteData == key;
            });
            plrInputNotes.sort(sortHitNotes);
    
            if (plrInputNotes.length != 0)
            {
                var funnyNote:Note = plrInputNotes[0];
                goodNoteHit(funnyNote);
            }
        }
    }
	
	public static function sortHitNotes(a:Note, b:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	
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
	
	public function onKeyRelease(event:KeyboardEvent):Void
	{
		// 只有在游戏开始且未暂停时才处理按键释放
		if (!gameStarted || paused) return;
		
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		
		if (key > -1) {
			keyReleased(key);
			room.send('noteReleased', key);
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
	
	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				notes.remove(note, true);
				note.destroy();
			}
		}
	}
	
	public function opponentNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				notes.remove(note, true);
				note.destroy();
			}
		}
	}
	
	public function noteMiss(note:Note):Void
	{
		if (!note.isSustainNote)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}
	
	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		super.destroy();
	}
}