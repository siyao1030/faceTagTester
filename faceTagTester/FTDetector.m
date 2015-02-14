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

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    int width = newSize.width;
    int height = newSize.height;
    
    unsigned char *rawData = (unsigned char*) malloc(width*height*sizeof(unsigned char));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    NSUInteger bytesPerPixel = 1;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, 0);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    CGImageRef grayImageRef = CGBitmapContextCreateImage(context);
    free(rawData);
    return [UIImage imageWithCGImage: grayImageRef];
}

+ (NSArray *)detectFaceIDsWithImage:(UIImage *)image {
    int sizeLimit = 600;
    float scale = MAX([image size].width / sizeLimit, [image size].height / sizeLimit);
    if (scale > 1) {
        image = [FaceppDetection imageWithImage:image scaledToSize:
                        CGSizeMake([image size].width/scale, [image size].height/scale)];
    }
    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
    FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 0) mode:FaceppDetectionModeNormal attribute:FaceppDetectionAttributeNone];
    if ([result success]) {
        NSArray *faces = [[result content] objectForKey:@"face"];
        if ([faces count]) {
            NSString *faceID = [[faces objectAtIndex:0] objectForKey:@"face_id"];
            [faceIDs addObject:faceID];
        }
    }
    
    return faceIDs;
}


// cidetector works like crap
+ (NSArray *)detectFacesWithImage:(UIImage *)image andImageInfo:(NSDictionary *)info {
    CIImage *myImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];
    
    opts = @{ CIDetectorImageOrientation :
                 [info valueForKey:@"PHImageFileOrientationKey"]};
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


/* fpp local detector
+ (FaceppResult *)detectAndUploadWithImage:(UIImage *)image {
    FaceppLocalResult *localResult = [[FTDetector sharedDetector] detectWithImage:image];
    if ([localResult faces]) {
         return [[FaceppAPI detection] uploadLocalResult:localResult attribute:FaceppDetectionAttributeNone tag:@""];
    } else {
        return nil;
    }
}*/

@end
