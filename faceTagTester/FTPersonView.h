//
//  FTPersonView.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/24/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTPerson.h"
#import <AVFoundation/AVFoundation.h>

@interface FTPersonView : UIView

@property (nonatomic, strong) FTPerson *person;
@property (nonatomic, strong) NSMutableArray *imagePaths;
@property (nonatomic, strong) NSMutableArray *addedImages;

@property (nonatomic, strong) UIView *cameraView;

@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UIButton *flipCameraButton;
@property (nonatomic, strong) UIButton *retakeButton;
@property (nonatomic, strong) UIButton *saveButton;


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UICollectionView *imagesCollectionView;
@property (nonatomic, strong) UIButton *selectPhotosButton;

- (id)initWithPerson:(FTPerson *)person;
@end
