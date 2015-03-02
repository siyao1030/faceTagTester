//
//  FTGroup.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroup.h"
#import "FTPhoto.h"

@implementation FTGroup

@dynamic id;
@dynamic fppID;
@dynamic name;
@dynamic photos;
@dynamic people;
@dynamic startDate;
@dynamic endDate;


@dynamic lastProcessedDate;
@dynamic photosTrained;
@dynamic didFinishProcessing;
@dynamic didFinishTraining;

- (id)init {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTGroup MR_createInContext:context];
    
    self.id = [[NSUUID UUID] UUIDString]; //for fetching photos and for api uses, cannot change
    
    self.didFinishTraining = NO;
    self.didFinishProcessing = NO;
    self.photosTrained = @(0);
    self.lastProcessedDate = [NSDate date];

    [context MR_saveToPersistentStoreAndWait];
    return self;
}

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTGroup MR_createInContext:context];
    
    self.name = name; //display, can change
    self.id = [[NSUUID UUID] UUIDString]; //for fetching photos and for api uses, cannot change
    self.people = [NSMutableSet setWithArray:people];
    self.startDate = start;
    self.endDate = end;
    
    self.didFinishTraining = NO;
    self.didFinishProcessing = NO;
    self.photosTrained = @(0);
    self.lastProcessedDate = [NSDate date];
    
    NSMutableArray *personIDs = [[NSMutableArray alloc] init];
    for (FTPerson *person in self.people) {
        [personIDs addObject:person.id];
    }
    
    FaceppResult *result = [[FaceppAPI group] createWithGroupName:self.id andTag:nil andPersonId:nil orPersonName:personIDs];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"group_id"];
    }
    
    [context MR_saveToPersistentStoreAndWait];
    return self;
}

- (void)addPhoto:(FTPhoto *)photo {
    [self.photos addObject:photo];
}

- (void)addPerson:(FTPerson *)person {
    [self.people addObject:person];
}

- (NSArray *)photoArray {
    return [self.photos allObjects];
}

- (NSArray *)peopleArray {
    return [self.people allObjects];
}

@end
