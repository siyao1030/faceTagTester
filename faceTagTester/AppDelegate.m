//
//  AppDelegate.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "AppDelegate.h"
#import "FTPerson.h"
#import "FTGroup.h"
#import "FTGroupsListViewController.h"

#define FACEPP_API_KEY @"279b8c5e109befce7316babba101d688"
#define FACEPP_API_SECRET @"689AlR1nBILA-GWrZCOkI6EG9egy2_Yd"

#define START_DATE [NSDate dateWithTimeIntervalSinceNow:-5*24*60*60]
#define END_DATE [NSDate dateWithTimeIntervalSinceNow:-3*24*60*60]

@interface AppDelegate () <PHPhotoLibraryChangeObserver, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *ongoingGroups;
@property (strong, nonatomic) PHFetchResult *cameraRollFetchResult;

@end

@implementation AppDelegate

static NSString *kDatabaseVersionKey = @"FTDatabaseVersion";

+ (AppDelegate*)sharedApplication {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

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
    
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = -1;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    if([CLLocationManager locationServicesEnabled]){
        [self.locationManager stopUpdatingLocation];
    }

    
    [FaceppAPI initWithApiKey:FACEPP_API_KEY andApiSecret:FACEPP_API_SECRET andRegion:APIServerRegionUS];
    [FaceppAPI setDebugMode:YES];
    
    __block FTGroup *testGroup = [[FTGroup fetchAll] firstObject];
    if (!testGroup) {
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            FTPerson *siyao = [[FTPerson alloc] initWithName:@"siyao" andInitialTrainingImages:@[[UIImage imageNamed:@"siyao-s.jpg"]] withContext:localContext];
            FTPerson *chengyue = [[FTPerson alloc] initWithName:@"chengyue" andInitialTrainingImages:@[[UIImage imageNamed:@"chengyue-s.jpg"]] withContext:localContext];
            testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue] andStartDate:START_DATE andEndDate:END_DATE withContext:localContext];
        }];
    }
    
    //fetch camera roll
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    if ([collectionResult count]) {
        //fetch image assets within group's specified date range
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage]];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]]];
        self.cameraRollFetchResult = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
    }

    [self fetchOngoingGroups];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"wakeUpCount"]) {
        [defaults setObject:@(0) forKey:@"wakeUpCount"];
        [defaults setObject:@(0) forKey:@"photoChangeCount"];
    }
    [defaults synchronize];


    
    FTGroupsListViewController *mainView = [[FTGroupsListViewController alloc] init];
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

#pragma mark - Ongoing Groups

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:[(NSNumber *)[defaults objectForKey:@"photoChangeCount"] intValue] + 1] forKey:@"photoChangeCount"];
    [defaults synchronize];
    
    NSLog(@"changes");
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.cameraRollFetchResult];
    if (collectionChanges) {
        // get the new fetch result
        self.cameraRollFetchResult = [collectionChanges fetchResultAfterChanges];
        
        NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
        if ([removedIndexes count]) {
            //delete them from core data and from self.group.photos
        }
        NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
        if ([insertedIndexes count]) {
            for (FTGroup *group in self.ongoingGroups) {
                [[FTFaceRecognitionManager sharedManager] processNewImagesForGroup:group InFetchResult:self.cameraRollFetchResult forIndexes:insertedIndexes];
            }
        }
        NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
        if ([changedIndexes count]) {
            //check whether we actually care about the changes -> self.frc -> asset localIdentifier -> reload collection view at index
            //[self.collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
        }
    }
}

- (void)fetchOngoingGroups {
    NSPredicate *ongoingPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"isOngoing == YES"]];
    self.ongoingGroups = [FTGroup fetchWithPredicate:ongoingPredicate];
    if ([self.ongoingGroups count]) {
        NSLog(@"start ongoing");
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    } else {
        NSLog(@"stop ongoing");
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

#pragma mark - Location 
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"location change, start updating");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:[(NSNumber *)[defaults objectForKey:@"wakeUpCount"] intValue] + 1] forKey:@"wakeUpCount"];
    [defaults synchronize];
}


@end
