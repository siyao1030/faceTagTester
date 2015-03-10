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
@dynamic isOngoing;


- (id)initWithContext:(NSManagedObjectContext *)context {
    self = [FTGroup MR_createInContext:context];
    
    self.id = [[NSUUID UUID] UUIDString]; //for fetching photos and for api uses, cannot change
    self.people = [[NSMutableSet alloc] init];
    self.didFinishTraining = YES;
    self.didFinishProcessing = YES;
    self.didFinishProcessing = YES;
    self.isOngoing = NO;
    self.photosTrained = @(0);
    self.lastProcessedDate = [NSDate date];
    
    FaceppResult *result = [[FaceppAPI group] createWithGroupName:self.id andTag:nil andPersonId:nil orPersonName:nil];
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"group_id"];
    }
    return self;
}

- (id)init {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    return [self initWithContext:context];
}

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end withContext:(NSManagedObjectContext *)context {
    self = [FTGroup MR_createInContext:context];
    
    self.name = name; //display, can change
    self.id = [[NSUUID UUID] UUIDString]; //for fetching photos and for api uses, cannot change
    
    self.startDate = start;
    self.endDate = end;
    if ([self.endDate compare:[NSDate date]] == NSOrderedDescending) {
        self.isOngoing  = YES;
    }
    
    self.didFinishTraining = YES;
    self.didFinishProcessing = YES;
    self.photosTrained = @(0);
    self.lastProcessedDate = [NSDate date];
    
    self.people = [[NSMutableSet alloc] init];
    NSMutableArray *personIDs = [[NSMutableArray alloc] init];
    for (FTPerson *person in people) {
        [personIDs addObject:person.id];
        [self addPerson:person];
    }
    FaceppResult *result = [[FaceppAPI group] createWithGroupName:self.id andTag:nil andPersonId:nil orPersonName:personIDs];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"group_id"];
    }
    return self;
}

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    return [self initWithName:name andPeople:people andStartDate:start andEndDate:end withContext:context];
}

- (void)addPhoto:(FTPhoto *)photo {
    NSMutableSet *mutablePhotos = [self mutableSetValueForKey:@"photos"];
    [mutablePhotos addObject:photo];
    self.didFinishTraining = NO;
}

- (void)removePhoto:(FTPhoto *)photo {
    NSMutableSet *mutablePhotos = [self mutableSetValueForKey:@"photos"];
    [mutablePhotos removeObject:photo];
}


- (void)addPerson:(FTPerson *)person {
    NSMutableSet *mutablePeople = [self mutableSetValueForKey:@"people"];
    [mutablePeople addObject:person];
    self.didFinishTraining = NO;
}

- (void)addPeople:(NSArray *)people {
    NSMutableArray *personIDs = [[NSMutableArray alloc] init];
    for (FTPerson *person in people) {
        [personIDs addObject:person.id];
        [self addPerson:person];
    }
#warning todo: personIDs is nil here
    [[FaceppAPI group] addPersonWithGroupId:nil orGroupName:self.id andPersonId:nil orPersonName:personIDs];
}

- (NSArray *)photoArray {
    return [self.photos allObjects];
}

- (NSArray *)peopleArray {
    return [self.people allObjects];
}

@end
