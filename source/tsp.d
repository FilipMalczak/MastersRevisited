module tsp;

import std.conv;
import std.stdio;
import std.random;
import std.algorithm: reduce;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.file;
import std.typecons;
import io;
import ga_framework;
import std.math;

double[][] generatePoints(int dim, int no, double min=-1000, double max=1000){
    double[][] toReturn = [];
    foreach (i; 0..no){
        double[] row = [];
        foreach (j; 0..dim)
            row ~= uniform(min, max);
        toReturn ~= row;
    }
    return toReturn;
}

unittest {
    auto result = generatePoints(3, 5);
    assert(result.length == 5);
    foreach (row; result)
        assert(row.length == 3);
}

/*
 * DEV NOTE: For faster computations, no sqrt() is performed - we only need to order distances
 * and sqrt is monotonic, so we can as well skip rooting.
 */

double distance(double[] p1, double[] p2){
    assert(p1.length == p2.length);
    double result = 0;
    foreach (i; 0..p1.length)
        result += (p1[i] - p2[i])^^2;
    return result;
}

unittest {
    assert(distance([1, 2, 3, 4], [1, 2, 3, 4]) == 0);
    assert(distance([1, 2], [3, 4]) == 8);
}

double[][] distances(double[][] points){
    double[][] toReturn = [];
    foreach (p1; points) {
        double[] row = [];
        foreach (p2; points)
            row ~= distance(p1, p2);
        toReturn ~= row;
    }
    return toReturn;
}

unittest {
    auto result = distances([[0, 0], [1, 1], [0, 1], [1, 0], [2, 2]]);
    foreach (i; 0..result.length) {
        assert(result[i][i] == 0);
        foreach (j; 0..(result.length-i))
            assert(result[i][j] == result[j][i]);
    }
    assert(result[0][1..$] == [2, 1, 1, 8]);
}


void generateProblemFile(string path, int size, double min=-1000, double max=1000){
    double[][] points = generatePoints(2, size, min, max);
    CsvFile!string problem = new CsvFile!string(path);
    foreach (row; points)
        problem.feed(row);
    problem.flush();
}

double[][] readProblemFile(string path){
    double[][] points = readCsvFile!(string, double)(";", 2, path);
    return distances(points);
}

unittest {
    generateProblemFile("./problem.csv", 10);
    string text = readText("./problem.csv");
    assert(count(text, "\n") == 10);
    assert(count(text, ";") == 10);
}

class Path: Specimen {
    int[] repr;

    this(int[] repr){
        this.repr = repr;
    }

    override string toString(){
        return "Path(" ~ to!string(repr) ~ "; eval = " ~ (isnan(eval) ? "NaN" : to!string(sqrt(eval))) ~ ")";
    }
}

class TspEval: Evaluator!Path {
    double[][] distances;

    this(double[][] distances){
        this.distances = distances;
    }

    override double getEval(Path s) {
        double result = 0;
        foreach (i; 0..s.repr.length-2)
            result += distances[s.repr[i]][s.repr[i+1]];
        result += distances[s.repr[s.repr.length-2]][s.repr[s.repr.length-1]];
        return result;
    }
}

class TspGenerator: Generator!Path {
    int size;

    this(int size){
        this.size = size;
    }

    int[] increasing(){
        int[] result = new int[size];
        foreach(int i, ref element; result)
            element = i;
        return result;
    }

    override Path generateRandom() {
        int[] repr = increasing();
        randomShuffle(repr);
        return new Path(repr);
    }
}

unittest {
    auto example = new TspGenerator(10).generateRandom();
    assert(example.repr.length == 10);
    foreach (i; 0..10)
        assert(canFind(example.repr, i));
}

class ReverseSubsequenceMutation: Mutation!Path {
    override Path[] mutate(Path s){
        auto upper = uniform(2, s.repr.length-1);
        auto lower = uniform(1, upper);
        return [ new Path(reverseSubsequence!(int)(s.repr, to!int(lower), to!int(upper))) ];
    }

    static T[] reverseSubsequence(T)(T[] original, int lower, int upper){
        auto toReverse = original[lower..upper];
        reverse(toReverse);
        return original[0..lower] ~ toReverse ~ original[upper..$];
    }

}

unittest {
    assert(ReverseSubsequenceMutation.reverseSubsequence([0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 7) == [0, 1, 2, 6, 5, 4, 3, 7, 8]);
}

class SubsequenceCrossover: Crossover!Path {
    override Path[] crossOver(Path s1, Path s2) {
        int cuttingPoint = uniform(1, to!int(s1.repr.length-1));
        return [
            new Path(fill(s1.repr[0..cuttingPoint], s2.repr)),
            new Path(fill(s2.repr[0..cuttingPoint], s1.repr))
        ];
    }

    static T[] fill(T)(T[] front, T[] candidates){
        T[] result = front.dup;
        foreach (idx; 0..candidates.length) {
            auto elem = candidates[(idx+front.length) % candidates.length];
            if (!canFind(result, elem))
                result ~= elem;
        }
        return result;
    }
}

unittest {
    assert(SubsequenceCrossover.fill([1, 4], [2, 4, 5, 3, 1]) == [1, 4, 5, 3, 2]);
}

//struct ProblemConfig(S) {
//    Generator!S generator;
//    Evaluator!S evaluator;
//    Mutation!S mut;
//    Crossover!S cross;
//}

ProblemConfig!Path tspConfig(string path){
    double[][] distances = readProblemFile(path);
    return ProblemConfig!Path(
        new TspGenerator(to!int(distances.length)),
        new TspEval(distances),
        new ReverseSubsequenceMutation,
        new SubsequenceCrossover
    );
}
