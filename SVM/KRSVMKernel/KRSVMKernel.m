//
//  KRSVMKernel.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/12/22.
//  Copyright © 2015年 Kalvar Lin. All rights reserved.
//

#define DEFAULT_SIGMOID_ALPHA_VALUE 1.0f
#define DEFAULT_TANGENT_ALPHA_VALUE 1.0f
#define DEFAULT_RBF_SIGMA_VALUE     2.0f

#import "KRSVMKernel.h"

@implementation KRSVMKernel (fixNormalization)

-(double)sgn:(double)_value
{
    return ( _value >= 0.0f ) ? 1.0f : -1.0f;
}

@end

@implementation KRSVMKernel (fixKernels)

-(double)linear:(NSArray *)_features1 features2:(NSArray *)_features2
{
    double _sum      = 0.0f;
    NSInteger _index = 0;
    for( NSNumber *_value in _features1 )
    {
        _sum += [_value doubleValue] * [[_features2 objectAtIndex:_index] doubleValue];
        ++_index;
    }
    return _sum;
}

-(double)rbf:(NSArray *)_features1 features2:(NSArray *)_features2
{
    double _sum      = 0.0f;
    NSInteger _index = 0;
    for( NSNumber *_value in _features1 )
    {
        // Formula : s = s + ( v1[i] - v2[i] )^2
        double _v  = [_value doubleValue] - [[_features2 objectAtIndex:_index] doubleValue];
        _sum      += ( _v * _v );
        ++_index;
    }
    // Formula : exp^( -s / ( 2.0f * sigma * sigma ) )
    return pow(M_E, ((-_sum) / ( 2.0f * self.sigma * self.sigma )));
}

-(double)sigmoid:(NSArray *)_features1 features2:(NSArray *)_features2
{
    double _sum = [self linear:_features1 features2:_features2];
    return ( 1.0f / ( 1.0f + pow(M_E, (-self.alpha * _sum)) ) );
}

// Formula is “ ( 2.0 / (1.0 + e^(-alpha * x)) ) - 1.0 “, alpha is default 1.0, the alpha value 越大則曲線越平滑
-(double)tangent:(NSArray *)_features1 features2:(NSArray *)_features2
{
    double _sum = [self linear:_features1 features2:_features2];
    return ( 2.0f / ( 1.0f + pow(M_E, (-self.alpha * _sum)) ) ) - 1.0f;
}

@end

@implementation KRSVMKernel

+(instancetype)sharedKernel
{
    static dispatch_once_t pred;
    static KRSVMKernel *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRSVMKernel alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _useKernel = KRSVMKernelFunctionLinear;
        
        // Sigmoid default value is 1.0f
        // Tangent default value is 1.0f that better than 2.0f
        // We will set up alpha, sigma default value when we setup kernel function
        _alpha     = DEFAULT_SIGMOID_ALPHA_VALUE;
        
        // RBF that default sigma value is 2.0f that is better, but some papers said 0.5f, we used 2.0f in here
        _sigma     = DEFAULT_RBF_SIGMA_VALUE;
    }
    return self;
}

#pragma --mark Normorlizion
-(double)normalizeValue:(double)_value
{
    // It should not only Linear need to normalize its target value to (-1, 1), try to normalize all first,
    // and we will change the rule later.
    return [self sgn:_value];
    
    /*
    double _v = _value;
    switch (_useKernel)
    {
        // Linear needs to normalize its target value to (-1, 1)
        case KRSVMKernelFunctionLinear:
            _v = [self sgn:_value];
            break;
        default:
            break;
    }
    return _v;
     */
}

#pragma --mark Kernel Functions
-(double)kernelOfFeatures1:(NSArray *)_features1 features2:(NSArray *)_features2
{
    double _kernelValue = 0.0f;
    switch (_useKernel)
    {
        case KRSVMKernelFunctionRBF:
            _kernelValue = [self rbf:_features1 features2:_features2];
            break;
        case KRSVMKernelFunctionSigmoid:
            _kernelValue = [self sigmoid:_features1 features2:_features2];
            break;
        case KRSVMKernelFunctionTangent:
            _kernelValue = [self tangent:_features1 features2:_features2];
            break;
        case KRSVMKernelFunctionLinear:
        default:
            _kernelValue = [self linear:_features1 features2:_features2];
            break;
    }
    return _kernelValue;
}

-(void)useLinear
{
    self.useKernel = KRSVMKernelFunctionLinear;
}

-(void)useRBF
{
    self.useKernel = KRSVMKernelFunctionRBF;
}

-(void)useSigmoid
{
    self.useKernel = KRSVMKernelFunctionSigmoid;
}

-(void)useTangent
{
    self.useKernel = KRSVMKernelFunctionTangent;
}

#pragma --mark Setters
-(void)setUseKernel:(KRSVMKernelFunctions)_theKernel
{
    _useKernel = _theKernel;
    switch (_useKernel)
    {
        case KRSVMKernelFunctionRBF:
            _sigma = DEFAULT_RBF_SIGMA_VALUE;
            break;
        case KRSVMKernelFunctionSigmoid:
            _alpha = DEFAULT_SIGMOID_ALPHA_VALUE;
            break;
        case KRSVMKernelFunctionTangent:
            _alpha = DEFAULT_TANGENT_ALPHA_VALUE;
            break;
        case KRSVMKernelFunctionLinear:
        default:
            break;
    }
}

@end
