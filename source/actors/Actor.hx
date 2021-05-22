package actors;

import data.C;
import data.M;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Contains logic for all in game characters, both player and enemies
 */
class Actor extends FlxSprite
{
	/**
	 * The row  of tile of actor's position
	 */
	public var nested(default, default):Int = 0;

	/**
	 * The col of tile of actor's position
	 */
	public var nest(default, default):Int = 0;

	/**
	 * truw if the actor is moving (or attacking)
	 */
	public var isMoving(default, default):Bool = false;

	/**
	 * counts the failed attemps of actions (for enemies only)
	 */
	public var actionsCount(default, default):Int = 0;

	/**
	 * the agro range in tiles
	 * 0 for unlimited range
	 */
	public var aggroRange(default, default):Int = 2;

	/**
	 * The damage the actor will cause if attacks
	 */
	public var damage(default, default):Int = 1;

	public function new()
	{
		super();

		// the damage can take the actor before dies
		health = 4;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	/**
	 * Bakes the [asset] into animations.
	 * @param asset do not include path nor .png file extension
	 * @param _width the width of each frame
	 * @param _height the height of each frame
	 */
	public function bakeAsset(asset:String, _width:Int, _height:Int)
	{
		// the vars that will wrarp the asset into a  file path
		var path:String = "assets/images/";
		var png:String = ".png";

		// load the asset and bake animations
		loadGraphic(path + asset + png, true, _width, _height);
		animation.add("idle", [0, 1], 3);
		animation.add("hit", [2, 3, 4, 5], 15);
		animation.add("win", [6, 7, 8, 9], 8);
		animation.play("idle");

		// facing
		setFacingFlip(FlxObject.LEFT, false, false);
		setFacingFlip(FlxObject.RIGHT, true, false);

		// reposition to be inside tile without messing with x and y
		width = C.TILE_SIZE;
		height = C.TILE_SIZE;
		offset.y = frameHeight - height;
	}

	/**
	 * Triggers the win animation
	 */
	public function win()
	{
		animation.play("win");
	}

	/**
	 * Triggers hit animation and the actor gets hit by [dmg] amount of damage
	 * @param dmg 
	 */
	public function hit(dmg:Int = 0)
	{
		// trigger animation
		animation.play("hit");

		// get dammage after delay
		haxe.Timer.delay(function()
		{
			health -= dmg;
			animation.play("idle");
			// if the actor dies dispatch a massege that he died
			if (health <= 0)
			{
				PlayState.signal.dispatch(M.DIED, this, nested, nest);
			}
		}, 250);
	}

	/**
	 * Moves the actor at the tile at [destNested](row) and [destNest](col)
	 * @param destNested 
	 * @param destNest 
	 */
	public function moveTo(destNested:Int, destNest:Int):Void
	{
		// determing which way the actor is facing
		faceTo(nested - destNested);

		// tween to direction
		var tweenType = FlxTweenType.ONESHOT;
		var options:TweenOptions = {onComplete: onMoveComplete.bind(_, destNested, destNest), ease: FlxEase.linear, type: tweenType}
		FlxTween.tween(this, {x: x + C.TILE_SIZE * sign(destNested - nested), y: y + C.TILE_SIZE * sign(destNest - nest)}, .1, options);
		isMoving = true;
	}

	/**
	 * Dispatch end of turn event after move [tween] ends
	 * @param tween 
	 * @param destNested 
	 * @param destNest 
	 */
	function onMoveComplete(tween:FlxTween, destNested:Int, destNest:Int)
	{
		haxe.Timer.delay(function()
		{
			// update the newly occupied tile coordinations
			nested = destNested;
			nest = destNest;

			isMoving = false;
			// dispatch event
			PlayState.signal.dispatch(M.END_TURN, this, 0, 0);
		}, 50);
	}

	/**
	 * The actor attacks at the tile at [destNested](row) and [destNest](col)
	 * @param destNested 
	 * @param destNest 
	 */
	public function attackTo(destNested:Int, destNest:Int)
	{
		// determing which way the actor is facing
		faceTo(nested - destNested);

		// tween the attack motion
		var tweenType = FlxTweenType.ONESHOT;
		var options:TweenOptions = {onComplete: onAttack.bind(_, destNested, destNest), ease: FlxEase.linear, type: tweenType}
		FlxTween.tween(this, {x: x + C.TILE_SIZE * sign(destNested - nested), y: y + C.TILE_SIZE * sign(destNest - nest)}, .1, options);

		isMoving = true;
	}

	/**
	 * Dispatches the attack event tweens back the actor to original position
	 * @param tween 
	 * @param destNested 
	 * @param destNest 
	 */
	function onAttack(tween:FlxTween, destNested:Int, destNest:Int)
	{
		// dispatch attack event
		PlayState.signal.dispatch(M.MELEE_ATTACK, this, destNested, destNest);
		// tween back to original position after dealay
		haxe.Timer.delay(function()
		{
			var tweenType = FlxTweenType.ONESHOT;
			var options:TweenOptions = {onComplete: onCompleteAttack, ease: FlxEase.linear, type: tweenType}
			FlxTween.tween(this, {x: x + C.TILE_SIZE * sign(nested - destNested), y: y + C.TILE_SIZE * sign(nest - destNest)}, .1, options);
		}, 50);
	}

	/**
	 * Dispatch end of turn event after attack finishes
	 * @param tween 
	 */
	function onCompleteAttack(tween:FlxTween)
	{
		PlayState.signal.dispatch(M.END_TURN, this, 0, 0);
		isMoving = false;
	}

	/**
	 * Despatch skip turn event
	 */
	public function skipTurn()
	{
		PlayState.signal.dispatch(M.END_TURN, this, 0, 0);
	}

	/**
	 * Despatch unable to act event
	 */
	public function unableToAct()
	{
		PlayState.signal.dispatch(M.UNABLE_TO_ACT, this, 0, 0);
	}

	/**
	 * Returns the sign (+ or -) of the [value]
	 * @param value 
	 * @return Int
	 */
	function sign(value:Int):Int
	{
		if (value > 0)
			return 1;
		else if (value < 0)
			return -1;
		else
			return 0;
	}

	/**
	 * Determing the horizontal facing depending on sign (+ or -) of [dir]
	 * @param dir 
	 */
	function faceTo(dir:Int)
	{
		// var dir = nested - destNested;
		if (dir < 0)
		{
			facing = FlxObject.LEFT;
		}
		else if (dir > 0)
		{
			facing = FlxObject.RIGHT;
		}
	}
}
