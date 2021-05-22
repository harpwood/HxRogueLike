package helpers;

class Random
{
	/**
	 * Returns a random element from the [arr] array
	 * @param arr 
	 */
	public static function choose<T>(arr:Array<T>)
	{
		return arr[Math.floor(Math.random() * (arr.length - 1))];
	}

	/**
	 * returns a random integer from 0 to [v]
	 * @param v 
	 */
	public static function int(v:Int)
	{
		return Math.floor(Math.random() * v);
	}
}
