//
//  KRSVM.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSMO.h"

#define DEFAULT_SETTINGS_ALPHA_VALUE 0.0f

@implementation KRSMO (fixTrains)

-(NSArray *)_calculateErrorsAtPatterns:(NSMutableArray *)_patterns
{
    NSArray *_biases               = self.biases;
    NSMutableArray *_patternErrors = [NSMutableArray new];
    double _biasValue              = [[_biases firstObject] doubleValue];
    NSInteger _patternIndex        = 0;
    for( KRPattern *_pattern in _patterns )
    {
        // 計算每個 Pattern 的 Error 值
        double _errorValue    = 0.0f;
        double _patternTarget = _pattern.targetValue;
        NSInteger _otherIndex = 0;
        for( KRPattern *_otherPattern in _patterns )
        {
            // 求 xi 與其它 xj 點的乘積 (含 xi 自己)
            NSInteger _valueIndex = 0;
            double _sumX          = 0.0f;
            double _targetValue   = _otherPattern.targetValue;
            double _alphaValue    = _otherPattern.alphaValue;
            for( NSNumber *_inputValue in _pattern.features )
            {
                _sumX += ( [_inputValue doubleValue] * [[_otherPattern.features objectAtIndex:_valueIndex] doubleValue] );
                ++_valueIndex;
            }
            _errorValue += ( _targetValue * _alphaValue * _sumX );
            ++_otherIndex;
        }
        _errorValue      = _errorValue + _biasValue - _patternTarget;
        NSNumber *_error = [NSNumber numberWithDouble:_errorValue];
        [_patternErrors addObject:_error];
        
        // 將 Error Value 記回去 Pattern 裡 ( Used Memory Linking Reference )
        _pattern.errorValue = _errorValue;
        //[self.patterns replaceObjectAtIndex:_pattern.index withObject:_pattern];
        
        ++_patternIndex;
    }
    return _patternErrors;
}

// 找出不符合 KKT 條件的 Patterns & 是否在找到時就直接停止再尋找
-(NSArray *)_findPatternsNotMatchKktAndFoundThenStop:(BOOL)_foudThenStop
{
    NSMutableArray *_waitUpdates = [NSMutableArray new];
    NSArray *_choseWeights       = [self.weights firstObject];
    NSNumber *_choseBias         = [self.biases firstObject];
    double _constValue           = self.constValue;
    NSArray *_patterns           = self.patterns;
    for( KRPattern *_pattern in _patterns )
    {
        BOOL _isMatchKkt = [_pattern isMatchKktByWeights:_choseWeights bias:_choseBias constValue:_constValue];
        // 不符合 KKT 條件
        if( !_isMatchKkt )
        {
            // 記錄要等待更新的 Pattern Alpha Value
            [_waitUpdates addObject:_pattern];
            if( _foudThenStop )
            {
                break;
            }
        }
    }
    return _waitUpdates;
}

// 找出所有不符合 KKT 條件的 Patterns
-(NSArray *)_findAllPatternsNotMatchKkt
{
    return [self _findPatternsNotMatchKktAndFoundThenStop:NO];
}

// 計算 New Matched Pattern Alpha Value & 判斷其是否符合上下限範圍
-(double)_calculateNewMatchAlphaAtMainPattern:(KRPattern *)_mainPattern matchPattern:(KRPattern *)_matchPattern maxError:(double)_maxError
{
    KRMathLib *_mathLib      = [KRMathLib sharedLib];
    double _constValue       = self.constValue;
    
    double _oldMainAlpha     = _mainPattern.alphaValue;
    double _mainTarget       = _mainPattern.targetValue;
    // Update the alpha value of match-pattern in first
    // Old alpha value + ( target value * ( main error - match error ) ) / ( ( x1 * x1 ) + ( x2 * x2 ) + ( 2 * x1 * x2 ) )
    double _oldMatchAlpha    = _matchPattern.alphaValue;
    double _matchTarget      = _matchPattern.targetValue;
    // Start in fracation
    double _numerator        = _matchTarget * _maxError;
    double _denominator      = [_mathLib sumParentMatrix:_mainPattern.features childMatrix:_mainPattern.features]   +
                               [_mathLib sumParentMatrix:_matchPattern.features childMatrix:_matchPattern.features] +
                               ( 2 * [_mathLib sumParentMatrix:_mainPattern.features childMatrix:_matchPattern.features] );
    double _newMatchAlpha    = _oldMatchAlpha + ( _numerator / _denominator );
    
    // Checking the max-min limitations (上下限範圍)
    double _miniScope        = 0.0f;
    double _maxScope         = 0.0f;
    // If main target * match target = -1 (minor singal), using this formula :
    if( ( _mainTarget * _matchTarget ) < 0.0f )
    {
        // Mini scope is MAX( 0.0f, ( old match alpha - old main alpha ) )
        _miniScope = MAX(0.0f, ( _oldMatchAlpha - _oldMainAlpha ));
        // Max scope is MIN( const vaue, const value + old match alpha - old main alpha )
        _maxScope  = MIN(_constValue, ( _constValue + _oldMatchAlpha - _oldMainAlpha ));
    }
    else
    {
        // If main target * match target = 1 (plus singal), using this formula :
        // Mini scope is MAX( 0.0f, ( old main alpha + old match alpha - const value ) )
        _miniScope = MAX(0.0f, ( _oldMatchAlpha - _oldMainAlpha ));
        // Max scope is MIN( const vaue, old match alpha + old main alpha )
        _maxScope  = MIN(_constValue, ( _oldMatchAlpha + _oldMainAlpha ));
    }

    // Comparing the new match alpha-value the max and mini value
    // 如果小於下限值, 就變成下限值
    if( _newMatchAlpha < _miniScope )
    {
        _newMatchAlpha = _miniScope;
    }
    // 如果大於上限值，就變成上限值
    else if( _newMatchAlpha > _maxScope )
    {
        _newMatchAlpha = _maxScope;
    }
    // 在原先公式制定的標準範圍內
    else
    {
        // Nothing else
    }
    return _newMatchAlpha;
}

// 更新 New Main Pattern Alpha Value
-(double)_calculateNewMainAlphaAtMainPattern:(KRPattern *)_mainPattern matchPattern:(KRPattern *)_matchPattern newMatchAlpha:(double)_newMatchAlpha
{
    // Formula : new main alpha = old main alpha + ( main target * match target * ( old match alpha - new match alpha ) )
    return _mainPattern.targetValue + ( _mainPattern.targetValue * _matchPattern.targetValue * ( _matchPattern.alphaValue - _newMatchAlpha ) );
}

// Use on quickly update weights
-(NSArray *)_multiplyFeatures:(NSArray *)_features byNumber:(double)_number
{
    return [[KRMathLib sharedLib] multiplyMatrix:_features byNumber:_number];
}

// Matrix + Matrix to be another Matrix
-(NSArray *)_plusMatrix:(NSArray *)_matrix anotherMatrix:(NSArray *)_anotherMatrix
{
    return [[KRMathLib sharedLib] plusMatrix:_matrix anotherMatrix:_anotherMatrix];
}

// 找出要更新的 Pattern Alphas
-(void)_updateAlphasByWaitUpdateAlphas:(NSArray *)_waitUpdates
{
    if( [_waitUpdates count] < 1 )
    {
        return;
    }
    /*
     * @ 更新方法與步驟
     *   - 1. 在一堆不符合 KKT 條件的點裡，任意隨機選 1 點來做主要更新點，之後依序比較每一個點，再照排序選出 2 點誤差距離最大的那一個點來做「搭配更新」的點，
     *        而如最大誤差距離有好幾個都一樣大，就能採用順序第 1 個 或 最後 1 個 或 隨機選取 的方式來選擇「搭配更新」的點。
     *
     *   - 2. 再用這 2 點更新後的 Alpha 值去更新 Weights & Bias
     *
     *   - 3. 將更新好的 Weights & Bias 再重新全部運算一次所有 Patterns 是否都符合 KKT 條件 : 
     *        @ YES = 訓練完成，收斂
     *        @ NO  = 再回到第 1 點重新執行，但此時那一堆不符合 KKT 條件的點裡，不包含已經挑出做過更新的點
     */
    NSMutableArray *_alphas  = [_waitUpdates mutableCopy];
    _waitUpdates             = nil;
    // If we still have over 2 patterns can do match-update task
    if( [_alphas count] > 1 )
    {
        // Random choosing or directly choosing in here (_choseIndex)
        NSInteger _choseIndex    = 0;
        KRPattern *_mainPattern  = (KRPattern *)[_alphas objectAtIndex:_choseIndex];
        double _mainPatternError = _mainPattern.errorValue;
        // Removed we chose pattern
        [_alphas removeObjectAtIndex:_choseIndex];
        
        NSInteger _index         = -1;
        NSInteger _maxIndex      = -1;
        double _maxErrorValue    = -1.0f;
        for( KRPattern *_pattern in _alphas )
        {
            ++_index;
            // Finding the index of max error-distance
            double _errorDistance = fabs( _mainPatternError - _pattern.errorValue );
            if( _errorDistance > _maxErrorValue )
            {
                _maxErrorValue = _errorDistance;
                _maxIndex      = _index;
            }
        }
        
        // If we successfully chose a pattern
        if( _maxIndex >= 0 )
        {
            KRPattern *_matchPattern = (KRPattern *)[_alphas objectAtIndex:_maxIndex];
            double _newMatchAlpha    = [self _calculateNewMatchAlphaAtMainPattern:_mainPattern
                                                                     matchPattern:_matchPattern
                                                                         maxError:_maxErrorValue];
            double _newMainAlpha     = [self _calculateNewMainAlphaAtMainPattern:_mainPattern
                                                                    matchPattern:_matchPattern
                                                                   newMatchAlpha:_newMatchAlpha];
            
            // Updating the weights and bias by used 2 new alphas
            // First, calculates the delta weights
            double _mainNumber         = ( _newMainAlpha - _mainPattern.alphaValue ) * _mainPattern.targetValue;
            NSArray *_deltaMainMatrix  = [self _multiplyFeatures:_mainPattern.features byNumber:_mainNumber];
            
            double _matchNumber        = ( _newMatchAlpha - _matchPattern.alphaValue ) * _matchPattern.targetValue;
            NSArray *_deltaMatchMatrix = [self _multiplyFeatures:_matchPattern.features byNumber:_matchNumber];
            
            NSArray *_deltaWeights     = [self _plusMatrix:_deltaMainMatrix anotherMatrix:_deltaMatchMatrix];
            // Second, let original weights + delta weights to be new weights array
            NSArray *_newWeights       = [self _plusMatrix:self.weights anotherMatrix:_deltaWeights];
            [self.weights removeAllObjects];
            [self.weights addObjectsFromArray:_newWeights];
            
            // Then, quickly updating bias
            
            
        }
    }
    else
    {
        // If we only have 1 pattern to update, then we just random pick anyone pattern to do match-update
        
    }
    
}

@end

@implementation KRSMO

+(instancetype)sharedSMO
{
    static dispatch_once_t pred;
    static KRSMO *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRSMO alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _patterns           = [NSMutableArray new];
        _weights            = [NSMutableArray new];
        _biases             = [NSMutableArray new];
        
        _constValue         = 1;
        _toleranceError     = 0.001f; // 鬆馳函數 ?
        _maxIteration       = 5000;
        
        _trainingCompletion = nil;
        _perIteration       = nil;
    }
    return self;
}

#pragma --mark Training Methods
-(void)addPatterns:(NSArray *)_inputs target:(double)_output alpha:(double)_alpha
{
    KRPattern *_pattern  = [[KRPattern alloc] init];
    [_pattern addFeatures:_inputs];
    _pattern.targetValue = _output;
    _pattern.alphaValue  = _alpha;
    _pattern.index       = [_patterns count];
    // Add the KRPattern object
    [_patterns addObject:_pattern];
}

-(void)addPatterns:(NSArray *)_inputs target:(double)_output
{
    [self addPatterns:_inputs
               target:_output
                alpha:DEFAULT_SETTINGS_ALPHA_VALUE];
}

-(void)addBiase:(NSNumber *)_lineBias
{
    [_biases addObject:[_lineBias copy]];
}

-(void)addWeights:(NSArray *)_lineWeights
{
    [_weights addObject:[_lineWeights copy]];
}

-(void)classify
{
    NSArray *_errors      = [self _calculateErrorsAtPatterns:_patterns];
    NSLog(@"_errors : %@", _errors);
    NSArray *_waitUpdates = [self _findAllPatternsNotMatchKkt];
    NSLog(@"_waitUpdates : %@", _waitUpdates);
    [self _updateAlphasByWaitUpdateAlphas:_waitUpdates];
}

-(void)classifyWithCompletion:(KRSMOCompletion)_completion
{
    _trainingCompletion = _completion;
    [self classify];
}

-(void)classifyPatterns:(NSArray *)_patterns completion:(KRSMODirectOutput)_completion
{
    
    if( nil != _completion )
    {
        //_completion(_weights, _biases, );
    }
}

-(void)verifyPatterns:(NSArray *)_patterns
{

}

-(void)print
{

}

-(void)clean
{
    [_patterns removeAllObjects];
    [_weights removeAllObjects];
    [_biases removeAllObjects];
}

#pragma --mark Blocks
-(void)setTrainingCompletion:(KRSMOCompletion)_theBlock
{
    _trainingCompletion = _theBlock;
}

-(void)setPerIteration:(KRSMOIteration)_theBlock
{
    _perIteration = _theBlock;
}

@end