

use "lib/chunk.yap"
use "lib/dyn.yap"

use "src/ast/put.yap"
use "src/ast/return.yap"
use "src/ast/lab.yap"
use "src/ast/jump.yap"
use "src/ast/static.yap"
use "src/ast/inplace.yap"

seq Ast::Block
{
    NODES, // Dyn<Ast::Block::Node>
}

seq Ast::Block::Node
{
    MESA, // Ptr
    KIND, // Ast::Block::Kind
}

seq Ast::Block::Kind
{
    PUT,
    RETURN,
    LAB,
    JUMP,
    STATIC,
    INPLACE,
}

fn Ast::Block::Local::MakeNode(mesa, kind)
{
    put node = Chunk::New(Ast::Block::Node);
    put node.Ast::Block::Node::MESA = mesa;
    put node.Ast::Block::Node::KIND = kind;
    return node;
}


fn Ast::Block::ParseNode(stream)
{
    put token_prefix = Lex::PeekTok(stream);
    put prefix = token_prefix.Lex::Token::CONTENT;

    jump kind_put    ~ Str::Diff(prefix, "put") == 0;
    jump kind_return ~ Str::Diff(prefix, "return") == 0;
    jump kind_lab    ~ Str::Diff(prefix, "lab") == 0;
    jump kind_jump   ~ Str::Diff(prefix, "jump") == 0;
    jump kind_static ~ Str::Diff(prefix, "static") == 0;
    jump kind_inplace;


    lab kind_put; return Ast::Block::Local::MakeNode(
        Ast::Put::Parse(stream), 
        Ast::Block::Kind::PUT
    );

    lab kind_return; return Ast::Block::Local::MakeNode(
        Ast::Return::Parse(stream), 
        Ast::Block::Kind::RETURN
    );

    lab kind_lab; return Ast::Block::Local::MakeNode(
        Ast::Lab::Parse(stream), 
        Ast::Block::Kind::LAB
    );

    lab kind_jump; return Ast::Block::Local::MakeNode(
        Ast::Jump::Parse(stream), 
        Ast::Block::Kind::JUMP
    );

    lab kind_static; return Ast::Block::Local::MakeNode(
        Ast::Static::Parse(stream), 
        Ast::Block::Kind::STATIC
    );

    lab kind_inplace; return Ast::Block::Local::MakeNode(
        Ast::Inplace::Parse(stream), 
        Ast::Block::Kind::INPLACE
    );

}


fn Ast::Block::Parse(stream)
{
    Lex::Expect(stream, "{");

    put nodes = Dyn::Create();
    lab loop;
        jump done ~ (Lex::Peek(stream).0) == '}';

        Dyn::Push(nodes, Ast::Block::ParseNode(stream));

        jump loop;
    lab done;
    
    Lex::Expect(stream, "}");

    put meta = Chunk::New(Ast::Block);
    put meta.Ast::Block::NODES = nodes;
    return meta;
}



fn Ast::Block::Resolve(meta, ctx)
{
    put nodes = meta.Ast::Block::NODES;

    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(nodes);

        put node = Dyn::Ptr(nodes).i;
        put i = i + 1;

        Ast::Block::ResolveNode(node, ctx);

        jump loop;
    lab done;
}

fn Ast::Block::ResolveNode(node, ctx)
{
    put kind    = node.Ast::Block::Node::KIND;
    put subnode = node.Ast::Block::Node::MESA;

    jump kind_put     ~ kind == Ast::Block::Kind::PUT;
    jump kind_return  ~ kind == Ast::Block::Kind::RETURN;
    jump kind_jump    ~ kind == Ast::Block::Kind::JUMP;
    jump kind_static  ~ kind == Ast::Block::Kind::STATIC;
    jump kind_inplace ~ kind == Ast::Block::Kind::INPLACE;
    jump done;
    
    lab kind_put;     Ast::Put::Resolve(subnode, ctx);     jump done;
    lab kind_return;  Ast::Return::Resolve(subnode, ctx);  jump done;
    lab kind_jump;    Ast::Jump::Resolve(subnode, ctx);    jump done;
    lab kind_static;  Ast::Static::Resolve(subnode, ctx);  jump done;
    lab kind_inplace; Ast::Inplace::Resolve(subnode, ctx); jump done;
    
    lab done;
}


fn Ast::Block::Compile(meta, ctx)
{
    put nodes = meta.Ast::Block::NODES;

    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(nodes);

        put node = Dyn::Ptr(nodes).i;
        put i = i + 1;

        Ast::Block::CompileNode(node, ctx);

        jump loop;
    lab done;
}

fn Ast::Block::CompileNode(node, ctx)
{
    put kind    = node.Ast::Block::Node::KIND;
    put subnode = node.Ast::Block::Node::MESA;

    jump kind_put     ~ kind == Ast::Block::Kind::PUT;
    jump kind_return  ~ kind == Ast::Block::Kind::RETURN;
    jump kind_jump    ~ kind == Ast::Block::Kind::JUMP;
    jump kind_lab     ~ kind == Ast::Block::Kind::LAB;
    jump kind_static  ~ kind == Ast::Block::Kind::STATIC;
    jump kind_inplace ~ kind == Ast::Block::Kind::INPLACE;
    jump done;
    
    lab kind_put;     Ast::Put::Compile(subnode, ctx);     jump done;
    lab kind_return;  Ast::Return::Compile(subnode, ctx);  jump done;
    lab kind_jump;    Ast::Jump::Compile(subnode, ctx);    jump done;
    lab kind_lab;     Ast::Lab::Compile(subnode, ctx);     jump done;
    lab kind_static;  Ast::Static::Compile(subnode, ctx);  jump done;
    lab kind_inplace; Ast::Inplace::Compile(subnode, ctx); jump done;
    
    lab done;
}



fn Ast::Block::Collect(meta, ctx)
{
    put nodes = meta.Ast::Block::NODES;
    put sum = 0;

    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(nodes);

        put node = Dyn::Ptr(nodes).i;
        put n = Ast::Block::CollectNode(node, ctx);
        put sum = sum + n;

        put i = i + 1;
        jump loop;
    lab done;

    return sum;
}



fn Ast::Block::CollectNode(node, ctx)
{
    put kind    = node.Ast::Block::Node::KIND;
    put subnode = node.Ast::Block::Node::MESA;

    jump kind_put     ~ kind == Ast::Block::Kind::PUT;
    jump kind_static  ~ kind == Ast::Block::Kind::STATIC;
	return 0;
    
    lab kind_put;     return Ast::Put::Collect(subnode, ctx);
    lab kind_static;  return Ast::Static::Collect(subnode, ctx);
}


fn Ast::Block::Void(meta)
{
    put nodes = meta.Ast::Block::NODES;

    put i = 0;
    lab loop;
        jump done ~ i == Dyn::Size(nodes);

        put node = Dyn::Ptr(nodes).i;
        Ast::Block::VoidNode(node);
        put i = i + 1;

        jump loop;
    lab done;

    Dyn::Void(nodes);
    Chunk::Void(meta);
}
fn Ast::Block::VoidNode(node)
{
    put kind    = node.Ast::Block::Node::KIND;
    put subnode = node.Ast::Block::Node::MESA;
    Chunk::Void(node);

    jump kind_put     ~ kind == Ast::Block::Kind::PUT;
    jump kind_return  ~ kind == Ast::Block::Kind::RETURN;
    jump kind_jump    ~ kind == Ast::Block::Kind::JUMP;
    jump kind_lab     ~ kind == Ast::Block::Kind::LAB;
    jump kind_static  ~ kind == Ast::Block::Kind::STATIC;
    jump kind_inplace ~ kind == Ast::Block::Kind::INPLACE;
    jump done;
    
    lab kind_put;     Ast::Put::Void    (subnode); jump done;
    lab kind_return;  Ast::Return::Void (subnode); jump done;
    lab kind_jump;    Ast::Jump::Void   (subnode); jump done;
    lab kind_lab;     Ast::Lab::Void    (subnode); jump done;
    lab kind_static;  Ast::Static::Void (subnode); jump done;
    lab kind_inplace; Ast::Inplace::Void(subnode); jump done;
    
    lab done;
}


