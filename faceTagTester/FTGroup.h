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
#import "FTPhoto.h"

@interface FTGroup : FTModel

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *fppID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *people;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

- (id)initWithName:(NSString *)name andPeople:(NSArray *)people;
- (void)addPhoto:(FTPhoto *)photo;

@end
