//
//  FTGroupManagingViewController.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTGroup.h"

@interface FTGroupManagingViewController : UIViewController

@property (nonatomic, strong) FTGroup *group;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) UITextField *groupNameField;
@property (nonatomic, strong) UILabel *fromLabel;
@property (nonatomic, strong) UILabel *toLabel;
@property (nonatomic, strong) UITextField *startDateField;
@property (nonatomic, strong) UITextField *endDateField;
@property (nonatomic, strong) UICollectionView *peopleView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@property (weak) id delegate;
@property SEL action;



- (id)initWithGroup:(FTGroup *)group;

@end
