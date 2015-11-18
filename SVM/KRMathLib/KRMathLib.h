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
-(double)multiplyParentMatrix:(NSArray *)_parentMatrix childMatrix:(NSArray *)_childMatrix;

@end