

fn Utils::Unescape(content)
    // in-place unescape string.
    // only supports most common control codes.
{
    put i = 0;
    put offset = 0;

    lab loop;
        put char = content.i;

        jump done    ~ char == '\0';
        jump control ~ char == '\\';

        put content.(i-offset) = char;
        put i = i + 1;
        jump loop;

    lab control;
        put subchar = content.(i+1);

        jump newline    ~ subchar == 'n';
        jump car_return ~ subchar == 'r';
        jump tabulate   ~ subchar == 't';
        jump terminator ~ subchar == '0';
        jump mesa       ~ subchar == '\\';
            //unknown control sequence.
            //ignore backslash.
        jump loop; 

    lab newline     ; put content.(i-offset) = '\n'; jump control_done;
    lab car_return  ; put content.(i-offset) = '\r'; jump control_done;
    lab tabulate    ; put content.(i-offset) = '\t'; jump control_done;
    lab terminator  ; put content.(i-offset) = '\0'; jump control_done;
    lab mesa        ; put content.(i-offset) = '\\'; jump control_done;

    lab control_done;
        put offset = offset + 1;
        put i = i + 2;
        jump loop;

    lab done;
        put content.(i-offset) = '\0';
        return content;
}



fn Utils::FloatEncode(real, frac, frac_len)
{
	// this routine is no efficient.
	// it is implemented like this for ease of understanding.
	// it is NOT intended as a high-performance double parser.

	// the algorithm can be divided into 3 steps:
	// 1. scale decimal literal to integer, keep track of negative exponent
	// 2. convert negative base 10 exponent to base 2
	// 3. normalize and encode floating point number

	// --- step 1 scale decimal ---

	// base 10 exponent must be big enough
	// for frac to fit. there may be leading
	// zero in frac so only trust frac_len!
	put base10_exp = frac_len;

	// compute scaling factor  
	put base10_factor = 1;
	put i = 0;
	lab scale_loop;
		put base10_factor = base10_factor * 10;
		put i = i + 1;
	jump scale_loop ~ i < base10_exp;

	// compute final scaled decimal
	put base10_value = (real * base10_factor) + frac;
	jump zero ~ base10_value == 0; // zero is special (just like me Owo)

	// --- step 2 convert exponent ---

	// find biggest possbile base 2 exponent,
	// to reduce error during scaling-down by base 10 factor.
	put base2_exp = 0;
	lab find_loop;
		put base2_exp = base2_exp + 1;
	jump find_loop ~ ((base10_value << base2_exp) >> 63) == 0;

	// compute corrected base 2 value
	put base2_value = (base10_value << base2_exp) / base10_factor;

	// --- step 3 normalize and encode ---

	// align number to end of 64 bit register
	// and cut off leading bit. (ieee does not store the leading bit)
	lab norm_loop;
		put msb = base2_value >> 63;
		put base2_value = base2_value << 1;
		put base2_exp   = base2_exp + 1;
	jump norm_loop ~ msb == 0;

	// move into first 52 bits
	put man = base2_value >> 12;
	put exp = base2_exp    - 12;

	// invert and bias exponent
	put exp = 1023 + (52 - exp);

	// assemble final value
	return (exp << 52) | man;

lab zero;
	// incidentally (or intentionally idk)
	return 0;
}



fn Utils::SliceParameters(params, quick_params, stack_params)
{
	put i = 0;
	lab loop;
		jump done ~ i == Dyn::Size(params);
		put param = Dyn::Ptr(params).i;
		put i = i + 1;

		jump quick ~ i < 5;
		jump stack;

	lab quick; Dyn::Push(quick_params, param); jump loop;
	lab stack; Dyn::Push(stack_params, param); jump loop;

lab done;
}

