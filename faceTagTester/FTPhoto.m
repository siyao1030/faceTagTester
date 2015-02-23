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
@dynamic people;
@dynamic photoAssetIdentifier;
@dynamic groups;
@dynamic faceIDs;
@dynamic creationDate;
@dynamic peopleNamesString;


-(id)initWithPhotoAsset:(PHAsset *)asset {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPhoto MR_createInContext:context];
    self.photoAssetIdentifier = asset.localIdentifier;
    self.peopleNamesString = @"";
    self.creationDate = [asset creationDate];
    return self;
}

-(void)addPerson:(FTPerson *)person {
    if (![self.people count]) {
        self.peopleNamesString = person.name;
    } else {
        self.peopleNamesString = [self.peopleNamesString  stringByAppendingString:[NSString stringWithFormat:@", %@", person.name]];
    }
    [self.people addObject:person];
}

-(void)addGroup:(FTGroup *)group {
    [self.groups addObject:group];
}


@end
