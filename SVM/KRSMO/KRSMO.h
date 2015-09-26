//
//  KRSVM.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSVM+Definition.h"

typedef void(^KRSMOCompletion)(BOOL success, NSDictionary *trainedInfo, NSInteger totalTimes);
typedef void(^KRSMOIteration)(NSInteger times, NSDictionary *trainedInfo);

@interface KRSMO : NSObject

@property (nonatomic, strong) NSMutableArray *inputs;
@property (nonatomic, strong) NSMutableArray *outputs;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSMutableArray *weights;
@property (nonatomic, strong) NSMutableArray *biases;
@property (nonatomic, assign) double constValue;
@property (nonatomic, assign) double toleranceError;
@property (nonatomic, assign) NSInteger limitIterations;

@property (nonatomic, copy) KRSMOCompletion trainingCompletion;
@property (nonatomic, copy) KRSMOIteration eachIteration;

+(instancetype)sharedSMO;
-(instancetype)init;

#pragma --mark Training Methods
-(void)addPatterns:(NSArray *)_patterns output:(NSNumber *)_output;
-(void)classify;
-(void)classifyPatterns:(NSArray *)_patterns;
-(void)verifyPatterns:(NSArray *)_patterns;
-(void)print;
-(void)clean;

#pragma --mark Blocks
-(void)setTrainingCompletion:(KRSMOCompletion)_theBlock;
-(void)setEachIteration:(KRSMOIteration)_theBlock;


@end

