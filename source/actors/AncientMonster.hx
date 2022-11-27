package actors;

import data.C;
import flixel.util.FlxDirectionFlags;

/**
 * AncientMonster actor Specific features
 */
class AncientMonster extends Actor
{
	public function new()
	{
		super();
		aggroRange = 0; // ulimited
		damage = 3;
		health = 6;
	}

	override public function bakeAsset(asset:String, _width:Int, _height:Int)
	{
		var path:String = "assets/images/";
		var png:String = ".png";

		loadGraphic(path + asset + png, true, _width, _height);
		animation.add("idle", [0, 2], 3);
		animation.add("hit", [0, 1, 2, 3, 4], 15);
		animation.add("win", [5, 6, 7, 8, 9], 8);
		animation.play("idle");

		setFacingFlip(FlxDirectionFlags.LEFT, false, false);
		setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

		width = C.TILE_SIZE;
		height = C.TILE_SIZE;
		offset.y = frameHeight - height;
	}
}
