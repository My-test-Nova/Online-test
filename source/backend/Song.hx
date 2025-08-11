package backend;

import haxe.Json;
import openfl.utils.Assets;
import backend.Section;
import objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;

	@:optional var mania:Int;
	
}

class Song
{
	public var song:String = null;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;

	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public var mapper:String = 'N/A';
	public var musican:String = 'N/A';
	public var mania:Int = 3;	//话说这是不是跟下面的重复了

	static public var isNewVersion:Bool = false;

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}
		//对，我指的就是这个
		//针对非多k创建的谱面（即非PsychEK所创建），默认为4k
		if (songJson.mania == null)
		{
			songJson.mania = 3;
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static var chartPath:String;
	public static var loadedSongName:String;

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		// prevent any saving errors by fixing the path on Windows (being the only OS to ever use backslashes instead of forward slashes for paths)
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;

	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		var rawData:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if (FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
		rawData = Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		isNewVersion = true;
		if (Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject)
			{
				songJson = subSong;
				if (songJson.format == null)
					isNewVersion = false; // it build with old
			}
		}

		if (convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if (fmt == null)
				fmt = songJson.format = 'unknown';

			switch (convertTo)
			{
				case 'psych_v1':
					if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						onLoadJson(songJson);
					}
			}
		}
		return songJson;
	}

	public static function castVersion(songJson:SwagSong):SwagSong
	{
		for (i in 0...songJson.notes.length)
		{
			for (ii in 0...songJson.notes[i].sectionNotes.length)
			{
				var gottaHitNote:Bool = songJson.notes[i].mustHitSection;
				if (!gottaHitNote)
				{
					if (songJson.notes[i].sectionNotes[ii][1] >= 4)
					{
						songJson.notes[i].sectionNotes[ii][1] -= 4;
					}
					else if (songJson.notes[i].sectionNotes[ii][1] <= 3)
					{
						songJson.notes[i].sectionNotes[ii][1] += 4;
					}
				}
			}
		}
		isNewVersion = false;
		return songJson;
	}
	/*
		public static function convert(songJson:Dynamic) // 用于0.1到0.3
		{
			if(songJson.gfVersion == null)
			{
				songJson.gfVersion = songJson.player3;
				if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
			}

			if(songJson.events == null)
			{
				songJson.events = [];
				for (secNum in 0...songJson.notes.length)
				{
					var sec:SwagSection = songJson.notes[secNum];

					var i:Int = 0;
					var notes:Array<Dynamic> = sec.sectionNotes;
					var len:Int = notes.length;
					while(i < len)
					{
						var note:Array<Dynamic> = notes[i];
						if(note[1] < 0)
						{
							songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
							notes.remove(note);
							len = notes.length;
						}
						else i++;
					}
				}
			}

			var sectionsData:Array<SwagSection> = songJson.notes;
			if(sectionsData == null) return;

			for (section in sectionsData)
			{
				var beats:Null<Float> = cast section.sectionBeats;
				if (beats == null || Math.isNaN(beats))
				{
					section.sectionBeats = 4;
					if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
				}

				for (note in section.sectionNotes)
				{
					var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
					note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

					if(!Std.isOfType(note[3], String))
						note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
				}
			}
	}*/
}
