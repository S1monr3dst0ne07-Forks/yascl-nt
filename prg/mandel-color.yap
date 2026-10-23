
use "lib/float.yap"
use "lib/debug.yap"

bind GetDC       ~ "USER32.DLL"
bind ReleaseDC   ~ "USER32.DLL"
bind ExitProcess ~ "KERNEL32.DLL"
bind SetPixel    ~ "GDI32.DLL"


fn main()
{
	put dc = GetDC(0);

	put width  = 800;
	put height = 800;

	mandel(dc, width, height);

	ReleaseDC(0, dc);
	ExitProcess(0);
}

fn color(idx)
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
	put color = 
		((entry.2) << 16) | 
		((entry.1) <<  8) |
		((entry.0)      ) ;

	return color;
}

fn mandel(dc, iXmax, iYmax)
{
    put zoom       = 2.0;

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

            put col = color(i);
            SetPixel(dc, iX, iY, col);

            put iX = iX + 1;
        jump x_loop ~ iX < iXmax;

        put iY = iY + 1;
    jump y_loop ~ iY < iYmax;

    lab done;
}
