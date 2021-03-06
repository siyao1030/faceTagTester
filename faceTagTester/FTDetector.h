//
//  FTDetector.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceppLocalDetector.h"

#import "FaceppAPI.h"

@interface FTDetector : NSObject

+ (id)sharedDetector;
+ (FaceppResult *)detectAndUploadWithImage:(UIImage *)image;

@end
