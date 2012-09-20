//
//  JFTestOperation.h
//  JFOperation
//
//  Created by Julien Fantin on 9/11/12.
//  Copyright (c) 2012 C6. All rights reserved.
//

#import "JFOperation.h"

@interface JFTestOperation : JFOperation

@property (nonatomic, assign) BOOL ranOnMainThread;
@property (nonatomic, assign) NSInteger timesShouldFail;
@property (nonatomic, readwrite) JFOperationState state;

@end
