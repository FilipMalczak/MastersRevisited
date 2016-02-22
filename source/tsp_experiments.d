module tsp_experiments;

import std.stdio;
import ga_framework;
import tsp;
import generic_imp;

Context!S runExperiment(S)(GAConfig!S ga_conf, ProblemConfig!S problem, Callback!(Context!S) callback=null){
    auto ga = new GA!S(ga_conf, problem);
    ga.run();
    return ga.ctx;
}

void main(string[] args){
    auto problem = tspConfig("./problem.csv");
    auto config = GAConfig!Path(-1, 0.7, 0.2, -1, new TourneySelect!Path(3));
    foreach (popSize; [2, 10, 100, 200, 500, 1000])
        foreach (maxEvals; [100, 1000, 10_000, 20_000, 50_000, 100_000]) {
            config.popSize = popSize;
            config.maxEvals = maxEvals;
            auto ctx = runExperiment!Path(config, problem, new UsefulCallback!(Context!Path));
            writeln(popSize, ";", maxEvals, ";", ctx.duration, ";", ctx.pop);

        }
}