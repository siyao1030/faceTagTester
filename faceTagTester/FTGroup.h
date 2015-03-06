//
//  FTGroup.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTModel.h"
#import "FaceppAPI.h"
#import "FTPerson.h"

@class FTPhoto;

@interface FTGroup : FTModel

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *fppID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSSet *photos;
@property (nonatomic, strong) NSSet *people;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSDate *lastProcessedDate;
@property (nonatomic, strong) NSNumber *photosTrained;
@property (nonatomic) BOOL didFinishProcessing;
@property (nonatomic) BOOL didFinishTraining;

- (id)initWithContext:(NSManagedObjectContext *)context;
- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end withContext:(NSManagedObjectContext *)context;

- (id)init;
- (id)initWithName:(NSString *)name andPeople:(NSArray *)people andStartDate:(NSDate *)start andEndDate:(NSDate *)end;
- (void)addPhoto:(FTPhoto *)photo;
- (void)removePhoto:(FTPhoto *)photo;

- (void)addPerson:(FTPerson *)person;
- (void)addPeople:(NSArray *)people;

- (NSArray *)photoArray;
- (NSArray *)peopleArray;

@end
