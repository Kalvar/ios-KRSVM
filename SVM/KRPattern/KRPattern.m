//
//  KRSVM.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRPattern.h"
#import "KRMathLib.h"

@implementation KRPattern (fixKKT)

-(double)_calculateKktValueByWeights:(NSArray *)_weights bias:(NSNumber *)_bias features:(NSArray *)_features targetValue:(double)_targetValue
{
    // Sum( weights x pattern features )
    double _sum = [[KRMathLib sharedLib] sumMatrix:_weights anotherMatrix:_features];
    return _targetValue * ( _sum + [_bias doubleValue] );
}

// 進行 KKT 條件判斷
-(BOOL)_isMatchKktValue:(double)_kktValue constValue:(double)_constValue patternAlpha:(double)_patternAlpha
{
    BOOL _isMatched        = YES;
    double _toleranceError = self.toleranceError;
    if( _patternAlpha == 0.0f && (_kktValue + _toleranceError) >= 1.0f )
    {
        
    }
    else if( _patternAlpha == _constValue && (_kktValue - _toleranceError) <= 1.0f )
    {
        
    }
    // _kktValue == 1.0f
    else if( 0.0f < _patternAlpha && _patternAlpha < _constValue && fabs(_kktValue) - 1.0f <= _toleranceError )
    {
        
    }
    else
    {
        _isMatched = NO;
    }
    return _isMatched;
}

@end

@implementation KRPattern

+(instancetype)sharedPattern
{
    static dispatch_once_t pred;
    static KRPattern *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRPattern alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _features       = [NSMutableArray new];
        _targetValue    = 0.0f;
        _alphaValue     = 0.0f;
        _errorValue     = 0.0f;
        _toleranceError = 0.0f;
        _isMatchKkt     = NO;
        _index          = 0;
    }
    return self;
}

// Implementing NSCopying protocal to achieve copy function
-(instancetype)copyWithZone:(NSZone *)zone
{
    typeof(KRPattern) *_copiedObject = [[[self class] alloc] init];
    if ( _copiedObject )
    {
        [_copiedObject setFeatures:[_features copyWithZone:zone]];
        [_copiedObject setTargetValue:_targetValue];
        [_copiedObject setAlphaValue:_alphaValue];
        [_copiedObject setErrorValue:_errorValue];
        [_copiedObject setIsMatchKkt:_isMatchKkt];
        [_copiedObject setIndex:_index];
    }
    return _copiedObject;
}

#pragma --mark Public Methods
-(void)addFeatures:(NSArray *)_featureVectors
{
    [_features addObjectsFromArray:[_featureVectors copy]];
}

-(BOOL)isMatchKktByWeights:(NSArray *)_weights bias:(NSNumber *)_bias constValue:(double)_constValue
{
    double _kktValue = [self _calculateKktValueByWeights:_weights bias:_bias features:_features targetValue:_targetValue];
    _isMatchKkt      = [self _isMatchKktValue:_kktValue constValue:_constValue patternAlpha:_alphaValue];
    return _isMatchKkt;
}

@end