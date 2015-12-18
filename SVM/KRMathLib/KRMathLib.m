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

@end

@implementation KRMathLib (fixNumber)

-(NSInteger)randomMax:(NSInteger)_maxValue min:(NSInteger)_minValue
{
    return ( arc4random() / ( RAND_MAX * 2.0f ) ) * (_maxValue - _minValue) + _minValue;;
}

@end

@implementation KRMathLib (fixArray)

-(NSArray *)sortArray:(NSArray *)_array byKey:(NSString *)_byKey ascending:(BOOL)_ascending
{
    return [_array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:_byKey ascending:_ascending]]];
}

// ex : [1, 2]^T * [3, 4]
-(double)sumMatrix:(NSArray *)_parentMatrix anotherMatrix:(NSArray *)_childMatrix
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

-(double)sumArray:(NSArray *)_array
{
    double _sum = 0.0f;
    for( NSNumber *_value in _array )
    {
        _sum += [_value doubleValue];
    }
    return _sum;
}

// ex : 0.5f * [1, 2]
-(NSArray *)multiplyMatrix:(NSArray *)_matrix byNumber:(double)_number
{
    NSMutableArray *_array = [NSMutableArray new];
    for( NSNumber *_value in _matrix )
    {
        double _newValue = _number * [_value doubleValue];
        [_array addObject:[NSNumber numberWithDouble:_newValue]];
    }
    return _array;
}

// ex : [1, 2] + [3, 4]
-(NSArray *)plusMatrix:(NSArray *)_matrix anotherMatrix:(NSArray *)_anotherMatrix
{
    NSMutableArray *_array = [NSMutableArray new];
    NSInteger _index       = 0;
    for( NSNumber *_value in _matrix )
    {
        double _newValue = [_value doubleValue] + [[_anotherMatrix objectAtIndex:_index] doubleValue];
        [_array addObject:[NSNumber numberWithDouble:_newValue]];
        ++_index;
    }
    return _array;
}

@end