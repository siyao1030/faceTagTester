//
//  FTGroupsListViewController.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/23/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTGroupsListViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, retain) NSFetchedResultsController *frc;
@end
