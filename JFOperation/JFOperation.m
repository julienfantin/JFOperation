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
        self.state = kOperationFailed;
        return;
    }
    
    [self setState:kOperationExecuting];
    
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
        
        NSMutableDictionary *kvcKeys = [NSMutableDictionary dictionaryWithCapacity:2];
        
        switch (state) {
            case kOperationIdle:
                break;
                                
            case kOperationExecuting:
                [kvcKeys setObject:@"isExecuting" forKey:[NSNumber numberWithBool:YES]];
                [kvcKeys setObject:@"isFinished" forKey:[NSNumber numberWithBool:NO]];
                break;
                
            case kOperationFinished:
                [kvcKeys setObject:@"isExecuting" forKey:[NSNumber numberWithBool:NO]];
                [kvcKeys setObject:@"isFinished" forKey:[NSNumber numberWithBool:YES]];
                break;
                
            case kOperationFailed:
                if (self.retryAttempts-- >= 0) {
                    // TODO Retry
                }
                else {
                    // TODO Finish
                }
                break;
                
            default:
                break;
        }
        
        [kvcKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [self willChangeValueForKey:key];
        }];
        
        _state = state;

        [kvcKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [self didChangeValueForKey:key];
        }];

    }
}

- (BOOL)isExecuting
{
    return self.state == kOperationExecuting;
}

- (BOOL)isFinished
{
    return self.state == kOperationFinished || self.state == kOperationFailed;
}

@end
