//
//  AppDelegate.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "AppDelegate.h"

#define FACEPP_API_KEY @"279b8c5e109befce7316babba101d688"
#define FACEPP_API_SECRET @"689AlR1nBILA-GWrZCOkI6EG9egy2_Yd"

@interface AppDelegate ()

@end

@implementation AppDelegate

static NSString *kDatabaseVersionKey = @"FTDatabaseVersion";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    BOOL shouldDelete = NO;
    // Check database version
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *databaseVersionVal = [userDefaults objectForKey:kDatabaseVersionKey];
    
    NSInteger databaseVersion = [databaseVersionVal integerValue];
    int expectedDatabaseVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:kDatabaseVersionKey] intValue];
    if (databaseVersion != expectedDatabaseVersion) {
        shouldDelete = YES;
    }
    
    NSString *storeName = @"FaceTagTester.sqlite";
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:storeName];
    NSString *storeURLString = [storeURL path];
    
    NSLog(@"Current version: %li Expected version: %i\n\t Database path: %@\n\tDatabase exists? %i", (long)databaseVersion, expectedDatabaseVersion, storeURLString, [[NSFileManager defaultManager] fileExistsAtPath:storeURLString]);
    
    if (shouldDelete && [[NSFileManager defaultManager] fileExistsAtPath:storeURLString]) {
        NSLog(@"Deleting database file!");
        [[NSFileManager defaultManager] removeItemAtPath:storeURLString error:NULL];
    }
    
    [userDefaults setObject:@(expectedDatabaseVersion) forKey:kDatabaseVersionKey];
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:storeName];
    
    [FaceppAPI initWithApiKey:FACEPP_API_KEY andApiSecret:FACEPP_API_SECRET andRegion:APIServerRegionUS];
    [FaceppAPI setDebugMode:YES];
    
    FTGroupPhotosViewController *mainView = [[FTGroupPhotosViewController alloc] init];
    [[mainView navigationItem] setTitle:@"Photos"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainView];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:navController];
    [self.window makeKeyAndVisible];

    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [MagicalRecord cleanUp];
}

/*

#pragma mark - Core Data stack

@synthesize masterContext = _masterContext;
@synthesize mainContext = _mainContext;
@synthesize workerContext = _workerContext;

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "siyaoxie.faceTagTester" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"faceTagTester" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"faceTagTester.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (!_masterContext || !_mainContext || !_workerContext) {
        [self setUpManagedObjectContexts];
    }
    
    if ([NSThread isMainThread]) {
        return _mainContext;
    } else {
        return _workerContext;
    }
}

- (void)setUpManagedObjectContexts {
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        _masterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_masterContext setPersistentStoreCoordinator:coordinator];
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = _masterContext;
        
        _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContext.parentContext = _mainContext;
    }

}
#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}*/

@end
