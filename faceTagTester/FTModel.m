//
//  FTModel.m
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTModel.h"

@implementation FTModel

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context {
    return [[self class] MR_findAllWithPredicate:predicate inContext:context];
}

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    return [[self class] MR_findAllWithPredicate:predicate inContext:localContext];
}

+ (NSArray *)fetchAllWithContext:(NSManagedObjectContext *)context {
    return [[self class] MR_findAllInContext:context];
}

+ (NSArray *)fetchAll {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    return [[self class] MR_findAllInContext:localContext];
}

+ (id)fetchWithID:(NSString *)modelID withContext:(NSManagedObjectContext *)context {
    FTModel *model = nil;
    
    NSArray *models =[[self class] MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"id == %@", modelID] inContext:context];
    if ([models count] == 1) {
        model = [models objectAtIndex:0];
    }
    
    return model;
}

+ (id)fetchWithID:(NSString *)modelID {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    FTModel *model = nil;
    
    NSArray *models =[[self class] MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"id == %@", modelID] inContext:localContext];
    if ([models count] == 1) {
        model = [models objectAtIndex:0];
    }
    
    return model;
}

+ (id)fetchOrCreateWithID:(NSString *)modelID withContext:(NSManagedObjectContext *)context {
    FTModel *model = [self fetchWithID:modelID];
    
    if (!model) {
        model = [[self class] MR_createInContext:context];
        [model setValue:modelID forKey:@"id"];
    }
    
    [context MR_saveToPersistentStoreAndWait];
    return model;
}

+ (id)fetchOrCreateWithID:(NSString *)modelID {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    FTModel *model = [self fetchWithID:modelID];
    
    if (!model) {
        model = [[self class] MR_createInContext:localContext];
        [model setValue:modelID forKey:@"id"];
    }
    
    [localContext MR_saveToPersistentStoreAndWait];
    return model;
}

+ (NSString *)objectIdentifierKey {
    @throw [NSException exceptionWithName:@"RLMObjectIdentifierException" reason:@"RLMObject must return an objectIdentifierKey" userInfo:nil];
}
+ (NSString *)serverObjectIdentifierKey {
    @throw [NSException exceptionWithName:@"RLMObjectServerIdentifierException" reason:@"RLMObject must return a serverObjectIdentifierKey" userInfo:nil];
}

+ (void)update:(NSArray *)batchedData withWriteBlock:(void(^)(id model))writeBlock completionBlock:(void(^)(NSArray *models))completionBlock {
    if ([NSThread isMainThread]) {
        @throw [NSException exceptionWithName:@"RLMObjectUpdateException" reason:@"-update:withWriteBlock:completionBlock: must be called from the RLMWriteQueue" userInfo:nil];
    }
    
    NSMutableArray *identifiers = [NSMutableArray array];
    @autoreleasepool {
        NSString *serverObjectIdentifierKey = [[self class] serverObjectIdentifierKey];
        
        for (NSDictionary *objectDictionary in batchedData) {
            id identifier = [objectDictionary objectForKey:serverObjectIdentifierKey];
            
            if ([identifier isKindOfClass:[NSNumber class]]) {
                identifier = [NSString stringWithFormat:@"%@", identifier];
            }
            
            id model = [[self class] fetchOrCreateWithID:identifier];
            
            if (model) {
                [model update:objectDictionary];
                
                if (writeBlock) {
                    writeBlock(model);
                }
                
                [identifiers addObject:identifier];
            }
        }
        
        NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_contextForCurrentThread];
        [localContext MR_saveToPersistentStoreAndWait];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *updatedModels = [NSMutableArray array];
        for (NSString *identifier in identifiers) {
            FTModel *model = [[self class] fetchWithID:identifier];
            if (model) {
                [updatedModels addObject:model];
            }
        }
        
        if (completionBlock) {
            completionBlock(updatedModels);
        }
    });
}

+ (NSString*)entityName {
    return NSStringFromClass(self);
}

+ (NSEntityDescription*)entityWithContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (NSEntityDescription*)entity {
    return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (void)update:(NSDictionary *)data {
    @throw [NSException exceptionWithName:@"RLMObjectException" reason:@"-update must be implemented in RLMObject subclass" userInfo:nil];
}

@end
