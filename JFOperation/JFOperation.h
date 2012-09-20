//
//  JFOperation.h
//  JFOperation
//
//  Created by Julien Fantin on 3/13/12.
//  Copyright (c) 2012 C6. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JFOperation;

#pragma Internal state type declaration

typedef enum JFOperationState {
    kOperationIdle,
    kOperationExecuting,
    kOperationFinished,
    kOperationFailed,
    kOperationStates
} JFOperationState;

#pragma Blocks type declarations

typedef void (^JFOperationBlock) (JFOperation *);
typedef void (^JFOperationResultBlock) (JFOperation *, id);

#pragma Blocks protocol

@protocol JFOperationBlocks <NSObject>
@property (nonatomic, strong) JFOperationBlock mainBlock;
@property (nonatomic, strong) JFOperationBlock onReady;
@property (nonatomic, strong) JFOperationBlock onStart;
@property (nonatomic, strong) JFOperationResultBlock onResult;
@property (nonatomic, strong) JFOperationResultBlock onFinishWithResult;
@property (nonatomic, strong) JFOperationBlock onFinish;
@property (nonatomic, strong) JFOperationBlock onFail;
@end

#pragma Delegate protocol

@protocol JFOperationDelegate <NSObject>
@optional
- (void)operationWillStart:(JFOperation *)operation;
- (void)operationDidStart:(JFOperation *)operation;
- (void)operation:(JFOperation *)operation didProduceTransientResult:(id)result;
- (void)operation:(JFOperation *)operation didFinishWithResult:(id)result;
- (void)operationDidFinish:(JFOperation *)operation;
- (void)operationDidFail:(JFOperation *)operation;
@end

@interface JFOperation : NSOperation <JFOperationBlocks>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0
@property (nonatomic, weak) id <JFOperationDelegate> delegate;
#else
@property (nonatomic, unsafe_unretained) id <JFOperationDelegate> delegate;
#endif
@property (nonatomic, readonly) JFOperationState state;
@property (nonatomic, readwrite) NSInteger retryAttempts;
@property (nonatomic, assign) BOOL isConcurrent;

- (void)signalTransientResult:(id)result;
- (void)markAsFinishedWithResult:(id)result;
- (void)markAsFinished;
- (void)markAsFailed;

@end
