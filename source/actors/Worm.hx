package actors;

/**
 * Worm actor Specific features
 */
class Worm extends Actor
{
	public function new()
	{
		super();
		aggroRange = 4;
		damage = 1;
		health = 2;
	}
}
