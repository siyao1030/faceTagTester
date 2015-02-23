//
//  FTNetwork.m
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTNetwork.h"

@implementation FTNetwork


+ (void)getResultForSession:(NSString *)sessionID completion:(void(^)(FaceppResult *result))completionBlock afterDelay:(double)delay {
    FaceppResult *result = [[FaceppAPI info] getSessionWithSessionId:sessionID];
    NSString *status = [[result content] objectForKey:@"status"];
    if ([status isEqualToString:@"SUCC"]) {
        if (completionBlock) {
            completionBlock(result);
        }
    } else if ([status isEqualToString:@"FAILED"]) {
        NSLog(@"%@ failed", sessionID);
        return;
    } else {
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) , ^(void){
            [FTNetwork getResultForSession:sessionID completion:completionBlock afterDelay:delay];
        });
    }
}

@end
