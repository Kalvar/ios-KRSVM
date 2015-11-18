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
    KRSMO *smo = [[KRSVM sharedSVM] useSMO];
    
    [smo addPatterns:@[@0.0f, @0.0f] target:-1.0f]; // x1
    [smo addPatterns:@[@2.0f, @2.0f] target:-1.0f]; // x2
    [smo addPatterns:@[@2.0f, @0.0f] target:1.0f];  // x3
    [smo addPatterns:@[@3.0f, @0.0f] target:1.0f];  // x4
    
    [smo addBiase:@0.0f]; // one bias
    [smo addWeights:@[@0.0f, @0.0f]]; // 多少輸入維度, 就有多少個權重維度
    
    [smo classifyWithCompletion:^(BOOL success, NSArray *weights, NSArray *biases, NSArray *outputs, NSInteger totalIterations) {
        
    }];
    
    [smo print];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
