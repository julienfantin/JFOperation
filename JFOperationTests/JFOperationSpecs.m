#import "Kiwi.h"
#import "JFTestOperation.h"

/*
 * NB:
 * The following specs are written against a JFOperation subclass
 * specifically designed to expose some implementation details
 * which are not available in JFOperation's public API
 */

SPEC_BEGIN(JFOperationSpec)

__block JFTestOperation *operation;
__block NSOperationQueue *queue;
__block KWMock <JFOperationDelegate> *delegate;
__block KWMock <JFOperationDelegate> *nullDelegate;

beforeEach(^{
    operation = [[JFTestOperation alloc] init];
    queue = [[NSOperationQueue alloc] init];
});

afterEach(^{
    operation = nil;
    [queue cancelAllOperations];
    queue = nil;
    delegate = nil;
    nullDelegate = nil;
});

__block void (^setupMockDelegate)(void) = ^() {
    delegate = [KWMock mockForProtocol:@protocol(JFOperationDelegate)];
    operation.delegate = delegate;
};

__block void (^setupNullMockDelegate)(void) = ^() {
    nullDelegate = [KWMock nullMockForProtocol:@protocol(JFOperationDelegate)];
    operation.delegate = nullDelegate;
};

describe(@"Delegate", ^{
    
    beforeEach(^{
        setupMockDelegate();
    });
    
    specify(^{
        [theValue(operation.delegate) shouldNotBeNil];
    });
});

describe(@"Concurrency", ^{
    
    context(@"Subclass", ^{
        
        it(@"Should run on MainThread when non-concurrent", ^{
            operation.isConcurrent = NO;
            [queue addOperation:operation];
            [[expectFutureValue(theValue([operation ranOnMainThread])) shouldEventually] beTrue];
        });
        
        it(@"Should run on a background thread when concurrent", ^{
            operation.isConcurrent = YES;
            [queue addOperation:operation];
            [[expectFutureValue(theValue([operation ranOnMainThread])) shouldEventually] beFalse];
        });
    });
    
    context(@"mainBlock", ^{
       
        it(@"Should invoke the mainBlock on the main MainThread when non-concurrent", ^{
            operation.isConcurrent = NO;
            operation.mainBlock = ^(JFOperation *o) {
                if (NO == [NSThread isMainThread]) {
                    [NSException raise:@"Should run on main thread" format:@""];
                }
            };
            [queue addOperation:operation];
        });
    });
    
});

/*
 * TODO
 *
 * conditional restart
 */

describe(@"Retying a failed operation", ^{
    
    describe(@"Retry and finish", ^{
    
        beforeEach(^{
            operation.retryAttempts = 2;
            operation.timesShouldFail = 2;
        });
        
        it(@"Should eventually finish if its retryAttemps equal or exceed it number of failures", ^{
            [queue addOperation:operation];
            [[expectFutureValue(theValue([operation state])) shouldEventually] equal:theValue(kOperationFinished)];
        });
        
        context(@"Delegate", ^{
            
            it(@"Should get an operationDidFinsihCallBack, but ShouldNot get an operationDidFailCallBack", ^{
                setupNullMockDelegate();
                [[[delegate shouldEventually] receive] operationWillStart:operation];
                [[[delegate shouldEventually] receive] operationDidStart:operation];

                [[[delegate shouldEventually] receive] operationWillStart:operation];
                [[[delegate shouldEventually] receive] operationDidStart:operation];

                [[[delegate shouldEventually] receive] operationWillStart:operation];
                [[[delegate shouldEventually] receive] operationDidStart:operation];
                
                [[[delegate shouldEventually] receive] operationDidFinish:operation];
                [queue addOperation:operation];
            });
        });
        
        context(@"Blocks", ^{
            
            __block id obj;
            
            beforeEach(^{
                obj = nil;
            });
            
             it(@"Should invoke the onFinish block", ^{
                 operation.onFinish = ^(JFOperation *op) {
                     obj = @1;
                 };

                 [queue addOperation:operation];
                 [[obj shouldEventually] beNonNil];
             });
            
            it(@"ShouldNot invoke the onFailed block", ^{
                operation.onFail = ^(JFOperation *op) {
                    obj = @1;
                    [NSException raise:@"Should not be invoked" format:@""];
                };
                [queue addOperation:operation];
                [[obj shouldEventually] beNil];
            });
        });
    });
    
    describe(@"Retry and fail", ^{
    
        beforeEach(^{
            operation.retryAttempts = 1;
            operation.timesShouldFail = 2;
        });
        
        it(@"Should fail if its retryAttempts are exceeded by the number of failures", ^{
            [queue addOperation:operation];
            [[expectFutureValue(theValue([operation state])) shouldEventually] equal:theValue(kOperationFailed)];
        });
        
        context(@"Blocks", ^{
            
            __block id obj;
            
            beforeEach(^{
                obj = nil;
            });
            
            it(@"ShouldNot invoke the onFinish block", ^{
                operation.onFinish = ^(JFOperation *op) {
                    obj = @1;
                    [NSException raise:@"Should not be invoked" format:@""];
                };
                [queue addOperation:operation];
                [[obj shouldEventually] beNil];
            });
            
            it(@"Should invoke the onFailed block", ^{
                operation.onFail = ^(JFOperation *op) {
                    obj = @1;
                };
                [queue addOperation:operation];
                [[obj shouldEventually] beNonNil];
            });
        });
    });
});
    
// TODO
// concurrent

describe(@"Lifecycle", ^{
    
    context(@"Delegate", ^{
        
        describe(@"Callbacks", ^{

            it(@"Should go from willStart to didStart to didFinish", ^{
                [[[delegate shouldEventually] receive] operationWillStart:operation];
                [[[delegate shouldEventually] receive] operationDidStart:operation];
                [[[delegate shouldEventually] receive] operationDidFinish:operation];
                [queue addOperation:operation];
            });
        
            it(@"Should get an operationDidFail callback", ^{
                operation.timesShouldFail = 1;
                [[[delegate shouldEventually] receive] operationWillStart:operation];
                [[[delegate shouldEventually] receive] operationDidStart:operation];
                [[[delegate shouldEventually] receive] operationDidFail:operation];
                [queue addOperation:operation];
            });
        });
    });
});

describe(@"Results", ^{
    
    __block NSArray *results;
    
    beforeEach(^{
        results = @[@1, @2, @3];
        
        operation.mainBlock = ^(JFOperation *op) {
            [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [op signalTransientResult:obj];
                [op markAsFinishedWithResult:results];
            }];
        };
    });
    
    context(@"Delegate", ^{
        
        beforeEach(^{
            setupNullMockDelegate();
        });
        
        it(@"Should signal a transient result", ^{
            [[[delegate shouldEventually] receive] operation:operation didProduceTransientResult:@1];
            [[[delegate shouldEventually] receive] operation:operation didProduceTransientResult:@2];
            [[[delegate shouldEventually] receive] operation:operation didProduceTransientResult:@3];
            [queue addOperation:operation];
        });
        
        it(@"Should signal a final result", ^{
            [[[delegate shouldEventually] receive] operation:operation didFinishWithResult:results];
            [queue addOperation:operation];
        });
    });
    
    context(@"Blocks", ^{
        
        __block NSMutableArray *receivedResults;
        
        beforeEach(^{
            receivedResults = nil;
        });
        
        it(@"Should invoke onResult with transient results", ^{
            receivedResults = [NSMutableArray arrayWithCapacity:[results count]];
            
            operation.onResult = ^ (JFOperation *o, id result) {
                [receivedResults addObject:result];
            };
            [queue addOperation:operation];
            [[receivedResults shouldEventually] equal:results];
        });
        
        it(@"Should invoke onFinishWithResult with results", ^{
            operation.onFinishWithResult = ^ (JFOperation *o, id result) {
                receivedResults = result;
            };
            [queue addOperation:operation];
            [[receivedResults shouldEventually] equal:results];
        });
    });
});

// TODO make sure we respect KVO notification conventions

SPEC_END
