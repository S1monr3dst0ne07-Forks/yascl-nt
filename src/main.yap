

use "lib/debug.yap"
use "lib/chunk.yap"
use "lib/bool.yap"

use "src/lex.yap"
use "src/ctx.yap"
use "src/error.yap"
use "src/ast/prog.yap"

bind GetCommandLineW    ~ "KERNEL32.DLL"
bind CommandLineToArgvW ~ "SHELL32.DLL"

fn read_arg(arg)
	// arg is encoded as a wide string
{
	put len = 0;
	lab len_loop;
		put char = (arg + (len << 1)).0;
		jump len_done ~ (char & 65535) == '\0';

		put len = len + 1;
		jump len_loop;
	lab len_done;

	put str = Chunk::New(len+1);
	put str.len = '\0';

	put i = 0;
	lab loop;
		jump done ~ len == i;
		put char = (arg + (i << 1)).0;
		put str.i = char & 255;

		put i = i + 1;
		jump loop;
	lab done;

	return str;
}

fn read_param()
{
	static 1 ~ argc_ptr;
	put argv = CommandLineToArgvW(GetCommandLineW(), argc_ptr);
	put argc = argc_ptr.0;

	jump no_param ~ argc < 2;
	return read_arg(argv.1);

lab no_param;
    Error::PrintError("No arguments provided.
    Usage: ./compiler <source-path>");
}

fn main(argc, argv)
{
	put source = read_param();

    put ctx = Ctx::MakeGlobal();

    put root = Ast::Prog::File(source, ctx);
    Ast::Prog::Resolve(root, ctx);
    
    //Ast::Prog::Compile(root, ctx);
    //Ctx::LinkGlobal(ctx);
    //IR::Asm(ctx);

    print("Compilation successful\n");
    //Ctx::Output(ctx, "BUILD.EXE");

	  dump_ht("binds.txt" , "%s: %s\n", ctx.Ctx::Global::BINDS );
    //dump_ht("consts.txt", "%s: %d\n", ctx.Ctx::Global::CONSTS);
    //dump_heap("core");

	ExitProcess(0);
}



