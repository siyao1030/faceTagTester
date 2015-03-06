//
//  FTPhoto.m
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPhoto.h"

@implementation FTPhoto

@dynamic assetURLString;
@dynamic id;
@dynamic people;
@dynamic photoAssetIdentifier;
@dynamic groups;
@dynamic faceIDs;
@dynamic creationDate;
@dynamic peopleNamesString;

-(id)initWithPhotoAsset:(PHAsset *)asset withContext:(NSManagedObjectContext *)context {
    self = [FTPhoto MR_createInContext:context];
    self.id = [[NSUUID UUID] UUIDString];
    self.photoAssetIdentifier = asset.localIdentifier;
    self.peopleNamesString = @"";
    self.creationDate = [asset creationDate];
    return self;
}

-(id)initWithPhotoAsset:(PHAsset *)asset {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPhoto MR_createInContext:context];
    self.id = [[NSUUID UUID] UUIDString];
    self.photoAssetIdentifier = asset.localIdentifier;
    self.peopleNamesString = @"";
    self.creationDate = [asset creationDate];
    return self;
}

-(void)addPerson:(FTPerson *)person {
    if (![self.people containsObject:person]) {
        NSMutableSet *mutablePeople = [self mutableSetValueForKey:@"people"];
        [mutablePeople addObject:person];
        self.peopleNamesString = [self namesString];
    }
}

-(NSString *)namesString {
    NSString *namesString = @"";
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];

    NSArray *sortedPeopleArray = [self.people sortedArrayUsingDescriptors:@[nameDescriptor]];
    for (FTPerson *person in sortedPeopleArray) {
        namesString = [namesString stringByAppendingString:[NSString stringWithFormat:@"%@, ", person.name]];
    }
    if ([namesString length]) {
        namesString = [namesString substringToIndex:[namesString length] -2];
    }
    return namesString;
}

-(void)addGroup:(FTGroup *)group {
    NSMutableSet *mutableGroups = [self mutableSetValueForKey:@"groups"];
    [mutableGroups addObject:group];
}


@end
