//
//  FTGroupListTableViewCell.h
//  faceTagTester
//
//  Created by Siyao Xie on 3/3/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTGroupListTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

- (void)setTitle:(NSString *)title;
- (void)setSubtitle:(NSString *)subtitle;

@end
