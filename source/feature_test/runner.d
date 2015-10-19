module feature_test.runner;

debug (featureTest) {
	import feature_test.core;
	import feature_test.exceptions;

	import colorize;

	import std.string;
	import std.stdio;
	import std.conv;
	import std.random;
	import std.algorithm;
	import std.array;

	import core.exception;

	struct FeatureTestRunner {
		struct Failure {
			string feature;
			string scenario;
			Throwable detail;
		}
		
		static randomize = true;
		static quiet = false;

		static uint featuresTested;
		static uint scenariosPassed;

		static FeatureTest[] features; 
		static Failure[] failures;
		static Failure[] pending;
		static string[] onlyTags;
		static string[] ignoreTags;

		static this() {
			import core.runtime;

			writeln("Feature Testing Enabled!".color(fg.light_green));
			foreach(arg; Runtime.args) {
				if (arg[0] == '@') { addOnlyTags(arg[1..$].split(",")); }
				if (arg[0] == '+') { removeIgnoreTags(arg[1..$].split(",")); }
				else if (arg[0] == '-') { addIgnoreTags(arg[1..$].split(",")); }
				else if (arg == "quiet") quiet = true;
			}
		}
		
		static ~this() {
			if (onlyTags.length) logln("Only including tags: ".color(fg.light_yellow) ~ format(onlyTags.join(", ").color(fg.light_white)));
			if (ignoreTags.length) logln("Ignoring tags: ".color(fg.light_magenta) ~ format(ignoreTags.join(", ").color(fg.light_white)));
			if (randomize) {
				logln("Randomizing Features".color(fg.light_cyan));
				features.randomShuffle;
			}

			foreach(feature; features) runFeature(feature);
			writeln(this.toString);
		}

		/// Adds the given tag to onlyTags if it doesn't already exist
		static void addOnlyTag(string tag) {
			if (!onlyTags.canFind(tag)) onlyTags ~= tag;
		}
		
		/// Adds each of the given tags to onlyTags if it doesn't already exist
		static void addOnlyTags(string[] tags ...) {
			foreach(tag; tags) addOnlyTag(tag);
		}
		
		/// Adds the given tag to ignoreTags if it doesn't already exist
		static void addIgnoreTag(string tag) {
			if (!ignoreTags.canFind(tag)) ignoreTags ~= tag;
		}

		/// Adds each of the given tags to ignoreTags if it doesn't already exist
		static void addIgnoreTags(string[] tags ...) {
			foreach(tag; tags) addIgnoreTag(tag);
		}
		

		/// Removes the given tag to ignoreTags if it exists
		static void removeIgnoreTag(string tag) {
			ignoreTags = array(ignoreTags.filter!(a => a != tag));
		}

		/// Removes each of the given tags from ignoreTags if they exist
		static void removeIgnoreTags(string[] tags ...) {
			foreach(tag; tags) removeIgnoreTag(tag);
		}
		
		/// Returns true if a feature with the given tags should be included
		static bool shouldInclude(string[] tags ...) {
			foreach(tag; ignoreTags) if (tags.canFind(tag)) return false;
			if (!onlyTags.length) return true; 
			foreach(tag; onlyTags) if (tags.canFind(tag)) return true;
			return false;
		}
		
		static @property scenariosTested() {
			return scenariosPassed + failures.length;
		}
		
		static void incFeatures() { featuresTested += 1; }
		static void incPassed() { scenariosPassed += 1; }

		static void reset() {
			featuresTested = 0;
			scenariosPassed = 0;
			failures = [];
			pending = [];
		}
		
		static string toString() {
			string output;

			if (pending.length) {
				output ~= "\n!!! Pending !!!\n\n".color(fg.light_yellow);
				foreach(failure; pending) {
					output ~= format("%s %s\n", "Feature:".color(fg.light_yellow), failure.feature.color(fg.light_white, bg.init, mode.bold));
					output ~= format("\t%s\n".color(fg.light_yellow), failure.scenario);
					output ~= format("\t%s(%s)\n".color(fg.cyan), failure.detail.file, failure.detail.line);
					output ~= format("\t%s\n\n", failure.detail.msg);
				}
			}

			if (failures.length) {
				output ~= "\n!!! Failures !!!\n\n".color(fg.light_red);
				foreach(failure; failures) {
					output ~= format("%s %s\n", "Feature:".color(fg.light_yellow), failure.feature.color(fg.light_white, bg.init, mode.bold));
					output ~= format("\t%s\n".color(fg.light_red), failure.scenario);
					output ~= format("\t%s(%s)\n".color(fg.cyan), failure.detail.file, failure.detail.line);
					output ~= format("\t%s\n\n", failure.detail.msg);
				}
			}
			else {
				output ~= "All feature tests passed successfully!\n".color(fg.light_green);
			}
			
			output ~= format("  Features tested: %s\n", featuresTested.to!string.color(fg.light_cyan));
			output ~= format(" Scenarios tested: %s\n", scenariosTested.to!string.color(fg.light_cyan));
			if (scenariosPassed) output ~= format(" Scenarios passed: %s\n", scenariosPassed.to!string.color(fg.light_green));
			if (failures.length) output ~= format(" Scenarios failed: %s\n", failures.length.to!string.color(fg.light_red));
			if (pending.length) output ~= format("Scenarios pending: %s\n", pending.length.to!string.color(fg.light_yellow));
			
			return output;
		}
		
		
		// Functions for indenting output appropriately;
		
		static @property ref uint indent() {
			return _indent;
		}
		
		static void log(T)(T output) {
			auto indentString = indentTabs;
			output = output.wrap(_displayWidth, indentString, indentString, indentString.length);
			write(output.stripRight);
		}
		
		static void logln(T)(T output) {
			auto indentString = indentTabs;
			output = output.wrap(_displayWidth, indentString, indentString, indentString.length);
			write(output);
		}
		
		static void logf(T, A ...)(T fmt, A args) {
			auto output = format(fmt, args);
			log(output);
		}
		
		static void logfln(T, A ...)(T fmt, A args) {
			logf(fmt, args);
			writeln();
		}
		
		static void info(A ...)(string fmt, A args) {
			logfln(fmt.color(fg.light_blue), args);
		}

		static void runFeature(FeatureTest feature) {
			incFeatures;
			string tagsDescription;

			if(feature.tags.length) tagsDescription = format(" (%s)", feature.tags.join(", "));

			logfln("%s %s%s", "Feature:".color(fg.light_yellow), feature.name.color(fg.light_white, bg.init, mode.bold), tagsDescription);
			++indent;

			if (feature.description.length) {
				writeln();
				logln(feature.description);
				writeln();
			}
			
			feature._beforeAll();
			
			logln("Scenarios:".color(fg.light_cyan));
			++indent; // Indent the scenarios
			foreach(scenario; feature.scenarios) {
				bool scenarioPass = true;
				
				feature._beforeEach;
				logfln("%s".color(fg.light_white, bg.init, mode.bold), scenario.name);
				++indent;
				try {
					scenario.implementation();
				}
				catch (Throwable t) {
					string failMessage;
					
					auto featureTestException = cast(FeatureTestException)t;
					scenarioPass = false;
					
					if (featureTestException && featureTestException.pending) {
						pending ~= FeatureTestRunner.Failure(feature.name, scenario.name, t);
						failMessage = "[ PENDING ]".color(fg.black, bg.light_yellow);
					}
					else {
						failures ~= FeatureTestRunner.Failure(feature.name, scenario.name, t);
						failMessage = "[ FAIL ]".color(fg.black, bg.light_red);
					}
					
					logln(failMessage);

					// Rethrow the original error if it's not an AsserError or a FeatureTestException
					if (!cast(AssertError)t && !featureTestException) throw t;
				}
				
				if (scenarioPass) {
					logln("[ PASS ]".color(fg.black, bg.light_green));
					incPassed;
				}
				--indent;
				feature._afterEach;
			}
			--indent; // Unindent the scenarios
			feature._afterAll;
			--indent;
			writeln();
		}
		
	private:
		// For display purposes
		static uint _indent; // Holds the current level of indentation
		static enum _tabString = "    ";
		static _displayWidth = 80;
		
		static @property string indentTabs() {
			string tabs;
			for(uint count = 0; count < _indent; ++count) tabs ~= _tabString;
			return tabs;
		}
	}
}
