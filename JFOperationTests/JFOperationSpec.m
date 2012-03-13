#import "Kiwi.h"
#import "JFOperation.h"


SPEC_BEGIN(JFOperationSpec)

describe(@"Basic usage", ^{

    __block NSOperationQueue *mainQueue;
    __block NSOperationQueue *queue;

    beforeAll(^{
        mainQueue = [NSOperationQueue mainQueue];
        queue = [NSOperationQueue new];
    });

    __block JFOperation *operation;

    beforeEach(^{
        operation = [JFOperation new];
    });
});

describe(@"Results", ^{

    context(@"Single object result", ^{
        
    });
    
    context(@"Collection result", ^{
        
    });
});

describe(@"Concurrency", ^{
   
    context(@"Running an operation from the main thread", ^{
        
    });
    
    context(@"Running an operation from a background thread", ^{
        
    });
});

describe(@"viewControllerDelegate" , ^{

    describe(@"activityIndicatorView", ^{
        
        it(@"Should call the startAnimating method upon starting", ^{
            
        });
        
        it(@"should call the stopAnimating method upon finishing", ^{
            
        });
    });
    
});

SPEC_END