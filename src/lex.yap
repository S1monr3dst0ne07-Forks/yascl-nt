

use "lib/fs.yap"
use "lib/dyn.yap"
use "lib/bool.yap"

use "src/error.yap"


seq Lex::Kind
{
    NONE, // initial fsm state
    IDEN,
    BLOCK_OPEN,
    BLOCK_CLOSE,
    PAREN_OPEN,
    PAREN_CLOSE,
    ARRAY_OPEN,
    ARRAY_CLOSE,
    END_OF_STATEMENT,
    DOUBLE_QUOTE,
    SINGLE_QUOTE,
    FORMAT,
    SYMBOL,
}

fn Lex::DecodeKind(kind)
{
	jump skip_NONE 	        	~ kind != Lex::Kind::NONE;              return "<NONE>"; lab skip_NONE ;
	jump skip_IDEN	        	~ kind != Lex::Kind::IDEN;              return "identifier"; lab skip_IDEN;
	jump skip_BLOCK_OPEN		~ kind != Lex::Kind::BLOCK_OPEN;        return "{"; lab skip_BLOCK_OPEN;
	jump skip_BLOCK_CLOSE		~ kind != Lex::Kind::BLOCK_CLOSE;       return "}"; lab skip_BLOCK_CLOSE;
	jump skip_PAREN_OPEN		~ kind != Lex::Kind::PAREN_OPEN;        return "("; lab skip_PAREN_OPEN;
	jump skip_PAREN_CLOSE		~ kind != Lex::Kind::PAREN_CLOSE;       return ")"; lab skip_PAREN_CLOSE;
	jump skip_ARRAY_OPEN		~ kind != Lex::Kind::ARRAY_OPEN;        return "["; lab skip_ARRAY_OPEN;
	jump skip_ARRAY_CLOSE		~ kind != Lex::Kind::ARRAY_CLOSE;       return "]"; lab skip_ARRAY_CLOSE;
	jump skip_END_OF_STATEMENT	~ kind != Lex::Kind::END_OF_STATEMENT;  return ";"; lab skip_END_OF_STATEMENT;
	jump skip_DOUBLE_QUOTE	    ~ kind != Lex::Kind::DOUBLE_QUOTE;      return "string"; lab skip_DOUBLE_QUOTE;
	jump skip_SINGLE_QUOTE	    ~ kind != Lex::Kind::SINGLE_QUOTE;      return "character literal"; lab skip_SINGLE_QUOTE;
	jump skip_FORMAT	        ~ kind != Lex::Kind::FORMAT;            return "formatting"; lab skip_FORMAT;
	jump skip_SYMBOL	        ~ kind != Lex::Kind::SYMBOL;            return "symbol"; lab skip_SYMBOL;
}




fn Lex::Get(char)
{
    // isalphanum(char)
    jump iden ~ (('a' - 1) < char) & (('z' + 1) > char);
    jump iden ~ (('A' - 1) < char) & (('Z' + 1) > char);
    jump iden ~ Str::IsDigit(char);

    jump iden ~ char == '_';
    jump iden ~ char == ':';

    jump block_open  ~ char == '{';
    jump block_close ~ char == '}';

    jump paren_open  ~ char == '(';
    jump paren_close ~ char == ')';

    jump array_open  ~ char == '[';
    jump array_close ~ char == ']';

    jump end_of_statement ~ char == ';';
    jump double_quote     ~ char == 34; // double quote
    jump single_quote     ~ char == 39; // single quote

    jump format ~ char == 32; // space
    jump format ~ char == 13; // carriage return
    jump format ~ char == '\n';
    jump format ~ char == '\t';

    jump symbol;
    

    lab iden;               return Lex::Kind::IDEN;
    lab block_open;         return Lex::Kind::BLOCK_OPEN;
    lab block_close;        return Lex::Kind::BLOCK_CLOSE;
    lab paren_open;         return Lex::Kind::PAREN_OPEN;
    lab paren_close;        return Lex::Kind::PAREN_CLOSE;
    lab array_open;         return Lex::Kind::ARRAY_OPEN;
    lab array_close;        return Lex::Kind::ARRAY_CLOSE;
    lab end_of_statement;   return Lex::Kind::END_OF_STATEMENT;
    lab double_quote;       return Lex::Kind::DOUBLE_QUOTE;
    lab single_quote;       return Lex::Kind::SINGLE_QUOTE;
    lab format;             return Lex::Kind::FORMAT;
    lab symbol;             return Lex::Kind::SYMBOL;
    
}


seq Lex::Info
{
    LINENO,  // Int
    PATH,    // Str
}

seq Lex::Token
{
    CONTENT, // Str
    KIND,    // Lex::Kind
    INFO,    // Lex::Info
}


seq Lex::Streamer
{
    TOKENS, // Dyn<Lex::Token>
    LIMIT,  // Int
    INDEX,  // Int
}


fn Lex::LookTok(stream, offset)
{
    return
        (stream.Lex::Streamer::TOKENS).
        ((stream.Lex::Streamer::INDEX) + offset);
}
fn Lex::PeekTok(stream)
{
    return Lex::LookTok(stream, 0);
}
fn Lex::PopTok(stream)
{
    put tok = Lex::PeekTok(stream);
    put (stream.Lex::Streamer::INDEX) = (stream.Lex::Streamer::INDEX) + 1;
    return tok;
}

fn Lex::Peek(stream)
{
    return Lex::PeekTok(stream).Lex::Token::CONTENT;
}
fn Lex::Pop(stream)
{
    return Lex::PopTok(stream).Lex::Token::CONTENT;
}

fn Lex::Done(stream)
{
    put index = stream.Lex::Streamer::INDEX;
    put limit = stream.Lex::Streamer::LIMIT;

    return index == limit;
}

fn Lex::Info(stream)
{
    put token = Lex::PeekTok(stream);
    put info = token.Lex::Token::INFO;
    put copy = Chunk::New(Lex::Info);
    Mem::Cpy(copy, info, Lex::Info);
    return copy;
}

fn Lex::PopCheck(stream, kind)
{
    put token = Lex::PopTok(stream);
    jump error ~ (token.Lex::Token::KIND) != kind;
        return token.Lex::Token::CONTENT;
    lab error;
        put info = token.Lex::Token::INFO;
        Error::LexError(info, "Expected kind `%s` got `%s`", [
            Lex::DecodeKind(kind),
            Lex::DecodeKind(token.Lex::Token::KIND),
        ]);
}
fn Lex::Expect(stream, content)
{
    put token = Lex::PopTok(stream);
    jump good ~ Str::Diff(token.Lex::Token::CONTENT, content) == 0;
        put info = token.Lex::Token::INFO;
        Error::LexError(info, "Expected `%s` got `%s`", [
            content,
            token.Lex::Token::CONTENT,
        ]);
    lab good;
}



fn Lex::Tokenize(path)
{
    put src = FS::Read(path);
    put tokens = Dyn::Create();


    put state_comment = Bool::FALSE;
    put state_string  = Bool::FALSE;
    put state_char    = Bool::FALSE;
    put lineno = 1;
    put last = Lex::Kind::NONE;

    static 4096 ~ buffer;
    put iter = buffer;
    
    put i = 0;
    lab loop;
        put char = src.i;
        jump done ~ char == '\0';
        put i = i + 1;
        put kind = Lex::Get(char);


        put state_comment = state_comment | ((Str::Diff(buffer, "//") == 0) & Bool::Not(state_string));
        put state_string  = state_string  ^ (last == Lex::Kind::DOUBLE_QUOTE);
        put state_char    = state_char    ^ (last == Lex::Kind::SINGLE_QUOTE);

        // state transition. or must trigger on symbol.
        put transition = (kind != last)
                       | (last == Lex::Kind::BLOCK_OPEN)
                       | (last == Lex::Kind::BLOCK_CLOSE)
                       | (last == Lex::Kind::PAREN_OPEN)
                       | (last == Lex::Kind::PAREN_CLOSE)
                       | (last == Lex::Kind::ARRAY_OPEN)
                       | (last == Lex::Kind::ARRAY_CLOSE);


        // can emit?
        put unlocked = Bool::Not(state_comment)
                     & Bool::Not(state_string)
                     & Bool::Not(state_char);

        // can emit!
        put emit = transition & unlocked;


        jump skip_emit ~ Bool::Not(emit);
            jump skip_push ~ last == Lex::Kind::NONE;
            jump skip_push ~ last == Lex::Kind::FORMAT;

                put info = Chunk::New(Lex::Info);
                put info.Lex::Info::LINENO = lineno;
                put info.Lex::Info::PATH   = path;

                put token = Chunk::New(Lex::Token);
                put token.Lex::Token::CONTENT = Str::Copy(buffer);
                put token.Lex::Token::KIND    = last;
                put token.Lex::Token::INFO    = info;

                Dyn::Push(tokens, token);
            lab skip_push;
            put iter = buffer;
        lab skip_emit;


        jump skip_comment_end ~ char != '\n';
        jump skip_comment_end ~ Bool::Not(state_comment);
            put iter = buffer;
            put state_comment = Bool::FALSE;
            put state_string  = Bool::FALSE;
            put state_char    = Bool::FALSE;
        lab skip_comment_end;

        jump skip_newline ~ char != '\n';
            put lineno = lineno + 1;
        lab skip_newline;

        // do not buffer/emit quotes. (annoying to filter out later)
        jump skip_write ~ kind == Lex::Kind::SINGLE_QUOTE;
        jump skip_write ~ kind == Lex::Kind::DOUBLE_QUOTE;
            put iter.0 = char;
            put iter = iter : 1;
            put iter.0 = '\0'; //make buffer valid string
        lab skip_write;

        put last = kind;
    jump loop;
    lab done;

    Chunk::Void(src);

    put stream = Chunk::New(Lex::Streamer);
    put stream.Lex::Streamer::TOKENS = Dyn::Ptr(tokens);
    put stream.Lex::Streamer::LIMIT  = Dyn::Size(tokens);
    put stream.Lex::Streamer::INDEX  = 0;

    Chunk::Void(tokens);
    return stream;
}



fn Lex::VoidStream(stream)
{
    put toks  = stream.Lex::Streamer::TOKENS;
    put limit = stream.Lex::Streamer::LIMIT;

    put i = 0;
    lab loop;
        Lex::VoidToken(toks.i);
        put i = i + 1;
    jump loop ~ i < limit;

    Chunk::Void(toks);
    Chunk::Void(stream);
}

fn Lex::VoidInfo(info)
{
    Chunk::Void(info);
}

fn Lex::VoidToken(token)
{
    Lex::VoidInfo(token.Lex::Token::INFO);
    Chunk::Void(token.Lex::Token::CONTENT);
    Chunk::Void(token);
}



