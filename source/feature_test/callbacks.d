module feature_test.callbacks;

debug (featureTest) {
    alias FTCallback = void delegate();

    mixin template FTCallbacks() {
		final void addBeforeAll(FTCallback d) {
			_beforeAllCallbacks ~= d;
		}
		
		final void addBeforeEach(FTCallback d) {
			_beforeEachCallbacks ~= d;
		}
		
		final void addAfterEach(FTCallback d) {
			_afterEachCallbacks ~= d;
		}
		
		final void addAfterAll(FTCallback d) {
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
	
		void runBeforeAll() {
			beforeAll;
			runCallbacks(_beforeAllCallbacks);
		}
		
		void runBeforeEach() {
			beforeEach;
			runCallbacks(_beforeEachCallbacks);
		}
		
		void runAfterEach() {
			runCallbacks(_afterEachCallbacks);
			afterEach;
		}
		
		void runAfterAll() {
			runCallbacks(_afterAllCallbacks);
			afterAll;
		}
    protected:
		FTCallback[] _beforeEachCallbacks, _afterEachCallbacks, _beforeAllCallbacks, _afterAllCallbacks;
		
		void runCallbacks(FTCallback[] callbacks) {
			foreach(callback; callbacks) callback();
		}
    }
}