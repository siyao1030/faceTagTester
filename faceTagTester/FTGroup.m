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

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTGroup MR_createInContext:context];
    
    self.name = name; //display, can change
    self.id = name; //for fetching photos and for api uses, cannot change
    self.people = [NSMutableSet setWithArray:people];
    self.startDate = start;
    self.endDate = end;
    
    self.didFinishTraining = NO;
    self.didFinishProcessing = NO;
    self.photosTrained = @(0);
    self.lastProcessedDate = [NSDate date];
    
    NSMutableArray *personNames = [[NSMutableArray alloc] init];
    for (FTPerson *person in self.people) {
        [personNames addObject:person.name];
    }
    
    FaceppResult *result = [[FaceppAPI group] createWithGroupName:self.id andTag:nil andPersonId:nil orPersonName:personNames];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"group_id"];
    }
    
    [context MR_saveToPersistentStoreAndWait];
    return self;
}

- (void)addPhoto:(FTPhoto *)photo {
    [self.photos addObject:photo];
}

- (NSArray *)photoArray {
    return [self.photos allObjects];
}

- (NSArray *)peopleArray {
    return [self.people allObjects];
}

@end
