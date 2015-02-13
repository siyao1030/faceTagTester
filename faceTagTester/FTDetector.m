//
//  FTDetector.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTDetector.h"

@implementation FTDetector

/*
+(id)sharedDetector {
    NSDictionary *options = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                                                 [NSNumber numberWithInt:20],
                                                                 FaceppDetectorAccuracyHigh, nil]
                                                        forKeys:[NSArray arrayWithObjects:FaceppDetectorTracking,
                                                                 FaceppDetectorMinFaceSize,
                                                                 FaceppDetectorAccuracy, nil]];
    
    FaceppLocalDetector *faceDetector = [FaceppLocalDetector detectorOfOptions:options andAPIKey:@"279b8c5e109befce7316babba101d688"];
    return faceDetector;
}*/

+ (NSArray *)detectFacesWithImage:(UIImage *)image {
    CIImage *myImage = [image CIImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];
    
    opts = @{ CIDetectorImageOrientation :
                 [[myImage properties] valueForKey: (__bridge NSString *)kCGImagePropertyOrientation] };
    NSArray *features = [detector featuresInImage:myImage options:opts];
    NSMutableArray *faces = [[NSMutableArray alloc] init];
    for (CIFaceFeature *faceFeature in features) {
        CGImageRef cgImage = [context createCGImage:myImage fromRect:faceFeature.bounds];
        UIImage *croppedFace = [UIImage imageWithCGImage:cgImage];
        NSData *faceData = UIImageJPEGRepresentation(croppedFace, 1);
        [faces addObject:faceData];
    }
    return faces;
    
}


/*
+ (FaceppResult *)detectAndUploadWithImage:(UIImage *)image {
    FaceppLocalResult *localResult = [[FTDetector sharedDetector] detectWithImage:image];
    if ([localResult faces]) {
         return [[FaceppAPI detection] uploadLocalResult:localResult attribute:FaceppDetectionAttributeNone tag:@""];
    } else {
        return nil;
    }
}*/

@end
