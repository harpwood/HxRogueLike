package data;

/**
 * Tiles specific constants and checks
 */
class T
{
	public static final WALL:Int = -1;
	public static final FLOOR:Int = 0;

	public static final START:Int = 10;
	public static final PLAYER:Int = 10;
	public static final EXIT:Int = 11;

	public static final SLIME:Int = 20;
	public static final WORM:Int = 21;
	public static final BAT:Int = 22;
	public static final ORC:Int = 23;
	public static final SKELETON:Int = 24;
	public static final ANCIENT_MONSTER:Int = 25;

	/**
	 * Checks if the [tile] is impasable
	 * @param tile 
	 * @return Bool true if impasable
	 */
	public static function isImpasable(tile:Int):Bool
	{
		return tile == WALL;
	}

	/**
	 * Checks if the [tile] has the player
	 * @param tile 
	 * @return Bool true if has the player
	 */
	public static function isPlayer(tile:Int):Bool
	{
		return tile == PLAYER;
	}

	/**
	 * Checks if the [tile] is the dungeon's exit
	 * @param tile 
	 * @return Bool true if is the dungeon's exit
	 */
	public static function isExit(tile:Int):Bool
	{
		return tile == EXIT;
	}

	/**
	 * Checks if the [tile] has an enemy
	 * @param tile 
	 * @return Bool true if has an enemy
	 */
	public static function isMob(tile:Int):Bool
	{
		return tile == SLIME || tile == ORC || tile == ANCIENT_MONSTER || tile == WORM || tile == SKELETON || tile == ANCIENT_MONSTER || tile == BAT;
	}
}
