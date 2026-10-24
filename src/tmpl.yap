
use "src/ctx.yap"
use "src/ir.yap"


seq Tmpl::Config
{
    LOAD_ADDR   = 4194304, // 0x400000
}

fn Tmpl::Header(ctx)
{
	// --- DOS MZ header ---
	IR::Push8(ctx, 'M');
	IR::Push8(ctx, 'Z');

	// zero are fine apparently
	put i = 0;
	lab dos_loop;
		IR::Push8(ctx, 0);
		put i = i + 1;
	jump dos_loop ~ i < 58;

	// e_lfanew = 0x40
	IR::Push32(ctx, 64);

	// --- COFF header ---
	IR::Push8(ctx, 'P');
	IR::Push8(ctx, 'E');
	IR::Push8(ctx, 0);
	IR::Push8(ctx, 0);

	IR::Push16(ctx, 34404); // machine          	= 0x8664 (haha get it?)
	IR::Push16(ctx,     1); // numberOfSection      = 1
	IR::Push32(ctx,     0); // timeDateStamp        = 0
	IR::Push32(ctx,     0); // pointerToSymbolTable = 0
	IR::Push32(ctx,     0); // numberOfSymbol       = 0
	IR::Push16(ctx,   128); // sizeOfOptionalHeader = 128 
							// (only export and import data entries are included)
	IR::Push16(ctx,    47); // 0x2f, copied from fasm, idk, should work

	// --- PE64 "optional" header ---
	IR::Push16(ctx,   523); // magic                       = PE_64BIT
	IR::Push8 (ctx,     0); // majorLinkerVersion          = 0
	IR::Push8 (ctx,     0); // minorLinkerVersion          = 0
	IR::Push32(ctx,     0); // sizeOfCode                  = ?
	IR::Push32(ctx,     0); // sizeOfInitializedData       = ?
	IR::Push32(ctx,     0); // sizeOfUninitializedData     = ?
	IR::Push32(ctx,  4096); // addressOfEntryPoint         = 0x1000
	IR::Push32(ctx,  4096); // baseOfCode                  = 0x1000
	IR::Push64(ctx,  Tmpl::Config::LOAD_ADDR
						 ); // imageBase                   = load address
	IR::Push32(ctx,  4096); // sectionAlignment            = 0x1000
	IR::Push32(ctx,   512); // fileAlignment               = 0x200
	IR::Push16(ctx,     0); // majorOperatingSystemVersion = 0
	IR::Push16(ctx,     0); // minorOperatingSystemVersion = 0
	IR::Push16(ctx,     0); // majorImageVersion           = 0
	IR::Push16(ctx,     0); // minorImageVersion           = 0
	IR::Push16(ctx,     0); // majorSubsystemVersion       = 0
	IR::Push16(ctx,     0); // minorSubsystemVersion       = 0
	IR::Push32(ctx,     0); // win32VersionValue           = 0

	// W - wery
	// I - insidiously
	// N - narcissist
	// D - disk
	// O - operating
	// W - (why!?!?!!)
	// S - system

	IR::Push32(ctx,     0); // sizeOfImage  = ... to be patched
	IR::Push32(ctx,   512); // sizeOfHeader = 0x200

	IR::Push32(ctx,       0); // checkSum            = ? (doesn't matter)
	IR::Push16(ctx,       3); // subsystem           = IMAGE_SUBSYSTEM_WINDOWS_CUI
	IR::Push16(ctx,       0); // dllCharacteristics  = 0
	IR::Push64(ctx, 1000000); // sizeOfStackReserve  = 1 MB
	IR::Push64(ctx,    4096); // sizeOfStackCommit   = 4 KB
	IR::Push64(ctx, 1000000); // sizeOfHeapReserve   = 1 MB
	IR::Push64(ctx,    4096); // sizeOfHeapCommit    = 4 KB
	IR::Push32(ctx,       0); // loaderFlags         = 0
	IR::Push32(ctx,       2); // numberOfRvaAndSizes = 2 (number of follwing entries)

	// exportTableEntry, not present
	IR::Push32(ctx, 0); // virtualAddress = 0
	IR::Push32(ctx, 0); // size           = 0

	// importTableEntry, to be patched...
	IR::Push32(ctx, 0); // virtualAddress = ...
	IR::Push32(ctx, 0); // size           = ...

	// --- "main" section header ---
	IR::Push8 (ctx, '.');
	IR::Push8 (ctx, 't');
	IR::Push8 (ctx, 'e');
	IR::Push8 (ctx, 'x');
	IR::Push8 (ctx, 't');
	IR::Push8 (ctx,   0);
	IR::Push8 (ctx,   0);
	IR::Push8 (ctx,   0);

	// memory and file images are the same (because i'm lazy)
	IR::Push32(ctx,          0); // virtualSize          = ... to be patched
	IR::Push32(ctx,       4096); // virtualAddress       = 0x1000
	IR::Push32(ctx,          0); // sizeOfRawData        = ... to be patched
	IR::Push32(ctx,       4096); // pointerToRawData     = 0x1000
	IR::Push32(ctx,          0); // pointerToRelocations = 0
	IR::Push32(ctx,          0); // pointerToLineNumbers = 0
	IR::Push16(ctx,          0); // numberOfRelocations  = 0
	IR::Push16(ctx,          0); // numberOfLineNumbers  = 0
	IR::Push32(ctx, 3758096384); // characteristics      = IMAGE_SCN_MEM_{READ, WRITE, EXECUTE}


	// --- pad to 0x1000 start of main section ---
	put missing = 4096 - (IR::Addr(ctx) - Tmpl::Config::LOAD_ADDR);

	put i = 0;
	lab pad_loop;
		// padding!!! over and over and over!!! OwO
		IR::Push8(ctx, 0);

		put i = i + 1;
	jump pad_loop ~ i < missing;

}


fn Tmpl::Finalize(ctx)
{
	put image_size_raw    = IR::Addr(ctx) - Tmpl::Config::LOAD_ADDR;
	put main_section_size = image_size_raw - 4096;

	// patch virtualSize and sizeOfRawData
	IR::Patch32(ctx, 224 + Tmpl::Config::LOAD_ADDR, main_section_size);
	IR::Patch32(ctx, 232 + Tmpl::Config::LOAD_ADDR, main_section_size);

	// patch sizeOfImage
	put image_size_aligned = (image_size_raw + 4095) & (0 - 4096);
	IR::Patch32(ctx, 144 + Tmpl::Config::LOAD_ADDR, image_size_aligned);
}


fn Tmpl::ImportTable(ctx, patch_dll)
{
	// YE, WHO ENTER HERE!
	//     ABANDON ALL HOPE.

	put binds = ctx.Ctx::Global::BINDS;
	
	// patch tables. name -> patch address
	put patch_dll_names    = HT::Create();
	put patch_proc_names   = HT::Create(); 
	put patch_proc_entries = HT::Create();

	// build map from dll name to dll procedure names.
	put dll_to_procs = HT::Create();
	put it = HT::MakeIter(binds);
	lab map_loop;
		jump map_done ~ Bool::Not(HT::Next(it));
		put proc_name = it.HT::Iter::KEY;
		put dll_name  = it.HT::Iter::VALUE;

		jump map_skip_create ~ HT::Has(dll_to_procs, dll_name);
			HT::Set(dll_to_procs, dll_name, Dyn::Create());
		lab map_skip_create;

		put proc_list = HT::Get(dll_to_procs, dll_name);
		Dyn::Push(proc_list, proc_name);

		jump map_loop;
	lab map_done;

	// import table base address
	put import_table_base = IR::Addr(ctx);

	// generate import directory table
	put it = HT::MakeIter(dll_to_procs);
	lab dir_loop;
		jump dir_done ~ Bool::Not(HT::Next(it));
		put dll_name = it.HT::Iter::KEY;

		IR::Push32(ctx, 0); // importLookupTableRVA = 0
		IR::Push32(ctx, 0); // timeDateStamp 		= 0
		IR::Push32(ctx, 0); // forwarderChain       = 0

		HT::Set(patch_dll_names   , dll_name, IR::Addr(ctx));
		IR::Push32(ctx, 0); // nameRVA               = ...
		HT::Set(patch_proc_entries, dll_name, IR::Addr(ctx));
		IR::Push32(ctx, 0); // importAddressTableRVA = ...

		jump dir_loop;
	lab dir_done;

	// import directory table terminator
	IR::Push32(ctx, 0);	IR::Push32(ctx, 0);	IR::Push32(ctx, 0);	IR::Push32(ctx, 0);	IR::Push32(ctx, 0);

	// the import table size end here.
	// apparently, windows uses the size to compute the number
	// of entires, which makes no sense, but ok.
	put import_table_size = IR::Addr(ctx) - import_table_base;
	put import_table_rva  = import_table_base - Tmpl::Config::LOAD_ADDR;


	// generate dll names
	put it = HT::MakeIter(patch_dll_names);
	lab dll_name_loop;
		jump dll_name_done ~ Bool::Not(HT::Next(it));
		put name_string = it.HT::Iter::KEY;
		put patch_addr  = it.HT::Iter::VALUE;

		put rva = IR::Addr(ctx) - Tmpl::Config::LOAD_ADDR;
		IR::Patch32(ctx, patch_addr, rva);

		put i = 0;
		lab dll_name_str_loop;
			IR::Push8(ctx, name_string.i);
			put i = i + 1;
		jump dll_name_str_loop ~ name_string.i;
		IR::Push8(ctx, 0); // string terminator

		jump dll_name_loop;
	lab dll_name_done;
	HT::Void(patch_dll_names);

	// generate procedure linkage points
	put it = HT::MakeIter(patch_proc_entries);
	lab proc_loop;
		jump proc_done ~ Bool::Not(HT::Next(it));
		put dll_name   = it.HT::Iter::KEY;
		put patch_addr = it.HT::Iter::VALUE;
		put procs      = HT::Get(dll_to_procs, dll_name);

		put rva = IR::Addr(ctx) - Tmpl::Config::LOAD_ADDR;
		IR::Patch32(ctx, patch_addr, rva);

		put i = 0;
		lab proc_point_loop;
			jump proc_point_done ~ i == Dyn::Size(procs);
			put proc_name = Dyn::Ptr(procs).i;

			// TODO! implement proc point linkage

			HT::Set(patch_proc_names, proc_name, IR::Addr(ctx));
			IR::Push64(ctx, 0); // to be patched...

			put i = i + 1;
			jump proc_point_loop;
		lab proc_point_done;
		IR::Push64(ctx, 0);

		jump proc_loop;
	lab proc_done;

	// generate procedure names
	put it = HT::MakeIter(patch_proc_names);
	lab proc_name_loop;
		jump proc_name_done ~ Bool::Not(HT::Next(it));
		put name_string = it.HT::Iter::KEY;
		put patch_addr  = it.HT::Iter::VALUE;

		put rva = IR::Addr(ctx) - Tmpl::Config::LOAD_ADDR;
		IR::Patch32(ctx, patch_addr, rva);

		put i = 0;
		IR::Push16(ctx, 0); // exportNamePtr = 0
		lab proc_name_str_loop;
			IR::Push8(ctx, name_string.i);
			put i = i + 1;
		jump proc_name_str_loop ~ name_string.i;
		IR::Push8(ctx, 0); // string terminator

		jump proc_name_loop;
	lab proc_name_done;
	HT::Void(patch_proc_names);

	// patch import data directory entry
	IR::Patch32(ctx, 208 + Tmpl::Config::LOAD_ADDR, import_table_rva);
	IR::Patch32(ctx, 212 + Tmpl::Config::LOAD_ADDR, import_table_size);
}
