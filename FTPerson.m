//
//  FTPerson.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPerson.h"
#import "FTPhoto.h"

@implementation FTPerson

@dynamic id;
@dynamic fppID;
@dynamic objectIDString;
@dynamic name;
@dynamic profileImageData;
@dynamic photos;
@dynamic groups;
@dynamic facesTrained;
@dynamic trainingImages;


- (id)initWithName:(NSString *)name andInitialTrainingImages:(NSArray *)images {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPerson MR_createInContext:context];
    self.name = name;
    self.id = [[NSUUID UUID] UUIDString];
    self.objectIDString = [[self.objectID URIRepresentation] absoluteString];
    self.trainingImages = [[NSMutableArray alloc] init];
    
    FaceppResult *result = [[FaceppAPI person] createWithPersonName:self.id andFaceId:nil andTag:nil andGroupId:nil orGroupName:nil];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"person_id"];
        [self train];
    }
    
    self.profileImageData = UIImageJPEGRepresentation(images[0], 0);
    [context MR_saveToPersistentStoreAndWait];
    return self;
}

- (void)trainWithImages:(NSArray *)images {
    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
    int index = (int)self.trainingImages.count;
    for (UIImage *image in images) {
        //save to local
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@%d.jpeg",[self.name removeAllWhitespace],index];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",directory,fileName];
        NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0f)];//1.0f = 100% quality
        [data writeToFile:filePath atomically:YES];
        [self.trainingImages addObject:fileName];
        
        //train
        FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 0.5) mode:FaceppDetectionModeOneFace];
        if ([result success]) {
            NSArray *faces = [[result content] objectForKey:@"face"];
            if ([faces count]) {
                NSString *faceID = [[faces objectAtIndex:0] objectForKey:@"face_id"];
                [faceIDs addObject:faceID];
            }
        }
    }
    [[FaceppAPI person] addFaceWithPersonName:self.id orPersonId:self.fppID andFaceId:faceIDs];
}

- (void)addPhoto:(FTPhoto *)photo {
    [self.photos addObject:photo];
}

@end
