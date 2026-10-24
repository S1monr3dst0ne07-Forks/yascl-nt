

// resources for further reading:
// - register decoder: https://intel.github.io/SDM/definition/Read_GPR.html


use "src/tmpl.yap"


seq IR::Op
{
    // reference exists to this node. noop.
    // address of node in binary will be written
    // to arg field by assembly pass.
    REF, 

    LOAD_INT,    // mov rax, arg
    LOAD_STRING, // mov rax, "arg"
    LOAD_STATIC, // mov rax, sizeof(arg)

    PUSH,     // push rax
    POP,      // pop  rax
    PUSH_AUX, // push rbx
    POP_AUX,  // pop  rbx

    // windows x64 calling-convention odd-ball operations
	    PUSH_RBP, // push rbp
	    POP_RBP,  // pop  rbp

	    LOAD_QUICK,  // mov rax, QUICK[arg]
	    STORE_QUICK, // pop QUICK[arg]

	    STORE_RSP , // mov [rsp+arg], rax
	    UPDATE_RBP, // lea rbp, [rsp+arg]

	    // these are used in the callee
	    // to adjust the stack frame once
	    // the local variable count is known.
	    RSP_DOWN, // sub rsp, arg
	    RSP_UP  , // add rsp, arg

    LOAD_LOCAL,  // mov rax, [rbp - arg]
    STORE_LOCAL, // mov [rbp - arg], rax

    RET,  // ret
    CALL, // call arg
    JMP,  // jmp arg
    JNZ,  // test rax, rax; jnz arg

    CALL_DLL, // call [arg]

    ADD, // add rax, rbx
    SUB, // sub rax, rbx
    DOT, // mov rax, [rax + rbx*8]
    DOUBLE_DOT, // lea rax, [rax + rbx*8]

    // cmp rax, rbx
    EQUAL,
    NOT_EQUAL,
    LESSER,
    GREATER,
    // movzx rax, cl

    MUL, // mul rbx
    DIV, // xor rdx, rdx; div rbx
    MOD, // xor rdx, rdx; div rbx; mov rax, rdx
    AND, // and rax, rbx
    OR,  // or  rax, rbx
    XOR, // xor rax, rbx
    SHR, // mov rcx, rbx; shr rax, cl
    SHL, // mov rcx, rbx; shl rax, cl

    // floating point operation.
    // argument specifies IR::FloatOp.
    FLOAT, 

    INDIRECT_STORE, // mov [rax], rbx
    OFFSET_STORE,   // mov [rbx + arg], rax
}

seq IR::FloatOp
{
	ADD,
	SUB,
	MUL,
	DIV,
	MOD,
	LESSER,
	GREATER,
}


seq IR::Node
{
    OPCODE,
    ARG,

    // relevant node address
    //  ref            -> defintion address
    //  call / jump    -> rel32 patch address
    //  string / const -> abs64 patch address
    //  etc ...
    ADDR, 
    
    PREV, // IR::Node
    NEXT, // IR::Node
}


fn IR::Emit(ctx, opcode, arg)
{
    put new = Chunk::New(IR::Node);
    put new.IR::Node::OPCODE = opcode;
    put new.IR::Node::ARG    = arg;
    put new.IR::Node::NEXT   = Mem::NULL;

    put iter = ctx.Ctx::Global::IR_ITER;

    put iter.IR::Node::NEXT = new;
    put new.IR::Node::PREV = iter;

    put ctx.Ctx::Global::IR_ITER = new;

    return new;
}

fn IR::Addr(ctx)
{
    put output = ctx.Ctx::Global::OUTPUT;
    return Dyn::Size(output) + Tmpl::Config::LOAD_ADDR;
}


fn IR::Push8(ctx, value)
{
    put output = ctx.Ctx::Global::OUTPUT;
    Dyn::Push(output, value & 255);
}
fn IR::PushREXW(ctx)
{
    IR::Push8(ctx, 72); // 0x48
}
fn IR::Push16(ctx, value)
{
    IR::Push8(ctx, value);
    IR::Push8(ctx, value >> 8);
}
fn IR::Push32(ctx, value)
{
    IR::Push8(ctx, value);
    IR::Push8(ctx, value >> 8);
    IR::Push8(ctx, value >> 16);
    IR::Push8(ctx, value >> 24);
}
fn IR::Push64(ctx, value)
{
    put i = 0;
    lab loop;
        IR::Push8(ctx, value);
        put value = value >> 8;
        put i = i + 1;
    jump loop ~ i < 8;
}

fn IR::PatchDyn(ctx, addr, value, bytes)
{
    put vaddr = addr - Tmpl::Config::LOAD_ADDR;
    put output = ctx.Ctx::Global::OUTPUT;

    put i = 0;
    lab loop;
        put Dyn::Ptr(output).(vaddr + i) = value & 255;
        put value = value >> 8;
        put i = i + 1;
    jump loop ~ i < bytes;
}

fn IR::Patch32(ctx, addr, value)
{
    IR::PatchDyn(ctx, addr, value, 4);
}
fn IR::Patch64(ctx, addr, value)
{
    IR::PatchDyn(ctx, addr, value, 8);
}

fn IR::PushCompare(ctx, cond)
{
    // cmp rax, rbx
    IR::PushREXW(ctx);
    IR::Push8(ctx, 57);
    IR::Push8(ctx, 216);

    // setcc cl
    IR::Push8(ctx, 15); // 0xf -> setcc
    IR::Push8(ctx, cond);
    IR::Push8(ctx, 193); // 0xc1 -> cl

    // movzx rax, cl
    IR::PushREXW(ctx);
    IR::Push8(ctx, 15);  // 0xf -> movzx
    IR::Push8(ctx, 182); // 0xb6 -> movzbq
    IR::Push8(ctx, 193); // 0xc1 -> cl

}

fn IR::PostPatch(ctx, patch_nodes)
    // normal patches.
{
    put node_i = 0;
    lab loop;
        jump done ~ node_i == Dyn::Size(patch_nodes);
        put node = Dyn::Ptr(patch_nodes).node_i;
        put node_i = node_i + 1;

        put opcode = node.IR::Node::OPCODE; 
        put arg    = node.IR::Node::ARG; 
        put addr   = node.IR::Node::ADDR;

        jump op_string ~ opcode == IR::Op::LOAD_STRING;
        jump op_static ~ opcode == IR::Op::LOAD_STATIC;
        jump op_jmp    ~ opcode == IR::Op::JMP;
        jump op_jmp    ~ opcode == IR::Op::JNZ;
        jump op_call   ~ opcode == IR::Op::CALL;
        jump loop;

        lab op_string;
            put base_ptr = IR::Addr(ctx);

            put i = 0;
            lab op_string_loop;
                put char = arg.i;
                put i = i + 1;

                IR::Push64(ctx, char);
            jump op_string_loop ~ char != '\0';

            IR::Patch64(ctx, addr, base_ptr);
            jump loop;

        lab op_static;
        	put base_ptr = IR::Addr(ctx);

        	put i = 0;
        	lab op_static_loop;
        		IR::Push64(ctx, 0);
        		put i = i + 1;
        	jump op_static_loop ~ i < arg;

        	IR::Patch64(ctx, addr, base_ptr);
        	jump loop;

        lab op_jmp;
        lab op_jnz;
        lab op_call;
            // subtract 4 for the rel32 value itself.
            // 4 * 8 = 32.

            put target_addr = arg.IR::Node::ADDR;
            put offset = (target_addr - addr) - 4;
            IR::Patch32(ctx, addr, offset);
            jump loop;


        jump loop;
    lab done;
}

fn IR::Asm(ctx)
{
    // list of nodes to be patched,
    // during post-assemble
    put patch_nodes  = Dyn::Create();

    Tmpl::Header(ctx);
    put iter = ctx.Ctx::Global::IR_ROOT;

lab loop;
    put iter = iter.IR::Node::NEXT;
    jump done ~ iter == Mem::NULL;
    put opcode = iter.IR::Node::OPCODE;
    put arg = iter.IR::Node::ARG;

    jump asm_ref      ~ opcode == IR::Op::REF;

    jump asm_load_int ~ opcode == IR::Op::LOAD_INT;
    jump asm_load_string ~ opcode == IR::Op::LOAD_STRING;
    jump asm_load_static ~ opcode == IR::Op::LOAD_STATIC;

    jump asm_load_local  ~ opcode == IR::Op::LOAD_LOCAL;
    jump asm_store_local ~ opcode == IR::Op::STORE_LOCAL;

    jump asm_push     ~ opcode == IR::Op::PUSH;
    jump asm_pop      ~ opcode == IR::Op::POP;
    jump asm_push_aux ~ opcode == IR::Op::PUSH_AUX;
    jump asm_pop_aux  ~ opcode == IR::Op::POP_AUX;

    // windows stuff
		jump asm_push_rbp    ~ opcode == IR::Op::PUSH_RBP;
//		jump asm_pop_rbp     ~ opcode == IR::Op::POP_RBP;

		jump asm_load_quick  ~ opcode == IR::Op::LOAD_QUICK;
		jump asm_store_quick ~ opcode == IR::Op::STORE_QUICK;

//		jump asm_store_rsp   ~ opcode == IR::Op::STORE_RSP;
//		jump asm_update_rbp  ~ opcode == IR::Op::UPDATE_RBP;
//
//		jump asm_rsp_down    ~ opcode == IR::Op::RSP_DOWN;
//		jump asm_rsp_up      ~ opcode == IR::Op::RSP_UP;

    //jump asm_ret  ~ opcode == IR::Op::RET;
    jump asm_call ~ opcode == IR::Op::CALL;
    jump asm_jmp  ~ opcode == IR::Op::JMP;
    jump asm_jnz  ~ opcode == IR::Op::JNZ;

    jump asm_add        ~ opcode == IR::Op::ADD;
    jump asm_sub        ~ opcode == IR::Op::SUB;
    jump asm_dot        ~ opcode == IR::Op::DOT;
    jump asm_double_dot ~ opcode == IR::Op::DOUBLE_DOT;
    jump asm_equal      ~ opcode == IR::Op::EQUAL;
    jump asm_not_equal  ~ opcode == IR::Op::NOT_EQUAL;
    jump asm_lesser     ~ opcode == IR::Op::LESSER;
    jump asm_greater    ~ opcode == IR::Op::GREATER;
    jump asm_mul        ~ opcode == IR::Op::MUL;
    jump asm_div        ~ opcode == IR::Op::DIV;
    jump asm_mod        ~ opcode == IR::Op::MOD;
    jump asm_and        ~ opcode == IR::Op::AND;
    jump asm_or         ~ opcode == IR::Op::OR;
    jump asm_xor        ~ opcode == IR::Op::XOR;
    jump asm_shr        ~ opcode == IR::Op::SHR;
    jump asm_shl        ~ opcode == IR::Op::SHL;

    jump asm_float      ~ opcode == IR::Op::FLOAT;

    jump asm_indirect_store ~ opcode == IR::Op::INDIRECT_STORE;
    jump asm_offset_store   ~ opcode == IR::Op::OFFSET_STORE;

	jump loop;
    Error::PrintError("INTERNAL: Invalid IR opcode %d", [opcode]);

lab asm_ref;
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    jump loop;    

lab asm_load_int;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 184); // B8 + 0 (0 -> rax)
    IR::Push64(ctx, arg);
    jump loop;

lab asm_load_local;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 139); // 0x8b
    IR::Push8(ctx, 133); // 0x85
    IR::Push32(ctx, (1 << 32) - arg);
    jump loop;
lab asm_store_local;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 137); // 0x89
    IR::Push8(ctx, 133); // 0x85
    IR::Push32(ctx, (1 << 32) - arg);
    jump loop;

lab asm_push;
    IR::Push8(ctx, 80); // 0x50 -> push rax
    jump loop;
lab asm_pop;
    IR::Push8(ctx, 88); // 0x58 -> pop rax
    jump loop;
lab asm_push_aux;
    IR::Push8(ctx, 83); // 0x53 -> push rbx
    jump loop;
lab asm_pop_aux;
    IR::Push8(ctx, 91); // 0x5b -> pop rbx
    jump loop;

lab asm_push_rbp;
	IR::Push8(ctx, 255);
	IR::Push8(ctx, 245);
	jump loop;


lab asm_call;
    IR::Push8(ctx, 232);
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    IR::Push32(ctx, 0); //rel32;
    Dyn::Push(patch_nodes, iter);
    jump loop;

lab asm_jmp;
    IR::Push8(ctx, 233);
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    IR::Push32(ctx, 0); //rel32
    Dyn::Push(patch_nodes, iter);
    jump loop;

lab asm_jnz;
    // test rax, rax
    IR::PushREXW(ctx);
    IR::Push8(ctx, 133);
    IR::Push8(ctx, 192);

    IR::Push8(ctx, 15);
    IR::Push8(ctx, 133);
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    IR::Push32(ctx, 0); //rel32
    Dyn::Push(patch_nodes, iter);
    jump loop;
    
    
lab asm_add; IR::PushREXW(ctx); IR::Push8(ctx, 1);  IR::Push8(ctx, 216); jump loop;
lab asm_sub; IR::PushREXW(ctx); IR::Push8(ctx, 41); IR::Push8(ctx, 216); jump loop;
lab asm_dot;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 139);
    IR::Push8(ctx, 4);
    IR::Push8(ctx, 216);
    jump loop;
lab asm_double_dot;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 141);
    IR::Push8(ctx, 4);
    IR::Push8(ctx, 216);
    jump loop;

lab asm_equal;     IR::PushCompare(ctx, 148); jump loop;
lab asm_not_equal; IR::PushCompare(ctx, 149); jump loop;
lab asm_lesser;    IR::PushCompare(ctx, 146); jump loop;
lab asm_greater;   IR::PushCompare(ctx, 151); jump loop;

lab asm_mul; 
    IR::PushREXW(ctx); IR::Push8(ctx, 247); IR::Push8(ctx, 227); // mul rbx
    jump loop;
lab asm_div; 
    IR::PushREXW(ctx); IR::Push8(ctx, 49);  IR::Push8(ctx, 210); // xor rdx, rdx
    IR::PushREXW(ctx); IR::Push8(ctx, 247); IR::Push8(ctx, 243); // div rbx
    jump loop;
lab asm_mod; 
    IR::PushREXW(ctx); IR::Push8(ctx, 49);  IR::Push8(ctx, 210); // xor rdx, rdx
    IR::PushREXW(ctx); IR::Push8(ctx, 247); IR::Push8(ctx, 243); // div rbx
    IR::PushREXW(ctx); IR::Push8(ctx, 137); IR::Push8(ctx, 208); // mov rax, rdx
    jump loop;

lab asm_and; IR::PushREXW(ctx); IR::Push8(ctx, 33); IR::Push8(ctx, 216); jump loop;
lab asm_or ; IR::PushREXW(ctx); IR::Push8(ctx,  9); IR::Push8(ctx, 216); jump loop;
lab asm_xor; IR::PushREXW(ctx); IR::Push8(ctx, 49); IR::Push8(ctx, 216); jump loop;

lab asm_shr; 
    IR::PushREXW(ctx); IR::Push8(ctx, 137); IR::Push8(ctx, 217); // mov rcx, rbx
    IR::PushREXW(ctx); IR::Push8(ctx, 211); IR::Push8(ctx, 232); // shr rax, cl
    jump loop;
lab asm_shl;
    IR::PushREXW(ctx); IR::Push8(ctx, 137); IR::Push8(ctx, 217); // mov rcx, rbx
    IR::PushREXW(ctx); IR::Push8(ctx, 211); IR::Push8(ctx, 224); // shl rax, cl
    jump loop;

lab asm_load_quick;
    jump asm_load_quick_rcx ~ arg == 0;
    jump asm_load_quick_rdx ~ arg == 1;
    jump asm_load_quick_r8  ~ arg == 2;
    jump asm_load_quick_r9  ~ arg == 3;
    Error::Error("PANIC: INTERNAL ERROR, DO NOT RUN EXECUTABLE");

    lab asm_load_quick_rcx; IR::Push8(ctx, 72); IR::Push8(ctx, 137); IR::Push8(ctx, 192); jump loop;
    lab asm_load_quick_rdx; IR::Push8(ctx, 72); IR::Push8(ctx, 137); IR::Push8(ctx, 192); jump loop;
    lab asm_load_quick_r8 ; IR::Push8(ctx, 76); IR::Push8(ctx, 137); IR::Push8(ctx, 192); jump loop;
    lab asm_load_quick_r9 ; IR::Push8(ctx, 76); IR::Push8(ctx, 137); IR::Push8(ctx, 192); jump loop;

lab asm_store_quick;
    jump asm_store_quick_rcx ~ arg == 0;
    jump asm_store_quick_rdx ~ arg == 1;

    IR::Push8(ctx, 65);
    jump asm_store_quick_r8 ~ arg == 2;
    jump asm_store_quick_r9 ~ arg == 3;
    Error::Error("PANIC: INTERNAL ERROR, DO NOT RUN EXECUTABLE");

    lab asm_store_quick_rcx; IR::Push8(ctx, 89); jump loop;
    lab asm_store_quick_rdx; IR::Push8(ctx, 91); jump loop;

    lab asm_store_quick_r8 ; IR::Push8(ctx, 88); jump loop;
    lab asm_store_quick_r9 ; IR::Push8(ctx, 89); jump loop;

lab asm_indirect_store;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 137);
    IR::Push8(ctx, 24);
    jump loop;
lab asm_offset_store;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 137); // mov m, r
    IR::Push8(ctx, 131); // ModR/M 0x83 -> [EBX + disp32]
    IR::Push32(ctx, arg);
    jump loop;

lab asm_syscall;
    IR::Push8(ctx, 15);
    IR::Push8(ctx, 5);
    jump loop;

lab asm_load_string;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 184);
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    IR::Push64(ctx, 0);

    Dyn::Push(patch_nodes, iter);
    jump loop;

lab asm_load_static;
    IR::PushREXW(ctx);
    IR::Push8(ctx, 184);
    put iter.IR::Node::ADDR = IR::Addr(ctx);
    IR::Push64(ctx, 0);

    Dyn::Push(patch_nodes, iter);
    jump loop;


lab asm_float;
	IR::AsmFloat(ctx, iter);
	jump loop;

lab done;
    IR::PostPatch (ctx, patch_nodes);
    Dyn::Void(patch_nodes);

    Tmpl::Finalize(ctx);
}



fn IR::AsmFloat(ctx, iter)
{
	// warning! nasty SSE2 stuff ahead.
    put arg = iter.IR::Node::ARG;

	// mov xmm0, rax
	IR::Push8(ctx, 102); 
	IR::PushREXW(ctx);
	IR::Push8(ctx, 15);
	IR::Push8(ctx, 110);
	IR::Push8(ctx, 192);

	// mov xmm1, rbx
	IR::Push8(ctx, 102); 
	IR::PushREXW(ctx);
	IR::Push8(ctx, 15);
	IR::Push8(ctx, 110);
	IR::Push8(ctx, 203);

	// modulo does not use the common operation prefix,
	// because it is composed from multiple instructions.
	jump asm_mod ~ arg == IR::FloatOp::MOD;

	// common prefix for operations
	IR::Push8(ctx, 242);
	IR::Push8(ctx, 15);

	jump asm_add ~ arg == IR::FloatOp::ADD;
	jump asm_sub ~ arg == IR::FloatOp::SUB;
	jump asm_mul ~ arg == IR::FloatOp::MUL;
	jump asm_div ~ arg == IR::FloatOp::DIV;
	jump asm_cmp ~ arg == IR::FloatOp::LESSER;
	jump asm_cmp ~ arg == IR::FloatOp::GREATER;

	lab asm_add; IR::Push8(ctx,  88); jump done; // addsd xmm0, xmm1
	lab asm_sub; IR::Push8(ctx,  92); jump done; // subsd xmm0, xmm1
	lab asm_mul; IR::Push8(ctx,  89); jump done; // mulsd xmm0, xmm1
	lab asm_div; IR::Push8(ctx,  94); jump done; // divsd xmm0, xmm1
	lab asm_cmp; IR::Push8(ctx, 194); jump done; // cmpsd xmm0, xmm1, op

	lab asm_mod;
		// this is, unfortunately, rather complicated.
		// this code right here, is probably the most,
		// niche and complicated in the entire compiler.
		//   a ~% b = a - (trunc(a / b) * b);

        //   0: 66 0f 28 d0        movapd xmm2,xmm0
        //   4: f2 0f 5e d1        divsd  xmm2,xmm1
        //   8: 66 0f 3a 0b d2 03  roundsd xmm2,xmm2, _MM_FROUND_TO_ZERO
        //   e: f2 0f 59 d1        mulsd  xmm2,xmm1
        //  12: f2 0f 5c c2        subsd  xmm0,xmm2
        //   (_MM_FROUND_TO_ZERO = 0x03)

        IR::Push8(ctx, 102); // 0x66
        IR::Push8(ctx, 15);  // 0x0f
        IR::Push8(ctx, 40);  // 0x28
        IR::Push8(ctx, 208); // 0xd0

        IR::Push8(ctx, 242); // 0xf2
        IR::Push8(ctx, 15);  // 0x0f
        IR::Push8(ctx, 94);  // 0x53
        IR::Push8(ctx, 209); // 0xd1

        IR::Push8(ctx, 102); // 0x66
        IR::Push8(ctx, 15);  // 0x0f
        IR::Push8(ctx, 58);  // 0x3a
        IR::Push8(ctx, 11);  // 0x0b
        IR::Push8(ctx, 210); // 0xd2
        IR::Push8(ctx, 03);  // 0x03

        IR::Push8(ctx, 242); // 0xf2
        IR::Push8(ctx, 15);  // 0x0f
        IR::Push8(ctx, 89);  // 0x59
        IR::Push8(ctx, 209); // 0xd1

        IR::Push8(ctx, 242); // 0xf2
        IR::Push8(ctx, 15);  // 0x0f
        IR::Push8(ctx, 92);  // 0x5c
        IR::Push8(ctx, 194); // 0x0f

		jump skip_suffixing;

	lab done;

	// common ModRM: 0xc1
	//  addr=2 -> direct
	//  reg=0, r/m=1
	IR::Push8(ctx, 193);

	// operator suffix for compare 
	jump op_lt ~ arg == IR::FloatOp::LESSER;
	jump op_gt ~ arg == IR::FloatOp::GREATER;
	jump op_done;

	// https://www.felixcloutier.com/x86/cmpsd
	lab op_lt; IR::Push8(ctx, 1);  jump op_done;
	lab op_gt; IR::Push8(ctx, 14); jump op_done;
	lab op_done;

lab skip_suffixing;

	// mov rax, xmm0
	IR::Push8(ctx, 102); 
	IR::PushREXW(ctx);
	IR::Push8(ctx, 15);
	IR::Push8(ctx, 126);
	IR::Push8(ctx, 192);
}


