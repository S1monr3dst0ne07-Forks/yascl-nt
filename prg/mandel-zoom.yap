
apptype gui

use "lib/float.yap"
use "lib/debug.yap"
use "lib/win.yap"

bind StretchDIBits ~ "GDI32.DLL"

seq Dims
{
    SIZE = 200,
    WIN  = 400,
}

fn FrameBuffer()
{
	static (Dims::WIN * Dims::WIN) ~ frame_buffer;
	return frame_buffer;
}

fn BitMapInfo()
{
	static 128 ~ x;
	jump done ~ x.0;

	put (x +  0).0 = 40;
	put (x +  4).0 = Dims::SIZE;
	put (x +  8).0 = Dims::SIZE;
	put (x + 12).0 =  1;
	put (x + 14).0 = 32;
	put (x + 16).0 =  0;

lab done;
	return x;
}

fn Paint(hdc)
{
	put fb = FrameBuffer();
        StretchDIBits(
            hdc,
            0, 0, Dims::WIN,  Dims::WIN,
            0, 0, Dims::SIZE, Dims::SIZE,
            fb, BitMapInfo(),
            0, 13369376,
        );
}

fn WndProc(hwnd, msg, wp, lp)
{
	jump destroy ~ msg == Win::MsgIden::DESTROY;
	jump paint   ~ msg == Win::MsgIden::PAINT;
        jump timer   ~ msg == Win::MsgIden::TIMER;

	return DefWindowProcA(hwnd, msg, wp, lp);

lab timer;
	Mandel();
        InvalidateRect(hwnd, Mem::NULL, Bool::FALSE);
        return 0;

lab destroy;
	PostQuitMessage(0);
	return 0;
lab paint;
	static Win::Paint::Struct ~ ps;

	put hdc = BeginPaint(hwnd, ps);
	Paint(hdc);
	EndPaint(hwnd, ps);
}

fn main()
{	
	put hinstance = GetModuleHandleA(Mem::NULL);
	static Win::Class ~ wc;
	
	put (wc + Win::Class::lpfnWndProc)    .0 = @WndProc;
	put (wc + Win::Class::hInstance)      .0 = hinstance;
	put (wc + Win::Class::lpszClassName)  .0 = Win::Str("MAIN");
	
	RegisterClassA(wc);

	put hwindow = CreateWindowExA(
		0,
		Win::Str("MAIN"),
		Win::Str("Mandelbrot -- Brought to you by YASCL-NT"),
			Win::Style::OVERLAPPED |
			Win::Style::CAPTION    |
			Win::Style::SYSMENU,
		Win::CreateWindow::USEDEFAULT,
		Win::CreateWindow::USEDEFAULT,
		Dims::WIN, Dims::WIN,
		Mem::NULL, Mem::NULL,
		hinstance, Mem::NULL,
	);
	
	ShowWindow(hwindow, Win::Show::SHOW);
        SetTimer  (hwindow, 1, 33, Mem::NULL);

	static Win::MsgObj ~ msg;
	lab loop;
		put res = GetMessageA(msg, Mem::NULL, 0, 0);
		jump done ~ res == 0;

		TranslateMessage(msg);
		DispatchMessageA(msg);
	jump loop;


lab done;
}





fn Color(idx)
{
	put table = [
		[66,  30,  15 ],
		[25,  7,   26 ],
		[9,   1,   47 ],
		[4,   4,   73 ],
		[0,   7,   100],
		[12,  44,  138],
		[24,  82,  177],
		[57,  125, 209],
		[134, 181, 229],
		[211, 236, 248],
		[241, 233, 191],
		[248, 201, 95 ],
		[255, 170, 0  ],
		[204, 128, 0  ],
		[153, 87,  0  ],
		[106, 52,  3  ],
		[0,   0,   0  ],
	];

	put entry = table.idx;

	return Win::Paint::RGB(
		entry.2,
		entry.1,
		entry.0,
	);
}

fn Mandel()
{
    static 1 ~ zoom_lvl_ptr;
    put zoom_lvl = zoom_lvl_ptr.0;
    put zoom_lvl_ptr.0 = zoom_lvl + 1;

    put zoom = Float::IntPow(1.05, zoom_lvl) ~/ (100.0);
    put zoom_limit = 1000000000.0;

    jump nreset ~ zoom ~< zoom_limit;
        put zoom_lvl_ptr.0 = 0;
    lab nreset;

	put iXmax = Dims::SIZE;
	put iYmax = Dims::SIZE;
	put fb    = FrameBuffer();

	put xBase = (0.0) ~- (1.76868306054   );
	put yBase = (0.0) ~+ (0.00333684791873);

    put CxMin = xBase ~+ (((0.0) ~- (2.5)) ~/ zoom);
    put CxMax = xBase ~+ ((         (1.5)) ~/ zoom);
    put CyMin = yBase ~+ (((0.0) ~- (2.0)) ~/ zoom);
    put CyMax = yBase ~+ ((         (2.0)) ~/ zoom);

    put PixelHeight  = 0;
    put PixelWidth  = (CxMax ~- CxMin) ~/ Float::FromInt(iXmax);
    put PixelHeight = (CyMax ~- CyMin) ~/ Float::FromInt(iYmax);

    put IterationMax = 100;
    put ER2 = 4.0; // 2^2

    put iY = 0;
    lab y_loop;
    	put Cy = CyMin ~+ (Float::FromInt(iY) ~* PixelHeight);

        put iX = 0;
        lab x_loop;
        	put Cx = CxMin ~+ (Float::FromInt(iX) ~* PixelWidth);

            put Zx  = 0.0;
            put Zy  = 0.0;
            put Zx2 = 0.0;
            put Zy2 = 0.0;

            put Iteration = 0;
            lab iter_loop;
                jump iter_done ~ Iteration == IterationMax;
                jump iter_done ~ (Zx2 ~+ Zy2) ~> ER2;
					put Zy  = Cy ~+ ((2.0) ~* Zx ~* Zy);
					put Zx  = Cx ~+ Zx2 ~- Zy2;
					put Zx2 = Zx ~* Zx;
					put Zy2 = Zy ~* Zy;

                put Iteration = Iteration + 1;
                jump iter_loop;
            lab iter_done;

            put i = Iteration & 15;
            jump black ~ Iteration != IterationMax; put i = 16; lab black;

		put col = Color(i);
		put i = 4 * (iX + (iY * Dims::SIZE));
		put (fb + i).0 = col;

            put iX = iX + 1;
        jump x_loop ~ iX < iXmax;

        put iY = iY + 1;
    jump y_loop ~ iY < iYmax;

    lab done;
}
