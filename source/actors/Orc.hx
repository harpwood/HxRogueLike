package actors;

/**
 * Orc actor Specific features
 */
class Orc extends Actor
{
	public function new()
	{
		super();
		aggroRange = 10;
		damage = 2;
		health = 4;
	}
}
