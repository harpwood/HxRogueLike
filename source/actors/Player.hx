package actors;

import data.C;
import flixel.FlxObject;

/**
 * Player actor Specific features
 */
class Player extends Actor
{
	public function new()
	{
		super();
		health = 30;
		damage = 2;
	}

	override public function bakeAsset(asset:String, _width:Int, _height:Int)
	{
		var path:String = "assets/images/";
		var png:String = ".png";

		loadGraphic(path + asset + png, true, _width, _height);
		animation.add("idle", [0, 1], 3);
		animation.add("hit", [2, 3, 4, 5], 15);
		animation.add("win", [6, 7, 8, 9], 8);
		animation.add("dying", [10, 11, 12, 13, 14], 8, false);
		animation.add("dead", [15, 16, 17, 18], 8, true);
		animation.play("idle");

		setFacingFlip(FlxObject.LEFT, false, false);
		setFacingFlip(FlxObject.RIGHT, true, false);

		width = C.TILE_SIZE;
		height = C.TILE_SIZE;
		offset.y = frameHeight - height;
	}

	public function die()
	{
		animation.play("dying");

		haxe.Timer.delay(function()
		{
			animation.play("dead");
		}, 500);
	}
}
