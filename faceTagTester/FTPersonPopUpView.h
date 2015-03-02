//
//  FTPersonPopUpView.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/24/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTGroup.h"
#import "FTPerson.h"
#import "FTPopupView.h"
#import <AVFoundation/AVFoundation.h>

@interface FTPersonPopUpView : FTPopupView

@property (nonatomic, strong) FTGroup *group;
@property (nonatomic, strong) FTPerson *person;
@property (nonatomic, strong) NSMutableArray *imagePaths;
@property (nonatomic, strong) NSMutableArray *addedImages;

@property (nonatomic, strong) UIView *cameraView;
@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UIButton *flipCameraButton;

@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIButton *retakeButton;
@property (nonatomic, strong) UIButton *saveButton;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UICollectionView *imagesCollectionView;
@property (nonatomic, strong) UIButton *selectPhotosButton;
@property (nonatomic, strong) UIButton *savePersonButton;
@property (nonatomic, strong) UIButton *cancelButton;

- (id)initWithGroup:(FTGroup *)group Person:(FTPerson *)person;

@end
