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

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	public static var SONG:SwagSong = null;

	public var generatedMusic:Bool = false;

	private var curSong:String = "";

	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	// 键盘控制相关
	public var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	// 网络连接相关
	public var room:Room<Dynamic>;
	public var isConnect:Bool = false;
	public var ConnectNum:Int = 0;

	public function new()
	{
		super();
		
		SONG = Song.loadFromJson("dad-battle-hard","dad-battle");
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
                generateSong(SONG.song);
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
		connectRoom();
		
		// 添加手机控件
		addMobileControls(false);
		
		// 添加键盘事件监听
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		// Gameplay settings
		songSpeed = PlayState.SONG.speed;
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

	override public function destroy()
	{
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

	// 按键按下处理
	public function keyPressed(key:Int):Void
	{
		if (key < 0 || key > 3) return;
		
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	// 按键释放处理
	public function keyReleased(key:Int):Void
	{
		if (key < 0 || key > 3) return;
		
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	private function generateSong(dataPath:String):Void
	{
		songSpeed = PlayState.SONG.speed;
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

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (unspawnNotes[0] != null)
		{
			var time:Float = 2000;
			if (songSpeed < 1)
				time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if (!daNote.mustPress)
						strumGroup = opponentStrums;

					var strum:StrumNote = strumGroup.members[daNote.noteData];
					daNote.followStrumNote(strum, (60 / SONG.bpm) * 1000, songSpeed);

					if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
						daNote.kill();
				});
			}
		}
	}
}