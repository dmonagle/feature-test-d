module feature_test.core;

debug (featureTest) {
	import feature_test.exceptions;
	import feature_test.runner;
	import feature_test.callbacks;

	import colorize;

	import std.stdio;
	import std.algorithm;

	alias FTImplementation = void delegate(FeatureTest);

	struct FeatureTestScenario {
		string name;
		FTCallback implementation;
	}

	class FeatureTest {
		mixin FTCallbacks;

		@property ref string name() { return _name; }
		@property ref string description() { return _description; }
		@property string[] tags() { return _tags; }
		@property ref FeatureTestScenario[] scenarios() { return _scenarios; }

		void info(A...)(string fmt, A args) {
			FeatureTestRunner.instance.info(fmt, args);
		}
		
		void addTags(string[] tags ...) {
			foreach(tag; tags) { if (!_tags.canFind(tag)) _tags ~= tag; }
		}
		
		void scenario(string name, FTCallback implementation) {
			_scenarios ~= FeatureTestScenario(name, implementation);
		}
		
	private:
		string _name;
		string _description;
		string[] _tags;
		
		FeatureTestScenario[] _scenarios;
	}

	void feature(T)(string name, string description, void delegate(T) implementation, string[] tags ...) {
		if (FeatureTestRunner.instance.shouldInclude(tags)) {
			auto f = new T();
			f.name = name;
			f.description = description;
			f.addTags(tags);
			implementation(f);
			FeatureTestRunner.instance.features ~= f;
		}
	}

	void feature(T)(string name, void delegate(T) implementation, string[] tags ...) {
		feature!T(name, "", implementation, tags);
	}

	void feature(string name, string description, void delegate(FeatureTest) implementation, string[] tags ...) {
		feature!FeatureTest(name, description, implementation, tags);
	}

	void feature(string name, void delegate(FeatureTest) implementation, string[] tags ...) {
		feature!FeatureTest(name, "", implementation, tags);
	}

	/// Marks a scenario as pending
	void featureTestPending(string file = __FILE__, typeof(__LINE__) line = __LINE__) {
		throw new FeatureTestException(file, line);
	}
}