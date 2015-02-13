//
//  FTGroup.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroup.h"

@implementation FTGroup

@dynamic id;
@dynamic fppID;
@dynamic name;
@dynamic photos;
@dynamic people;
@dynamic startDate;
@dynamic endDate;

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    self = [FTGroup MR_createInContext:context];
    
    self.name = name;
    self.id = name;
    self.people = [NSMutableSet setWithArray:people];
    
    NSMutableArray *personNames = [[NSMutableArray alloc] init];
    for (FTPerson *person in self.people) {
        [personNames addObject:person.name];
    }
    
    FaceppResult *result = [[FaceppAPI group] createWithGroupName:name andTag:nil andPersonId:nil orPersonName:personNames];
    
    if ([result success]) {
        self.fppID = [[result content] objectForKey:@"group_id"];
    }
    
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
