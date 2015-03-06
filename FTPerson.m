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
@dynamic shouldTrainAgain;

- (id)initWithName:(NSString *)name andInitialTrainingImages:(NSArray *)images withContext:(NSManagedObjectContext *)context {
    self = [FTPerson MR_createInContext:context];
    self.name = name;
    self.id = [[NSUUID UUID] UUIDString];
    self.objectIDString = [[self.objectID URIRepresentation] absoluteString];
    self.profileImageData = UIImageJPEGRepresentation(images[0], 0);
    self.shouldTrainAgain = NO;
    [self addTrainingImages:images];

    FaceppResult *result = [[FaceppAPI person] createWithPersonName:self.id andFaceId:nil andTag:nil andGroupId:nil orGroupName:nil];
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"person_id"];
        [self trainWithImages:images];
    }
    
    return self;

}

- (id)initWithName:(NSString *)name andInitialTrainingImages:(NSArray *)images {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPerson MR_createInContext:context];
    self.name = name;
    self.id = [[NSUUID UUID] UUIDString];
    self.objectIDString = [[self.objectID URIRepresentation] absoluteString];
    self.shouldTrainAgain = NO;
    [self addTrainingImages:images];
    self.profileImageData = UIImageJPEGRepresentation(images[0], 0);

    FaceppResult *result = [[FaceppAPI person] createWithPersonName:self.id andFaceId:nil andTag:nil andGroupId:nil orGroupName:nil];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"person_id"];
        [self trainWithImages:images];

    }
    return self;
}

- (void)addTrainingImages:(NSArray *)images {
    NSMutableArray *mutableTrainingImages = [NSMutableArray arrayWithArray:self.trainingImages];
    int index = (int)self.trainingImages.count;
    for (UIImage *image in images) {
        //save to local
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@%d.jpeg",[self.name removeAllWhitespace],index];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",directory,fileName];
        NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0f)];//1.0f = 100% quality
        [data writeToFile:filePath atomically:YES];
        [mutableTrainingImages addObject:fileName];
        index++;
    }
    self.trainingImages = mutableTrainingImages;
}

- (void)trainWithImages:(NSArray *)images {
    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
    for (UIImage *image in images) {
        //train
        UIImage *fixedImage = [image fixOrientation];
        FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(fixedImage, 0.5) mode:FaceppDetectionModeOneFace];
        if ([result success]) {
            NSArray *faces = [[result content] objectForKey:@"face"];
            if ([faces count]) {
                NSString *faceID = [[faces objectAtIndex:0] objectForKey:@"face_id"];
                [faceIDs addObject:faceID];
            } else {
                //mark this image as invalid
                NSLog(@"no face!");
            }
        }
    }
    if (faceIDs) {
        [[FaceppAPI person] addFaceWithPersonName:self.id orPersonId:nil andFaceId:faceIDs];
        if (!self.shouldTrainAgain) {
            self.shouldTrainAgain = YES;
        }
    }
}

- (void)addPhoto:(FTPhoto *)photo {
    NSMutableSet *mutablePhotos = [self mutableSetValueForKey:@"photos"];
    [mutablePhotos addObject:photo];
}

- (void)addGroup:(FTGroup *)group {
    NSMutableSet *mutableGroups = [self mutableSetValueForKey:@"groups"];
    [mutableGroups addObject:group];
}

@end
