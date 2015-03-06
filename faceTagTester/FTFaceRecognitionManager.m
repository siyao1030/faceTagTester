//
//  FTFaceRecognitionManager.m
//  faceTagTester
//
//  Created by Siyao Xie on 3/5/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTFaceRecognitionManager.h"


#define CONFIDENCE 10

@implementation FTFaceRecognitionManager

+ (instancetype)sharedManager {
    static FTFaceRecognitionManager* sManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sManager = [[FTFaceRecognitionManager alloc] init];
    });
    return sManager;
}

- (void)detectAndIdentifyPhotoAssets:(NSArray *)imageAssets inGroup:(FTGroup *)group {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
        for (PHAsset *asset in imageAssets) {
            dispatch_group_enter(ProcessImageGroup());
            [self detectAndIdentifyPhotoAsset:asset inGroup:group Completion:^{
                dispatch_group_leave(ProcessImageGroup());
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    FTGroup *localGroup = [group MR_inContext:localContext];
                    [localGroup setLastProcessedDate:[asset creationDate]]; //**maybe saving too much?
                }];
#warning TODO: could add progress bar info here
            }];
        }
        
        dispatch_group_notify(ProcessImageGroup(), dispatch_get_main_queue(), ^{
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                FTGroup *localGroup = [group MR_inContext:localContext];
                [localGroup setDidFinishProcessing:YES];
            } completion:^(BOOL success, NSError *error) {
                NSLog(@"finished Processing");
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
                    //retrain if new faces are added
                    [self trainIfNeededForGroup:group WithCompletion:nil];
                });
            }];
        });
    });
    
}

- (void)detectAndIdentifyPhotoAsset:(PHAsset *)asset inGroup:(FTGroup *)group Completion:(void(^)(void))completionBlock {
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    [requestOptions setSynchronous:YES];
    [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
    
    PHImageManager *manager = [[PHImageManager alloc] init];
    [manager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                                contentMode:PHImageContentModeAspectFit
                                    options:requestOptions
                              resultHandler:^(UIImage *image, NSDictionary *info) {
                                  @autoreleasepool {
                                      //only detect images that are not screenshot -> should eliminate download too
                                      if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                          if (completionBlock) {
                                              completionBlock();
                                          }
                                          return;
                                      }
                                      //detect faces
                                      NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image];
                                      if ([detectedFaceIDs count]) {
                                          //identify faces
                                          FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:nil orGroupName:group.id andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:YES];
                                          
                                          NSString *sessionID = [[identifyResult content] objectForKey:@"session_id"];
                                          if (sessionID) {
                                              [FTNetwork getResultForSession:sessionID completion:^(FaceppResult *result) {
                                                  if ([result success]) {
                                                      NSArray *identifiedFaces = [[[result content] objectForKey:@"result"] objectForKey:@"face"];
                                                      
                                                      [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                          FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset withContext:localContext];
                                                          BOOL shouldAddToGroup = NO;
                                                          for (NSDictionary *face in identifiedFaces) {
                                                              NSArray *candidates = [face objectForKey:@"candidate"];
                                                              if ([candidates count]) {
                                                                  NSDictionary *candidate = candidates[0];
                                                                  if ([[candidate objectForKey:@"confidence"] floatValue] > CONFIDENCE) {
                                                                      shouldAddToGroup = YES;
                                                                      FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"] withContext:localContext];
                                                                      if (person) {
                                                                          if (![photo.people containsObject:person]) {
                                                                              [photo addPerson:person];
                                                                              [[FaceppAPI person] addFaceWithPersonName:person.id orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                                          }
                                                                      }
                                                                  }
                                                              }
                                                          }
                                                          if (shouldAddToGroup) {
                                                              FTGroup *localGroup = [group MR_inContext:localContext];
                                                              [localGroup addPhoto:photo];
                                                              localGroup.didFinishTraining = NO;
                                                          }
                                                          
                                                      } completion:^(BOOL success, NSError *error) {
                                                          if (completionBlock) {
                                                              completionBlock();
                                                          }
                                                      }];
                                                  }
                                                  
                                              } afterDelay:0.5];
                                          }
                                      } else {
                                          if (completionBlock) {
                                              completionBlock();
                                          }
                                      }
                                  }
                              }];
}

- (void)trainIfNeededForGroup:(FTGroup *)group WithCompletion:(void(^)(void))completionBlock {
    if (!group.didFinishTraining) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"training");
            FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:nil orName:group.id andType:FaceppTrainIdentify];
            NSString *sessionID = [[result content] objectForKey:@"session_id"];
            if (sessionID) {
                [FTNetwork getResultForSession:sessionID completion:^(FaceppResult *result) {
                    if ([result success]) {
                        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                            FTGroup *localGroup = [group MR_inContext:localContext];
                            [localGroup setDidFinishTraining:YES];
                        } completion:^(BOOL success, NSError *error) {
                            if (completionBlock) {
                                completionBlock();
                            }
                        }];
                    }
                } afterDelay:0.5];
            }
        });
    }
}



@end
