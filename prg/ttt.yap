
use "lib/bool.yap"
use "lib/str.yap"

seq Game
{
	BOARD, // char[9] character in field (digit if not set)
	DATA , // bool[9] data in field (zero if not set, otherwise Player)
	TURN,  // Player
}
seq Player
{
	O = 1,
	X = 2,
}
fn init()
{
	static 9 ~ board;
	put i = 0;
	lab loop;
		put board.i = i + '1';
		put i = i + 1;
	jump loop ~ i < 9;

	static 9 ~ data;
	Mem::Set(data, Bool::FALSE, 9);

	static Game ~ game;
	put game.Game::BOARD = board;
	put game.Game::DATA  = data;
	put game.Game::TURN  = Player::O;

	return game;
}



fn render(game)
{
	static 4096 ~ buffer;
	put board = game.Game::BOARD;

	put iter = buffer;
	Mem::Set(iter, '\n', 100);
	put iter = iter : 100;

	put iter = Str::Format(iter, "+---+---+---+\n");
	put iter = Str::Format(iter, "| %c | %c | %c |\n", [board.0, board.1, board.2]);
	put iter = Str::Format(iter, "+---+---+---+\n");
	put iter = Str::Format(iter, "| %c | %c | %c |\n", [board.3, board.4, board.5]);
	put iter = Str::Format(iter, "+---+---+---+\n");
	put iter = Str::Format(iter, "| %c | %c | %c |\n", [board.6, board.7, board.8]);
	put iter = Str::Format(iter, "+---+---+---+\n\n\n");

	IO::Print(buffer);
}

fn get_prompt_string(turn)
{
	jump o ~ turn == Player::O;
	jump x ~ turn == Player::X;

	lab o; return "player o turn (1-9): ";
	lab x; return "player x turn (1-9): ";
}
fn get_player_char(turn)
{
	jump o ~ turn == Player::O;
	jump x ~ turn == Player::X;

	lab o; return 'O';
	lab x; return 'X';
}

fn input(game)
{
	static 32 ~ buf;

lab again;
	IO::Print(get_prompt_string(game.Game::TURN));
	syscall(SYSCALL::READ, IO::STD::IN, buf, 32);

	put move = ((buf.0) & 255) - '1';
	jump invalid  ~ move > 8;
	jump not_free ~ (game.Game::DATA).move;
	return move;

lab invalid;
	IO::Print("invalid input, try again.\n\n");
	jump again;
lab not_free;
	IO::Print("that field not free, try again.\n\n");
	jump again;
}


fn check_triple(game, player, base, step)
{
	put data = game.Game::DATA;

	jump no ~ (data.base) != player;
	put base = base + step;
	jump no ~ (data.base) != player;
	put base = base + step;
	jump no ~ (data.base) != player;

	return Bool::TRUE;

lab no;
	return Bool::FALSE;
}

fn check_won(game)
{
	put player = game.Game::TURN;

	// rows
	jump won ~ check_triple(game, player, 0, 1);
	jump won ~ check_triple(game, player, 3, 1);
	jump won ~ check_triple(game, player, 6, 1);

	// columns
	jump won ~ check_triple(game, player, 0, 3);
	jump won ~ check_triple(game, player, 1, 3);
	jump won ~ check_triple(game, player, 2, 3);

	// diagonals
	jump won ~ check_triple(game, player, 0, 4);
	jump won ~ check_triple(game, player, 2, 2);

	return Bool::FALSE;

lab won;
	return Bool::TRUE;
}

fn main()
{
	put game = init();

	lab loop;
		render(game);
		put move = input(game);

		// write move to board
		put turn = game.Game::TURN;
		put (game.Game::BOARD).move = get_player_char(turn);
		put (game.Game::DATA) .move = turn;

		jump won ~ check_won(game);

		// switch player
		put game.Game::TURN = turn ^ 3;
	jump loop;

lab won;
	render(game); // make winning move show up
	jump o_won ~ turn == Player::O;
	jump x_won ~ turn == Player::X;

lab o_won; IO::Print("player o won!\n"); jump done;
lab x_won; IO::Print("player x won!\n"); jump done;

lab done;
}


