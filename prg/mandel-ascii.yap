
use "lib/frac.yap"
use "lib/io.yap"

fn main()
{
    put iXmax = 100;
    put iYmax = 100;

    put zoom       = 2;
    put zoom_frac  = Frac::Make(1, zoom, 0);

    put CxMin = Frac::Mul(Frac::Make(5, 2, 1), zoom_frac); //-2.5
    put CxMax = Frac::Mul(Frac::Make(3, 2, 0), zoom_frac); // 1.5
    put CyMin = Frac::Mul(Frac::Make(2, 1, 1), zoom_frac); //-2.0
    put CyMax = Frac::Mul(Frac::Make(2, 1, 0), zoom_frac); // 2.0

    put PixelHeight  = 0;
    put PixelWidth  = Frac::Mul(Frac::Add(CxMax, Frac::Neg(CxMin)), Frac::Make(1, iXmax, 0));
    put PixelHeight = Frac::Mul(Frac::Add(CyMax, Frac::Neg(CyMin)), Frac::Make(1, iYmax, 0));

    put IterationMax = 200;
    put ER2 = Frac::Make(2*2, 1, 0); // 2^2

    put iY = 0;
    lab y_loop;
        put Cy = Frac::Add(CyMin, Frac::Mul(Frac::Make(iY, 1, 0), PixelHeight));

        put iX = 0;
        lab x_loop;
            put Cx = Frac::Add(CxMin, Frac::Mul(Frac::Make(iX, 1, 0), PixelWidth));

            put Zx  = Frac::Make(0, 1, 0);
            put Zy  = Frac::Make(0, 1, 0);
            put Zx2 = Frac::Make(0, 1, 0);
            put Zy2 = Frac::Make(0, 1, 0);


            put Iteration = 0;
            lab iter_loop;
                jump iter_done_inside ~ Iteration == IterationMax;
                jump iter_done_outside ~ Frac::Cmp(Frac::Add(Zx2, Zy2), ER2);
                    put Zy = Frac::Add(Frac::Mul(Frac::Make(2, 1, 0), Frac::Mul(Zx, Zy)), Cy);
                    put Zx = Frac::Add(Frac::Add(Zx2, Frac::Neg(Zy2)),                    Cx);
                    put Zx2 = Frac::Mul(Zx, Zx);
                    put Zy2 = Frac::Mul(Zy, Zy);


                put Iteration = Iteration + 1;
                jump iter_loop;
            lab iter_done_inside;   IO::Print("#"); jump iter_done;
            lab iter_done_outside;  IO::Print(" "); jump iter_done;
            lab iter_done;

            put iX = iX + 1;
        jump x_loop ~ iX < iXmax;

        IO::Print("\n");
        put iY = iY + 1;
    jump y_loop ~ iY < iYmax;

    lab done;
}
