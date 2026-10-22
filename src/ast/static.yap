
use "lib/chunk.yap"
use "lib/ht.yap"


seq Ast::Static
{
    WORDS, // Int
    EXPR,  // Ast::Expr
}



fn Ast::Static::Parse(stream)
{
    put node = Chunk::New(Ast::Static);
    Lex::Expect(stream, "static");
    put node.Ast::Static::WORDS = Ast::Expr::Parse(stream);
    Lex::Expect(stream, "~");
    put node.Ast::Static::EXPR = Ast::Expr::Parse(stream);
    Lex::Expect(stream, ";");
    return node;
}


fn Ast::Static::Resolve(node, ctx)
{
    Ast::Expr::Resolve(node.Ast::Static::WORDS, ctx);
    Ast::Expr::Resolve(node.Ast::Static::EXPR, ctx);
}


fn Ast::Static::Compile(node, ctx)
{
    put words = Ast::Expr::Eval(node.Ast::Static::WORDS, ctx);

    IR::Emit(ctx, IR::Op::LOAD_STATIC, words);
    Ast::Expr::Store(node.Ast::Static::EXPR, ctx);
}

fn Ast::Static::Collect(node, ctx)
{
    return Ast::Expr::Collect(node.Ast::Static::EXPR, ctx);
}

fn Ast::Static::Void(node)
{
    Ast::Expr::Void(node.Ast::Static::WORDS);
    Ast::Expr::Void(node.Ast::Static::EXPR);
    Chunk::Void(node);
}

