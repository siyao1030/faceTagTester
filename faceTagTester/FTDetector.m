//
//  FTDetector.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTDetector.h"

@implementation FTDetector

+(id)sharedDetector {
    NSDictionary *options = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                                                 [NSNumber numberWithInt:20],
                                                                 FaceppDetectorAccuracyHigh, nil]
                                                        forKeys:[NSArray arrayWithObjects:FaceppDetectorTracking,
                                                                 FaceppDetectorMinFaceSize,
                                                                 FaceppDetectorAccuracy, nil]];
    
    FaceppLocalDetector *faceDetector = [FaceppLocalDetector detectorOfOptions:options andAPIKey:@"279b8c5e109befce7316babba101d688"];
    return faceDetector;
}

+ (FaceppResult *)detectAndUploadWithImage:(UIImage *)image {
    FaceppLocalResult *localResult = [[FTDetector sharedDetector] detectWithImage:image];
    if ([localResult faces]) {
         return [[FaceppAPI detection] uploadLocalResult:localResult attribute:FaceppDetectionAttributeNone tag:@""];
    } else {
        return nil;
    }
}

@end
