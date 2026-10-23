

use "lib/ht.yap"
use "src/ctx.yap"


seq Ast::Leaf
{
    VALUE, // Void
    KIND,  // Ast::Leaf::Kind

    // length of source identifier for integer.
    // needed to reconstruct leading zeros
    // for floating point literals.
    // only set for Ast::Leaf::Kind::NUMBER!
    INT_LEN, 

    INFO,  // Lex::Info
}

seq Ast::Leaf::Call
{
    NAME,   // Str
    PARAMS, // Dyn<Ast::Expr>
}

seq Ast::Leaf::Kind
{
    NUMBER,
    VAR,
    CALL,
    CONST,
    META,
    STRING,
    ARRAY,
    CHAR,
    SUBEXPR,
}


fn Ast::Leaf::Local::MakeLeaf(value, kind, info)
{
    put node = Chunk::New(Ast::Leaf);
    put node.Ast::Leaf::VALUE = value;
    put node.Ast::Leaf::KIND  = kind;
    put node.Ast::Leaf::INFO  = info;
    return node;
}



fn Ast::Leaf::Parse(stream)
{
    put info = Lex::Info(stream);

    put token = Lex::PopTok(stream);
    put tok_kind = token.Lex::Token::KIND;
    put content  = token.Lex::Token::CONTENT;

    put next = Lex::Peek(stream);


    jump char_lit  ~ tok_kind == Lex::Kind::SINGLE_QUOTE;
    jump string    ~ tok_kind == Lex::Kind::DOUBLE_QUOTE;
    jump sub_expr  ~ Str::Diff(content, "(") == 0;
    jump array     ~ Str::Diff(content, "[") == 0;
    jump call      ~ Str::Diff(next, "(") == 0;
    jump number    ~ Str::IsNumber(content);
    jump meta;

lab sub_expr;
    put expr = Ast::Expr::Parse(stream);
    Lex::Expect(stream, ")");

    return Ast::Leaf::Local::MakeLeaf(
        expr, Ast::Leaf::Kind::SUBEXPR, info,
    );

lab array;
    put elems = Dyn::Create();
    
    lab array_loop;
        jump array_done ~ (Lex::Peek(stream).0) == ']';
        Dyn::Push(elems, Ast::Expr::Parse(stream));
        jump array_loop ~ (Lex::Peek(stream).0) != ',';
        Lex::Expect(stream, ",");
        jump array_loop;
    lab array_done;
    Lex::Expect(stream, "]");

    return Ast::Leaf::Local::MakeLeaf(
        elems, Ast::Leaf::Kind::ARRAY, info,
    );


lab char_lit;
    return Ast::Leaf::Local::MakeLeaf(
        Utils::Unescape(content).0, 
        Ast::Leaf::Kind::CHAR,
        info,
    );


lab string;
    return Ast::Leaf::Local::MakeLeaf(
        Utils::Unescape(Str::Copy(content)),
        Ast::Leaf::Kind::STRING,
        info,
    );


lab call;
    Lex::Expect(stream, "(");
    put params = Dyn::Create();
    
    lab call_loop;
        put tok = Lex::PeekTok(stream);
        jump call_done ~ (tok.Lex::Token::KIND) == Lex::Kind::PAREN_CLOSE;
        Dyn::Push(params, Ast::Expr::Parse(stream));
        
        jump call_loop ~ (Lex::Peek(stream).0) != ',';
        Lex::Expect(stream, ",");
        jump call_loop;
    lab call_done;

    Lex::Expect(stream, ")");
    put subnode = Chunk::New(Ast::Leaf::Call);
    put subnode.Ast::Leaf::Call::NAME = Str::Copy(content);
    put subnode.Ast::Leaf::Call::PARAMS = params;

    return Ast::Leaf::Local::MakeLeaf(
        subnode, Ast::Leaf::Kind::CALL, info
    );

lab number;
    put node = Ast::Leaf::Local::MakeLeaf(
        Str::ToInt(content), Ast::Leaf::Kind::NUMBER, info
    );
    put node.Ast::Leaf::INT_LEN = Str::Len(content);
    return node;

lab meta;
    return Ast::Leaf::Local::MakeLeaf(
        Str::Copy(content), Ast::Leaf::Kind::META, info
    );
    

}


fn Ast::Leaf::ResolveContainer(container, ctx)
    // assume container : Dyn<Ast::Expr>
{
    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(container);
        Ast::Expr::Resolve(Dyn::Ptr(container).i, ctx);
        put i = i + 1;
        jump loop;
    lab done;
}


fn Ast::Leaf::Resolve(node, ctx)
    // this is complicated, because a leaf can both be ...
    //  ... the base case for recursive resolution.
    //  ... another container objects whos fields need to be resolved.
{
    put kind  = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;

    // recursive resolve
    jump subexpr ~ kind == Ast::Leaf::Kind::SUBEXPR;
    jump call    ~ kind == Ast::Leaf::Kind::CALL;
    jump array   ~ kind == Ast::Leaf::Kind::ARRAY;

    jump done    ~ kind != Ast::Leaf::Kind::META;

    // base resolve
    jump const ~ HT::Has(ctx.Ctx::Global::CONSTS, value);
    jump var;
    
    lab const;
        put node.Ast::Leaf::KIND = Ast::Leaf::Kind::CONST;
        jump done;
    lab var;
        put node.Ast::Leaf::KIND = Ast::Leaf::Kind::VAR;
        jump done;

    lab subexpr;
        Ast::Expr::Resolve(value, ctx);
        jump done;

    lab call;
        put container = value.Ast::Leaf::Call::PARAMS;
        Ast::Leaf::ResolveContainer(container, ctx);
        jump done;

    lab array;
        Ast::Leaf::ResolveContainer(value, ctx);
        jump done;

    lab done;
}


fn Ast::Leaf::Load(node, ctx)
{
    put kind  = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;
    put info  = node.Ast::Leaf::INFO;

    jump load_subexpr   ~ kind == Ast::Leaf::Kind::SUBEXPR;
    jump load_number    ~ kind == Ast::Leaf::Kind::NUMBER;
    jump load_var       ~ kind == Ast::Leaf::Kind::VAR;
    jump load_call      ~ kind == Ast::Leaf::Kind::CALL;
    jump load_const     ~ kind == Ast::Leaf::Kind::CONST;
    jump load_string    ~ kind == Ast::Leaf::Kind::STRING;
    jump load_array     ~ kind == Ast::Leaf::Kind::ARRAY;
    jump load_char      ~ kind == Ast::Leaf::Kind::CHAR;
    Error::LexError(info, "Internal error: meta node while Ast::Leaf::Load");
    jump done;

lab load_char;   
lab load_number;
    IR::Emit(ctx, IR::Op::LOAD_INT, value);
    jump done;
lab load_const;
    put const = HT::Get(ctx.Ctx::Global::CONSTS, value);
    IR::Emit(ctx, IR::Op::LOAD_INT, const);
    jump done;
lab load_var;
    jump var_not_exist ~ Bool::Not(Ctx::VarExists(ctx, value));
    put addr = Ctx::VarLookup(ctx, value);
    IR::Emit(ctx, IR::Op::LOAD_LOCAL, addr);
    jump done;

lab load_subexpr;
    Ast::Expr::Load(value, ctx);
    jump done;

lab load_call;
    put name   = value.Ast::Leaf::Call::NAME;
    put params = value.Ast::Leaf::Call::PARAMS;

	put quick_params  = Dyn::Create();
	put stack_params  = Dyn::Create();
	Utils::SliceParameters(params, quick_params, stack_params);
	put space         = 32 + (8 * Dyn::Size(stack_params));
	put need_padding  = (space % 16) == 0;
	put space_aligned = space + (need_padding * 8);

	// save base pointer
	IR::Emit(ctx, IR::Op::PUSH_RBP);
	IR::Emit(ctx, IR::Op::RSP_DOWN, space_aligned);

	// load stack parameters
	put i = 0;
	lab load_stack_loop;
		jump load_stack_done ~ i == Dyn::Size(stack_params);
		put param = Dyn::Ptr(stack_params).i;

		put addr = 32 + (i * 8);
        Ast::Expr::Load(param, ctx);
		IR::Emit(ctx, IR::Op::STORE_RSP, addr);

		put i = i + 1;
		jump load_stack_loop;
	lab load_stack_done;

	// load quick register parameters
    put i = 0;
    lab push_loop;
        jump push_done ~ i == Dyn::Size(quick_params);
        put param = Dyn::Ptr(quick_params).i;
        put i = i + 1;

        Ast::Expr::Load(param, ctx);
        IR::Emit(ctx, IR::Op::PUSH);
        jump push_loop;
    lab push_done;

    lab pop_loop;
        jump pop_done ~ i == 0;
        put i = i - 1;
        IR::Emit(ctx, IR::Op::POP);
        IR::Emit(ctx, IR::Op::STORE_QUICK, i);
        jump pop_loop;
    lab pop_done;

    // set new base pointer
    //  this has to happen after loading the parameters
    //  to allow them to access the local variables of the caller frame.
    IR::Emit(ctx, IR::Op::UPDATE_RBP, space);

	// actual call
	jump external ~ HT::Has(ctx.Ctx::Global::BINDS, name);
	jump internal;

	lab internal; IR::Emit(ctx, IR::Op::CALL    , name); jump call_over;
	lab external; IR::Emit(ctx, IR::Op::CALL_DLL, name); jump call_over;
	lab call_over;

	// remove callee stack
	IR::Emit(ctx, IR::Op::RSP_UP, space_aligned);
	IR::Emit(ctx, IR::Op::POP_RBP);

	jump done;


lab load_string;
    IR::Emit(ctx, IR::Op::LOAD_STRING, value);
    jump done;

lab load_array;
    put value_count = Dyn::Size(value);
    IR::Emit(ctx, IR::Op::LOAD_STATIC, value_count);
    IR::Emit(ctx, IR::Op::PUSH);

    // load elements of array
    put vaddr = 0;
    lab array_loop;
        jump array_done ~ vaddr == Dyn::Size(value);
        put addr = vaddr * Config::WORD_SIZE;

        put elem = Dyn::Ptr(value).vaddr;
        Ast::Expr::Load(elem, ctx);
        IR::Emit(ctx, IR::Op::POP_AUX);
        IR::Emit(ctx, IR::Op::PUSH_AUX);
        IR::Emit(ctx, IR::Op::OFFSET_STORE, addr);

        put vaddr = vaddr + 1;
        jump array_loop;
    lab array_done;

    IR::Emit(ctx, IR::Op::POP);
    jump done;

lab var_not_exist;
    Error::LexError(info, "Variable `%s` has not been defined", [value]);

lab done;
}

fn Ast::Leaf::Store(node, ctx)
{
    put kind = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;
    jump subexpr ~ kind == Ast::Leaf::Kind::SUBEXPR;
    jump not_var ~ kind != Ast::Leaf::Kind::VAR;

    put addr = Ctx::VarLookup(ctx, value);
    IR::Emit(ctx, IR::Op::STORE_LOCAL, addr);

    jump done;
lab not_var;
    put info = node.Ast::Leaf::INFO;
    Error::LexError(info, "Trying to store into non-variable value");
lab subexpr;
    Ast::Expr::Store(value, ctx);
lab done;
}


fn Ast::Leaf::Collect(node, ctx)
{
    put kind = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;

    jump not_var ~ kind != Ast::Leaf::Kind::VAR;
    return Ctx::VarAlloc(ctx, value);

lab not_var;
    return 0;
}


fn Ast::Leaf::Eval(node, ctx)
{
    put kind = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;

    jump eval_subexpr   ~ kind == Ast::Leaf::Kind::SUBEXPR;
    jump eval_number    ~ kind == Ast::Leaf::Kind::NUMBER;
    jump eval_char      ~ kind == Ast::Leaf::Kind::CHAR;
    jump eval_const     ~ kind == Ast::Leaf::Kind::CONST;

    put info = node.Ast::Leaf::INFO;
    Error::LexError(info, "Unsupported compile-time leaf");

lab eval_char;   
lab eval_number;
    return value;

lab eval_const;
    put const = HT::Get(ctx.Ctx::Global::CONSTS, value);
    return const;

lab eval_subexpr;
    return Ast::Expr::Eval(value, ctx);

}


fn Ast::Leaf::Void(node)
{
    put kind = node.Ast::Leaf::KIND;
    put value = node.Ast::Leaf::VALUE;
    Lex::VoidInfo(node.Ast::Leaf::INFO);
    Chunk::Void(node);

    jump void_meta      ~ kind == Ast::Leaf::Kind::META;
    jump void_subexpr   ~ kind == Ast::Leaf::Kind::SUBEXPR;
    jump void_var       ~ kind == Ast::Leaf::Kind::VAR;
    jump void_call      ~ kind == Ast::Leaf::Kind::CALL;
    jump void_const     ~ kind == Ast::Leaf::Kind::CONST;
    jump void_string    ~ kind == Ast::Leaf::Kind::STRING;
    jump void_array     ~ kind == Ast::Leaf::Kind::ARRAY;
    jump done;

lab void_meta;
lab void_const;
lab void_var;
lab void_string;
    // all of these are just string identifiers.

    Chunk::Void(value);
    jump done;

lab void_subexpr;
    Ast::Expr::Void(value);
    jump done;

lab void_call;
    put params = value.Ast::Leaf::Call::PARAMS;
    put i = 0;
    lab void_call_loop;
        jump void_call_done ~ i == Dyn::Size(params);
        put param = Dyn::Ptr(params).i;
        put i = i + 1;

        Ast::Expr::Void(param);
        jump void_call_loop;
    lab void_call_done;

    Dyn::Void(value.Ast::Leaf::Call::PARAMS);
    Chunk::Void(value.Ast::Leaf::Call::NAME);
    Chunk::Void(value);
    jump done;

lab void_array;
    put i = 0;
    lab array_loop;
        jump array_done ~ i == Dyn::Size(value);
        put elem = Dyn::Ptr(value).i;
        put i = i + 1;

        Ast::Expr::Void(elem);

        jump array_loop;
    lab array_done;

    Dyn::Void(value);
    jump done;


lab done;
}

