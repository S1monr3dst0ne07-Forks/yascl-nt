
use "src/ast/leaf.yap"


seq Ast::Expr::Op
{
    NONE,
    ADD,
    SUB,
    DOT,
    DOUBLE_DOT,
    EQUAL
    NOT_EQUAL,
    LESSER,
    GREATER,
    MUL,
    DIV,
    AND,
    OR,
    XOR,
    SHIFT_RIGHT,
    SHIFT_LEFT,
    MODULO,

    FADD,
    FSUB,
    FMUL,
    FDIV,
    FMOD,
    FLESSER,
    FGREATER,
}


seq Ast::Expr
{
    LEFT,  // AstExpr | AstLeaf
    RIGHT, // AstExpr | AstLeaf
    OP,    // Ast::Expr::Op

    INFO,  // Lex::Info
}


fn Ast::Expr::OpDecode(op)
{
	jump skip_ADD 	        ~ Str::Diff(op, "+");  return Ast::Expr::Op::ADD;           lab skip_ADD;
	jump skip_SUB 	        ~ Str::Diff(op, "-");  return Ast::Expr::Op::SUB;           lab skip_SUB;
	jump skip_DOT 	        ~ Str::Diff(op, ".");  return Ast::Expr::Op::DOT;           lab skip_DOT;
	jump skip_DOUBLE_DOT 	~ Str::Diff(op, ":");  return Ast::Expr::Op::DOUBLE_DOT;    lab skip_DOUBLE_DOT;
	jump skip_EQUAL 	    ~ Str::Diff(op, "=="); return Ast::Expr::Op::EQUAL;         lab skip_EQUAL;
	jump skip_NOT_EQUAL 	~ Str::Diff(op, "!="); return Ast::Expr::Op::NOT_EQUAL;     lab skip_NOT_EQUAL;
	jump skip_LESSER 	    ~ Str::Diff(op, "<");  return Ast::Expr::Op::LESSER;        lab skip_LESSER;
	jump skip_GREATER 	    ~ Str::Diff(op, ">");  return Ast::Expr::Op::GREATER;       lab skip_GREATER;
	jump skip_MUL 	        ~ Str::Diff(op, "*");  return Ast::Expr::Op::MUL;           lab skip_MUL;
	jump skip_DIV 	        ~ Str::Diff(op, "/");  return Ast::Expr::Op::DIV;           lab skip_DIV;
	jump skip_AND 	        ~ Str::Diff(op, "&");  return Ast::Expr::Op::AND;           lab skip_AND;
	jump skip_OR 	        ~ Str::Diff(op, "|");  return Ast::Expr::Op::OR;            lab skip_OR;
	jump skip_XOR 	        ~ Str::Diff(op, "^");  return Ast::Expr::Op::XOR;           lab skip_XOR;
	jump skip_SHIFT_RIGHT 	~ Str::Diff(op, ">>"); return Ast::Expr::Op::SHIFT_RIGHT;   lab skip_SHIFT_RIGHT;
	jump skip_SHIFT_LEFT 	~ Str::Diff(op, "<<"); return Ast::Expr::Op::SHIFT_LEFT;    lab skip_SHIFT_LEFT;
	jump skip_MODULO 	    ~ Str::Diff(op, "%");  return Ast::Expr::Op::MODULO;        lab skip_MODULO;

	// float operators
	jump skip_FADD     ~ Str::Diff(op, "~+"); return Ast::Expr::Op::FADD;     lab skip_FADD;
	jump skip_FSUB     ~ Str::Diff(op, "~-"); return Ast::Expr::Op::FSUB;     lab skip_FSUB;
	jump skip_FMUL     ~ Str::Diff(op, "~*"); return Ast::Expr::Op::FMUL;     lab skip_FMUL;
	jump skip_FDIV     ~ Str::Diff(op, "~/"); return Ast::Expr::Op::FDIV;     lab skip_FDIV;
	jump skip_FMOD     ~ Str::Diff(op, "~%"); return Ast::Expr::Op::FMOD;     lab skip_FMOD;
	jump skip_FLESSER  ~ Str::Diff(op, "~<"); return Ast::Expr::Op::FLESSER;  lab skip_FLESSER;
	jump skip_FGREATER ~ Str::Diff(op, "~>"); return Ast::Expr::Op::FGREATER; lab skip_FGREATER;

    return Ast::Expr::Op::NONE;
}


fn Ast::Expr::Parse(stream)
{
    put left = Ast::Leaf::Parse(stream);
    put right = Mem::NULL;
    put op = Ast::Expr::OpDecode(Lex::Peek(stream));
    put info = Lex::Info(stream);

    jump skip_right ~ op == Ast::Expr::Op::NONE;
        Lex::Pop(stream);
        put right = Ast::Expr::Parse(stream);
    lab skip_right;

    put node = Chunk::New(Ast::Expr);
    put node.Ast::Expr::LEFT  = left;
    put node.Ast::Expr::RIGHT = right;
    put node.Ast::Expr::OP    = op;
    put node.Ast::Expr::INFO  = info;
    return node;
}


fn Ast::Expr::FloatLiteral(node)
{
	// EXPERIMENTAL FEATURE
	// convert to floating point literal
	// if lhs and rhs of dot operator are
	// integer literals.

	// check operator
	jump no ~ (node.Ast::Expr::OP) != Ast::Expr::Op::DOT;
	put left = node.Ast::Expr::LEFT;
	put next = node.Ast::Expr::RIGHT;

	// check right hand side
	jump no ~ (next.Ast::Expr::OP) != Ast::Expr::Op::NONE;
	put right = next.Ast::Expr::LEFT;

	// check leaf types
	jump no ~ (left.Ast::Leaf::KIND ) != Ast::Leaf::Kind::NUMBER;
	jump no ~ (right.Ast::Leaf::KIND) != Ast::Leaf::Kind::NUMBER;

	put real     = left.Ast::Leaf::VALUE;
	put frac     = right.Ast::Leaf::VALUE;
	put frac_len = right.Ast::Leaf::INT_LEN;

	put value = Utils::FloatEncode(real, frac, frac_len);

	// deallocate right hand size
	Ast::Expr::Void(next);

	// update with new information
	put node.Ast::Expr::OP = Ast::Expr::Op::NONE;
	put left.Ast::Leaf::VALUE = value;
	put left.Ast::Leaf::KIND  = Ast::Leaf::Kind::NUMBER;

lab no;
}


fn Ast::Expr::Resolve(node, ctx)
{
    Ast::Leaf::Resolve(node.Ast::Expr::LEFT, ctx);
    
    jump skip_right ~ (node.Ast::Expr::OP) == Ast::Expr::Op::NONE;
        Ast::Expr::Resolve(node.Ast::Expr::RIGHT, ctx);
    lab skip_right;

	Ast::Expr::FloatLiteral(node);
}



fn Ast::Expr::Load(node, ctx)
{
    jump only_leaf ~ (node.Ast::Expr::OP) == Ast::Expr::Op::NONE;

    Ast::Expr::Load(node.Ast::Expr::RIGHT, ctx);
    IR::Emit(ctx, IR::Op::PUSH);
    Ast::Leaf::Load(node.Ast::Expr::LEFT, ctx);
    IR::Emit(ctx, IR::Op::POP_AUX); // pop into auxiliary register (rbx)

    put op = node.Ast::Expr::OP;
    jump compile_add         ~ op == Ast::Expr::Op::ADD;
    jump compile_sub         ~ op == Ast::Expr::Op::SUB;
    jump compile_dot         ~ op == Ast::Expr::Op::DOT;
    jump compile_double_dot  ~ op == Ast::Expr::Op::DOUBLE_DOT;
    jump compile_equal       ~ op == Ast::Expr::Op::EQUAL;
    jump compile_not_equal   ~ op == Ast::Expr::Op::NOT_EQUAL;
    jump compile_lesser      ~ op == Ast::Expr::Op::LESSER;
    jump compile_greater     ~ op == Ast::Expr::Op::GREATER;
    jump compile_mul         ~ op == Ast::Expr::Op::MUL;
    jump compile_div         ~ op == Ast::Expr::Op::DIV;
    jump compile_and         ~ op == Ast::Expr::Op::AND;
    jump compile_or          ~ op == Ast::Expr::Op::OR;
    jump compile_xor         ~ op == Ast::Expr::Op::XOR;
    jump compile_shift_right ~ op == Ast::Expr::Op::SHIFT_RIGHT;
    jump compile_shift_left  ~ op == Ast::Expr::Op::SHIFT_LEFT;
    jump compile_modulo      ~ op == Ast::Expr::Op::MODULO;

    // floating point
    jump compile_fadd     ~ op == Ast::Expr::Op::FADD;
    jump compile_fsub     ~ op == Ast::Expr::Op::FSUB;
    jump compile_fmul     ~ op == Ast::Expr::Op::FMUL;
    jump compile_fdiv     ~ op == Ast::Expr::Op::FDIV;
    jump compile_fmod     ~ op == Ast::Expr::Op::FMOD;
    jump compile_flesser  ~ op == Ast::Expr::Op::FLESSER;
    jump compile_fgreater ~ op == Ast::Expr::Op::FGREATER;


    lab compile_add; IR::Emit(ctx, IR::Op::ADD); jump done;
    lab compile_sub; IR::Emit(ctx, IR::Op::SUB); jump done;
    lab compile_dot; IR::Emit(ctx, IR::Op::DOT); jump done;
    lab compile_double_dot; IR::Emit(ctx, IR::Op::DOUBLE_DOT); jump done;

    lab compile_equal;          IR::Emit(ctx, IR::Op::EQUAL);     jump done;
    lab compile_not_equal;      IR::Emit(ctx, IR::Op::NOT_EQUAL); jump done;
    lab compile_lesser;         IR::Emit(ctx, IR::Op::LESSER);    jump done;
    lab compile_greater;        IR::Emit(ctx, IR::Op::GREATER);   jump done;

    lab compile_mul;            IR::Emit(ctx, IR::Op::MUL); jump done;
    lab compile_div;            IR::Emit(ctx, IR::Op::DIV); jump done;
    lab compile_modulo;         IR::Emit(ctx, IR::Op::MOD); jump done;
    lab compile_and;            IR::Emit(ctx, IR::Op::AND); jump done;
    lab compile_or ;            IR::Emit(ctx, IR::Op::OR ); jump done;
    lab compile_xor;            IR::Emit(ctx, IR::Op::XOR); jump done;
    lab compile_shift_right;    IR::Emit(ctx, IR::Op::SHR); jump done;
    lab compile_shift_left;     IR::Emit(ctx, IR::Op::SHL); jump done;

    lab compile_fadd;     IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::ADD);     jump done;
    lab compile_fsub;     IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::SUB);     jump done;
    lab compile_fmul;     IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::MUL);     jump done;
    lab compile_fdiv;     IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::DIV);     jump done;
    lab compile_fmod;     IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::MOD);     jump done;
    lab compile_flesser;  IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::LESSER);  jump done;
    lab compile_fgreater; IR::Emit(ctx, IR::Op::FLOAT, IR::FloatOp::GREATER); jump done;

lab only_leaf;
    Ast::Leaf::Load(node.Ast::Expr::LEFT, ctx);
lab done;
}


fn Ast::Expr::Store(node, ctx)
{
    jump only_leaf ~ (node.Ast::Expr::OP) == Ast::Expr::Op::NONE;
    jump error     ~ (node.Ast::Expr::OP) != Ast::Expr::Op::DOT;

    IR::Emit(ctx, IR::Op::PUSH);
    Ast::Expr::Load(node.Ast::Expr::RIGHT, ctx);
    IR::Emit(ctx, IR::Op::PUSH);
    Ast::Leaf::Load(node.Ast::Expr::LEFT,  ctx);
    IR::Emit(ctx, IR::Op::POP_AUX);
    IR::Emit(ctx, IR::Op::DOUBLE_DOT);
    IR::Emit(ctx, IR::Op::POP_AUX);
    IR::Emit(ctx, IR::Op::INDIRECT_STORE);

    jump done;

lab error;
    put info = node.Ast::Expr::INFO;
    Error::LexError(info, "Trying to store into non-dot expression.");
lab only_leaf;
    Ast::Leaf::Store(node.Ast::Expr::LEFT, ctx);
lab done;
}


fn Ast::Expr::Collect(node, ctx)
{
    jump skip ~ (node.Ast::Expr::OP) != Ast::Expr::Op::NONE;
        Ast::Leaf::Collect(node.Ast::Expr::LEFT, ctx);
    lab skip;
}

fn Ast::Expr::Eval(node, ctx)
    // static compiler-time evaluation.
{
    jump only_leaf ~ (node.Ast::Expr::OP) == Ast::Expr::Op::NONE;

    put left  = Ast::Leaf::Eval(node.Ast::Expr::LEFT , ctx);
    put right = Ast::Expr::Eval(node.Ast::Expr::RIGHT, ctx);

    put op = node.Ast::Expr::OP;
    jump eval_add         ~ op == Ast::Expr::Op::ADD;
    jump eval_sub         ~ op == Ast::Expr::Op::SUB;
    jump eval_equal       ~ op == Ast::Expr::Op::EQUAL;
    jump eval_not_equal   ~ op == Ast::Expr::Op::NOT_EQUAL;
    jump eval_lesser      ~ op == Ast::Expr::Op::LESSER;
    jump eval_greater     ~ op == Ast::Expr::Op::GREATER;
    jump eval_mul         ~ op == Ast::Expr::Op::MUL;
    jump eval_div         ~ op == Ast::Expr::Op::DIV;
    jump eval_and         ~ op == Ast::Expr::Op::AND;
    jump eval_or          ~ op == Ast::Expr::Op::OR;
    jump eval_xor         ~ op == Ast::Expr::Op::XOR;
    jump eval_shift_right ~ op == Ast::Expr::Op::SHIFT_RIGHT;
    jump eval_shift_left  ~ op == Ast::Expr::Op::SHIFT_LEFT;
    jump eval_modulo      ~ op == Ast::Expr::Op::MODULO;

    put info = node.Ast::Expr::INFO;
    Error::LexError(info, "Unsupported compile-time operation.");


    lab eval_add;       return left + right;
    lab eval_sub;       return left - right;
    lab eval_equal;     return left == right;
    lab eval_not_equal; return left != right;
    lab eval_lesser;    return left <  right;
    lab eval_greater;   return left >  right;
    lab eval_mul;       return left * right;
    lab eval_div;       return left / right;
    lab eval_modulo;    return left % right;
    lab eval_and;       return left & right;
    lab eval_or;        return left | right;
    lab eval_xor;       return left ^ right;
    lab eval_shift_right; return left >> right;
    lab eval_shift_left;  return left << right;

lab only_leaf;
    return Ast::Leaf::Eval(node.Ast::Expr::LEFT, ctx);

}


fn Ast::Expr::Void(node)
{
    jump only_leaf ~ (node.Ast::Expr::OP) == Ast::Expr::Op::NONE;

    Ast::Expr::Void(node.Ast::Expr::RIGHT);
lab only_leaf;
    Ast::Leaf::Void(node.Ast::Expr::LEFT);

    Lex::VoidInfo(node.Ast::Expr::INFO);
    Chunk::Void(node);
}
