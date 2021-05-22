package actors;

/**
 * Bat actor Specific features
 */
class Bat extends Actor
{
	public function new()
	{
		super();
		aggroRange = 12;
		damage = 1;
		health = 2;
	}
}
