//
//  FTDetector.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
//#import "FaceppLocalDetector.h"

#import "FaceppAPI.h"

@interface FTDetector : NSObject

//+ (id)sharedDetector;
//+ (FaceppResult *)detectAndUploadWithImage:(UIImage *)image;
+ (NSArray *)detectFaceIDsWithImage:(UIImage *)image andImageInfo:(NSDictionary *)info;
+ (NSArray *)detectFacesWithImage:(UIImage *)image andImageInfo:(NSDictionary *)info;
+ (NSArray *)detectFaceIDsWithImage:(UIImage *)image;
@end
