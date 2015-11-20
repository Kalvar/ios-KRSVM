//
//  KRMathLib.h
//
//  Created by Kalvar Lin on 2015/9/19.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@interface KRMathLib : NSObject

+(instancetype)sharedLib;
-(instancetype)init;

@end

@interface KRMathLib (fixNumber)

-(NSInteger)randomMax:(NSInteger)_maxValue min:(NSInteger)_minValue;

@end

@interface KRMathLib (fixArray)

-(NSArray *)sortArray:(NSArray *)_array byKey:(NSString *)_byKey ascending:(BOOL)_ascending;

-(double)sumMatrix:(NSArray *)_parentMatrix anotherMatrix:(NSArray *)_childMatrix;
-(double)sumArray:(NSArray *)_array;

-(NSArray *)multiplyMatrix:(NSArray *)_matrix byNumber:(double)_number;
-(NSArray *)plusMatrix:(NSArray *)_matrix anotherMatrix:(NSArray *)_anotherMatrix;

@end