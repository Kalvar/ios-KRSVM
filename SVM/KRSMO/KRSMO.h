//
//  KRSVM.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSVM+Definition.h"

typedef void(^KRSMOCompletion)(BOOL success, NSArray *weights, NSArray *biases, NSArray *outputs, NSInteger totalIterations);
typedef void(^KRSMOIteration)(NSInteger iteration, NSArray *weights, NSArray *biases);
typedef void(^KRSMODirectOutput)(NSArray *weights, NSArray *biases, NSArray *outputs);

@interface KRSMO : NSObject

@property (nonatomic, strong) NSMutableArray *patterns;
@property (nonatomic, strong) NSMutableArray *weights;
@property (nonatomic, strong) NSMutableArray *biases;
@property (nonatomic, assign) double constValue;
@property (nonatomic, assign) double toleranceError;
@property (nonatomic, assign) NSInteger maxIteration;

@property (nonatomic, copy) KRSMOCompletion trainingCompletion;
@property (nonatomic, copy) KRSMOIteration perIteration;

+(instancetype)sharedSMO;
-(instancetype)init;

#pragma --mark Training Methods
-(void)addPatterns:(NSArray *)_inputs target:(double)_output alpha:(double)_alpha;
-(void)addPatterns:(NSArray *)_inputs target:(double)_output;
-(void)addBiase:(NSNumber *)_lineBias;
-(void)addWeights:(NSArray *)_lineWeights;

-(void)classify;
-(void)classifyWithCompletion:(KRSMOCompletion)_completion;
-(void)classifyPatterns:(NSArray *)_patterns completion:(KRSMODirectOutput)_completion;
-(void)verifyPatterns:(NSArray *)_patterns;
-(void)print;
-(void)clean;

#pragma --mark Blocks
-(void)setTrainingCompletion:(KRSMOCompletion)_theBlock;
-(void)setPerIteration:(KRSMOIteration)_theBlock;


@end

