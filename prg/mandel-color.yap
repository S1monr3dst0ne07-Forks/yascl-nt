
apptype gui

use "lib/float.yap"
use "lib/debug.yap"
use "lib/win.yap"

bind SetDIBitsToDevice ~ "GDI32.DLL"

seq Dims
{
	WIDTH  = 800,
	HEIGHT = 800,
}

fn FrameBuffer()
{
	static (Dims::WIDTH * Dims::HEIGHT) ~ frame_buffer;
	return frame_buffer;
}

fn BitMapInfo()
{
	static 128 ~ x;
	jump done ~ x.0;

	put (x +  0).0 = 40;
	put (x +  4).0 = Dims::WIDTH;
	put (x +  8).0 = Dims::HEIGHT;
	put (x + 12).0 =  1;
	put (x + 14).0 = 32;
	put (x + 16	).0 =  0;

lab done;
	return x;
}

fn Paint(hdc)
{
	Mandel();
	put fb = FrameBuffer();
	put res = SetDIBitsToDevice(
		hdc,
		0, 0, Dims::WIDTH, Dims::HEIGHT,
		0, 0, 0          , Dims::HEIGHT,
		fb,
		BitMapInfo(),
		0,
	);
}

fn WndProc(hwnd, msg, wp, lp)
{
	jump destroy ~ msg == Win::MsgIden::DESTROY;
	jump paint   ~ msg == Win::MsgIden::PAINT;

	return DefWindowProcA(hwnd, msg, wp, lp);

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
		Dims::WIDTH, Dims::HEIGHT,
		Mem::NULL, Mem::NULL,
		hinstance, Mem::NULL,
	);
	
	ShowWindow(hwindow, Win::Show::SHOW);

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
    put zoom       = 2.0;

	put iXmax = Dims::WIDTH;
	put iYmax = Dims::HEIGHT;
	put fb    = FrameBuffer();

    put CxMin = ((0.0) ~- (2.5)) ~/ zoom;
    put CxMax = (         (1.5)) ~/ zoom;
    put CyMin = ((0.0) ~- (2.0)) ~/ zoom;
    put CyMax = (         (2.0)) ~/ zoom;

    put PixelHeight  = 0;
    put PixelWidth  = (CxMax ~- CxMin) ~/ Float::FromInt(iXmax);
    put PixelHeight = (CyMax ~- CyMin) ~/ Float::FromInt(iYmax);

    put IterationMax = 30;
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
		put i = 4 * (iX + (iY * iYmax));
		put (fb + i).0 = col;

            put iX = iX + 1;
        jump x_loop ~ iX < iXmax;

        put iY = iY + 1;
    jump y_loop ~ iY < iYmax;

    lab done;
}
