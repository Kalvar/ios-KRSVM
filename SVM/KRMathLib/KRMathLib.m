//
//  KRMathLib.m
//
//  Created by Kalvar Lin on 2015/9/19.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRMathLib.h"

@implementation KRMathLib

+(instancetype)sharedLib
{
    static dispatch_once_t pred;
    static KRMathLib *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRMathLib alloc] init];
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

-(NSArray *)sortArray:(NSArray *)_array byKey:(NSString *)_byKey ascending:(BOOL)_ascending
{
    return [_array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:_byKey ascending:_ascending]]];
}

-(double)multiplyParentMatrix:(NSArray *)_parentMatrix childMatrix:(NSArray *)_childMatrix
{
    double _sum      = 0.0f;
    NSInteger _index = 0;
    for( NSNumber *_value in _parentMatrix )
    {
        _sum += [_value doubleValue] * [[_childMatrix objectAtIndex:_index] doubleValue];
        ++_index;
    }
    return _sum;
}

@end