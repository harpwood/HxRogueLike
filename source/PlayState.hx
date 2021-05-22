package;

import actors.Actor;
import actors.AncientMonster;
import actors.Bat;
import actors.Orc;
import actors.Player;
import actors.Slime;
import actors.Worm;
import data.C;
import data.Level;
import data.M;
import data.T;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;
import helpers.Random;

using flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{
	/**
	 * The listener for actors communication with game logic
	 */
	public static var signal:FlxTypedSignal<String->FlxObject->Int->Int->Void>;

	/**
	 * shows gameplay and debug info
	 */
	private var statusText:FlxText;

	/**
	 * holds the the position of actors and elements on battefield 
	 */
	private var currentLevel:Array<Array<Int>>;

	/**
	 * The length of currentLevel[][NESTED] 
	 * (I find NEST and NESTED instead or ROWS and COLS less confusing)
	 */
	private var NESTED:Int;

	/**
	 * The length of currentLevel[NESTED][]
	 * (I find NEST and NESTED instead or ROWS and COLS less confusing)
	 */
	private var NEST:Int;

	/**
	 * Draws the battlefield grid lines as a debug helper
	 */
	private var debugGrid:FlxSprite;

	/**
	 * Allows debuging after everything is initialized
	 */
	private var initDone:Bool = false;

	/**
	 * flag for showing debug data in statusText
	 */
	private var showDebug:Bool = false;

	/**
	 * The actor that will controlled by player
	 */
	private var player:Player;

	/**
	 * flag if is player's turn or not
	 */
	private var isPlayerTurn:Bool = true;

	/**
	 * groups all enemies for easier manipulation
	 */
	private var enemies:FlxSpriteGroup = new FlxSpriteGroup();

	/**
	 * The queue of enemies to act in their turn
	 */
	private var queue:Array<Actor> = new Array();

	/**
	 * flags win condition
	 */
	private var hasPlayerWon:Bool = false;

	/**
	 * flags loose condition
	 */
	private var hasPlayerDied:Bool = false;

	/**
	 * turns counter
	 */
	private var turn:Int = 0;

	override public function create()
	{
		super.create();

		init();
		// after initialization is safe to show debug stuff
		initDone = true;
	}

	/**
	 * Game loop
	 * @param elapsed 
	 */
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// press R to restart
		if (FlxG.keys.justPressed.R)
			FlxG.resetGame();

		// press D to show/hide debug info
		if (FlxG.keys.justPressed.D)
		{
			showDebug = !showDebug;

			if (showDebug)
				debugGrid.alpha = .25;
			else
				debugGrid.alpha = 0;
		}

		if (initDone)
		{
			// show debug or gameplay info
			if (showDebug)
			{
				var mouse:FlxPoint = FlxG.mouse.getWorldPosition();
				var tileRow:Float = Math.min(Math.floor(mouse.x / C.TILE_SIZE), NESTED - 1);
				var tileCol:Float = Math.min(Math.floor(mouse.y / C.TILE_SIZE), NEST - 1);
				statusText.text = "Turn: " + turn;
				statusText.text += " Ppos: " + player.nested + ", " + player.nest;
				statusText.text += " - Mpos: " + tileRow + ", " + tileCol;
				statusText.text += " - Tile index: " + currentLevel[Std.int(tileCol)][Std.int(tileRow)];
				if (T.isMob(currentLevel[Std.int(tileCol)][Std.int(tileRow)]))
				{
					var id:Int = -1;
					for (i in 0...enemies.length)
					{
						var enemy = cast(enemies.members[i], Actor);
						if (enemy.nest == Std.int(tileCol) && enemy.nested == Std.int(tileRow))
						{
							id = enemies.members[i].ID;
							break;
						}
					}
					statusText.text += " Mob ID: " + id;
				}
			}
			else
				statusText.text = isPlayerTurn ? "Player's turn" : "Enemy's turn";
		}

		// check if valid for player to play
		if (isPlayerTurn && !player.isMoving && !hasPlayerDied)
		{
			// press SPACE to skip turn
			if (FlxG.keys.justPressed.SPACE)
				player.skipTurn();

			// move player input
			var left:Int = (FlxG.keys.pressed.LEFT || FlxG.keys.justPressed.LEFT) ? -1 : 0;
			var right:Int = (FlxG.keys.pressed.RIGHT || FlxG.keys.justPressed.RIGHT) ? 1 : 0;
			var up:Int = (FlxG.keys.pressed.UP || FlxG.keys.justPressed.UP) ? -1 : 0;
			var down:Int = (FlxG.keys.pressed.DOWN || FlxG.keys.justPressed.DOWN) ? 1 : 0;

			// if left or right is pressed
			if (left + right != 0)
			{
				// check if the destination is the exit to win
				if (T.isExit(currentLevel[player.nest][player.nested + left + right]))
					hasPlayerWon = true;

				// attempt to move the player to destination
				actTo(player, player.nested + left + right, player.nest);
			}
			// if up or down is pressed
			else if (up + down != 0)
			{
				// check if the destination is the exit to win
				if (T.isExit(currentLevel[player.nest + up + down][player.nested]))
					hasPlayerWon = true;

				// attempt to move the player to destination
				actTo(player, player.nested, player.nest + up + down);
			}
		}

		// check win/loose conditions
		if (hasPlayerWon)
			statusText.text = C.PLAYER_WON;
		if (hasPlayerDied)
			statusText.text = C.PLAYER_DIED;
	}

	/**
	 * Attemps the [actor] to perform an action on destination tile row:[destNest] col:[destNested]. 
	 * The resulted action depents on destination tile contents
	 * @param actor 
	 * @param destNested 
	 * @param destNest 
	 */
	function actTo(actor:Actor, destNested:Int, destNest:Int)
	{
		// make sure first that the actor is still alive. Even if dead, might still be in enemies group ar turn queue...
		// ..until the end of the turn. So if dead, skip its turn.
		if (!actor.alive)
			actor.skipTurn();
		// if the destination is the exit and the actor is a mob then report that this move is invalid
		else if (T.isExit(currentLevel[destNest][destNested]) && (T.isMob(currentLevel[actor.nest][actor.nested])))
		{
			actor.unableToAct();
		}
		// if the destination is not reachable
		else if (T.isImpasable(currentLevel[destNest][destNested]))
		{
			// if the actor is a mob then report that this move is invalid
			if (T.isMob(currentLevel[actor.nest][actor.nested]))
				actor.unableToAct();

			// if the actor is the player, nothing will happen, thus be able the player to act again
		}
		// if the destination is occupied by a hostile, attack
		else if ((T.isPlayer(currentLevel[actor.nest][actor.nested]) && T.isMob(currentLevel[destNest][destNested]))
			|| (T.isMob(currentLevel[actor.nest][actor.nested]) && T.isPlayer(currentLevel[destNest][destNested])))
		{
			actor.attackTo(destNested, destNest);
		}
		// if the destination is occupied by mob and the actor is mob then report that this move is invalid
		else if (T.isMob(currentLevel[actor.nest][actor.nested]) && T.isMob(currentLevel[destNest][destNested]))
		{
			actor.unableToAct();
		}
		// if nothing of the above, move to destination
		else
		{
			currentLevel[destNest][destNested] = currentLevel[actor.nest][actor.nested];
			currentLevel[actor.nest][actor.nested] = T.FLOOR;
			actor.moveTo(destNested, destNest);
		}
	}

	/**
	 * Intializes game
	 */
	function init()
	{
		// load the level data
		currentLevel = new Level().get();
		// width of level
		NEST = currentLevel.length;
		NESTED = currentLevel[0].length;

		// position bg tiles, enemy, player; draw the debug grid
		positionElements();
		drawDebugGrid();

		// place status text
		statusText = new FlxText(0, FlxG.height - 30, FlxG.width, "Hello from HaxeFlixel!", 12);
		statusText.alignment = FlxTextAlign.CENTER;
		add(statusText);

		// init signal listener
		signal = new FlxTypedSignal<String->FlxObject->Int->Int->Void>();
		signal.add(processSignal);
	}

	/**
	 * Listens and processes the signals from actors
	 * @param message The signaled message
	 * @param from the actor that signaled the [message] (aka the messenger)
	 * @param destNested the col of the involved tile (I pass 0 if not needed)
	 * @param destNest the row of the involved tile (I pass 0 if not needed)
	 */
	function processSignal(message:String, from:FlxObject, destNested:Int, destNest:Int)
	{
		// cast the messeger into the actor var
		var actor = cast(from, Actor);

		// process the message
		switch message
		{
			// if the messenger died
			case M.DIED:
				{
					// if the died messenger is the player
					if (actor == player)
					{
						// flag that player died
						hasPlayerDied = true;
						// trigger die animation
						player.die();

						// trigger win animation on enemies
						if (enemies.length > 0)
						{
							for (i in 0...enemies.length)
							{
								var enemy:Actor = cast(enemies.members[i], Actor);
								enemy.win();
							}
						}
					}
					// if the messenger is an enemy
					else
					{
						// splice him from enemies group
						enemies.remove(actor, true);
						// update the tile that he was standing that is empty
						currentLevel[destNest][destNested] = T.FLOOR;
						// kill hum
						actor.kill();
					}
				}
			// if the messenger completed his turn
			case M.END_TURN:
				{
					// if the messenger is the player
					if (actor == player)
					{
						// flag that his turn is over
						isPlayerTurn = false;

						// count the turn
						turn++;

						// check if player won
						if (hasPlayerWon)
						{
							// trigger win animation on player
							player.win();
							// do not process more!
							return;
						}

						// player's turn ended, put enemies in queue
						if (enemies.length > 0)
						{
							for (i in 0...enemies.length)
							{
								var enemy:Actor = cast(enemies.members[i], Actor);
								// will count failed actions (eg trying to move on impassable tile)
								enemy.actionsCount = 0;
								// put him in queue only if he is alive
								if (enemy.alive)
									queue.push(enemy);
							}

							// init enemies turn logic
							enemyTurn();
						}
						// if no enemies is player's turn
						else
							isPlayerTurn = true;
					}
					// if the messenger is an enemy
					else
					{
						// if the queue is not empty then the enemies' turn is not finished
						if (queue.length > 0)
						{
							// procced with enemies turn logic
							enemyTurn();
						}
						// if the queue is empty then the enemies' turn has ended
						else
							isPlayerTurn = true;
					}
				}
			// if the messenger attacks
			case M.MELEE_ATTACK:
				{
					// if the messenger is the player
					if (isPlayerTurn)
					{
						// check if the attack is targeting an enemy
						for (i in 0...enemies.length)
						{
							if (cast(enemies.members[i], Actor).nest == destNest && cast(enemies.members[i], Actor).nested == destNested)
							{
								// hit the target with players damage
								cast(enemies.members[i], Actor).hit(player.damage);
							}
						}
					}
					// if the messenger is an enemy
					else
					{
						// check if the attack is targeting the player
						if (player.nest == destNest && player.nested == destNested)
							player.hit(actor.damage); // hit the player with attacker's damage
					}
				}
			// if the messenger is unable to perform the assigned action
			case M.UNABLE_TO_ACT:
				{
					trace(M.UNABLE_TO_ACT);
					// this will only be dispached by enemies, but just in case filter it
					if (!isPlayerTurn)
					{
						// count the failed action
						actor.actionsCount++;
						// if unable to act after certain tries, skip turn
						if (actor.actionsCount > 10)
							actor.skipTurn();
						else
						{
							// insert the enemy back on top of the queue
							queue.insert(0, actor);
							enemyTurn();
						}
					}
				}
		}

		// update the status text
		statusText.text = isPlayerTurn && !player.isMoving ? C.PLAYERS_TURN : C.ENEMY_TURN;
	}

	/**
	 * Enemies' turn logic
	 */
	function enemyTurn()
	{
		// retrieve the top enemy from queue and cast it into Actor
		var next = queue.splice(0, 1);
		var enemy:Actor = cast(next[0], Actor);

		// initialize the enemy's direction of action by assigning a random direction
		var dir = Math.ceil(Math.random() * 3);

		// TODO make them constants
		//  up : 0
		//  down : 1
		//  left : 2
		//  right : 3

		// if the player is withing aggro range go towards player's position
		if (enemy.aggroRange == 0 || enemy.aggroRange >= getDistanceFromPlayer(enemy))
			if (enemy.actionsCount == 0)
				dir = getMoveTowardsPlayer(enemy);
		// if the player is dead skip turn
		if (hasPlayerDied)
			dir = 4;

		// assign the action
		switch dir
		{
			case 0:
				actTo(enemy, enemy.nested - 1, enemy.nest);
			case 1:
				actTo(enemy, enemy.nested + 1, enemy.nest);
			case 2:
				actTo(enemy, enemy.nested, enemy.nest - 1);
			case 3:
				actTo(enemy, enemy.nested, enemy.nest + 1);
			default:
				enemy.skipTurn();
		}
	}

	/**
	 * Very basic "go-to-[actor]" logic
	 * Maybe it will be replaced into a proper A* pathfinding if this project grows enough
	 * @param actor 
	 * @return Int
	 */
	function getMoveTowardsPlayer(actor:Actor):Int
	{
		var tiles:Array<Int> = [];

		for (i in -1...2)
		{
			if (i != 0)
			{
				var v = Std.int(Math.abs(actor.nest - player.nest) + Math.abs(actor.nested + i - player.nested));
				tiles.push(v);
			}
		}
		for (i in -1...2)
		{
			if (i != 0)
			{
				var v = Std.int(Math.abs(actor.nest + i - player.nest) + Math.abs(actor.nested - player.nested));
				tiles.push(v);
			}
		}

		var smallerValue = currentLevel.length;
		for (i in 0...tiles.length)
		{
			if (tiles[i] < smallerValue)
				smallerValue = tiles[i];
		}

		return tiles.indexOf(smallerValue);
	}

	/**
	 * Returns the distance from player (measuring tiles)
	 * @param actor 
	 * @return Int
	 */
	function getDistanceFromPlayer(actor:Actor):Int
	{
		return Std.int(Math.abs(actor.nest - player.nest) + Math.abs(actor.nested - player.nested));
	}

	/**
	 * Draw the debug lines (was very usefull before puting the tileset)
	 */
	function drawDebugGrid()
	{
		var color:FlxColor = FlxColor.TRANSPARENT;
		debugGrid = new FlxSprite();
		debugGrid.makeGraphic(FlxG.width, FlxG.height, color, true);
		add(debugGrid);
		var lineStyle:LineStyle = {color: FlxColor.WHITE, thickness: 1};
		var drawStyle:DrawStyle = {smoothing: true};

		for (nest in 0...NEST)
		{
			debugGrid.drawLine(0, nest * C.TILE_SIZE, (NESTED - 1) * C.TILE_SIZE, nest * C.TILE_SIZE, lineStyle, drawStyle);
		}
		for (nested in 0...NESTED)
		{
			debugGrid.drawLine(nested * C.TILE_SIZE, 0, nested * C.TILE_SIZE, (NEST - 1) * C.TILE_SIZE, lineStyle, drawStyle);
		}

		debugGrid.alpha = showDebug ? .25 : 0;
	}

	/**
	 * Positions the tiles based on currentLevel array data
	 */
	function positionElements()
	{
		for (nest in 0...NEST)
		{
			for (nested in 0...NESTED)
			{
				// place walls
				if (currentLevel[nest][nested] == T.WALL)
				{
					var tile = new FlxSprite(nested * C.TILE_SIZE, nest * C.TILE_SIZE);
					tile.loadGraphic("assets/images/wall.png", true, C.TILE_SIZE, C.TILE_SIZE);
					tile.animation.add("w", [Random.choose([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 6, 6, 7, 7])], 1);
					tile.animation.play("w");
					add(tile);
				}

				// place starting tile with player
				if (currentLevel[nest][nested] == T.START)
				{
					var tile = new FlxSprite(nested * C.TILE_SIZE, nest * C.TILE_SIZE);
					tile.loadGraphic("assets/images/floor.png", true, C.TILE_SIZE, C.TILE_SIZE);
					tile.animation.add("fs", [1], 1);
					tile.animation.play("fs");
					add(tile);

					var tile = new FlxSprite(nested * C.TILE_SIZE, nest * C.TILE_SIZE);
					tile.loadGraphic("assets/images/stairs.png", true, C.TILE_SIZE, C.TILE_SIZE);
					tile.animation.add("s", [Random.int(1)], 1);
					tile.animation.play("s");
					add(tile);

					player = new Player();
					player.bakeAsset("player", C.TILE_SIZE, C.TILE_SIZE);
					player.x = nested * C.TILE_SIZE;
					player.y = nest * C.TILE_SIZE;
					player.nest = nest;
					player.nested = nested;
					// add(player);
				}

				// place the exit tile
				if (currentLevel[nest][nested] == T.EXIT)
				{
					var tile = new FlxSprite(nested * C.TILE_SIZE, nest * C.TILE_SIZE);
					tile.loadGraphic("assets/images/exit.png", true, C.TILE_SIZE, C.TILE_SIZE);
					tile.animation.add("e", [Random.int(2)], 1);
					tile.animation.play("e");
					add(tile);
				}

				// place floor
				if (currentLevel[nest][nested] == T.FLOOR)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);
				}

				// place the enemies and group them
				if (currentLevel[nest][nested] == T.SLIME)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new Slime();
					enemy.bakeAsset("slime", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}

				if (currentLevel[nest][nested] == T.ORC)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new Orc();
					enemy.bakeAsset("orc", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}
				if (currentLevel[nest][nested] == T.SKELETON)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new Orc();
					enemy.bakeAsset("skeleton", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}
				if (currentLevel[nest][nested] == T.ANCIENT_MONSTER)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new AncientMonster();
					enemy.bakeAsset("ancient_monster", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}
				if (currentLevel[nest][nested] == T.BAT)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new Bat();
					enemy.bakeAsset("bat", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}
				if (currentLevel[nest][nested] == T.WORM)
				{
					addFloor(nested * C.TILE_SIZE, nest * C.TILE_SIZE);

					var enemy = new Worm();
					enemy.bakeAsset("worm", C.TILE_SIZE, C.TILE_SIZE);
					enemy.x = nested * C.TILE_SIZE;
					enemy.y = nest * C.TILE_SIZE;
					enemy.nest = nest;
					enemy.nested = nested;
					enemies.add(enemy);
				}
			}
		}
		// place the enemies and the player on the display list last, to be visually on top
		for (i in 0...enemies.length)
		{
			add(enemies.members[i]);
		}
		add(player);
	}

	/**
	 * Add a random floor tile at [_x] and [_y]
	 * @param _x 
	 * @param _y 
	 */
	function addFloor(_x, _y)
	{
		var tile = new FlxSprite(_x, _y);
		tile.loadGraphic("assets/images/floor.png", true, C.TILE_SIZE, C.TILE_SIZE);
		tile.animation.add("f", [Random.choose([0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4])], 1);
		tile.animation.play("f");
		add(tile);
	}
}
