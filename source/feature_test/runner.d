module feature_test.runner;

debug (featureTest) {
	import feature_test.core;
	import feature_test.exceptions;
	import feature_test.callbacks;

	import colorize;

	import std.string;
	import std.stdio;
	import std.conv;
	import std.random;
	import std.algorithm;
	import std.array;

	import core.exception;

	class FeatureTestRunner {
		mixin FTCallbacks;

		struct Failure {
			string feature;
			string scenario;
			Throwable detail;
		}
		
		uint featuresTested;
		uint scenariosPassed;

		FeatureTest[] features; 
		Failure[] failures;
		Failure[] pending;
		string[] onlyTags;
		string[] ignoreTags;

		this() {
			randomize = true;
			quiet = false;
			_displayWidth = 80;
		}

		static @property FeatureTestRunner instance() {
			if (!_runner) _runner = new FeatureTestRunner;
			return _runner;
		}

		static this() {
			import core.runtime;

			writeln("Feature Testing Enabled!".color(fg.light_green));
			foreach(arg; Runtime.args) {
				if (arg[0] == '@') { instance.addOnlyTags(arg[1..$].split(",")); }
				if (arg[0] == '+') { instance.removeIgnoreTags(arg[1..$].split(",")); }
				else if (arg[0] == '-') { instance.addIgnoreTags(arg[1..$].split(",")); }
				else if (arg == "quiet") instance.quiet = true;
			}
		}
		
		static ~this() {
			if (instance.onlyTags.length) instance.logln("Only including tags: ".color(fg.light_yellow) ~ format(instance.onlyTags.join(", ").color(fg.light_white)));
			if (instance.ignoreTags.length) instance.logln("Ignoring tags: ".color(fg.light_magenta) ~ format(instance.ignoreTags.join(", ").color(fg.light_white)));
			if (instance.randomize) {
				instance.logln("Randomizing Features".color(fg.light_cyan));
				instance.features.randomShuffle;
			}

			instance.runBeforeAll;
			foreach(feature; _runner.features) {
				instance.runBeforeEach;
				_runner.runFeature(feature);
				instance.runAfterEach;
			}
			instance.runAfterAll;
			writeln(_runner.report);
		}

		/// Adds the given tag to onlyTags if it doesn't already exist
		void addOnlyTag(string tag) {
			if (!onlyTags.canFind(tag)) onlyTags ~= tag;
		}
		
		/// Adds each of the given tags to onlyTags if it doesn't already exist
		void addOnlyTags(string[] tags ...) {
			foreach(tag; tags) addOnlyTag(tag);
		}
		
		/// Adds the given tag to ignoreTags if it doesn't already exist
		void addIgnoreTag(string tag) {
			if (!ignoreTags.canFind(tag)) ignoreTags ~= tag;
		}

		/// Adds each of the given tags to ignoreTags if it doesn't already exist
		void addIgnoreTags(string[] tags ...) {
			foreach(tag; tags) addIgnoreTag(tag);
		}
		

		/// Removes the given tag to ignoreTags if it exists
		void removeIgnoreTag(string tag) {
			ignoreTags = array(ignoreTags.filter!(a => a != tag));
		}

		/// Removes each of the given tags from ignoreTags if they exist
		void removeIgnoreTags(string[] tags ...) {
			foreach(tag; tags) removeIgnoreTag(tag);
		}
		
		/// Returns true if a feature with the given tags should be included
		bool shouldInclude(string[] tags ...) {
			foreach(tag; ignoreTags) if (tags.canFind(tag)) return false;
			if (!onlyTags.length) return true; 
			foreach(tag; onlyTags) if (tags.canFind(tag)) return true;
			return false;
		}
		
		@property scenariosTested() {
			return scenariosPassed + failures.length;
		}
		
		void incFeatures() { featuresTested += 1; }
		void incPassed() { scenariosPassed += 1; }

		void reset() {
			featuresTested = 0;
			scenariosPassed = 0;
			failures = [];
			pending = [];
		}
		
		string report() {
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
		
		@property ref uint indent() {
			return _indent;
		}
		
		void log(T)(T output) {
			auto indentString = indentTabs;
			output = output.wrap(_displayWidth, indentString, indentString, indentString.length);
			write(output.stripRight);
		}
		
		void logln(T)(T output) {
			auto indentString = indentTabs;
			output = output.wrap(_displayWidth, indentString, indentString, indentString.length);
			write(output);
		}
		
		void logf(T, A ...)(T fmt, A args) {
			auto output = format(fmt, args);
			log(output);
		}
		
		void logfln(T, A ...)(T fmt, A args) {
			logf(fmt, args);
			writeln();
		}
		
		void info(A ...)(string fmt, A args) {
			logfln(fmt.color(fg.light_blue), args);
		}

		void runFeature(FeatureTest feature) {
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
			
			feature.runBeforeAll;
			
			logln("Scenarios:".color(fg.light_cyan));
			++indent; // Indent the scenarios
			foreach(scenario; feature.scenarios) {
				bool scenarioPass = true;
				
				feature.runBeforeEach;
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
				feature.runAfterEach;
			}
			--indent; // Unindent the scenarios
			feature.runAfterAll;
			--indent;
			writeln();
		}
		
	private:
		static FeatureTestRunner _runner; // The instance

		// For display purposes
		uint _indent; // Holds the current level of indentation
		enum _tabString = "    ";
		uint _displayWidth;
		bool randomize;
		bool quiet;
		
		@property string indentTabs() {
			string tabs;
			for(uint count = 0; count < _indent; ++count) tabs ~= _tabString;
			return tabs;
		}
	}
}
