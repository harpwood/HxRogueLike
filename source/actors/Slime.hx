package actors;

import data.C;
import flixel.util.FlxDirectionFlags;

/**
 * Slime actor Specific features
 */
class Slime extends Actor
{
	public function new()
	{
		super();
		aggroRange = 2;
		damage = 1;
		health = 2;
	}

	override public function bakeAsset(asset:String, _width:Int, _height:Int)
	{
		var path:String = "assets/images/";
		var png:String = ".png";

		loadGraphic(path + asset + png, true, _width, _height);
		animation.add("idle", [0, 1, 2, 3], 3);
		animation.add("hit", [4, 5, 6, 7], 15);
		animation.add("win", [0, 1, 2, 3], 8);
		animation.play("idle");

		setFacingFlip(FlxDirectionFlags.LEFT, false, false);
		setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

		width = C.TILE_SIZE;
		height = C.TILE_SIZE;
		offset.y = frameHeight - height;
	}
}
