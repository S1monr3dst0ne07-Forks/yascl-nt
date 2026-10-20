

seq Mem 
{
    // null pointer contant.
    // mostly semantic.
    NULL 
}


fn Mem::Set(buf, value, count)
{
    put i = 0;
    lab loop;
        put buf.i = value;
        put i = i + 1;
    jump loop ~ i < count;
}


// copy forwards
fn Mem::CpyF(dst, src, count)
{
    put i = 0;
    lab loop; jump done ~ i == count;
        put dst.i = src.i;
        put i = i + 1;
    jump loop; lab done;
}

// copy backwards
fn Mem::CpyB(dst, src, count)
{
    put i = count;
    lab loop; jump done ~ i == 0;
        put i = i - 1;
        put dst.i = src.i;
    jump loop; lab done;
}

// select copy direction
fn Mem::Cpy(dst, src, count)
{
    jump done ~ dst == src;
    jump fore ~ dst < src;
    jump back ~ dst > src;

    lab fore; Mem::CpyF(dst, src, count); jump done;
    lab back; Mem::CpyB(dst, src, count); jump done;

    lab done; 
}


fn Mem::ToBytes(dst, src, count)
{
    put i = 0;
    lab loop;
        put (dst+i).0 = (src.i) & 255;
        put i = i + 1;
    jump loop ~ i < count;
}

fn Mem::FromBytes(dst, src, count)
{
    put i = 0;
    lab loop;
        put (dst.i) = ((src+i).0) & 255;
        put i = i + 1;
    jump loop ~ i < count;
}


fn Mem::Offset(buffer, target, length, default)
    // like `memchr` but returns offset into buffer.
    // if not found, returns default.
{
    put offset = 0;
    lab loop;
        jump missing ~         offset  == length;
        jump found   ~ (buffer.offset) == target;

        put offset = offset + 1;
    jump loop;

lab missing; return default;
lab found;   return offset;
}

