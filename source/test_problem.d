module test_problem;

import std.conv;
import std.string;
import ga_framework;
import std.random;

class Point2D: Specimen {
    double x;
    double y;
    this(double x, double y){
        this.x = x;
        this.y = y;
    }

    override string toString(){
        return "Point2D("~to!string(x)~", "~to!string(y)~")";
    }
}

class PointGen: Generator!Point2D {
    override Point2D generateRandom(){
        return new Point2D(uniform(-500, 500), uniform(-500, 500));
    }
}

class DoubleSquareEval: Evaluator!Point2D {
    override double getEval(Point2D p){
        with(p)
            return x^^2 + y^^2;

    }
}

class MultMutation: SingleSpecimenMutation!Point2D {
	override Point2D mutateOne(Point2D s) {
        return new Point2D(s.x*uniform01(), s.y*uniform01());
	}
}

class CrossPoints: Crossover!Point2D {
    Point2D[] crossOver(Point2D s1, Point2D s2) {
        return [
            new Point2D(s1.x, s2.y),
            new Point2D(s2.x, s1.y),
            new Point2D(s1.y, s2.x),
            new Point2D(s1.x, s2.y)
        ];
    }
}