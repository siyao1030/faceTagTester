//
//  FTModel.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>

@interface FTModel : NSManagedObject

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate;
+ (NSArray *)fetchAll;
+ (id)fetchWithID:(NSString *)modelID;
+ (id)fetchOrCreateWithID:(NSString *)modelID;
+ (void)update:(NSArray *)batchedData withWriteBlock:(void(^)(id model))writeBlock completionBlock:(void(^)(NSArray *models))completionBlock;
+ (NSString*)entityName;
+ (NSEntityDescription*)entity;

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context;
+ (NSArray *)fetchAllWithContext:(NSManagedObjectContext *)context;
+ (id)fetchWithID:(NSString *)modelID withContext:(NSManagedObjectContext *)context;
+ (id)fetchOrCreateWithID:(NSString *)modelID withContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription*)entityWithContext:(NSManagedObjectContext *)context;

- (void)update:(NSDictionary *)data;

@end
