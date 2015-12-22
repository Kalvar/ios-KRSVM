//
//  KRSVM.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KRSVMPattern : NSObject<NSCopying>

@property (nonatomic, strong) NSMutableArray *features;
@property (nonatomic, assign) double targetValue;
@property (nonatomic, assign) double alphaValue;
@property (nonatomic, assign) double errorValue;
@property (nonatomic, assign) double toleranceError;
@property (nonatomic, assign) BOOL isMatchKkt;
@property (nonatomic, strong) NSNumber *classifiedTarget;
// To record what index number in patterns of parent class and it could be ID Key
@property (nonatomic, assign) NSInteger index;
// To identify the singal of target value is + or -
@property (nonatomic, assign) BOOL isPlusSignal;

#warning 想想看是否真的需要記錄次數 ? 是否要設一個隨時能停止隨機更新的機制 ?
// To record how many times been main updated pattern
//@property (nonatomic, assign) NSInteger beenMainTimes;
// To record how many times been match updated pattern

+(instancetype)sharedPattern;
-(instancetype)init;

-(void)addFeatures:(NSArray *)_featureVectors;
-(BOOL)isMatchKktByWeights:(NSArray *)_weights bias:(NSNumber *)_bias constValue:(double)_constValue;
-(NSNumber *)getClassifyTarget;

@end

