//
//  FTGroupManagingViewController.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTGroup.h"
#import "FTPersonPopUpView.h"

@interface FTGroupManagingViewController : UIViewController

@property (nonatomic, strong) FTGroup *group;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSMutableArray *people;

@property (nonatomic, strong) UITextField *groupNameField;
@property (nonatomic, strong) UILabel *fromLabel;
@property (nonatomic, strong) UILabel *toLabel;
@property (nonatomic, strong) UITextField *startDateField;
@property (nonatomic, strong) UITextField *endDateField;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, strong) UIButton *selectDatesButton;
@property (nonatomic, strong) UIButton *addPeopleButton;


@property (nonatomic, strong) FTPersonPopUpView *personPopUpView;

@property (nonatomic, strong) UICollectionView *peopleCollectionView;

@property (nonatomic, strong) NSFetchedResultsController *allPeopleFRC;
@property (nonatomic, strong) NSFetchedResultsController *groupPeopleFRC;

@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *itemChanges;

@property (weak) id target;
@property SEL action;



- (id)initWithGroup:(FTGroup *)group;

@end
