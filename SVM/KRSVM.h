//
//  KRSVM.h
//  KRSVM
//
//  Created by Kalvar Lin on 2015/9/20.
//  Copyright (c) 2015年 Kalvar Lin. All rights reserved.
//

#import "KRSMO.h"

@interface KRSVM : NSObject

+(instancetype)sharedSVM;
-(instancetype)init;

-(KRSMO *)useSMO;

@end

