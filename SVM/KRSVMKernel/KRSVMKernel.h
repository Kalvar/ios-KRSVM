//
//  KRSVMKernel.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/12/22.
//  Copyright © 2015年 Kalvar Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum KRSVMKernelFunctions
{
    KRSVMKernelFunctionLinear = 0, // Linear, 線性函式
    KRSVMKernelFunctionRBF,        // Radial Basis Function, 徑向基函式
    KRSVMKernelFunctionSigmoid,    // Sigmoid, S 形曲線函式
    KRSVMKernelFunctionTanh        // Hyperbolic Tangent, 雙曲線正切函式
}KRSVMKernelFunctions;

@interface KRSVMKernel : NSObject

@property (nonatomic, assign) KRSVMKernelFunctions useKernel;
@property (nonatomic, assign) double alpha; // This alpha isn't the alpha of pattern, it just use on Sigmoid and Tangent.
@property (nonatomic, assign) double sigma; // This sigma use in RBF.

+(instancetype)sharedKernel;
-(instancetype)init;

-(double)normalizeValue:(double)_value;
-(double)kernelOfFeatures1:(NSArray *)_features1 features2:(NSArray *)_features2;

-(void)useLinear;
-(void)useRBF;
-(void)useSigmoid;
-(void)useTanh;

@end
