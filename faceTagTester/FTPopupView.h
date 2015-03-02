//
//  FTPopupView.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/27/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PTPopupViewDismissDont,
    PTPopupViewDismissDeny,
    PTPopupViewDismissNoAnimation,
    PTPopupViewDismissNormal,
    PTPopupViewDismissFlyUp,
    PTPopupViewDismissFlyDown,
    PTPopupViewDismissScaleDown
} PTPopupViewDismissType;

typedef enum : NSUInteger {
    PTPopupViewShowNormal,
    PTPopupViewShowFlyUp,
    PTPopupViewShowFlyDown
} PTPopupViewShowType;

@interface FTPopupView : UIView
//@property (readwrite, nonatomic, weak) id<PTPopupViewDelegate> delegate;

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, assign) PTPopupViewShowType showType;
@property (nonatomic, assign) PTPopupViewDismissType dismissType;

-(void)showPopup;
-(void)dismissPopup;


@end