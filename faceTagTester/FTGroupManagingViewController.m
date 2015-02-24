//
//  FTGroupManagingViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupManagingViewController.h"
#import "FTGroupPhotosViewController.h"

#define SIDE_PADDING 40

@implementation FTGroupManagingViewController

- (id)initWithGroup:(FTGroup *)group {
    self = [super init];

    if (group) {
        [self setGroupName:group.name];
        [self setStartDate:group.startDate];
        [self setEndDate:group.endDate];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createButtonPressed)];
        self.navigationItem.rightBarButtonItem = createButton;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.groupNameField = [[UITextField alloc] init];
    [self.groupNameField setFont:[UIFont boldSystemFontOfSize:24]];
    [self.groupNameField setPlaceholder:@"Name of the Group"];
    [self.groupNameField setTextAlignment:NSTextAlignmentLeft];
    if (self.groupName) {
        [self.groupNameField setText:self.groupName];
        [self.groupNameField setTextColor:[UIColor colorForText:self.groupName]];
    }
    [self.view addSubview:self.groupNameField];
    [self.groupNameField becomeFirstResponder];
    
    UIColor *dateColor = [UIColor colorForText:@"date"];
    self.fromLabel = [[UILabel alloc] init];
    [self.fromLabel setText:@"FROM"];
    [self.fromLabel setFont:[UIFont boldSystemFontOfSize:22]];
    [self.fromLabel setTextAlignment:NSTextAlignmentLeft];
    [self.fromLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.fromLabel];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    UIDatePicker *startDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [startDatePicker setDatePickerMode:UIDatePickerModeDate];
    [startDatePicker setDate:[NSDate date]];
    startDatePicker.backgroundColor = [UIColor whiteColor];
    [startDatePicker addTarget:self action:@selector(startDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.startDateField = [[UITextField alloc] init];
    [self.startDateField setUserInteractionEnabled:YES];
    [self.startDateField setInputView:startDatePicker];
    [self.startDateField setFont:[UIFont boldSystemFontOfSize:22]];
    if (self.startDate) {
        NSString *startDateString = [dateFormatter stringFromDate:self.startDate];
        [self.startDateField setText:startDateString];
        [self.startDateField setTextColor:dateColor];
        [startDatePicker setDate:self.startDate];
    } else {
        [self.startDateField setText:@"Once upon a time..."];
        [self.startDateField setTextColor:[dateColor pathDarkColor]];
    }
    [self.view addSubview:self.startDateField];
    
    self.toLabel = [[UILabel alloc] init];
    [self.toLabel setText:@"TO"];
    [self.toLabel setFont:[UIFont boldSystemFontOfSize:22]];
    [self.toLabel setTextAlignment:NSTextAlignmentLeft];
    [self.toLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.toLabel];

    
    UIDatePicker *endDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [endDatePicker setDatePickerMode:UIDatePickerModeDate];
    [endDatePicker setDate:[NSDate date]];
    endDatePicker.backgroundColor = [UIColor whiteColor];
    [endDatePicker addTarget:self action:@selector(endDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.endDateField = [[UITextField alloc] init];
    [self.endDateField setUserInteractionEnabled:YES];
    [self.endDateField setInputView:endDatePicker];
    [self.endDateField setFont:[UIFont boldSystemFontOfSize:22]];
    if (self.endDate) {
        NSString *endDateString = [dateFormatter stringFromDate:self.endDate];
        [self.endDateField setText:endDateString];
        [self.endDateField setTextColor:dateColor];
        [endDatePicker setDate:self.endDate];
    } else {
        [self.endDateField setText:@"The end of the world..."];
        [self.endDateField setTextColor:[dateColor pathDarkColor]];
    }
    [self.view addSubview:self.endDateField];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect bounds = [[self view] bounds];
    CGFloat yOffset = 100;
    
    [self.groupNameField sizeToFit];
    CGRect groupNameFrame = [self.groupNameField frame];
    groupNameFrame.size.width = bounds.size.width - 2 * SIDE_PADDING;
    groupNameFrame.origin.x = SIDE_PADDING;
    groupNameFrame.origin.y = yOffset;
    [self.groupNameField setFrame:groupNameFrame];
    yOffset = CGRectGetMaxY(groupNameFrame) + 20;
    
    [self.fromLabel sizeToFit];
    CGRect fromLabelFrame = [self.fromLabel frame];
    fromLabelFrame.origin.x = SIDE_PADDING;
    fromLabelFrame.origin.y = yOffset;
    [self.fromLabel setFrame:fromLabelFrame];

    [self.startDateField sizeToFit];
    CGRect startDateFieldFrame = [self.endDateField frame];
    startDateFieldFrame.origin.x = CGRectGetMaxX(fromLabelFrame) + 10;
    startDateFieldFrame.origin.y = fromLabelFrame.origin.y - rintf((startDateFieldFrame.size.height - fromLabelFrame.size.height) / 2.0);
    [self.startDateField setFrame:startDateFieldFrame];
    
    yOffset = CGRectGetMaxY(fromLabelFrame) + 20;
    
    [self.toLabel sizeToFit];
    CGRect toLabelFrame = [self.toLabel frame];
    toLabelFrame.origin.x = SIDE_PADDING;
    toLabelFrame.origin.y = yOffset;
    [self.toLabel setFrame:toLabelFrame];

    [self.endDateField sizeToFit];
    CGRect endDateFieldFrame = [self.endDateField frame];
    endDateFieldFrame.origin.x = startDateFieldFrame.origin.x;
    endDateFieldFrame.origin.y = toLabelFrame.origin.y - rintf((endDateFieldFrame.size.height - toLabelFrame.size.height) / 2.0);
    [self.endDateField setFrame:endDateFieldFrame];
    
    yOffset = CGRectGetMaxY(fromLabelFrame) + 20;

    
}

- (void)startDateSelected:(UIDatePicker *)datePicker {
    NSLog(@"start selected:%@", [datePicker date]);
    [self setStartDate:[datePicker date]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[datePicker date]];
    [self.startDateField setText:dateString];
}

- (void)endDateSelected:(UIDatePicker *)datePicker {
    NSLog(@"end selected:%@", [datePicker date]);
    [self setEndDate:[datePicker date]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[datePicker date]];
    [self.endDateField setText:dateString];
}

- (void)doneButtonPressed {
    NSMutableDictionary *editedGroupInfo = [[NSMutableDictionary alloc] init];
    [editedGroupInfo setValue:self.groupNameField.text forKey:@"groupName"];
    [editedGroupInfo setValue:self.startDate forKey:@"startDate"];
    [editedGroupInfo setValue:self.endDate forKey:@"endDate"];

    [self.target performSelector:self.action withObject:editedGroupInfo afterDelay:0];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createButtonPressed {
    dispatch_sync(CoreDataWriteQueue(), ^{
        FTGroup *newGroup = [[FTGroup alloc] initWithName:self.groupNameField.text andPeople:self.people andStartDate:self.startDate andEndDate:self.endDate];
        FTGroupPhotosViewController *groupPhotosView = [[FTGroupPhotosViewController alloc] initWithGroup:newGroup];
        [self.navigationController showViewController:groupPhotosView sender:self];
    });
}

@end
