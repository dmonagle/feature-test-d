module test_feature_tests;

debug (featureTest) {
	import feature_test;

	unittest {
		feature("Wrong is never right", (f) {
				f.scenario("Failing Scenario", {
						"Wrong".shouldEqual("Right", "String value");
					});
			}, "english");
		
		feature("Ultimate answer", "According to the HGTTG", (f) {
				f.scenario("What is the correct answer", {
						f.info("Calculation ultimate answer, please wait 7.5 million years...");
						42.shouldEqual(42, "The ultimate answer");
					});
				f.scenario("Check the answer according to the scrabble tiles", {
						f.info("Using Arthur Dent algorithm to produce scrabble tiles...");
						enum scrabbleTiles = 6*9;
						scrabbleTiles.shouldEqual(42, "Scrabble tile answer");
					});
			}, "hgttg", "slow");

		feature("Ultimate question", "", (f) {
				f.scenario("Calculate the _correct_ ultimate question", {
						featureTestPending;
					});
			}, "hgttg");
	}
}