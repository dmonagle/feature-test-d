module feature_test.shoulds.core;

debug (featureTest) {
	import std.string;
	import feature_test.exceptions;

	template should(alias operation, string description) {
		bool should(E)(lazy E expression, string name="Value", string file = __FILE__, typeof(__LINE__) line = __LINE__) {
			auto eValue = expression;
			if (operation(eValue)) return true;
			throw new FeatureTestException(format("%s should %s, but it was %s", name, description, eValue), file, line);
		}
	}
	
	template shouldValue(alias operation, string description) {
		bool shouldValue(E, V)(lazy E expression, V value, string name="Value", string file = __FILE__, typeof(__LINE__) line = __LINE__) {
			auto eValue = expression;
			if (operation(eValue, value)) return true;
			throw new FeatureTestException(format("%s should %s %s, but was actually %s", name, description, value, eValue), file, line);
		}
	}
	
	alias shouldBeTrue = should!((e) => e ? true : false, "be true");
	alias shouldBeFalse = should!((e) => e ? false : true, "be false");
	alias shouldEqual = shouldValue!((e, v) => e == v, "equal");
	alias shouldBeGreaterThan = shouldValue!((e, v) => e > v, "be greater than");
	alias shouldBeLessThan = shouldValue!((e, v) => e < v, "be less than");
	alias shouldNotBeEmpty = should!((e) => e.length ? true : false, "not be empty");
}
