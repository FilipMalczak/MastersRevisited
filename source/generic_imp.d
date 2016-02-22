module generic_imp;

import std.random;
import std.algorithm: canFind;
import ga_framework;

class TourneySelect(S): Selection!S {
	int size;
	this(int size){
        this.size = size;
	}

	S[] select(S[] pop, Evaluator!S eval, int popSize) {
        S[] used = [];
        S[] result = [];
        while (result.length < popSize) {
        	S[] tourney = [];
            while (tourney.length < size) {
                auto candidate = pop[uniform(0, pop.length)];
                if (! used.canFind(candidate))
                    tourney ~= candidate;
            }
            S winner = tourney[0];
            foreach (s; tourney[1..$])
                if (eval.evaluate(s) < eval.evaluate(winner))
                	winner = s;
            result ~= winner;
        }
        return result;
	}
}

