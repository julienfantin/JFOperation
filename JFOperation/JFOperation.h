//
//  JFOperation.h
//  JFOperation
//
//  Created by Julien Fantin on 3/13/12.
//  Copyright (c) 2012 C6. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum JFOperationState {
    IDLE,
    QUEUED,
    EXECUTING,
    FINISHED,
    FAILED
} JFOperationState;

@interface JFOperation : NSOperation

@property (nonatomic, readonly) JFOperationState state;
@property (atomic, readwrite) NSInteger retryAttempts;

@end
