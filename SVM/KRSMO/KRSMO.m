//
//  KRSVM.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSMO.h"

@implementation KRSMO (fixTrains)


@end

@implementation KRSMO

+(instancetype)sharedSMO
{
    static dispatch_once_t pred;
    static KRSMO *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRSMO alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _inputs             = [NSMutableArray new];
        _outputs            = [NSMutableArray new];
        _results            = [NSMutableArray new];
        _weights            = [NSMutableArray new];
        _biases             = [NSMutableArray new];
        
        _constValue         = 1;
        _toleranceError     = 0.001f; // 鬆馳函數 ?
        _limitIterations    = 5000;
        
        _trainingCompletion = nil;
        _eachIteration      = nil;
    }
    return self;
}

#pragma --mark Training Methods
-(void)addPatterns:(NSArray *)_patterns output:(NSNumber *)_output
{
    [_inputs addObject:[_patterns copy]];
    [_outputs addObject:[_output copy]];
}

-(void)classify
{

}

-(void)classifyPatterns:(NSArray *)_patterns
{

}

-(void)verifyPatterns:(NSArray *)_patterns
{

}

-(void)print
{

}

-(void)clean
{
    [_inputs removeAllObjects];
    [_outputs removeAllObjects];
    [_results removeAllObjects];
    [_weights removeAllObjects];
    [_biases removeAllObjects];
}

#pragma --mark Blocks
-(void)setTrainingCompletion:(KRSMOCompletion)_theBlock
{
    _trainingCompletion = _theBlock;
}

-(void)setEachIteration:(KRSMOIteration)_theBlock
{
    _eachIteration      = _theBlock;
}

@end