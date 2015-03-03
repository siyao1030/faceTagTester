//
//  FTGroupListTableViewCell.m
//  faceTagTester
//
//  Created by Siyao Xie on 3/3/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupListTableViewCell.h"
#define SIDE_PADDING 30

@implementation FTGroupListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // configure cell
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [self.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [self.titleLabel setTextColor:[UIColor blackColor]];
        [self.titleLabel setText:@"placeholder"];
        [self.titleLabel sizeToFit];
        
        CGRect titleFrame = [self.titleLabel frame];
        titleFrame.origin.x = SIDE_PADDING;
        titleFrame.origin.y = SIDE_PADDING;
        [self.titleLabel setFrame:titleFrame];
        
        self.subtitleLabel = [[UILabel alloc] init];
        [self.subtitleLabel setFont:[UIFont systemFontOfSize:16]];
        [self.subtitleLabel setTextAlignment:NSTextAlignmentLeft];
        [self.subtitleLabel setTextColor:[UIColor blackColor]];
        
        CGRect subtitleFrame = [self.subtitleLabel frame];
        subtitleFrame.origin.x = SIDE_PADDING;
        subtitleFrame.origin.y = CGRectGetMaxY(titleFrame) + 10;
        [self.subtitleLabel setFrame:subtitleFrame];

        [self addSubview:self.titleLabel];
        [self addSubview:self.subtitleLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    [self.titleLabel setText:title];
    [self.titleLabel sizeToFit];
}

- (void)setSubtitle:(NSString *)subtitle {
    [self.subtitleLabel setText:subtitle];
    [self.subtitleLabel sizeToFit];
}

@end
