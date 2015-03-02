//
//  FTPersonViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/27/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPersonViewController.h"

#define IMAGE_GRID_WIDTH 50
#define CAPTURE_BUTTON_RADIUS 40


@interface FTPersonViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate> {
    BOOL _frontCameraIsOn;
    BOOL _isTakingPicture;
}

@end

@implementation FTPersonViewController

- (id)initWithPerson:(FTPerson *)person {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self = [super init];
    //[self.view setFrame:screenRect];
    //[self.view setBackgroundColor:[UIColor clearColor]];
    //UIView *bgView = [[UIView alloc] initWithFrame:screenRect];
    //[bgView setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.3]];
    //[self.view addSubview:bgView];
    
    if (person) {
        [self setPerson:person];
        [self setImagePaths:person.trainingImages];
    }
    
    self.addedImages = [[NSMutableArray alloc] init];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rintf(screenRect.size.width * 0.8), rintf(screenRect.size.height * 0.6))];
    CGRect contentFrame = [contentView frame];
    contentFrame.origin.x = rintf((self.view.bounds.size.width - contentFrame.size.width) / 2.0);
    contentFrame.origin.y = rintf((self.view.bounds.size.height - contentFrame.size.height) / 2.0);
    [contentView setFrame:contentFrame];
    [self.view addSubview:contentView];
    CGRect bounds = [contentView bounds];

    
    //cameraView
    self.cameraView = [[UIView alloc] initWithFrame:bounds];
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.imageOutput setOutputSettings:outputSettings];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            self.backCamera = device;
        }
        if ([device position] == AVCaptureDevicePositionFront) {
            self.frontCamera = device;
        }
    }
    
    [self turnOnCamera:self.frontCamera];
    _frontCameraIsOn = YES;
    
    [self.captureSession addOutput:self.imageOutput];
    captureVideoPreviewLayer.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    [contentView addSubview:self.cameraView];
    //[self.view addSubview:self.cameraView];
    
    self.flipCameraButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.flipCameraButton setBackgroundImage:[UIImage imageNamed:@"capture-flip"] forState:UIControlStateNormal];
    [self.flipCameraButton setBackgroundImage:[UIImage imageNamed:@"capture-flip-pressed"] forState:UIControlStateHighlighted];
    [self.flipCameraButton addTarget:self action:@selector(flipCameraPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.flipCameraButton sizeToFit];
    [self.flipCameraButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    
    CGRect flipCameraFrame = [self.flipCameraButton frame];
    flipCameraFrame.origin.x = CGRectGetMaxX(bounds) - flipCameraFrame.size.width - 10;
    flipCameraFrame.origin.y = 10;
    [self.flipCameraButton setFrame:flipCameraFrame];
//    [self.view addSubview:self.flipCameraButton];
    [contentView addSubview:self.flipCameraButton];

    
    CGFloat cameraViewHeight = bounds.size.width;
    
    //Preview View
    CGFloat previewHeight = cameraViewHeight + CAPTURE_BUTTON_RADIUS;
    self.previewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, previewHeight)];
    [self.previewView setHidden:YES];
//    [self.view addSubview:self.previewView];
    [contentView addSubview:self.previewView];
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:self.cameraView.frame];
    [self.previewView addSubview:self.previewImageView];
    
    
    self.retakeButton = [[UIButton alloc] initWithFrame:flipCameraFrame];
    [self.retakeButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
    [self.retakeButton setTitle:@"Retake" forState:UIControlStateNormal];
    [self.retakeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.retakeButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [self.retakeButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.retakeButton addTarget:self action:@selector(retakeImage) forControlEvents:UIControlEventTouchUpInside];
    [self.previewView addSubview:self.retakeButton];
    
    //collection view
    self.selectPhotosButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, IMAGE_GRID_WIDTH, IMAGE_GRID_WIDTH)];
    [self.selectPhotosButton setTitle:@"Select" forState:UIControlStateNormal];
    [self.selectPhotosButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self.selectPhotosButton titleLabel] setFont:[UIFont boldSystemFontOfSize:16]];
    [[self.selectPhotosButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    [self.selectPhotosButton setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.5]];
    [self.selectPhotosButton addTarget:self action:@selector(selectPhotosButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(CAPTURE_BUTTON_RADIUS + 5, 5, 0, 5);
    self.imagesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, cameraViewHeight, bounds.size.width, bounds.size.height - cameraViewHeight) collectionViewLayout:flowLayout];
    [self.imagesCollectionView setDelegate:self];
    [self.imagesCollectionView setDataSource:self];
    [self.imagesCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.imagesCollectionView setBackgroundColor:[UIColor whiteColor]];
//    [self.view addSubview:self.imagesCollectionView];
    [contentView addSubview:self.imagesCollectionView];
    
    //capture button & save button
    self.captureButton = [[UIButton alloc] initWithFrame:CGRectMake(rintf(bounds.size.width / 2.0) - CAPTURE_BUTTON_RADIUS, cameraViewHeight - CAPTURE_BUTTON_RADIUS, CAPTURE_BUTTON_RADIUS * 2, CAPTURE_BUTTON_RADIUS * 2)];
    self.captureButton.layer.cornerRadius = CAPTURE_BUTTON_RADIUS;
    self.captureButton.clipsToBounds = YES;
    self.captureButton.layer.borderWidth = 3.0f;
    self.captureButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.captureButton setBackgroundColor:[UIColor colorForText:@"capture"]];
    [self.captureButton addTarget:self action:@selector(captureImage) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.captureButton];
    [contentView addSubview:self.captureButton];

    
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(rintf(bounds.size.width / 2.0) - CAPTURE_BUTTON_RADIUS, cameraViewHeight - CAPTURE_BUTTON_RADIUS, CAPTURE_BUTTON_RADIUS * 2, CAPTURE_BUTTON_RADIUS * 2)];
    self.saveButton.layer.cornerRadius = CAPTURE_BUTTON_RADIUS;
    self.saveButton.clipsToBounds = YES;
    self.saveButton.layer.borderWidth = 3.0f;
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.saveButton setBackgroundColor:[UIColor colorForText:@"capture"]];
    [self.saveButton addTarget:self action:@selector(captureImage) forControlEvents:UIControlEventTouchUpInside];
    
    [self.saveButton setTitle:@"Keep it" forState:UIControlStateNormal];
    [self.saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.saveButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
//    [self.view addSubview:self.saveButton];
    [contentView addSubview:self.saveButton];

    
    //Top Layer
    self.nameField = [[UITextField alloc] init];
    [self.nameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.nameField setDelegate:self];
    if (self.person) {
        [self.nameField setText:[NSString stringWithFormat:@"%@",self.person.name]];
    }
    [self.nameField setPlaceholder:@"Type the name"];
    [self.nameField setFont:[UIFont boldSystemFontOfSize:20]];
    [self.nameField setTextAlignment:NSTextAlignmentLeft];
    [self.nameField setTextColor:[UIColor colorForText:self.nameField.text]];
    [self.nameField sizeToFit];
    CGRect nameFrame = [self.nameField frame];
    nameFrame.size.width = 200;
    nameFrame.origin.x = 10;
    nameFrame.origin.y = 10;
    [self.nameField setFrame:nameFrame];
//    [self.view addSubview:self.nameField];
    [contentView addSubview:self.nameField];

    
    self.savePersonButton = [[UIButton alloc] initWithFrame:CGRectMake(0, bounds.size.height, bounds.size.width, 50)];
    [self.savePersonButton setBackgroundColor:[UIColor colorForText:@"capture"]];
    [self.savePersonButton setTitle:@"Save" forState:UIControlStateNormal];
    [self.savePersonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.savePersonButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.savePersonButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.savePersonButton addTarget:self action:@selector(savePersonButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.savePersonButton];
    [contentView addSubview:self.savePersonButton];

    
    [self setIsTakingPicture:YES];
    return self;
}

- (void)flipCameraPressed {
    if (_frontCameraIsOn) {
        [self turnOnCamera:self.backCamera];
        _frontCameraIsOn = NO;
    } else {
        [self turnOnCamera:self.frontCamera];
        _frontCameraIsOn = YES;
    }
    
}

- (void)turnOnCamera:(AVCaptureDevice *)device {
    if (device) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!input) {
            // Handle the error appropriately.
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        for (AVCaptureDeviceInput *input in [self.captureSession inputs]) {
            [self.captureSession removeInput:input];
        }
        [self.captureSession addInput:input];
        [self.captureSession startRunning];
    }
}

- (void)selectPhotosButtonPressed {
    
}

- (void)setIsTakingPicture:(BOOL)takingPicture {
    if (takingPicture) {
        _isTakingPicture = YES;
        [self.previewView setHidden:YES];
        [self.saveButton setHidden:YES];
    } else {
        _isTakingPicture = NO;
        [self.previewView setHidden:NO];
        [self.saveButton setHidden:NO];
    }
}

- (void)saveImage {
    [self.addedImages addObject:self.previewImageView.image];
    [self.imagesCollectionView reloadData];
    
    [self retakeImage];
}

- (void)retakeImage {
    [self setIsTakingPicture:YES];
}

- (void)captureImage {
    if (_isTakingPicture) {
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.imageOutput.connections) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                    videoConnection = connection;
                    break;
                }
            }
            
            if (videoConnection) {
                [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            }
        }
        
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            if (imageSampleBuffer != NULL) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                [self processImage:[UIImage imageWithData:imageData]];
            }
        }];
    } else {
        [self saveImage];
    }
    
}

- (void)processImage:(UIImage *)image {
    UIImage *newImage = [image fixOrientation];
    if (_frontCameraIsOn) {
        newImage = [UIImage imageWithCGImage:newImage.CGImage scale:1.0 orientation:UIImageOrientationUpMirrored];
    }
    
    [self.previewImageView setImage:newImage];
    [self setIsTakingPicture:NO];
}

- (UIImage *)scaleAndCropImage:(UIImage *)image toSize:(CGSize)newSize {
    //doesnt work still
    CGFloat ratio = image.size.width/ newSize.width;
    UIImage *rotatedImage = [image fixOrientation];
    UIImage *scaledImage = [UIImage imageWithCGImage:rotatedImage.CGImage scale:ratio orientation:UIImageOrientationUpMirrored];
    
    CGRect clippedRect  = CGRectMake(0, 0, newSize.width, newSize.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([scaledImage CGImage], clippedRect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return newImage;
}

#pragma - mark UITextFieldDelegate
-(void)textFieldDidChange :(UITextField *)textField{
    [textField setTextColor:[UIColor colorForText:textField.text]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
    
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(IMAGE_GRID_WIDTH, IMAGE_GRID_WIDTH);
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [self.imagePaths count] + [self.addedImages count] + 1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    if (indexPath.row == [self.imagePaths count] + [self.addedImages count]) {
        [cell addSubview:self.selectPhotosButton];
    } else {
        UIImage *image = [self loadImageForIndex:indexPath.row];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        [imageView setFrame:CGRectMake(0, 0, IMAGE_GRID_WIDTH, IMAGE_GRID_WIDTH)];
        [cell addSubview:imageView];
    }
    return cell;
}

- (UIImage *)loadImageForIndex:(NSInteger)index {
    UIImage *image;
    if (index < [self.imagePaths count]) {
        NSString *fileName = [self.imagePaths objectAtIndex:index];
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",directory,fileName];
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
        image = [[UIImage alloc] initWithData:imgData];
    } else {
        image = [self.addedImages objectAtIndex:index - self.imagePaths.count];
    }
    return image;
}
@end
