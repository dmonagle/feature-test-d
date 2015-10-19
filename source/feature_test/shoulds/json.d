module feature_test.shoulds.json;

version (Have_vibe_d) {
	import vibe.data.json;
	/// Asserts the the given expression is of a specific Json type
	bool shouldBe(Json.Type jsonType)(Json object, string file = __FILE__, typeof(__LINE__) line = __LINE__) {
		bool function(ref const Json) check = mixin("&is" ~ type);
		if (object.type == jsonType) return true;
		throw new FeatureTestException(format("Should be JSON type %s but is %s", jsonType, object.type), file, line);
	}
}