package mobile.flixel;

import mobile.flixel.input.FlxMobileInputManager;
import openfl.display.BitmapData;
import mobile.flixel.FlxButton;
import openfl.display.Shape;
import mobile.flixel.input.FlxMobileInputID;
import states.PlayState;
import backend.extraKeys.ExtraKeysHandler;
import flixel.util.FlxColor;

/**
 * A zone with dynamic hint's based on mania.
 * 
 * @author: Mihai Alexandru
 * @modification's author: Karim Akra & Lily (mcagabe19)
 */
class FlxHitbox extends FlxMobileInputManager
{
	public var buttonNotes:Array<FlxButton> = [];
	public var buttonExtra1:FlxButton = new FlxButton(0, 0);
	public var buttonExtra2:FlxButton = new FlxButton(0, 0);
	public var buttonExtra3:FlxButton = new FlxButton(0, 0);
	public var buttonExtra4:FlxButton = new FlxButton(0, 0);

	var storedButtonsIDs:Map<String, Array<FlxMobileInputID>> = new Map<String, Array<FlxMobileInputID>>();

	/**
	 * Create the zone.
	 */
	public function new()
	{
		super();

		// Get mania value (default to 3 for 4K)
		var mania:Int = 3;
		if (PlayState.SONG != null && PlayState.SONG.mania != null)
		{
			mania = PlayState.SONG.mania;
		}
		var keys:Int = mania + 1; // Number of keys

		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
			{
				storedButtonsIDs.set(button, Reflect.getProperty(Reflect.field(this, button), 'IDs'));
			}
		}

		if (ClientPrefs.data.extraKey == 0)
		{
			// Full screen keys
			for (i in 0...keys)
			{
				var button = createHint(FlxG.width * i / keys, 0, Std.int(FlxG.width / keys), Std.int(FlxG.height), getColor(i, mania));
				buttonNotes.push(button);
				add(button);
			}
		}
		else
		{
			if (ClientPrefs.data.hitboxLocation == 'Bottom')
			{

				for (i in 0...keys)
				{
					var button = createHint(FlxG.width * i / keys, 0, Std.int(FlxG.width / keys), Std.int(FlxG.height * 0.8), getColor(i, mania));
					buttonNotes.push(button);
					add(button);
				}

				switch (ClientPrefs.data.extraKey)
				{
					case 1:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, FlxG.width, Std.int(FlxG.height / 5), 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFFFF00));
					case 3:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 3 - 1, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3 + 2), Std.int(FlxG.height / 5),
							0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 3 * 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFFFF00));
					case 4:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 4, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 4 * 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra4 = createHint(FlxG.width / 4 * 3, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
				}
			}
			else if (ClientPrefs.data.hitboxLocation == 'Top')
			{
				// Top 20% for extra keys
				switch (ClientPrefs.data.extraKey)
				{
					case 1:
						add(buttonExtra1 = createHint(0, 0, FlxG.width, Std.int(FlxG.height / 5), 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFF0000));
					case 3:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 3, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra3 = createHint(FlxG.width / 3 * 2, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0x0000FF));
					case 4:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra2 = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra3 = createHint(FlxG.width / 4 * 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x0000FF));
						add(buttonExtra4 = createHint(FlxG.width / 4 * 3, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x00FF00));
				}

				// Bottom 80% for main keys
				for (i in 0...keys)
				{
					var button = createHint(FlxG.width * i / keys, FlxG.height * 0.2, Std.int(FlxG.width / keys), Std.int(FlxG.height * 0.8),
						getColor(i, mania));
					buttonNotes.push(button);
					add(button);
				}
			}
			else
			{ // Middle layout (keep as 4K for now)
				// Middle layout remains as 4K for compatibility
				add(createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFC24B99));
				add(createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF00FFFF));
				add(createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF12FA05));
				add(createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFF9393F));

				// Extra keys for middle layout
				switch (ClientPrefs.data.extraKey)
				{
					case 1:
						add(buttonExtra1 = createHint(Std.int(FlxG.width / 5) * 2, 0, Std.int(FlxG.width / 5), FlxG.height, 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(Std.int(FlxG.width / 5) * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height / 2), 0xFFFF00));
						add(buttonExtra2 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 2), Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 2), 0xFFFF00));
					case 3:
						add(buttonExtra1 = createHint(Std.int(FlxG.width / 5) * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height / 3), 0xFFFF00));
						add(buttonExtra2 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 3), Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 3), 0xFFFF00));
						add(buttonExtra3 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 3) * 2, Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 3), 0xFFFF00));
					case 4:
						add(buttonExtra1 = createHint(Std.int(FlxG.width / 5) * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height / 4), 0xFFFF00));
						add(buttonExtra2 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 4), Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 4), 0xFFFF00));
						add(buttonExtra3 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 4) * 2, Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 4), 0xFFFF00));
						add(buttonExtra4 = createHint(Std.int(FlxG.width / 5) * 2, Std.int(FlxG.height / 4) * 3, Std.int(FlxG.width / 5),
							Std.int(FlxG.height / 4), 0xFFFF00));
				}

				add(createHint(Std.int(FlxG.width / 5) * 3, 0, Std.int(FlxG.width / 5), FlxG.height, 0xFF12FA05));
				add(createHint(Std.int(FlxG.width / 5) * 4, 0, Std.int(FlxG.width / 5), FlxG.height, 0xFFF9393F));
			}
		}

		// Assign input IDs to main keys
		for (i in 0...buttonNotes.length)
		{
			buttonNotes[i].IDs = [getInputID(mania, i)];
		}

		// Assign input IDs to extra buttons
		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
			{
				Reflect.setProperty(Reflect.getProperty(this, button), 'IDs', storedButtonsIDs.get(button));
			}
		}

		scrollFactor.set();
		updateTrackedButtons();
	}

	/**
	 * Get input ID based on mania and index
	 */
	private function getInputID(mania:Int, index:Int):FlxMobileInputID
	{
		return switch (mania)
		{
			case 0: FlxMobileInputID.EK_0_0; // 1K
			case 1: index == 0 ? FlxMobileInputID.EK_1_0 : FlxMobileInputID.EK_1_1; // 2K
			case 2: switch (index) { // 3K
				case 0: FlxMobileInputID.EK_2_0;
				case 1: FlxMobileInputID.EK_2_1;
				case _: FlxMobileInputID.EK_2_2;
			}
			case 3: switch (index) { // 4K (default)
				case 0: FlxMobileInputID.noteLEFT;
				case 1: FlxMobileInputID.noteDOWN; 
				case 2: FlxMobileInputID.noteUP;
				case _: FlxMobileInputID.noteRIGHT;
			}
			case 4: switch (index) { // 5K
				case 0: FlxMobileInputID.EK_4_0;
				case 1: FlxMobileInputID.EK_4_1;
				case 2: FlxMobileInputID.EK_4_2;
				case 3: FlxMobileInputID.EK_4_3;
				case _: FlxMobileInputID.EK_4_4;
			}
			case 5: switch (index) { // 6K
				case 0: FlxMobileInputID.EK_5_0;
				case 1: FlxMobileInputID.EK_5_1;
				case 2: FlxMobileInputID.EK_5_2;
				case 3: FlxMobileInputID.EK_5_3;
				case 4: FlxMobileInputID.EK_5_4;
				case _: FlxMobileInputID.EK_5_5;
			}
			case 6: switch (index) { // 7K
				case 0: FlxMobileInputID.EK_6_0;
				case 1: FlxMobileInputID.EK_6_1;
				case 2: FlxMobileInputID.EK_6_2;
				case 3: FlxMobileInputID.EK_6_3;
				case 4: FlxMobileInputID.EK_6_4;
				case 5: FlxMobileInputID.EK_6_5;
				case _: FlxMobileInputID.EK_6_6;
			}
			case 7: switch (index) { // 8K
				case 0: FlxMobileInputID.EK_7_0;
				case 1: FlxMobileInputID.EK_7_1;
				case 2: FlxMobileInputID.EK_7_2;
				case 3: FlxMobileInputID.EK_7_3;
				case 4: FlxMobileInputID.EK_7_4;
				case 5: FlxMobileInputID.EK_7_5;
				case 6: FlxMobileInputID.EK_7_6;
				case _: FlxMobileInputID.EK_7_7;
			}
			case 8: switch (index) { // 9K
				case 0: FlxMobileInputID.EK_8_0;
				case 1: FlxMobileInputID.EK_8_1;
				case 2: FlxMobileInputID.EK_8_2;
				case 3: FlxMobileInputID.EK_8_3;
				case 4: FlxMobileInputID.EK_8_4;
				case 5: FlxMobileInputID.EK_8_5;
				case 6: FlxMobileInputID.EK_8_6;
				case 7: FlxMobileInputID.EK_8_7;
				case _: FlxMobileInputID.EK_8_8;
			}
			case 9: switch (index) { // 10K
				case 0: FlxMobileInputID.EK_9_0;
				case 1: FlxMobileInputID.EK_9_1;
				case 2: FlxMobileInputID.EK_9_2;
				case 3: FlxMobileInputID.EK_9_3;
				case 4: FlxMobileInputID.EK_9_4;
				case 5: FlxMobileInputID.EK_9_5;
				case 6: FlxMobileInputID.EK_9_6;
				case 7: FlxMobileInputID.EK_9_7;
				case 8: FlxMobileInputID.EK_9_8;
				case _: FlxMobileInputID.EK_9_9;
			}
			default: switch (index) { // Default to 4K
				case 0: FlxMobileInputID.noteLEFT;
				case 1: FlxMobileInputID.noteDOWN;
				case 2: FlxMobileInputID.noteUP;
				case _: FlxMobileInputID.noteRIGHT;
			}
		}
	}

	/**
	 * Get color for key based on index and mania
	 */
	private function getColor(index:Int, mania:Int):Int
	{
		// 动态颜色设置优先
		if (ClientPrefs.data.dynamicColors)
		{
			var keyMode = ExtraKeysHandler.instance.data.keys[mania];
			if (keyMode != null)
			{
				var noteIndex = keyMode.notes[index];
				if (ClientPrefs.data.arrowRGB != null && noteIndex < ClientPrefs.data.arrowRGB.length)
				{
					return ClientPrefs.data.arrowRGB[noteIndex][0];
				}
			}
		}
		
		// 使用extrakeys.json中的默认颜色
		var keyMode = ExtraKeysHandler.instance.data.keys[mania];
		if (keyMode != null)
		{
			var noteIndex = keyMode.notes[index];
			if (noteIndex < ExtraKeysHandler.instance.data.colors.length)
			{
				var colorObj = ExtraKeysHandler.instance.data.colors[noteIndex];
				return FlxColor.fromString('#' + colorObj.inner);
			}
		}

		return switch (mania)
		{
			case 0: 0xFFC24B99; // 1K - Purple
			case 1: index == 0 ? 0xFFC24B99 : 0xFFF9393F; // 2K - Purple/Red
			case 2: [0xFFC24B99, 0xFF12FA05, 0xFFF9393F][index]; // 3K - Purple/Green/Red
			default: [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F][index % 4]; // 4K+ colors
		}
	}

	/**
	 * Clean up memory.
	 */
	override function destroy()
	{
		super.destroy();

		for (button in buttonNotes)
		{
			button = FlxDestroyUtil.destroy(button);
		}
		buttonExtra1 = FlxDestroyUtil.destroy(buttonExtra1);
		buttonExtra2 = FlxDestroyUtil.destroy(buttonExtra2);
		buttonExtra3 = FlxDestroyUtil.destroy(buttonExtra3);
		buttonExtra4 = FlxDestroyUtil.destroy(buttonExtra4);
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hintTween:FlxTween = null;
		var hint = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height));
		hint.color = Color;
		hint.solid = false;
		hint.immovable = true;
		hint.multiTouch = true;
		hint.moves = false;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.antialiasing = ClientPrefs.data.antialiasing;
		if (ClientPrefs.data.playControlsAlpha >= 0)
		{
			hint.onDown.callback = function()
			{
				if (hintTween != null)
					hintTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: ClientPrefs.data.playControlsAlpha}, ClientPrefs.data.playControlsAlpha / 100, {
					ease: FlxEase.circInOut,
					onComplete: function(twn:FlxTween)
					{
						hintTween = null;
					}
				});
			}
			hint.onUp.callback = function()
			{
				if (hintTween != null)
					hintTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: 0.00001}, ClientPrefs.data.playControlsAlpha / 10, {
					ease: FlxEase.circInOut,
					onComplete: function(twn:FlxTween)
					{
						hintTween = null;
					}
				});
			}
			hint.onOut.callback = function()
			{
				if (hintTween != null)
					hintTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: 0.00001}, ClientPrefs.data.playControlsAlpha / 10, {
					ease: FlxEase.circInOut,
					onComplete: function(twn:FlxTween)
					{
						hintTween = null;
					}
				});
			}
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	function createHintGraphic(Width:Int, Height:Int):BitmapData
	{
		var shape:Shape = new Shape();

		var guh = ClientPrefs.data.playControlsAlpha;
		if (guh >= 0.9)
			guh = ClientPrefs.data.playControlsAlpha - 0.07;

		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.lineStyle(3, 0xFFFFFF, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.lineStyle(0, 0, 0);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		shape.graphics.beginGradientFill(RADIAL, [0xFFFFFF, FlxColor.TRANSPARENT], [guh, 0], [0, 255], null, null, null, 0.5);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}
}