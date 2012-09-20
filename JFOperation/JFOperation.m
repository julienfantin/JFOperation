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
- (void)asynchronousMain;
- (void)markAsReady;
- (void)markAsStarted;
@end

@implementation JFOperation

@synthesize state = _state;
@synthesize retryAttempts = _retryAttempts;
@synthesize isConcurrent = __isConcurrent;

@synthesize mainBlock = _mainBlock;

@synthesize onReady = _onReady;
@synthesize onStart = _onStart;
@synthesize onResult = _onResult;
@synthesize onFinishWithResult = _onFinishWithResult;
@synthesize onFinish = _onFinish;
@synthesize onFail = _onFail;

@synthesize delegate = _delegate;

#pragma mark - NSOperationQueue related

- (void)start
{    
    if (self.isCancelled) {
        self.state = kOperationFailed;
        return;
    }
    
    [self markAsReady];

    [self markAsStarted];

    // TODO GCD dispatch
    if (self.isConcurrent) {
        if (self.mainBlock != nil) {

            dispatch_block_t block = ^{
                self.mainBlock(self);
            };
            dispatch_queue_t queue = dispatch_get_main_queue();
            dispatch_async(queue, block);
        }
        else {
            [self performSelectorInBackground:@selector(asynchronousMain) withObject:nil];
        }
    }
    else {
        if (self.mainBlock != nil) {
            self.mainBlock(self);
        }
        else {
            [self performSelectorOnMainThread:@selector(main) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)main
{
    [NSException raise:@"Abstract Method" format:@"Override this method in your subclass."];
}

- (void)asynchronousMain
{
    @autoreleasepool {
        @synchronized(self) {
            
            [self main];

            while (!self.isCancelled && !self.isFinished) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
    }
}

- (void)markAsReady
{
    self.state = kOperationIdle;
    
    if ([self.delegate respondsToSelector:@selector(operationWillStart:)]) {
        [self.delegate operationWillStart:self];
    }
    
    if (self.onReady != nil) {
        self.onReady(self);
    }
}

- (void)markAsStarted
{
    self.state = kOperationExecuting;

    if ([self.delegate respondsToSelector:@selector(operationDidStart:)]) {
        [self.delegate operationDidStart:self];
    }
    
    if (self.onStart != nil) {
        self.onStart(self);
    }
}

- (void)signalTransientResult:(id)result
{
    if ([self.delegate respondsToSelector:@selector(operation:didProduceTransientResult:)]) {
        [self.delegate operation:self didProduceTransientResult:result];
    }
    
    if (self.onResult != nil) {
        self.onResult(self, result);
    }
}

- (void)markAsFinishedWithResult:(id)result
{
    if ([self.delegate respondsToSelector:@selector(operation:didFinishWithResult:)]) {
        [self.delegate operation:self didFinishWithResult:result];
    }
    
    if (self.onFinishWithResult != nil) {
        self.onFinishWithResult(self, result);
    }
}

- (void)markAsFinished
{
    if ([self.delegate respondsToSelector:@selector(operationDidFinish:)]) {
        [self.delegate operationDidFinish:self];
    }

    if (self.onFinish != nil) {
        self.onFinish(self);
    }
    
    self.state = kOperationFinished;
}

- (void)markAsFailed
{
    if (self.retryAttempts-- > 0) {
        [self start];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(operationDidFail:)]) {
        [self.delegate operationDidFail:self];
    }
    
    if (self.onFail != nil) {
        self.onFail(self);
    }
    
    self.state = kOperationFailed;
}

#pragma mark - State

/**
 * Private
 * Automaticallay takes care of KVO notifications depending on the state change.
 */
- (void)setState:(JFOperationState)state
{
    @synchronized(self) {
        
        if (state == _state) {
            return;
        }
        
        if (self.isConcurrent == NO) {
            // No need for KVO notifications in a non-concurrent operation
            _state = state;
            return;
        }
        
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
                [kvcKeys setObject:@"isExecuting" forKey:[NSNumber numberWithBool:NO]];
                [kvcKeys setObject:@"isFinished" forKey:[NSNumber numberWithBool:YES]];
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
    @synchronized(self) {
        return self.state == kOperationExecuting;
    }
}

- (BOOL)isFinished
{
    @synchronized(self) {
        return self.state == kOperationFinished || self.state == kOperationFailed;
    }
}

@end
