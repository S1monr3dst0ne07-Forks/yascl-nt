

use "lib/chunk.yap"



seq Ast::Lab
{
    NAME, // Str
}


fn Ast::Lab::Parse(stream)
{
    put node = Chunk::New(Ast::Lab);
    Lex::Expect(stream, "lab");
    put node.Ast::Lab::NAME = Str::Copy(Lex::PopCheck(stream, Lex::Kind::IDEN));
    Lex::Expect(stream, ";");
    return node;
}


fn Ast::Lab::Compile(node, ctx)
{
    put local = ctx.Ctx::Global::LOCAL;
    //HT::Set(
    //    local.Ctx::Local::LAB_TABLE,
    //    node.Ast::Lab::NAME,
    //    IR::Emit(ctx, IR::Op::REF),
    //);

    static 4096 ~ tmp;
    Str::Format(tmp, "%s:%s", [
    	local.Ctx::Local::FN_NAME, 
    	node.Ast::Lab::NAME,
    ]);
    HT::Set(
        local.Ctx::Local::LAB_TABLE,
        node.Ast::Lab::NAME,
        IR::Emit(ctx, IR::Op::REF, Str::Copy(tmp)),
    );
}

fn Ast::Lab::Void(node)
{
    Chunk::Void(node.Ast::Lab::NAME);
    Chunk::Void(node);
}
