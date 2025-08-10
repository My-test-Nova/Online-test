package backend;

import flixel.FlxBasic;

class Replay extends FlxBasic
{
	// 整个组>摁压类型>行数>时间
	public var hitData:Array<Array<Array<Float>>> = [[], []];
	public var mania:Int = 3; // 添加键位数变量

	var follow:Dynamic; //跟随的state

	/////////////////////////////////////////////

	public function new(follow:Dynamic)
	{
		super();
		this.follow = follow;
		// 初始化键位数
		if (follow.SONG != null) {
			mania = follow.SONG.mania;
		}
		// 初始化数据结构
		reset();
	}

	public function push(time:Float, type:Int, state:Int)
	{
		if (!follow.replayMode && type < mania)
			hitData[state][type].push(time);
	}

	var isPaused:Bool = false;
	var pauseArray:Array<Float> = [];

	public function pauseCheck(time:Float, type:Int)
	{
		if (follow.replayMode || type >= mania)
			return;
		pauseArray[type] = time;
		isPaused = true;
	}

	public function keysCheck()
	{
		if (!follow.replayMode)
		{
			if (isPaused)
			{
				for (key in 0...mania)
					if (key < pauseArray.length && !follow.controls.pressed(follow.keysArray[key]) && pauseArray[key] != -9999)
						push(pauseArray[key], key, 1);

				// 重置暂停数组
				for (i in 0...mania)
					pauseArray[i] = -9999;
				isPaused = false;
			}
		}
		else
		{
			for (type in 0...mania)
			{
				if (type < hitData[1].length && hitData[1][type].length > 0 && hitData[1][type][0] <= Conductor.songPosition)
					holdCheck(type);
			}
		}
	}

	var allowHit:Array<Bool> = [];

	function holdCheck(type:Int)
	{
		if (type >= hitData[0].length || type >= hitData[1].length)
			return;
			
		if (hitData[0][type][0] >= Conductor.songPosition)
		{
			follow.keysCheck(type, Conductor.songPosition);
			if (allowHit[type])
			{
				follow.keyPressed(type, hitData[1][type][0]);
				allowHit[type] = false;
			}
		}
		else
		{
			follow.keysCheck(type, Conductor.songPosition);
			if (allowHit[type])
			{
				follow.keyPressed(type, hitData[1][type][0]);
			}
			follow.keyReleased(type);
			allowHit[type] = true;
			hitData[0][type].splice(0, 1);
			hitData[1][type].splice(0, 1);
		}
	}

	public function init()
	{
		// 只能这么复制 --狐月影
		hitData = [[], []];
		for (state in 0...2) {
			hitData[state] = [];
			for (type in 0...mania) {
				hitData[state][type] = [];
				for (hit in 0...hitData[state][type].length) {
					hitData[state][type].push(hitData[state][type][hit]);
				}
			}
		}
		
		// 初始化允许命中数组
		allowHit = [];
		for (i in 0...mania)
			allowHit.push(true);
	}

	public function reset()
	{
		// 根据键位数动态创建数据结构
		hitData = [[], []];
		for (state in 0...2) {
			hitData[state] = [];
			for (type in 0...mania) {
				hitData[state][type] = [];
			}
		}
		
		// 初始化暂停数组
		pauseArray = [];
		for (i in 0...mania)
			pauseArray.push(-9999);
		
		// 初始化允许命中数组
		allowHit = [];
		for (i in 0...mania)
			allowHit.push(true);
			
		isPaused = false;
	}

	public function saveDetails(input:Array<Array<Dynamic>>)
	{
		ReplayData.put(input, hitData);
	}
}

class ReplayData {
	/**
		Array<Array<Dynamic>> = [
			[
				songName, songLength, Date.now().toString()
			],
			[
				songSpeed, playbackRate, healthGain, healthLoss,
				cpuControlled, practiceMode, instakillOnMiss, ClientPrefs.data.playOpponent, 
				ClientPrefs.data.flipChart,
			],
			[
				songScore, ratingPercent, ratingFC, songHits, highestCombo, songMisses
			],
			[
				NoteTime, NoteMs
			]
		];
	**/	

	static public var hitData:Array<Array<Array<Float>>> = [];
	static public var songData:Array<Array<Dynamic>> = [];

	static public function put(song:Array<Array<Dynamic>>, hit:Array<Array<Array<Float>>>) {
		songData = song;
		hitData = hit;
	}
}