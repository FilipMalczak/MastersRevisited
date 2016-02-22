import std.stdio;
import ga_framework;
import generic_imp;
import test_problem;
import std.conv;
import std.datetime;
import std.string;
import std.array;

//void main()
//{
//    writeln(["iter", "popSize", "maxEval", "sec", "msec", "nsec"].join(";"));
//    foreach(maxEvals; [1_000_000, 2_000_000, 5_000_000, 10_000_000, 20_000_000, 50_000_000, 10_000_000]) {
//        foreach (popSize; [100, 1000, 10000])    {
//            foreach(iter; 0..3) {
//                StopWatch sw;
//                sw.start();
//                GA!Point2D ga = new GA!Point2D(
//                    popSize,
//                    0.8, 0.2,
//                    maxEvals,
//                    new PointGen, new DoubleSquareEval, new MultMutation, new CrossPoints, new TourneySelect!Point2D(3)
//                );
////                auto ga = new GA!Point2D(
////                    100, 0.8, 0.2, 2_000_000, new PointGen, new DoubleSquareEval, new MultMutation, new CrossPoints, new TourneySelect!Point2D(3)
////                );
////                writeln(ga.ctx.pop);
//                ga.run();
////                writeln(ga.ctx.pop);
//                sw.stop();
//                writeln([
//                    to!string(iter),
//                    to!string(popSize),
//                    to!string(maxEvals),
//                    to!string(sw.peek().seconds),
//                    to!string(sw.peek().msecs),
//                    to!string(sw.peek().nsecs)
//                ].join(";"));
//                delete ga;
//    }    }}
//}
