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
    
    [smo addPatterns:@[@0.0f, @0.0f] target:-1.0f]; // x1
    [smo addPatterns:@[@2.0f, @2.0f] target:-1.0f]; // x2
    [smo addPatterns:@[@2.0f, @0.0f] target:1.0f];  // x3
    [smo addPatterns:@[@3.0f, @0.0f] target:1.0f];  // x4
    
    // One bias likes a net of neural network
    [smo addBiase:@0.0f];
    
    // One input value by one weight that likes inputs & weights of neural network
    [smo addWeights:@[@0.0f, @0.0f]];
    
    // Setup the groups of classification and the target-value of group
    [smo addGroupForTarget:-1.0f];
    [smo addGroupForTarget:1.0f];
    
    [smo classifyWithCompletion:^(BOOL success, NSArray *weights, NSArray *biases, NSDictionary *outputs, NSInteger totalIterations) {
        
    }];
    
    [smo print];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
