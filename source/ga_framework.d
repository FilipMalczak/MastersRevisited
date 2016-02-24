module ga_framework;

import std.math: isNaN, sqrt;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.random;
import std.stdio;
import std.datetime;
import std.format;
import std.array;

import io;

class Stat {
    double best = double.max;
    double worst = double.min_normal;
    double avg = 0;
    double variance = 0;

    @property double stdDev(){
        return sqrt(variance);
    }

    static string[] csvHeader = ["best", "worst", "avg", "stdDev", "variance"];

    override string toString(){
        return format("Stat(best = %f, worst = %f, avg = %f, variance = %f)", best, worst, avg, variance);
    }
}


class Context(S){
    int genNo=0;
    int evals=0;
    S[] pop = [];
    Stat[] stats = [];
    Stat[] properStats = [];
    TickDuration duration;

    @property string metadata(){
        with (std.conv.to!(Duration)(duration).split()) {
            return format("Generations: %d\nEvaluations: %d\nTicks: %d\nDuration: %s\nGlobal best: %f\nProper eval of global best: %f\n",
                            genNo, evals, duration.length,
                            format("%02d:%02d:%02d.%3d", hours, minutes, seconds, msecs),
                            globalBest, properGlobalBest
            );
        }
    }

    static double best(Stat[] theStats){
        double result = double.max;
        foreach (stat; theStats)
            if (stat.best < result)
                result = stat.best;
        return result;
    }

    @property double globalBest(){
        return best(stats);
    }

    @property double properGlobalBest(){
        return best(properStats);
    }

    void saveStats(S)(CsvFormatter!S csv){
        foreach (stat; stats)
            with (stat) {
                string formatDouble(double x){
                    return format("%f", x);
                }
                csv.feed!string(array(map!formatDouble([best, worst, avg, stdDev, variance])));
            }
    }
}

class Specimen {
    double eval = double.nan;
    double properEval = double.nan;
}

class Evaluator(S) {
    Context!S ctx;

    double evaluate(S s){
        if (isNaN(s.eval)) {
        	auto e = getEval(s);
        	s.eval=e;
            ++ctx.evals;
        }
        return s.eval;
    }
    abstract double getEval(S s);

    double evaluateProperly(S s){
        if (isNaN(s.properEval)) {
            auto e = getProperEval(s);
            s.properEval=e;
        }
        return s.properEval;
    }

    double getProperEval(S s) {
        return evaluate(s);
    }
}

interface Generator(S){
    S generateRandom();

    final S[] generateMany(int size){
        S[] result = new S[size];
        foreach (ref s; result)
            s = generateRandom();
        return result;
    }
}

class Callback(S){
    Evaluator!S evaluator = null;

    void atStart(Context!S ctx){}
    void postSelect(Context!S ctx){}
    void atEnd(Context!S ctx){}
}

class UsefulCallback(S): Callback!S {
    StopWatch stopWatch;
    bool exact;

    this(bool exact){
        this.exact = exact;
    }

    override void atStart(Context!S ctx){
        stopWatch.start();
        writeln("AT START");
    }

    Stat calculateStats(alias F)(S[] pop){
        writeln("POP ", pop);
        Stat stat = new Stat();
        foreach (elem; pop) {
            auto eval = F(elem);
            if (eval > stat.worst)
                stat.worst = eval;
            if (eval < stat.best)
                stat.best = eval;
            stat.avg += eval;
        }
        stat.avg /= pop.length;
        foreach (elem; pop)
            stat.variance += (elem.eval-stat.avg)^^2;
        stat.variance /= pop.length;
        writeln("STAT ", stat);
        return stat;
    }

    double justEval(S s){ return evaluator.evaluate(s); }
    double properEval(S s){ return evaluator.evaluateProperly(s); }

    override void postSelect(Context!S ctx){
        writeln("justEval");
        ctx.stats ~= calculateStats!justEval(ctx.pop);
        if (exact) {
            writeln("properEval");
            ctx.properStats ~= calculateStats!properEval(ctx.pop);
        }
    }

    override void atEnd(Context!S ctx){
        writeln("AT END");
        stopWatch.stop();
        ctx.duration = stopWatch.peek();
        stopWatch.reset();
    }
}

interface Mutation(S) {
    S[] mutate(S s);
}

class SingleSpecimenMutation(S): Mutation!S {
	override S[] mutate(S s) {
        return [ mutateOne(s) ];
	}

	abstract S mutateOne(S s);
}

interface Crossover(S) {
    S[] crossOver(S s1, S s2);
}

interface Selection(S) {
    S[] select(S[] pop, Evaluator!S eval, int size);
}

struct GAConfig(S) {
    int popSize;
    float cp;
    float mp;
    int maxEvals;
    Selection!S select;
}

struct ProblemConfig(S) {
    Generator!S generator;
    Evaluator!S evaluator;
    Mutation!S mut;
    Crossover!S cross;
}

class GA(S) {
	Context!S ctx;

    int popSize;
    float cp;
    float mp;
    int maxEvals;

    Evaluator!S evaluator;
    Mutation!S mut;
    Crossover!S cross;
    Selection!S select;

    Callback!S callback;

    this(GAConfig!S ga, ProblemConfig!S problem, Callback!S callback=null){
        this(ga.popSize, ga.cp, ga.mp, ga.maxEvals, problem.generator, problem.evaluator, problem.mut, problem.cross, ga.select, callback);
    }

    this(int popSize, float cp, float mp, int maxEvals, Generator!S generator, Evaluator!S eval, Mutation!S mut, Crossover!S cross, Selection!S select, Callback!S callback = null) {
        this.ctx = new Context!S;
    	this.popSize = popSize;
        this.cp = cp;
        this.mp = mp;
        this.maxEvals = maxEvals;

    	ctx.pop = generator.generateMany(popSize);//generateInitialPop(generator);

		this.evaluator = eval;
        eval.ctx = ctx;
        this.mut = mut;
        this.cross = cross;
        this.select = select;

        this.callback = callback;
        if (this.callback)
            this.callback.evaluator = eval;
    }

    S[] generateInitialPop(Generator!S generator){
    	S[] pop = new S[popSize];
        foreach (ref s; pop)
        	s = generator.generateRandom();
		return pop;
    }

    void run(){
        if (callback) callback.atStart(ctx);
        int genNo;
        while (ctx.evals < maxEvals){
            auto pop = ctx.pop;
            auto newPop = pop.dup;
            foreach (s; pop)
                if (uniform01()<mp)
                    newPop ~= mut.mutate(s);
            foreach (s; pop)
                if (uniform01()<(cp/2)) {
                    S other = null;
                    do
                    	other = pop[uniform(0, pop.length)];
					while (other != s);
                    newPop ~= cross.crossOver(s, other);
                }
            ctx.pop = select.select(newPop, evaluator, popSize);
            if (callback) callback.postSelect(ctx);
            ++ctx.genNo;
//            writefln("Population after gen %s:", ctx.genNo);
            //writeln(ctx.pop);
        }
        if (callback) callback.atEnd(ctx);

    }
}
