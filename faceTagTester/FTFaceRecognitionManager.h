//
//  FTFaceRecognitionManager.h
//  faceTagTester
//
//  Created by Siyao Xie on 3/5/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTGroup.h"
#import "FTPhoto.h"

@interface FTFaceRecognitionManager : NSObject

+ (instancetype)sharedManager;

- (void)detectAndIdentifyPhotoAssets:(NSArray *)imageAssets inGroup:(FTGroup *)group;
- (void)detectAndIdentifyPhotoAsset:(PHAsset *)asset inGroup:(FTGroup *)group Completion:(void(^)(void))completionBlock;
- (void)trainIfNeededForGroup:(FTGroup *)group WithCompletion:(void(^)(void))completionBlock;

@end
