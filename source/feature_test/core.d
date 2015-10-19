module feature_test.core;

debug (featureTest) {
	import feature_test.exceptions;
	import feature_test.runner;

	import colorize;

	import std.stdio;
	import std.algorithm;

	alias FTImplementation = void delegate(FeatureTest);
	alias FTDelegate = void delegate();

	struct FeatureTestScenario {
		string name;
		FTDelegate implementation;
	}

	class FeatureTest {
		alias info = FeatureTestRunner.info;
		
		@property ref string name() { return _name; }
		@property ref string description() { return _description; }
		@property string[] tags() { return _tags; }
		@property ref FeatureTestScenario[] scenarios() { return _scenarios; }

		void addTags(string[] tags ...) {
			foreach(tag; tags) { if (!_tags.canFind(tag)) _tags ~= tag; }
		}
		
		final void addBeforeAll(FTDelegate d) {
			_beforeAllCallbacks ~= d;
		}
		
		final void addBeforeEach(FTDelegate d) {
			_beforeEachCallbacks ~= d;
		}
		
		final void addAfterEach(FTDelegate d) {
			_afterEachCallbacks ~= d;
		}
		
		final void addAfterAll(FTDelegate d) {
			_afterAllCallbacks ~= d;
		}
		
		// To be overridden 
		void beforeAll() {
		}
		
		// To be overridden 
		void beforeEach() {
		}
		
		// To be overridden 
		void afterEach() {
		}
		
		// To be overridden 
		void afterAll() {
		}
		
		void scenario(string name, FTDelegate implementation) {
			_scenarios ~= FeatureTestScenario(name, implementation);
		}
		
	package:
		void _beforeAll() {
			beforeAll;
			runCallbacks(_beforeAllCallbacks);
		}
		
		void _beforeEach() {
			beforeEach;
			runCallbacks(_beforeEachCallbacks);
		}
		
		void _afterEach() {
			runCallbacks(_afterEachCallbacks);
			afterEach;
		}
		
		void _afterAll() {
			runCallbacks(_afterAllCallbacks);
			afterAll;
		}
		
	private:
		string _name;
		string _description;
		string[] _tags;
		
		FeatureTestScenario[] _scenarios;
		FTDelegate[] _beforeEachCallbacks, _afterEachCallbacks, _beforeAllCallbacks, _afterAllCallbacks;
		
		void runCallbacks(FTDelegate[] callbacks) {
			foreach(callback; callbacks) callback();
		}
	}

	void feature(T)(string name, string description, void delegate(T) implementation, string[] tags ...) {
		if (FeatureTestRunner.shouldInclude(tags)) {
			auto f = new T();
			f.name = name;
			f.description = description;
			f.addTags(tags);
			implementation(f);
			FeatureTestRunner.features ~= f;
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