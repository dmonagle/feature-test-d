module feature_test.exceptions;

import core.exception;

class FeatureTestException : Exception {
	this(string s, string file = __FILE__, typeof(__LINE__) line = __LINE__) { super(s, file, line); }
	this(string file = __FILE__, typeof(__LINE__) line = __LINE__) { pending = true; super("Pending", file, line); }
	
	bool pending = false;
}
