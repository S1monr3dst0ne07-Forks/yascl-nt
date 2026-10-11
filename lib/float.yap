
// "BLESSED BE YE,
//    who read this file and have
//    no idea how it works." - me

// "CURSED BE YE,
//    who have to maintain this,
//    haha lol." - idk, satan or smth

use "lib/str.yap"


fn Float::FromInt(man)
	// warning! slow!
	// don't use for constants.
{
	jump zero ~ man == 0;

	put exp = 0;
	lab loop;
		put msb = man >> 63;
		put exp = exp + 1;
		put man = man << 1;
	jump loop ~ msb == 0;

	return (man >> 12) | ((1023 + 64 - exp) << 52);

lab zero;
	return 0;
}

fn Float::ToInt(float)
{
	put exp_raw = (float >> 52) & ((1 << 11) - 1);
	put man = (float & ((1 << 52) - 1)) | (1 << 52);

	put exp_shift = (52 - (exp_raw - 1023));
	jump subnormal ~ exp_shift > 255;
	return man >> exp_shift;

lab subnormal;
	return 0;
}

fn Float::ToSigned(float)
{
	put sign = float >> 63;
	put int = Float::ToInt(float);
	jump pos ~ sign == 0;
		put int = 0 - int;
	lab pos;
	return int;
}


fn Float::IntPow(base, power)
{
	jump pos ~ (power >> 63) == 0;
		put power = 0 - power;
		put base  = (1.0) ~/ base;
	lab pos;

	put res = 1.0;
	lab loop; jump done ~ power == 0;
		put power = power - 1;
		put res   = res ~* base;
	jump loop; lab done;

	return res;
}

fn Float::ToStr(float, prec)
{
	static 256 ~ buffer;

	// real part
	put real = Float::ToInt(float);
	put str = Str::FromIntBase(real, 10);
	put len1 = Str::Len(str);
	Mem::Cpy(buffer, str, len1);

	// radix
	put buffer.len1 = '.';
	put float = float ~- Float::FromInt(real);

	// frac part
	put frac = Float::ToInt(float ~* Float::IntPow(10.0, prec));
	put str = Str::FromIntBase(frac, 10);
	put len2 = Str::Len(str);
	Mem::Cpy(buffer : (len1 + 1), str, len2);

	put buffer.(len1 + len2 + 1)= '\0';
	return buffer;
}


