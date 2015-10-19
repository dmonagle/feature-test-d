# Feature Test D

## Introduction

This library is to be included in a D2 project where feature testing is required. It should be fairly light and allows the definitions of features and scenarios. It extends upon D's native unittest and has no compilation or runtime impact when compiled without the unittest and featureTest debugging flag.

## How it works

Feature testing is enabled when compiled with both unittest and --debug=featureTest

When the featureTest debugging flag is present, a static class, FeatureTestRunner, is created. It has a static destructor that does all of the feature testing once all of the unittest blocks have been executed. This allows the configuration of featureTests from within unittest blocks which are deferred until the runner is asked to destruct. This has the advantage that there is no special build requirement to make sure that every feature within a project is run, no matter what the compile order was.

## Writing Feature Tests

A feature test can be defined in any compiled D file in your project. This can be the same file as a class that the feature revolves around, or all features tests could live within a subdirectory.

There are some example tests included with this library in the file source/test_feature_tests;  

```D
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
```

So the first line after the module declaration is making the compilation of the test dependant on the debug version "featureTest" being defined. This is how we prevent all of the feature tests being built when either the main code, or only simple unit testing is to be done. 

A feature is defined by calling the feature helper method, passing in a title and (optionally) a description and then a lamda function in which we define the scenarios for the feature.

The scenario helper is called on the feature instance and within the lambda body we do our testing. There is a module, feature_test.shoulds, which has quite a few handy should methods. These shoulds will throw a FeatureTestException if they do not succeed, which will be interpreted by the FeatureTestRunner and be used to display the final report when running tests.

We will run this using dub, although dub should not be necessary:

	dub test --debug=featureTest
	
And the output we get is:

	Feature Testing Enabled!
	All unit tests have been run successfully.
	Randomizing Features
	Feature: Ultimate question (hgttg)
		Scenarios:
			Calculate the _correct_ ultimate question
				[ PENDING ]
	
	Feature: Ultimate answer (hgttg, slow)
	
		According to the HGTTG
	
		Scenarios:
			What is the correct answer
				Calculation ultimate answer, please wait 7.5 million
				years...
				[ PASS ]
			Check the answer according to the scrabble tiles
				Using Arthur Dent algorithm to produce scrabble tiles...
				[ FAIL ]
	
	Feature: Wrong is never right (english)
		Scenarios:
			Failing Scenario
				[ FAIL ]
	
	
	!!! Pending !!!
	
	Feature: Ultimate question
		Calculate the _correct_ ultimate question
		source/test_feature_tests.d(27)
		Pending
	
	
	!!! Failures !!!
	
	Feature: Ultimate answer
		Check the answer according to the scrabble tiles
		source/test_feature_tests.d(21)
		Scrabble tile answer should equal 42, but was actually 54
	
	Feature: Wrong is never right
		Failing Scenario
		source/test_feature_tests.d(9)
		String value should equal Right, but was actually Wrong
	
	Features tested: 3
	Scenarios tested: 3
	Scenarios passed: 1
	Scenarios failed: 2
	Scenarios pending: 1
	
Things to note:

* As each feature and scenario is run detailed information is output to show what is happening.
* The f.info calls allow verbose information to form part of the test output.
* While failures are noted at the time they occur, we get a nice summary at the bottom if tests fail.
* The file and line number of the failing test is reported as part of the error message.
* When using the "should" methods, the errors give both the expected and the actual values that were tested. Great for debugging!

### Writing a helper script

If running tests is something you do frequently (and it should be!), you can create a simple script to make the execution simpler. I have a scripts directory at the root of my project and in it I have a script called "featureTest". It looks like this:

```bash
#!/bin/bash
dub test --debug=featureTest -- $@
```

The "--$@" will mean any parameters passed to this script will be passed to the executable generated by "dub test" when it is run.

### Tagging

There are situations where you may not want to run the full suite of tests you have made:

* Some of the tests may take a long time
* Some of the tests may not be able to run in the current environment (eg. needs access to local database)

In these situations we can use feature tagging to select which features can be run. For the time being, this only works at the feature level, not scenario.

Note in the example features, after the lambda function there are one or more string parameters. These make up the tags associated with the feature.

When the test executable is run, the runner looks at the arguments passed on the command line and uses them to select features to run. By default all features are run. Tags can be specified as follows:

* **@_tagName_** Only run tests with the given tagName. Multiple tags imply an OR, not an AND. 
* **-_tagName_** Ignore any tests that contain the tagName
* **+_tagName_** Negates an ignore for tagName if it appeared before it on the command line

Tags can be specified in groups for convenience, Eg:

	@myLibrary,myApp -slow,localMongo
 
#### Examples

Using the script above, I can do the following:

```bash
scripts/featureTest 						# Runs all tests
scripts/featureTest @hgttg					# Only runs featureTests with the hgttg tag
scripts/featureTest @hgttg -slow			# Only runs featureTests with the hgttg tag but leave out the slow tag
scripts/featureTest @hgttg,english -slow	# Only runs featureTests with the hgttg or english tag but leave out the slow tag
scripts/featureTest -slow @httg +slow		# Only httg tags get run. The +slow negates the -slow.
```

#### Why the +?

So why have a prefix which negates the former prefix? It's to make scripts a little easier to write. Imagine the same convenience script we created earlier, with a slight change:

```bash
#!/bin/bash
dub test --debug=featureTest -- -slow -localMongo $@
```

So by default now the script will leave out slow and localMongo (presuming that localMongo means the test requires a MongoDB instance running on port 9200.)

And if we want to check anything that needs localMongo access, we can do it as such:

```bash
scripts/featureTest +localMongo
```

### Hooks

Features have a number of hooks to allow us to minimise code. They are as follows:

* beforeAll: Runs once before all scenarios in the feature.
* beforeEach: Runs before each scenario in the feature.
* afterEach: Runs after each scenario in the feature.
* afterAll: Runs after all scenarios in the feature.

These hooks can be utilised within the feature's lambda block by calling the add method corresponding to the hook. Example:

```D
feature("POST /api/users", "Add a new user", (f) {
            f.addBeforeAll({
				// Ensure the user table exists
			});
			
            f.addBeforeEach({
				// Clean up the user table
			});
			
            f.addAfterAll({
				// Drop the user table
			});
	)};
```


### Custom Features

There would be a lot of repetition if we couldn't reuse some of our code. Luckily we are working with an object oriented language which allows for easy code reuse.

Example. We have a vibe.d app which serves an API and we want the features to have some common code to ensure that the tests themselves only contain code relevant to the specific test. The code below is theoretical but should give a good idea of how the paradigm works. 

```D
module _feature_tests.controllers.controller_test;

debug (featureTest) {
	bool startServerForFeatureTests() {
		static bool started;
		if (started) return false;
		
		// Set the logLevel to error to stop lots of annoying feedback from the HTTP Server
		setLogLevel(LogLevel.error); 
		auto settings = new HTTPServerSettings;
		settings.port = 9080;
		listenHTTP(settings, defaultRouter); // Obviously defaultRouter would have to come from somewhere in your application

		started = true;
		return true;
	}
	
	class ControllerFeatureTest : FeatureTest {
		override void beforeAll() {
			super.beforeAll();
			
			dropUsers();

			if (startServerForFeatureTests) {
				info("Started test HTTP server");
				info("Clearing authentication tokens...");
				clearAuthenticationTokens;
			}
		}

		auto restClient(A)() {
			auto client = new RestInterfaceClient!A("http://localhost:9080/");
			client.requestFilter((req) {
				if (_token) req.headers["Authorization"] = "token " ~ _token.token;
			});

			return client;
		}

		/// Creates a valid auth token for the user
		void authenticateUser(User user, bool sync = true) {
			import std.stdio;

			auto at = new AuthenticationToken;
			at.generate();
			at.userId = user._id;
			_token = at;
		}

	private:
		AuthenticationToken _token;
	}
}
```

Things to note:

* Creating a custom feature is as simple as deriving the class from FeatureTest (or any class that is itself derived from FeatureTest)
* The hooks can be overridden in the custom class (don't forget to call super!)

Using this class is very simple:

```D
feature!ControllerFeatureTest("POST /api/users", "Create a user", (f) {
			// Define scenarios....
        });
		
```

Now the "f" is of type FeatureControllerTest and any methods or properties that exist on it can be called directly.

This as well as the ability to create any number of custom feature tests can lead to some powerful setups:

FeatureTest -> DatabaseFeatureTest -> ControllerFeatureTest

You can then put all of the methods for controllering and configuring database access into a single class, then build on that for ControllerFeatureTest and any hooks defined will be chained together.
