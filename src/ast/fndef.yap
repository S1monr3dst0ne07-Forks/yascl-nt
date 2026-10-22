

use "lib/dyn.yap"

use "src/utils.yap"
use "src/config.yap"
use "src/ast/block.yap"



seq Ast::FnDef
{
    NAME,   // Str
    PARAMS, // Dyn<Str>
    BODY,   // Ast::Block
}






fn Ast::FnDef::Parse(stream)
{
    put node = Chunk::New(Ast::FnDef);
    
    Lex::Expect(stream, "fn");
    put node.Ast::FnDef::NAME = Str::Copy(Lex::PopCheck(stream, Lex::Kind::IDEN));
    Lex::Expect(stream, "(");


    put params = Dyn::Create();
    lab loop;
        jump done ~ (Lex::Peek(stream).0) == ')';
        Dyn::Push(params, Str::Copy(Lex::PopCheck(stream, Lex::Kind::IDEN)));

        jump loop ~ (Lex::Peek(stream).0) != ',';

        Lex::Pop(stream);
        jump loop;

    lab done;
    put node.Ast::FnDef::PARAMS = params;

    
    Lex::Expect(stream, ")");
    put node.Ast::FnDef::BODY = Ast::Block::Parse(stream);

    jump param_count_warning ~ Dyn::Size(params) > Config::PARAM_LIMIT;
    return node;

lab param_count_warning;
    print("warning: fndef of `%s` uses %d parameters which exceeds the limit of %d\n", [
        node.Ast::FnDef::NAME,  
        Dyn::Size(params),  
        Config::PARAM_LIMIT,
    ]);

    return node; 
}


fn Ast::FnDef::Resolve(node, ctx)
{
    Ast::Block::Resolve(
        node . Ast::FnDef::BODY,
        ctx,
    );
}

fn Ast::FnDef::SliceParameters(params, quick_params, stack_params)
{
	put i = 0;
	lab loop;
		jump done ~ i == Dyn::Size(params);
		put param = Dyn::Ptr(params).i;
		put i = i + 1;

		jump quick ~ i < 4;
		jump stack;

	lab quick; Dyn::Push(quick_params, param); jump loop;
	lab stack; Dyn::Push(stack_params, param); jump loop;

lab done;
}

fn Ast::FnDef::Compile(node, ctx)
{
    put local_super_ctx = ctx.Ctx::Global::LOCAL;
    put local_ctx = Ctx::MakeLocal(node.Ast::FnDef::NAME);
    put ctx.Ctx::Global::LOCAL = local_ctx;

	put params = node.Ast::FnDef::PARAMS;
	put quick_params = Dyn::Create();
	put stack_params = Dyn::Create();
	Ast::FnDef::SliceParameters(params, quick_params, stack_params);
	
	// this code right here is very tricky.
	// the windows calling conventions make it
	// so that caller allocates the stack space
	// for parameters. meaning we can use that.
	// but the non-paramter local (i have called them
	// "real" locals here) need to have additional
	// space reserved. this also means that the order
	// of local allocation is very very important!

	// we mask the caller part of the stack with
	// our variable allocationss. here, the stack
	// paramters slot come from.
	put i = 0;
	lab stack_loop;
		jump stack_done ~ i == Dyn::Size(stack_params);

		put param = Dyn::Ptr(stack_params).i;
		Ctx::VarAlloc(ctx, param);

		put i = i + 1;
		jump stack_loop;
	lab stack_done;


	// now we do the same for the register-passing
	// parameters and fill in the shadow space
	// on the stack.
	put i = 0;
	lab quick_loop;
		jump quick_done ~ i == Dyn::Size(quick_params);

		put param_name = Dyn::Ptr(quick_params).i;
		Ctx::VarAlloc(ctx, param_name); // allocate
		put param_addr = Ctx::VarLookup(ctx, param_name);
		IR::Emit(ctx, IR::Op::LOAD_PARAM, i);
		IR::Emit(ctx, IR::Op::STORE_LOCAL, param_addr);

        put i = i + 1;
        jump quick_loop;
    lab quick_done;

	// for functions with less than 4 parameter,
	// the shadow space is not filled out entirely.
	// so we has to compensate for that.
	put missing = 4 - Dyn::Size(quick_params);
	put local_ctx.Ctx::Local::ALLOCER = 
	   (local_ctx.Ctx::Local::ALLOCER) + missing;

	// now we are at the point on the stack,
	// where the call has happened, so we need
	// to account for the return address
	//    "don't touch me in my speical stack slot!"
	Ctx::VarAlloc(ctx, "__return_addr_dont_touch");

	// all of the parameter variables are present now.
	// the ALLOCER is point to the start of local
	// stack space. we can finally collect.
	put n_real_local = Ast::FnDef::Collect(node, ctx);
	put local_space  = n_real_local * Config::WORD_SIZE;

	// the stack might not be aligned after reserving local space.
	// but in x64 the stack has to always be aligned to 16 bytes
	// offsets.
	put local_space = local_space + 
	    (Config::WORD_SIZE * ((local_space % 16) == 0));

	IR::Emit(ctx, IR::Op::RSP_DOWN, local_space);
	put local_ctx.Ctx::Local::STACK_SPACE = local_space;

    // actual body and stack recovery
    Ast::Block::Compile(node.Ast::FnDef::BODY, ctx); // <--- SUB-COMPILE HERE
    Ctx::RecoverStack(ctx);

    // function exit
    IR::Emit(ctx, IR::Op::LOAD_INT, 0); //default return value
    IR::Emit(ctx, IR::Op::LEAVE);

    // link lab/jump pairs together
    Ctx::LinkLocal(ctx);

    // void subctx, restore superctx
    Ctx::VoidLocal(local_ctx);
    put ctx.Ctx::Global::LOCAL = local_super_ctx;
}



fn Ast::FnDef::Collect(node, ctx)
{
    put body = node.Ast::FnDef::BODY;
    return Ast::Block::Collect(body, ctx);
}

fn Ast::FnDef::Void(node)
{
    put params = node.Ast::FnDef::PARAMS;
    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(params);
        put param_name = Dyn::Ptr(params).i;

        Chunk::Void(param_name);
        
        put i = i + 1;
        jump loop;
    lab done;
    
    Dyn::Void(node.Ast::FnDef::PARAMS);
    Chunk::Void(node.Ast::FnDef::NAME);
    Ast::Block::Void(node.Ast::FnDef::BODY);
    Chunk::Void(node);
}

