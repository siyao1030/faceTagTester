//
//  FTNetwork.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTNetwork : NSObject

+ (void)getResultForSession:(NSString *)sessionID completion:(void(^)(FaceppResult *result))completionBlock afterDelay:(double)delay;

@end
