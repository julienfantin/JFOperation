//
//  JFTestOperation.m
//  JFOperation
//
//  Created by Julien Fantin on 9/11/12.
//  Copyright (c) 2012 C6. All rights reserved.
//

#import "JFTestOperation.h"

@implementation JFTestOperation

@synthesize ranOnMainThread;
@synthesize timesShouldFail;

- (void)main
{
    self.ranOnMainThread = [NSThread isMainThread];
    [self performSelector:@selector(fakeCallback) withObject:nil afterDelay:0];
}

- (void)fakeCallback
{
    if (self.timesShouldFail-- > 0) {
        [self markAsFailed];
    }
    else {
        [self markAsFinished];
    }
}

@end
