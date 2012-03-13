//
//  JFOperation.m
//  JFOperation
//
//  Created by Julien Fantin on 3/13/12.
//  Copyright (c) 2012 C6. All rights reserved.
//

#import "JFOperation.h"

@interface JFOperation ()
@property (nonatomic, readwrite) JFOperationState state;
- (void)performOperation;
@end

@implementation JFOperation
{
    JFOperationState _state;
}

@synthesize state = _state;
@synthesize retryAttempts = _retryAttempts;

#pragma mark - NSOperationQueue related

- (void)start
{
    if (self.isCancelled) {
        self.state = FINISHED;
        return;
    }
    
    [self setState:EXECUTING];
    
    if (self.isConcurrent) {
        [NSThread detachNewThreadSelector:@selector(performOperation) toTarget:self withObject:nil];        
    }
    else {
        [self main];
    }
}

- (void)performOperation
{
    @autoreleasepool {
        
        // Actually do something
        [self main];
                
        // Wait until it's done
        while (1) {
            
            if (self.isCancelled || self.isFinished) break;
            
            // Make sure we schedule on the current run loop so that we can trigger NSURLConnection
            // with a concurrent operation, i.e. from a background thread.
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

#pragma mark - State

/**
 * Private
 * Automaticallay takes care of KVO notifications depending on the state change.
 */
- (void)setState:(JFOperationState)state
{
    @synchronized(self) {
        
        NSString *kvcKeyName;
        
        switch (state) {
            case IDLE:
                break;
                
            case QUEUED:
                break;
                
            case EXECUTING:
                kvcKeyName = @"isExecuting";
                break;
                
            case FINISHED:
                kvcKeyName = @"isFinished";
                break;
                
            case FAILED:
                if (self.retryAttempts-- >= 0) {
                    // Retry
                }
                break;
        }
        
        if (kvcKeyName) {
            [self willChangeValueForKey:kvcKeyName];
        }
        
        _state = state;
        
        if (kvcKeyName) {
            [self didChangeValueForKey:kvcKeyName];
        }
    }
}

- (BOOL)isExecuting
{
    return self.state == EXECUTING;
}

- (BOOL)isFinished
{
    return self.state == FINISHED || self.state == FAILED;
}

@end
