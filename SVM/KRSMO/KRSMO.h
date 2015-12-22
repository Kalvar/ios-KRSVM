//
//  KRSVM.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSVM+Definition.h"

typedef void(^KRSMOCompletion)(BOOL success, NSArray *weights, NSArray *biases, NSDictionary *groups, NSInteger totalIterations);
typedef void(^KRSMOIteration)(NSInteger iteration, NSArray *weights, NSArray *biases);
typedef void(^KRSMODirectOutput)(NSArray *weights, NSArray *biases, NSArray *results, NSDictionary *allGroups);

@interface KRSMO : NSObject

@property (nonatomic, strong) NSMutableArray *patterns;
@property (nonatomic, strong) NSMutableArray *weights;
@property (nonatomic, strong) NSMutableArray *biases;
@property (nonatomic, assign) double constValue;
@property (nonatomic, assign) double toleranceError;
@property (nonatomic, assign) NSInteger maxIteration;
@property (nonatomic, strong) KRSVMKernel *kernel;

@property (nonatomic, copy) KRSMOCompletion trainingCompletion;
@property (nonatomic, copy) KRSMOIteration perIteration;
@property (nonatomic, copy) KRSMODirectOutput directOutput;

// It records all targets of classification that means how many groups we wanna have
@property (nonatomic, strong) NSMutableDictionary *groups;

+(instancetype)sharedSMO;
-(instancetype)init;

#pragma --mark Settings Methods
-(KRSVMPattern *)createPatternByFeatures:(NSArray *)_features target:(double)_output alpha:(double)_alpha index:(NSInteger)_index;
-(KRSVMPattern *)createPatternByFeatures:(NSArray *)_features;
-(void)addPatterns:(NSArray *)_inputs target:(double)_output alpha:(double)_alpha;
-(void)addPatterns:(NSArray *)_inputs target:(double)_output;
-(void)addBias:(NSNumber *)_lineBias;
-(void)addWeights:(NSArray *)_lineWeights;
-(void)addGroupOfTarget:(double)_groupTarget;

#pragma --mark Training Methods
-(void)classify;
-(void)classifyWithCompletion:(KRSMOCompletion)_completion;
-(void)classifyWithPerIteration:(KRSMOIteration)_eachIteration completion:(KRSMOCompletion)_completion;
-(void)classifyPatterns:(NSArray *)_samples completion:(KRSMODirectOutput)_completion;
-(void)verifyPatterns:(NSArray *)_samples;
-(void)print;
-(void)clean;

#pragma --mark Blocks
-(void)setTrainingCompletion:(KRSMOCompletion)_theBlock;
-(void)setPerIteration:(KRSMOIteration)_theBlock;
-(void)setDirectOutput:(KRSMODirectOutput)_theBlock;


@end

