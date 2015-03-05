//
//  FTPopupView.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/27/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPopupView.h"
#define POPUP_BACKGROUND_ALPHA 0.5
@interface FTPopupView () <UIGestureRecognizerDelegate>

@end

@implementation FTPopupView


- (id)init {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self = [super initWithFrame:screenRect];
    if(self == nil) {
        return nil;
    }
    
    self.backgroundColor = [UIColor clearColor];
    //self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UILongPressGestureRecognizer* touchRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    touchRecognizer.minimumPressDuration = 0.005;
    touchRecognizer.delegate = self;
    
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [UIColor blackColor];
    self.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
    [self.overlayView addGestureRecognizer:touchRecognizer];
    [self addSubview:self.overlayView];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    return self;
}

- (void)showPopup {
    // Simply return if we're already shown.
    if(self.superview != nil) {
        return;
    }

    // Get into position.
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    self.frame = currentWindow.bounds;

    [self setNeedsLayout];

    // Force layout of dialog.
    [self layoutIfNeeded];

    CGRect finalFrame = self.contentView.frame;
    
    CGRect startFrame = CGRectMake(finalFrame.origin.x, CGRectGetMaxY(self.frame), finalFrame.size.width, finalFrame.size.height);
    self.contentView.frame = startFrame;
    
    __strong __typeof(self) strongSelf = self;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        strongSelf.contentView.frame = finalFrame;
    } completion:nil];
    // Ready overlay view for fade-in.
    
    self.overlayView.alpha = 0.0;

    // Throw self at front of root view controller or window.
    if(currentWindow.rootViewController != nil) {
        [currentWindow.rootViewController.view addSubview:self];
    }
    else {
        [currentWindow addSubview:self];
    }

    // Fade overlay view in behind content.
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
    } completion:NULL];

    /*
    // About to show.
    if(self.showBlock != nil) {
        self.showBlock();
    }

    // Tell delegate.
    if([self.delegate respondsToSelector:@selector(popupViewDidShow:)]) {
        [self.delegate popupViewDidShow:self];
    }*/

}

- (void)dismissPopup {
    __strong __typeof(self) strongSelf = self;
    PTPopupViewDismissType dismissType = self.dismissType;
    if(dismissType == PTPopupViewDismissNoAnimation) {
        // Instant dismiss avoids animation entirely.
        // Dismiss.
        [strongSelf removeFromSuperview];
        
        // Tell delegate we've dismissed.
        if([strongSelf.delegate respondsToSelector:@selector(popupViewDidDismiss:)]) {
            [strongSelf.delegate popupViewDidDismiss:strongSelf];
        }
        /*
        // Optional dismiss block, handy when tracking multiple popups on delegate
        if (self.dismissBlock) {
            self.dismissBlock();
        }*/
    }
    else if(dismissType == PTPopupViewDismissNormal) {
        // Normal dismiss fades out.
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn animations:^{
            strongSelf.alpha = 0.0;
        } completion:^(BOOL finished) {
            // Dismiss.
            [strongSelf removeFromSuperview];
            strongSelf.alpha = 1.0;
            
            
            // Tell delegate we've dismissed.
            if([strongSelf.delegate respondsToSelector:@selector(popupViewDidDismiss:)]) {
                [strongSelf.delegate popupViewDidDismiss:strongSelf];
            }
            /*
            // Optional dismiss block, handy when tracking multiple popups on delegate
            if (self.dismissBlock) {
                self.dismissBlock();
            }*/
        }];
    }
    else if(dismissType == PTPopupViewDismissScaleDown) {
        // Normal dismiss fades out.
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn animations:^{
            strongSelf.alpha = 0.0;
            strongSelf.contentView.transform = CGAffineTransformScale(strongSelf.contentView.transform, 0.9, 0.9);
        } completion:^(BOOL finished) {
            // Dismiss.
            [strongSelf removeFromSuperview];
            strongSelf.alpha = 1.0;
            strongSelf.contentView.transform = CGAffineTransformIdentity;
            
            // Tell delegate we've dismissed.
            if([strongSelf.delegate respondsToSelector:@selector(popupViewDidDismiss:)]) {
                [strongSelf.delegate popupViewDidDismiss:strongSelf];
            }
            /*
            // Optional dismiss block, handy when tracking multiple popups on delegate
            if (self.dismissBlock) {
                self.dismissBlock();
            }*/
        }];
    }
    else if(dismissType == PTPopupViewDismissFlyUp) {
        // Fly up dismiss pushes the dialog up and offscreen.
        strongSelf.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn animations:^{
            CGRect flyawayFrame = strongSelf.contentView.frame;
            flyawayFrame.origin.y = -flyawayFrame.size.height;
            flyawayFrame.origin.y -= 20.0;
            strongSelf.contentView.frame = flyawayFrame;
            strongSelf.overlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            // Dismiss.
            [strongSelf removeFromSuperview];
            strongSelf.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
            
            
            // Tell delegate we've dismissed.
            if([strongSelf.delegate respondsToSelector:@selector(popupViewDidDismiss:)]) {
                [strongSelf.delegate popupViewDidDismiss:strongSelf];
            }
            /*
            // Optional dismiss block, handy when tracking multiple popups on delegate
            if (self.dismissBlock) {
                self.dismissBlock();
            }*/
        }];
    }
    else if(dismissType == PTPopupViewDismissFlyDown) {
        // Fly down dismiss pushes the dialog down and offscreen.
        strongSelf.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect flyawayFrame = strongSelf.contentView.frame;
            flyawayFrame.origin.y = strongSelf.overlayView.bounds.size.height;
            flyawayFrame.origin.y += 20.0;
            strongSelf.contentView.frame = flyawayFrame;
            strongSelf.overlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            // Dismiss.
            [strongSelf removeFromSuperview];
            strongSelf.overlayView.alpha = POPUP_BACKGROUND_ALPHA;
            
            
            // Tell delegate we've dismissed.
            if([strongSelf.delegate respondsToSelector:@selector(popupViewDidDismiss:)]) {
                [strongSelf.delegate popupViewDidDismiss:strongSelf];
            }
            /*
            // Optional dismiss block, handy when tracking multiple popups on delegate
            if (self.dismissBlock) {
                self.dismissBlock();
            }*/
        }];
    }
}


- (void)backgroundTapped:(UIGestureRecognizer*)recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        [self dismissPopup];
    }
}


#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification*)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval keyboardAnimationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationCurveOptions = UIViewAnimationOptionBeginFromCurrentState;
    
    switch(keyboardAnimationCurve) {
        case UIViewAnimationCurveLinear:
            animationCurveOptions |= UIViewAnimationOptionCurveLinear;
            break;
            
        case UIViewAnimationCurveEaseIn:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseIn;
            break;
            
        case UIViewAnimationCurveEaseOut:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseOut;
            break;
            
        case UIViewAnimationCurveEaseInOut:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseInOut;
            break;
    }
    
    
    CGRect contentFrame = [self.contentView frame];
    contentFrame.origin.y -= keyboardFrame.size.height;
    [UIView animateWithDuration:keyboardAnimationDuration delay:0.0 options:animationCurveOptions animations:^{
        [self.contentView setFrame:contentFrame];
        //self.contentView.frame = [self _dialogFrameWithKeyboardFrame:keyboardFrame];
    } completion:NULL];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval keyboardAnimationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationCurveOptions = UIViewAnimationOptionBeginFromCurrentState;
    
    switch(keyboardAnimationCurve) {
        case UIViewAnimationCurveLinear:
            animationCurveOptions |= UIViewAnimationOptionCurveLinear;
            break;
            
        case UIViewAnimationCurveEaseIn:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseIn;
            break;
            
        case UIViewAnimationCurveEaseOut:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseOut;
            break;
            
        case UIViewAnimationCurveEaseInOut:
            animationCurveOptions |= UIViewAnimationOptionCurveEaseInOut;
            break;
    }
    
    CGRect contentFrame = [self.contentView frame];
    contentFrame.origin.y += keyboardFrame.size.height;
    [UIView animateWithDuration:keyboardAnimationDuration delay:0.0 options:animationCurveOptions animations:^{
        [self.contentView setFrame:contentFrame];
        //self.contentView.frame = [self _dialogFrameWithKeyboardFrame:keyboardFrame];
    } completion:NULL];
}

/*
- (CGRect)_contentFrameWithKeyboardFrame:(CGRect)keyboardFrame {
    CGRect visibleFrame = self.bounds;
    CGRect dialogFrame = CGRectZero;
    CGSize contentSize = self.contentView.frame.size;
    CGSize dialogSize = CGSizeMake(self.bounds.size.width - (POPUP_DIALOG_PADDING * 2.0), contentSize.height);
    
    dialogSize.width = MIN(dialogSize.width, POPUP_DIALOG_MAX_WIDTH);
    
    if(self.dialogButtons.count > 0) {
        dialogSize.height += POPUP_DIALOG_BUTTONS_PADDING;
        dialogSize.height += POPUP_DIALOG_BUTTONS_HEIGHT;
        dialogSize.height += POPUP_DIALOG_BUTTONS_PADDING;
    }
    
    if(!CGRectIsEmpty(keyboardFrame)) {
        visibleFrame = CGRectMake(0.0, 0.0, self.bounds.size.width, keyboardFrame.origin.y);
    }
    
    if(!CGAffineTransformIsIdentity(self.dialogView.transform)) {
        dialogSize = CGSizeApplyAffineTransform(dialogSize, self.dialogView.transform);
    }
    
    dialogFrame = CGRectMake(roundf(CGRectGetMidX(visibleFrame) - (dialogSize.width / 2.0)), roundf(CGRectGetMidY(visibleFrame) - (dialogSize.height / 2.0)), dialogSize.width, dialogSize.height);
    dialogFrame.origin.y = MAX(dialogFrame.origin.y, POPUP_DIALOG_PADDING);
    
    return dialogFrame;
}*/

@end
