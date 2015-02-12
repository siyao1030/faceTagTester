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
@dynamic initialImages;
@dynamic groups;

- (id)initWithName:(NSString *)name {
    self = [super init];
    self.name = name;
    self.id = name;
    
    FaceppResult *result = [[FaceppAPI person] createWithPersonName:self.name andFaceId:nil andTag:nil andGroupId:nil orGroupName:nil];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"person_id"];
    }

    return self;
}

- (void)trainWithImages:(NSArray *)images {
    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
    for (UIImage *image in images) {
        FaceppResult *result = [FTDetector detectAndUploadWithImage:image];
        if ([result success]) {
            NSString *faceID = [[result content] objectForKey:@"face_id"];
            [faceIDs addObject:faceID];
        }

    }
    [[FaceppAPI person] addFaceWithPersonName:self.name orPersonId:self.fppID andFaceId:faceIDs];
    [[FaceppAPI train] trainAsynchronouslyWithId:self.fppID orName:self.name andType:FaceppTrainIdentify];
}

- (void)addPhoto:(FTPhoto *)photo {
    
}

@end
