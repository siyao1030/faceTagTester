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
@dynamic photoAsset;
@dynamic groups;
@dynamic faceIDs;


-(id)initWithPhotoAsset:(PHAsset *)asset {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTPhoto MR_createInContext:context];
    self.photoAsset = asset;
    return self;
}

-(void)addPerson:(FTPerson *)person {
    [self.people addObject:person];
}

-(void)addGroup:(FTGroup *)group {
    [self.groups addObject:group];
}


-(NSString *)peopleNamesString {
    [self willAccessValueForKey:@"peopleNamesString"];
    NSString *names = @"";
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortedPeople = [self.people sortedArrayUsingDescriptors:@[descriptor]];
    for (FTPerson * person in sortedPeople) {
        names = [names stringByAppendingString:[NSString stringWithFormat:@"%@, ", person.name]];
    }
    if ([names length]) {
        names = [names substringToIndex:[names length] - 2];
    }
    [self didAccessValueForKey:@"peopleNamesString"];
    return names;
}

@end
