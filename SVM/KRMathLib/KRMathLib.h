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

-(NSArray *)sortArray:(NSArray *)_array byKey:(NSString *)_byKey ascending:(BOOL)_ascending;
-(double)sumParentMatrix:(NSArray *)_parentMatrix childMatrix:(NSArray *)_childMatrix;
-(NSArray *)multiplyMatrix:(NSArray *)_matrix byNumber:(double)_number;
-(NSArray *)plusMatrix:(NSArray *)_matrix anotherMatrix:(NSArray *)_anotherMatrix;

@end