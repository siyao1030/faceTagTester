//
//  FTPerson.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPerson.h"

@implementation FTPerson

@dynamic id;
@dynamic fppID;
@dynamic name;
@dynamic photos;
@dynamic groups;

- (id)initWithName:(NSString *)name {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPerson MR_createInContext:context];
    self.name = name;
    self.id = name;
    
    FaceppResult *result = [[FaceppAPI person] createWithPersonName:self.name andFaceId:nil andTag:nil andGroupId:nil orGroupName:nil];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"person_id"];
    }
    
    [context MR_saveOnlySelfAndWait];

    return self;
}

- (void)addTrainingImages:(NSArray *)images {
    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
    for (UIImage *image in images) {
        //FaceppResult *result = [FTDetector detectAndUploadWithImage:image];
        FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 0.5) mode:FaceppDetectionModeOneFace];
        if ([result success]) {
            NSArray *faces = [[result content] objectForKey:@"face"];
            if ([faces count]) {
                NSString *faceID = [[faces objectAtIndex:0] objectForKey:@"face_id"];
                [faceIDs addObject:faceID];
            }
        }
    }
    [[FaceppAPI person] addFaceWithPersonName:self.name orPersonId:self.fppID andFaceId:faceIDs];
}

- (void)addPhoto:(FTPhoto *)photo {
    [self.photos addObject:photo];
}

@end
