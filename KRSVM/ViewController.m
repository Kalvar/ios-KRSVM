//
//  ViewController.m
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "ViewController.h"
#import "KRSVM.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KRSMO *smo         = [[KRSVM sharedSVM] useSMO];
    smo.toleranceError = 0.001f;
    smo.maxIteration   = 1000;
    smo.constValue     = 1;
//    [smo.kernel useLinear];

    
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
    
    //[smo print];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
