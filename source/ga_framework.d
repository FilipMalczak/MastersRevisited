module ga_framework;

import std.math: isNaN;
import std.random;
import std.stdio;

enum Stat {Best, Worst, Avg, Median};


class Context(S){
    int genNo=0;
    int evals=0;
    S[] pop;
    double[Stat][] stats;
}

class Specimen {
    double eval = double.nan;
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

class Callback(C){
    void updateCtx(C ctx){}
}

class StatUpdatingCallback(S): Callback!C {
	void updateCtx(C ctx){
        //todo
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

    this(GAConfig!S ga, ProblemConfig!S problem){
        this(ga.popSize, ga.cp, ga.mp, ga.maxEvals, problem.generator, problem.evaluator, problem.mut, problem.cross, ga.select);
    }

    this(int popSize, float cp, float mp, int maxEvals, Generator!S generator, Evaluator!S eval, Mutation!S mut, Crossover!S cross, Selection!S select) {
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
    }

    S[] generateInitialPop(Generator!S generator){
    	S[] pop = new S[popSize];
        foreach (ref s; pop)
        	s = generator.generateRandom();
		return pop;
    }

    void run(){

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
            ++ctx.genNo;
//            writefln("Population after gen %s:", ctx.genNo);
            //writeln(ctx.pop);
        }

    }
}
