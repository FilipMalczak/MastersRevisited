module tsp_experiments;

import std.stdio;
import ga_framework;
import tsp;
import generic_imp;
import std.format;
import std.file;
import std.array;
import std.algorithm.iteration;
import std.conv;
import std.path;
import io;

Context!S runExperiment(S)(GAConfig!S ga_conf, ProblemConfig!S problem, Callback!S callback=null){
    auto ga = new GA!S(ga_conf, problem, callback);
    ga.run();
    writeln(ga.ctx);
    return ga.ctx;
}

void tspInitialExperiments(string path){
    auto problem = tspConfig("./problem.csv");
    auto config = GAConfig!Path(-1, 0.7, 0.2, -1, new TourneySelect!Path(3));
    CsvFile!string file = null;
        foreach (popSize; [100, 200, 500, 1000, 5000])
            foreach (cp; [50, 60, 65, 70, 75, 80, 90, 100])
                foreach (mp; [5, 10, 20, 25, 30, 35, 50, 50, 100])
                    foreach (maxEvals; [10_000, 20_000, 50_000, 100_000, 200_000, 500_000, 1_000_000])
                        foreach (iter; 0..5){
                            string filenameNoExt =format("./results/initial_tsp/%s_%s_%s_%s_%s", popSize, cp, mp, maxEvals, iter);
                            writeln(filenameNoExt, "START");
                            config.popSize = popSize;
                            config.cp = 1.0*cp/100;
                            config.mp = 1.0*mp/100;
                            config.maxEvals = maxEvals;
                            auto ctx = runExperiment!Path(config, problem, new UsefulCallback!Path(true));
                            writeln(filenameNoExt, "DONE");
                            auto csv = new CsvFile!string(filenameNoExt ~ ".csv", Stat.csvHeader);
                            ctx.saveStats(csv);
                            csv.flush();
                            std.file.write(filenameNoExt ~ ".txt", ctx.metadata);
                            writeln(filenameNoExt, "END");
                        }
}

string getFilepath(S)(string name, string[] paths...){
    string parent = buildPath(paths);
    string result = buildPath(parent, name);
    if (!exists(parent))
        mkdirRecurse(parent);
    return result;
}

string getFilepath(S)(GAConfig!S config, int iter, string extension, string[] paths...){
    return getFilepath!S(getFilename!S(config, iter, extension), paths);
}

string getFilename(S)(GAConfig!S config, int iter, string extension){
    with (config) {
        return join(map!(to!string)([popSize, cp, mp, maxEvals, -1, iter]), "_") ~ extension;
    }
}

void saveMeta(S)(GAConfig!S config, int iter, Context!S context, string[] paths...){
    std.file.write(getFilepath!S(config, iter, ".txt", paths), context.metadata);
}

void saveStatsHistory(S)(GAConfig!S config, int iter, Context!S context, string[] paths...){
    auto csv = new CsvFile!string(getFilepath!S(config, iter, ".csv", paths), Stat.csvHeader);
    context.saveStats(csv);
    csv.flush();
}

void savePopulationHistory(S)(GAConfig!S config, int iter, Context!S context, string[] paths...){
    writeln("NOT IMPLEMENTED YET");
}

void tspInitialSingleExperiment(string path, bool saveMetadata = true, bool saveStats = true, bool savePopulation = false){
    auto problem = tspConfig(path);
    auto config = GAConfig!Path(200, 0.7, 0.2, 50_000, new TourneySelect!Path(3));
    auto ctx = runExperiment!Path(config, problem, new UsefulCallback!Path(true));
    if (saveMetadata)
        saveMeta!Path(config, 0, ctx, "./single");
    if (saveStats)
        saveStatsHistory!Path(config, 0, ctx, "./single");
    if (savePopulation)
        savePopulationHistory!Path(config, 0, ctx, "./single");
}

void main(string[] args){
    //tspInitialSingleExperiment("./problem.csv", true, true, false);
    tspInitialSingleExperiment("./sahara.csv", true, true, false);
}