//
//  KRSVM.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSMO.h"

#define DEFAULT_PATTERN_TARGET_VALUE 0.0f
#define DEFAULT_PATTERN_ALPHA_VALUE  0.0f

typedef enum KRSMOTrainingTypes
{
    // One iteration done
    KRSMOTrainingTypeIsOneIterationFinished = 0,
    // All pattern matchs KKT
    KRSMOTrainingTypeIsAllPatternsMatchedKKT,
    // Training failed
    KRSMOTrainingTypeIsFailed
}KRSMOTrainingTypes;

@interface KRSMO ()

@property (nonatomic, assign) NSInteger iteration;

@end

@implementation KRSMO (fixMatrix)

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

@end

@implementation KRSMO (fixBlocks)

-(void)_blockCompletedTrainingBySucceed:(BOOL)_isSucceed finalResults:(NSDictionary *)_results
{
    if( nil != self.trainingCompletion )
    {
        self.trainingCompletion(_isSucceed, self.weights, self.biases, _results, self.iteration);
    }
}

-(void)_blockPerIteration
{
    if( nil != self.perIteration )
    {
        self.perIteration(self.iteration, self.weights, self.biases);
    }
}

-(void)_blockDirectOutputResults:(NSArray *)_results allGroups:(NSDictionary *)_allGroups
{
    if( nil != self.directOutput )
    {
        self.directOutput(self.weights, self.biases, _results, _allGroups);
    }
}

@end

@implementation KRSMO (fixTrains)

// 計算每個 Pattern 的 Error Value
-(NSArray *)_calculateErrorsAtPatterns:(NSMutableArray *)_patterns
{
    KRSVMKernel *_kernel           = self.kernel;
    NSArray *_biases               = self.biases;
    NSMutableArray *_patternErrors = [NSMutableArray new];
    double _biasValue              = [[_biases firstObject] doubleValue];
    NSInteger _patternIndex        = 0;
    for( KRSVMPattern *_pattern in _patterns )
    {
        double _errorValue    = 0.0f;
        double _patternTarget = _pattern.targetValue;
        NSInteger _otherIndex = 0;
        for( KRSVMPattern *_otherPattern in _patterns )
        {
            // _sumX : 求 xi 與其它 xj 點的乘積 (含 xi 自己)，同時做 Kernel()
            double _sumX         = [_kernel kernelOfFeatures1:_pattern.features features2:_otherPattern.features];
            double _targetValue  = _otherPattern.targetValue;
            double _alphaValue   = _otherPattern.alphaValue;
            _errorValue         += ( _targetValue * _alphaValue * _sumX );
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
    for( KRSVMPattern *_pattern in _patterns )
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
-(double)_calculateNewMatchAlphaAtMainPattern:(KRSVMPattern *)_mainPattern matchPattern:(KRSVMPattern *)_matchPattern
{
    KRMathLib *_mathLib      = [KRMathLib sharedLib];
    double _constValue       = self.constValue;
    
    double _oldMainAlpha     = _mainPattern.alphaValue;
    double _mainTarget       = _mainPattern.targetValue;
    
    // Update the alpha value of match-pattern in first
    // Old match alpha value + ( match target value * ( main error - match error ) ) / ( ( x1 * x1 ) + ( x2 * x2 ) + ( 2 * x1 * x2 ) )
    double _oldMatchAlpha    = _matchPattern.alphaValue;
    double _matchTarget      = _matchPattern.targetValue;
    
    // Start in fraction (分數) : match target * ( main error - match error ) and it won't need to do fabs(error)
    double _numerator        = _matchTarget * ( _mainPattern.errorValue - _matchPattern.errorValue );
    
    double _denominator      = [_mathLib sumMatrix:_mainPattern.features anotherMatrix:_mainPattern.features]   +
                               [_mathLib sumMatrix:_matchPattern.features anotherMatrix:_matchPattern.features] +
                               ( 2 * [_mathLib sumMatrix:_mainPattern.features anotherMatrix:_matchPattern.features] );
    
    double _newMatchAlpha    = _oldMatchAlpha + ( _numerator / _denominator );
    
    // Checking the max-min limitations (上下限範圍)
    double _miniScope        = 0.0f;
    double _maxScope         = 0.0f;
    // 相異訊號
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
        // 同訊號
        // If main target * match target = 1 (plus singal), using this formula :
        // Mini scope is MAX( 0.0f, ( old main alpha + old match alpha - const value ) )
        // http://littlefish.top/2015/06/18/ml-svm-2/
        _miniScope = MAX(0.0f, ( _oldMatchAlpha + _oldMainAlpha - _constValue )); // another formula is + _constValue
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
-(double)_calculateNewMainAlphaAtMainPattern:(KRSVMPattern *)_mainPattern matchPattern:(KRSVMPattern *)_matchPattern newMatchAlpha:(double)_newMatchAlpha
{
    // Formula : new main alpha = old main alpha + ( main target * match target * ( old match alpha - new match alpha ) )
    return _mainPattern.alphaValue + ( _mainPattern.targetValue * _matchPattern.targetValue * ( _matchPattern.alphaValue - _newMatchAlpha ) );
}

// 判斷 New Alpha Value 是否在接受範圍裡 ( Used on quickly update bias )
-(BOOL)_isAcceptAlphaValue:(double)_alphaValue
{
    return ( _alphaValue > 0.0f && _alphaValue < self.constValue );
}

// Random picking a pattern and must avoid the exited index of picked before
-(KRSVMPattern *)_randomPickPatternAvoidIndex:(NSInteger)_avoidIndex maxIndex:(NSInteger)_maxIndex
{
    NSInteger _pickedIndex = [[KRMathLib sharedLib] randomMax:_maxIndex min:0];
    if( _pickedIndex == _avoidIndex )
    {
        _pickedIndex = ( _pickedIndex != _maxIndex ) ? _maxIndex : 0;
        //[self _randomPickPatternAvoidIndex:_avoidIndex maxIndex:_maxIndex];
    }
    return (KRSVMPattern *)[self.patterns objectAtIndex:_pickedIndex];
}

// Update the weights & bias by patterns of not matched KKT and return training status
-(KRSMOTrainingTypes)_updateWeightsByWaitUpdateAlphas:(NSMutableArray *)_alphas
{
    NSInteger _alphaCount = [_alphas count];
    // 如果為空，代表完成本次迭代訓練，但所有 Patterns 都還未全部符合 KKT 條件
    if( _alphaCount < 1 )
    {
        return KRSMOTrainingTypeIsOneIterationFinished;
    }
    
    // If we still have over 2 patterns can do match-update task
    if( _alphaCount > 1 )
    {
        KRSVMKernel *_kernel       = self.kernel;
        // Random choosing or directly choosing in here (_choseIndex)
        NSInteger _choseIndex      = 0;
        KRSVMPattern *_mainPattern = (KRSVMPattern *)[_alphas objectAtIndex:_choseIndex];
        double _mainPatternError   = _mainPattern.errorValue;
        // Removed we chose pattern
        [_alphas removeObjectAtIndex:_choseIndex];
        
        NSInteger _index      = -1;
        NSInteger _maxIndex   = -1;
        double _maxErrorValue = -1.0f;
        for( KRSVMPattern *_pattern in _alphas )
        {
            ++_index;
            // Finding the index of max absolute error-distance
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
            KRSVMPattern *_matchPattern = (KRSVMPattern *)[_alphas objectAtIndex:_maxIndex];
            double _newMatchAlpha    = [self _calculateNewMatchAlphaAtMainPattern:_mainPattern
                                                                     matchPattern:_matchPattern];
            
            double _newMainAlpha     = [self _calculateNewMainAlphaAtMainPattern:_mainPattern
                                                                    matchPattern:_matchPattern
                                                                   newMatchAlpha:_newMatchAlpha];
            
            // Quickly updating the weights and bias by used 2 new alphas
            // First, calculates the delta weights, Formula :
            // delta weights = (new alpha 1 - old alpha 1) * target1 * x1 + (new alpha 2 - old alpha 2) * target2 * x2
            double _mainNumber         = ( _newMainAlpha - _mainPattern.alphaValue ) * _mainPattern.targetValue;
            NSArray *_deltaMainMatrix  = [self _multiplyFeatures:_mainPattern.features byNumber:_mainNumber];
            
            double _matchNumber        = ( _newMatchAlpha - _matchPattern.alphaValue ) * _matchPattern.targetValue;
            NSArray *_deltaMatchMatrix = [self _multiplyFeatures:_matchPattern.features byNumber:_matchNumber];
            
            NSArray *_deltaWeights     = [self _plusMatrix:_deltaMainMatrix anotherMatrix:_deltaMatchMatrix];
            // Second, let original weights + delta weights to be new weights array, Formula :
            // new weights = old weights + delta weights
            NSArray *_newWeights       = [self _plusMatrix:[self.weights firstObject] anotherMatrix:_deltaWeights];
            
            [self.weights removeAllObjects];
            [self addWeights:_newWeights];
            
            // Then, quickly updating bias via 2 patterns (Main & Match), Formula :
            // new bias 1 = old bias - error1 - (new alpha 1 - old alpha 1) * target1 * (x1^T * x1) - (new alpha2 - old alpha2) * target2 * (x2^T * x1)
            double _biasValue   = [[self.biases firstObject] doubleValue];
            // New formula but it seems not work ? I need to dicuss with Enoch about this
            // Calculating the main-pattern bias
            double _newMainBias = _biasValue
            - _mainPattern.errorValue
            - ( ( _newMainAlpha - _mainPattern.alphaValue ) * _mainPattern.targetValue * [_kernel kernelOfFeatures1:_mainPattern.features features2:_mainPattern.features] )
            - ( ( _newMatchAlpha - _matchPattern.alphaValue ) * _matchPattern.targetValue * [_kernel kernelOfFeatures1:_matchPattern.features features2:_mainPattern.features] );
            
            // new bias 2 = old bias - error2 - (new alpha 1 - old alpha 1) * target1 * (x1^T * x2) - (new alpha2 - old alpha2) * target2 * (x2^T * x2)
            // Calculatin the match-pattern bias
            double _newMatchBias = _biasValue
            - _matchPattern.errorValue
            - ( ( _newMainAlpha - _mainPattern.alphaValue ) * _mainPattern.targetValue * [_kernel kernelOfFeatures1:_mainPattern.features features2:_matchPattern.features] )
            - ( ( _newMatchAlpha - _matchPattern.alphaValue ) * _matchPattern.targetValue * [_kernel kernelOfFeatures1:_matchPattern.features features2:_matchPattern.features] );
            
            // Then, to choose the final bias or to get the average value of biases
            _mainPattern.alphaValue  = _newMainAlpha;
            _matchPattern.alphaValue = _newMatchAlpha;
            double _newBias          = 0.0f;
            if( [self _isAcceptAlphaValue:_newMainAlpha] )
            {
                _newBias = _newMainBias;
            }
            else if( [self _isAcceptAlphaValue:_newMatchAlpha] )
            {
                _newBias = _newMatchBias;
            }
            else
            {
                _newBias = ( _newMainBias + _newMatchBias ) * 0.5f;
            }
            
            // Updated original bias
            [self.biases removeAllObjects];
            [self addBias:[NSNumber numberWithDouble:_newBias]];
            
            // Fetched original patterns and updated the alpha value of pattern
            ((KRSVMPattern *)[self.patterns objectAtIndex:_mainPattern.index]).alphaValue  = _newMainAlpha;
            ((KRSVMPattern *)[self.patterns objectAtIndex:_matchPattern.index]).alphaValue = _newMatchAlpha;
            
            // Removed we chose pattern
            [_alphas removeObjectAtIndex:_maxIndex];
            
            // Then purly checking all patterns are they all fit KKT conditions ?
            // If YES, stop the training then return YES, If NO, continually recurse this function
            // 單純檢查是否所有數據都符合 KKT 條件了 ? 如還有不符合的，就再遞迴進 Function 跑第 1 行的 [_alpha count] < 1 的檢查直接 return Iteration Done !
            NSArray *_notMatchKkts = [self _findPatternsNotMatchKktAndFoundThenStop:YES];
            if( [_notMatchKkts count] > 0 )
            {
                // 將其它不符合 KKT 條件的點都再重新進行更新 weights & bias 運算，直至所有點都運算完畢，才 Return YES 完成 1 迭代
                return [self _updateWeightsByWaitUpdateAlphas:_alphas];
            }
            else
            {
                // Since we return YES it means that we done 1 iteration and we finished all of " not match KKT patterns updated "
                // 更新完所有不符合 KKT 條件的點，同時代表完成完整的 1 迭代運算就 return YES
                return KRSMOTrainingTypeIsAllPatternsMatchedKKT;
            }
        }
    }
    else
    {
        // If we only have 1 pattern to update, then we just random pick anyone pattern to do match-update
        // 任意挑 1 個出來搭配，之後重新跑一次這裡的遞迴
        //NSLog(@"_alphas : %@", _alphas);
        KRSVMPattern *_mainPattern  = (KRSVMPattern *)[_alphas firstObject];
        KRSVMPattern *_matchPattern = [self _randomPickPatternAvoidIndex:_mainPattern.index maxIndex:( [self.patterns count] - 1 )];
        if( nil != _matchPattern )
        {
            [_alphas addObject:_mainPattern];
            return [self _updateWeightsByWaitUpdateAlphas:_alphas];
        }
    }
    return KRSMOTrainingTypeIsFailed;
}

// 分類 Patterns 到總 Groups results 裡，並回傳分類後的群聚結果, return [哪一群與目標值] = [KRPatterns]
-(NSDictionary *)_classifyPatterns:(NSArray *)_patterns
{
    // 從每一個 Pattern 的 Target Value 來逐一判斷該點是屬於哪一群
    NSMutableDictionary *_groups = self.groups;
    for( KRSVMPattern *_finalPattern in _patterns )
    {
        NSMutableArray *_targetGroup = [_groups objectForKey:[_finalPattern getClassifyTarget]];
        if( nil != _targetGroup )
        {
            // Directly adding, it based on memory reference that working in here
            [_targetGroup addObject:_finalPattern];
        }
        
        // Maybe for extended other methods of classification ?
        // ... But not now
    }
    return _groups;
}

// 找出要更新的 Pattern Alphas
-(void)_findWannaUpdateAlphasByWaitUpdateAlphas:(NSArray *)_waitUpdates
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
    NSMutableArray *_alphas            = [_waitUpdates mutableCopy];
    _waitUpdates                       = nil;
    KRSMOTrainingTypes _trainingResult = [self _updateWeightsByWaitUpdateAlphas:_alphas];
    // 判斷是否需要停止迭代或要繼續下一迭代的訓練
    switch ( _trainingResult )
    {
        case KRSMOTrainingTypeIsOneIterationFinished:
            // 迭代數達到上限
            if( self.iteration >= self.maxIteration )
            {
                [self _blockCompletedTrainingBySucceed:YES finalResults:[self _classifyPatterns:self.patterns]];
            }
            else
            {
                // Continually training for next iteration
                [self _blockPerIteration];
                [self classify];
            }
            break;
        case KRSMOTrainingTypeIsAllPatternsMatchedKKT:
            // 所有點都符合 KKT 條件
            [self _blockCompletedTrainingBySucceed:YES finalResults:[self _classifyPatterns:self.patterns]];
            break;
        default:
            // KRSMOTrainingTypeIsFailed
            // Directly passing the original classified (or not classify) groups
            [self _blockCompletedTrainingBySucceed:NO finalResults:self.groups];
            break;
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
        _groups             = [NSMutableDictionary new];
        
        _constValue         = 1;
        _toleranceError     = 0.001f; // 鬆馳函數 (容認誤差)
        _maxIteration       = 5000;
        
        _kernel             = [KRSVMKernel sharedKernel];
        [_kernel useLinear];
        
        _trainingCompletion = nil;
        _perIteration       = nil;
        _directOutput       = nil;
        
        _iteration          = 0;
    }
    return self;
}

#pragma --mark Settings Methods
-(KRSVMPattern *)createPatternByFeatures:(NSArray *)_features target:(double)_output alpha:(double)_alpha index:(NSInteger)_index
{
    KRSVMPattern *_pattern  = [[KRSVMPattern alloc] init];
    [_pattern addFeatures:_features];
    _pattern.targetValue    = _output;
    _pattern.alphaValue     = _alpha;
    _pattern.index          = _index;
    _pattern.toleranceError = _toleranceError;
    return _pattern;
}

-(KRSVMPattern *)createPatternByFeatures:(NSArray *)_features
{
    return [self createPatternByFeatures:_features
                                  target:DEFAULT_PATTERN_TARGET_VALUE
                                   alpha:DEFAULT_PATTERN_ALPHA_VALUE
                                   index:[_patterns count]];
}

-(void)addPatterns:(NSArray *)_inputs target:(double)_output alpha:(double)_alpha
{
    // Add the KRPattern object
    [_patterns addObject:[self createPatternByFeatures:_inputs target:_output alpha:_alpha index:[_patterns count]]];
}

-(void)addPatterns:(NSArray *)_inputs target:(double)_output
{
    [self addPatterns:_inputs
               target:_output
                alpha:DEFAULT_PATTERN_ALPHA_VALUE];
    //[self addGroupForTarget:_output];
}

-(void)addBias:(NSNumber *)_lineBias
{
    [_biases addObject:[_lineBias copy]];
}

-(void)addWeights:(NSArray *)_lineWeights
{
    [_weights addObject:[_lineWeights copy]];
}

-(void)addGroupOfTarget:(double)_groupTarget
{
    // 這裡設定了想分成幾群及該群的目標值
    // Value is that group patterns, Key is that group target value
    if( nil == [_groups objectForKey:[NSNumber numberWithDouble:_groupTarget]] )
    {
        [_groups setValue:[NSMutableArray new] forKey:[[NSNumber numberWithDouble:_groupTarget] copy]];
        return;
    }
}

#pragma --mark Training Methods
-(void)classify
{
    ++_iteration;
    
    // Calculating the errors of patterns then directly set errors up in these patterns at the same time
    [self _calculateErrorsAtPatterns:_patterns];
    
    NSArray *_waitUpdates = [self _findAllPatternsNotMatchKkt];
    [self _findWannaUpdateAlphasByWaitUpdateAlphas:_waitUpdates];
}

-(void)classifyWithCompletion:(KRSMOCompletion)_completion
{
    _trainingCompletion = _completion;
    [self classify];
}

-(void)classifyWithPerIteration:(KRSMOIteration)_eachIteration completion:(KRSMOCompletion)_completion
{
    _perIteration       = _eachIteration;
    _trainingCompletion = _completion;
    [self classify];
}

-(void)classifyPatterns:(NSArray *)_samples completion:(KRSMODirectOutput)_completion
{
    _directOutput = _completion;
    
    // Directly output the target value by formula : yi = (W^T * xi + b) or (W^T * xi - b)
    NSArray *_choseWeights        = [_weights firstObject];
    double _biasValue             = [[_biases firstObject] doubleValue];
    NSMutableArray *_waitPatterns = [NSMutableArray new];
    for( NSArray *_features in _samples )
    {
        KRSVMPattern *_pattern = [self createPatternByFeatures:_features];
        // 計算目標推估值
        double _targetValue    = 0.0f;
        NSInteger _index       = -1;
        for( NSNumber *_weightValue in _choseWeights )
        {
            ++_index;
            _targetValue += ( [_weightValue doubleValue] * [[_features objectAtIndex:_index] doubleValue] ) + _biasValue;
        }
        _targetValue         = [_kernel normalizeValue:_targetValue];
        _pattern.targetValue = _targetValue;
        [_waitPatterns addObject:_pattern];
        //NSLog(@"_targetValue : %lf", _targetValue);
    }
    
    // 直接 Output @[KRPatterns]，讓外部用 KRPattern.targetValue 來知道其分到哪一類
    [self _blockDirectOutputResults:[_waitPatterns copy]
                          allGroups:[self _classifyPatterns:_waitPatterns]];
}

-(void)verifyPatterns:(NSArray *)_samples
{
    // TODO : to verify the predication-accuracy of samples by trained SVM model. (驗證模型的預測準度)
}

-(void)print
{
    NSLog(@"classified patterns : %@", _groups);
}

-(void)clean
{
    _iteration          = 0;
    _trainingCompletion = nil;
    _perIteration       = nil;
    _directOutput       = nil;
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

-(void)setDirectOutput:(KRSMODirectOutput)_theBlock
{
    _directOutput = _theBlock;
}

@end

