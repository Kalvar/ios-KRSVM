//
//  KRSVM.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSVM.h"

@implementation KRSVM

+(instancetype)sharedSVM
{
    static dispatch_once_t pred;
    static KRSVM *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRSVM alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        
    }
    return self;
}

#pragma --mark SMO
-(KRSMO *)useSMO
{
    return [KRSMO sharedSMO];
}

@end