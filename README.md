## About

KRSVM is implemented SVM of machine learning.

#### Podfile

```ruby
platform :ios, '7.0'
pod "KRSVM", "~> 1.0.0"
```

## How To Get Started

#### Import
``` objective-c
#import "KRSVM.h"
```

#### Use SMO
``` objective-c
KRSMO *smo = [[KRSVM sharedSVM] useSMO];
```

#### Use Linear Kernel Function
``` objective-c
[smo.kernel useLinear];
```

#### Use RBF Kernel Function
The sigma that could be customized by your wishes, default value is 2.0, but some papers said 0.5, 1.0, 3.0, 5.0 that all can do training. Anyway, just try, nothing else.
``` objective-c
[smo.kernel useRBF];
smo.kernel.sigma = 2.0f;
```

#### Use Tangent (tanh) Kernel Function
The alpha of tangent could be customized by your wishes, default value is 1.0, but sometimes to be 2.0 is better, in this sample case we used 0.8 to do regression.
``` objective-c
[smo.kernel useTangent];
smo.kernel.alpha = 0.8f;
```
    
#### Training Sample
``` objective-c

smo.toleranceError = 0.001f;
smo.maxIteration   = 1000;
smo.constValue     = 1;
[smo.kernel useLinear];

[smo addPatterns:@[@0.0f, @0.0f] target:-1.0f]; // x1
[smo addPatterns:@[@2.0f, @2.0f] target:-1.0f]; // x2
[smo addPatterns:@[@2.0f, @0.0f] target:1.0f];  // x3
[smo addPatterns:@[@3.0f, @0.0f] target:1.0f];  // x4

// One bias likes a net of neural network
[smo addBias:@0.0f];

// One input value by one weight that likes inputs & weights of neural network
[smo addWeights:@[@0.0f, @0.0f]];

// Setup the groups of classification and the target-value of group
[smo addGroupOfTarget:-1.0f];
[smo addGroupOfTarget:1.0f];

[smo classifyWithPerIteration:^(NSInteger iteration, NSArray *weights, NSArray *biases) {
    //NSLog(@"%li Iteration weights : %@", iteration, weights);
    //NSLog(@"%li Iteration biases : %@", iteration, biases);
} completion:^(BOOL success, NSArray *weights, NSArray *biases, NSDictionary *groups, NSInteger totalIterations) {
    NSLog(@"===============================================");
    NSLog(@"%li Completion weights : %@", totalIterations, weights);
    NSLog(@"%li Completion biases : %@", totalIterations, biases);
    NSLog(@"%li Completion groups : %@", totalIterations, groups);
    NSLog(@"===============================================");
    // Verify & Directly Output
    [smo classifyPatterns:@[@[@2.0f, @2.0f], @[@3.0f, @0.0f]] completion:^(NSArray *weights, NSArray *biases, NSArray *results, NSDictionary *allGroups) {
        for( KRSVMPattern *pattern in results )
        {
            NSLog(@"direct classify to target %@", pattern.classifiedTarget);
        }
        NSLog(@"all groups : %@", allGroups);
    }];
}];
```

## Version

V1.0.0

## LICENSE

MIT.

