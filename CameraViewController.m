//
//  CameraViewController.m
//  CameraViewController
//
//  Created by Ken M. Haggerty on 9/17/15.
//  Copyright (c) 2015 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "CameraViewController.h"
#import "AKDebugger.h"
#import "AKGenerics.h"
#import "AKSystemInfo+AssetsLibrary.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
@import AssetsLibrary;
#import "UIView+ResizeLayers.h"

#pragma mark - // DEFINITIONS (Private) //

#define DEFAULT_FLASH NO
#define IMAGE_QUALITY_WIFI AVCaptureSessionPresetMedium
#define IMAGE_QUALITY_3G AVCaptureSessionPresetLow
#define IMAGE_QUALITY_BEST AVCaptureSessionPresetPhoto

#define ANIMATION_DURATION_FLIP 0.33
#define ANIMATION_DURATION_ROTATION 0.18

#define BUTTON_CAMERAROLL_CORNER_RADIUS fminf(self.buttonCameraRollView.frame.size.width, self.buttonCameraRollView.frame.size.height)*0.1f
#define BUTTON_CAMERAROLL_BORDER_WIDTH 1.0f

#define BUTTON_FLASH_COLOR [UIColor colorWithHue:53.0/360.0 saturation:0.9 brightness:1.0 alpha:1.0]

#define BUTTON_SWITCHCAMERA_COLOR [UIColor whiteColor]

@interface CameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSString *segueName;
@property (nonatomic, strong) IBOutlet UIView *viewfinder;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIVisualEffectView *cameraToolbar;
@property (nonatomic, strong) IBOutlet UIView *editToolbar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintEditToolbarBottom;
@property (nonatomic, strong) IBOutlet UIButton *buttonShutter;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *buttonShutterActivityIndicator;
@property (nonatomic, strong) IBOutlet UIButton *buttonCameraRoll;
@property (nonatomic, strong) IBOutlet UIView *buttonCameraRollView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *buttonCameraRollActivityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *buttonCameraRollIcon;
@property (nonatomic, strong) IBOutlet UIView *buttonCameraRollBackground;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintButtonCameraRollBackgroundWidth;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintButtonCameraRollBackgroundHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintButtonCameraRollWidth;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintButtonCameraRollHeight;
@property (nonatomic, strong) IBOutlet UIButton *buttonSwitchCamera;
@property (nonatomic, strong) IBOutlet UIVisualEffectView *buttonSwitchCameraVisualEffectView;
@property (nonatomic, strong) IBOutlet UIButton *buttonFlash;
@property (nonatomic, strong) IBOutlet UIVisualEffectView *buttonFlashVisualEffectView;
@property (nonatomic, strong) IBOutlet UIButton *buttonCancel;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *cameraPreviewLayer;
@property (nonatomic) UIDeviceOrientation deviceOrientation;
@property (nonatomic) CGFloat deviceOrientationAngle;
@property (nonatomic) CGFloat rotationAngle;
@property (nonatomic) BOOL flash;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

// GENERAL //

- (void)setup;
- (void)teardown;
- (void)loadCameraRollThumbnail;

// OBSERVERS //

- (void)addObserversToAKSystemInfo;
- (void)removeObserversFromAKSystemInfo;
- (void)addObserversToAssetsLibrary:(ALAssetsLibrary *)assetsLibrary;
- (void)removeObserversFromAssetsLibrary:(ALAssetsLibrary *)assetsLibrary;

// RESPONDERS //

- (void)internetStatusDidChange:(NSNotification *)notification;
- (void)cameraIsReady:(NSNotificationCenter *)notification;
- (void)deviceOrientationDidChange:(NSNotification *)notification;
- (void)interfaceOrientationDidChange:(NSNotification *)notification;
- (void)assetsLibraryDidChange:(NSNotification *)notification;
- (void)cameraRollDidChange:(NSNotification *)notification;
- (void)didTakePhotoWithImage:(UIImage *)image;

// ACTIONS //

- (IBAction)actionShutter:(id)sender;
- (IBAction)actionCameraRoll:(id)sender;
- (IBAction)actionSwitchCameraTouchDown:(id)sender;
- (IBAction)actionSwitchCamera:(id)sender;
- (IBAction)actionFlash:(id)sender;
- (IBAction)actionRetake:(id)sender;
- (IBAction)actionSegueContinue:(id)sender;
- (IBAction)actionSegueCancel:(id)sender;

// CAMERA //

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
+ (NSString *)imageQuality;

@end

@implementation CameraViewController

#pragma mark - // SETTERS AND GETTERS //

@synthesize segueName = _segueName;
@synthesize viewfinder = _viewfinder;
@synthesize imageView = _imageView;
@synthesize cameraToolbar = _cameraToolbar;
@synthesize editToolbar = _editToolbar;
@synthesize constraintEditToolbarBottom = _constraintEditToolbarBottom;
@synthesize buttonShutter = _buttonShutter;
@synthesize buttonShutterActivityIndicator = _buttonShutterActivityIndicator;
@synthesize buttonCameraRoll = _buttonCameraRoll;
@synthesize buttonCameraRollView = _buttonCameraRollView;
@synthesize buttonCameraRollActivityIndicator = _buttonCameraRollActivityIndicator;
@synthesize buttonCameraRollIcon = _buttonCameraRollIcon;
@synthesize buttonCameraRollBackground = _buttonCameraRollBackground;
@synthesize constraintButtonCameraRollBackgroundWidth = _constraintButtonCameraRollBackgroundWidth;
@synthesize constraintButtonCameraRollBackgroundHeight = _constraintButtonCameraRollBackgroundHeight;
@synthesize constraintButtonCameraRollWidth = _constraintButtonCameraRollWidth;
@synthesize constraintButtonCameraRollHeight = _constraintButtonCameraRollHeight;
@synthesize buttonSwitchCamera = _buttonSwitchCamera;
@synthesize buttonSwitchCameraVisualEffectView = _buttonSwitchCameraVisualEffectView;
@synthesize buttonFlash = _buttonFlash;
@synthesize buttonFlashVisualEffectView = _buttonFlashVisualEffectView;
@synthesize buttonCancel = _buttonCancel;
@synthesize session = _session;
@synthesize frontCameraInput = _frontCameraInput;
@synthesize backCameraInput = _backCameraInput;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoConnection = _videoConnection;
@synthesize cameraPreviewLayer = _cameraPreviewLayer;
@synthesize deviceOrientation = _deviceOrientation;
@synthesize deviceOrientationAngle = _deviceOrientationAngle;
@synthesize rotationAngle = _rotationAngle;
@synthesize flash = _flash;
@synthesize imagePickerController = _imagePickerController;

- (AVCaptureSession *)session
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
    if (_session) return _session;
    
    AVCaptureDeviceInput *input = self.backCameraInput;
    if (!input) input = self.frontCameraInput;
    if (!input)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeWarning methodType:AKMethodTypeSetup customCategories:nil message:[NSString stringWithFormat:@"Could not obtain %@", stringFromVariable(input)]];
        return nil;
    }
    
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:[CameraViewController imageQuality]];
    [_session addInput:input];
    [_session addOutput:self.stillImageOutput];
    
    return _session;
}

- (AVCaptureDeviceInput *)frontCameraInput
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
    if (_frontCameraInput) return _frontCameraInput;
    
    AVCaptureDevice *frontCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    if (!frontCamera)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeNotice methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(frontCamera)]];
        return nil;
    }
    
    NSError *error;
    [frontCamera lockForConfiguration:&error];
    if (error)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
    }
    _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
    if (error)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
    }
    if (!_frontCameraInput)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeWarning methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(_frontCameraInput)]];
    }
    return _frontCameraInput;
}

- (AVCaptureDeviceInput *)backCameraInput
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
    if (_backCameraInput) return _backCameraInput;
    
    AVCaptureDevice *backCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    if (!backCamera)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeNotice methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(backCamera)]];
        return nil;
    }
    
    NSError *error;
    [backCamera lockForConfiguration:&error];
    if (error)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
    }
    _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
    if (error)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
    }
    if (!_backCameraInput)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeWarning methodType:AKMethodTypeGetter customCategories:nil message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(_backCameraInput)]];
    }
    return _backCameraInput;
}

- (AVCaptureStillImageOutput *)stillImageOutput
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
    if (_stillImageOutput) return _stillImageOutput;
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_stillImageOutput setOutputSettings:[[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil]];
    return _stillImageOutput;
}

- (AVCaptureConnection *)videoConnection
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
    if (_videoConnection) return _videoConnection;
    
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                _videoConnection = connection;
                break;
            }
        }
        if (_videoConnection) break;
    }
    return _videoConnection;
}

- (AVCaptureVideoPreviewLayer *)cameraPreviewLayer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:@[AKD_UI] message:nil];
    
    if (_cameraPreviewLayer) return _cameraPreviewLayer;
    
    _cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [_cameraPreviewLayer setFrame:self.viewfinder.bounds];
    [_cameraPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    if (UIDeviceOrientationLandscapeLeft == [[UIDevice currentDevice] orientation])
    {
        [_cameraPreviewLayer setTransform:CATransform3DMakeRotation(-M_PI/2, 0, 0, 1)];
    }
    else if (UIDeviceOrientationLandscapeRight == [[UIDevice currentDevice] orientation])
    {
        [_cameraPreviewLayer setTransform:CATransform3DMakeRotation(M_PI/2, 0, 0, 1)];
    }
    [self.viewfinder.layer addSublayer:_cameraPreviewLayer];
    return _cameraPreviewLayer;
}

- (void)setFlash:(BOOL)flash
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter customCategories:nil message:nil];
    
    _flash = flash;
    
    AVCaptureFlashMode flashMode;
    if (flash)
    {
        flashMode = AVCaptureFlashModeOn;
        [self.buttonFlashVisualEffectView setBackgroundColor:BUTTON_FLASH_COLOR];
    }
    else
    {
        flashMode = AVCaptureFlashModeOff;
        [self.buttonFlashVisualEffectView setBackgroundColor:[UIColor clearColor]];
    }
    for (AVCaptureDeviceInput *input in self.session.inputs)
    {
        if (input.device && input.device.hasFlash)
        {
            [input.device setFlashMode:flashMode];
        }
    }
}

- (UIImagePickerController *)imagePickerController
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:@[AKD_UI] message:nil];
    
    if (_imagePickerController) return _imagePickerController;
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    [_imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [_imagePickerController setAllowsEditing:NO];
    [_imagePickerController setDelegate:self];
    return _imagePickerController;
}

#pragma mark - // INITS AND LOADS //

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeCritical methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:[NSString stringWithFormat:@"Could not initialize %@", stringFromVariable(self)]];
        return nil;
    }
    
    [self setup];
    return self;
}

- (void)awakeFromNib
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super awakeFromNib];
    [self setup];
}

- (void)viewDidLoad
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewDidLoad];
    
    [self setDeviceOrientation:[[UIDevice currentDevice] orientation]];
    CGFloat angle = 0.0f;
    NSNumber *deviceOrientationAngle = [AKGenerics angleForDeviceOrientation:self.deviceOrientation];
    if (deviceOrientationAngle) angle = [deviceOrientationAngle floatValue];
    [self setDeviceOrientationAngle:angle];
    [self setRotationAngle:0.0f];
}

- (void)viewWillAppear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewWillAppear:animated];
    
    [AKSystemInfo setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    CGFloat cornerRadius = BUTTON_CAMERAROLL_CORNER_RADIUS;
    CGFloat borderWidth = BUTTON_CAMERAROLL_BORDER_WIDTH;
    [self.buttonCameraRollView.layer setCornerRadius:cornerRadius];
    [self.buttonCameraRollView.layer setMasksToBounds:YES];
    [self.constraintButtonCameraRollBackgroundWidth setConstant:borderWidth];
    [self.constraintButtonCameraRollBackgroundHeight setConstant:borderWidth];
    [self.buttonCameraRollBackground setNeedsUpdateConstraints];
    [self.buttonCameraRollBackground.layer setCornerRadius:cornerRadius-0.5f*borderWidth];
    [self.buttonCameraRollBackground.layer setMasksToBounds:YES];
    [self.buttonCameraRollBackground.layer setBorderWidth:borderWidth];
    [self.buttonCameraRollBackground.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.constraintButtonCameraRollWidth setConstant:3.0f*borderWidth];
    [self.constraintButtonCameraRollHeight setConstant:3.0f*borderWidth];
    [self.buttonCameraRoll setNeedsUpdateConstraints];
    [self.buttonCameraRoll.layer setCornerRadius:cornerRadius-1.5f*borderWidth];
    [self.buttonCameraRoll.layer setMasksToBounds:YES];
    
    CGSize buttonShutterSize = CGSizeMake(self.buttonShutter.bounds.size.width, self.buttonShutter.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(buttonShutterSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    borderWidth = 4.0f;
    CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.5f);
    CGContextSetLineWidth(context, borderWidth);
    CGContextFillEllipseInRect (context, CGRectMake(borderWidth, borderWidth, buttonShutterSize.width-2.0f*borderWidth, buttonShutterSize.height-2.0f*borderWidth));
    CGContextStrokeEllipseInRect(context, CGRectMake(borderWidth/2.0f, borderWidth/2.0f, buttonShutterSize.width-borderWidth, buttonShutterSize.height-borderWidth));
    CGContextFillPath(context);
    UIImage *circle = UIGraphicsGetImageFromCurrentImageContext();
    [AKGenerics setBackgroundImage:circle forButton:self.buttonShutter];
    UIGraphicsEndImageContext();
    
    if (![self.buttonCameraRoll backgroundImageForState:UIControlStateNormal])
    {
        [self loadCameraRollThumbnail];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewDidAppear:animated];
    
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [self teardown];
}

#pragma mark - // PUBLIC METHODS //

- (void)setSegue:(NSString *)segueName
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter customCategories:@[AKD_UI] message:nil];
    
    [self setSegueName:segueName];
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS (UIImagePickerControllerDelegate) //

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_UI] message:nil];
    
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    [self didTakePhotoWithImage:image];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - // OVERWRITTEN METHODS //

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.cameraPreviewLayer setFrame:CGRectMake(self.viewfinder.bounds.origin.x, self.viewfinder.bounds.origin.y, size.width, size.height)];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super layoutSublayersOfLayer:layer];
}

- (void)viewDidLayoutSubviews
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [super viewDidLayoutSubviews];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    if ([AKGenerics object:segue.identifier isEqualToObject:self.segueName])
    {
        id destinationViewController = segue.destinationViewController;
        if ([destinationViewController respondsToSelector:@selector(setImage:)])
        {
            [destinationViewController performSelector:@selector(setImage:) withObject:self.imageView.image];
        }
    }
}

#pragma mark - // PRIVATE METHODS (General) //

- (void)setup
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [self setView:[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject]];
    
    CALayer *cameraPreviewLayer = self.cameraPreviewLayer;
    [self.viewfinder setLayoutBlock:^(UIView *viewfinder){
        [cameraPreviewLayer setFrame:viewfinder.bounds];
    }];
    
    [self.buttonShutterActivityIndicator setHidesWhenStopped:YES];
    [self.buttonShutterActivityIndicator stopAnimating];
    [self.buttonCameraRollActivityIndicator setHidesWhenStopped:YES];
    [self.buttonCameraRollActivityIndicator stopAnimating];
//    [self.buttonCameraRoll setTintColor:[UIColor colorWithWhite:1.0 alpha:0.1]];
    [self.buttonCameraRoll setAdjustsImageWhenHighlighted:NO];
    
    [self setFlash:DEFAULT_FLASH];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraIsReady:) name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
    
    [self addObserversToAKSystemInfo];
}

- (void)teardown
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_UI] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
    
    [self removeObserversFromAKSystemInfo];
}

- (void)loadCameraRollThumbnail
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:@[AKD_DATA, AKD_UI] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:[AKSystemInfo assetsLibrary]];
    [self.buttonCameraRollIcon setHidden:YES];
    [self.buttonCameraRollActivityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [AKSystemInfo getLastPhotoThumbnailFromCameraRollWithCompletion:^(UIImage *thumbnail){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttonCameraRollActivityIndicator stopAnimating];
                if (!thumbnail)
                {
                    [self.buttonCameraRollIcon setHidden:NO];
                }
                [AKGenerics setBackgroundImage:thumbnail forButton:self.buttonCameraRoll];
            });
        }];
    });
}

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversToAKSystemInfo
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetStatusDidChange:) name:NOTIFICATION_INTERNETSTATUS_DID_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) name:NOTIFICATION_ASSETSLIBRARY_DID_CHANGE object:nil];
    
    [self addObserversToAssetsLibrary:[AKSystemInfo assetsLibrary]];
}

- (void)removeObserversFromAKSystemInfo
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_INTERNETSTATUS_DID_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_ASSETSLIBRARY_DID_CHANGE object:nil];
    
    [self removeObserversFromAssetsLibrary:[AKSystemInfo assetsLibrary]];
}

- (void)addObserversToAssetsLibrary:(ALAssetsLibrary *)assetsLibrary
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraRollDidChange:) name:ALAssetsLibraryChangedNotification object:assetsLibrary];
}

- (void)removeObserversFromAssetsLibrary:(ALAssetsLibrary *)assetsLibrary
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:assetsLibrary];
}

#pragma mark - // PRIVATE METHODS (Responders) //

- (void)internetStatusDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:nil message:nil];
    
    [self.session setSessionPreset:[CameraViewController imageQuality]];
}

- (void)cameraIsReady:(NSNotificationCenter *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_UI] message:nil];
    
    [self.buttonShutterActivityIndicator stopAnimating];
    [self.buttonShutter setUserInteractionEnabled:YES];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_UI] message:nil];
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    NSNumber *newOrientationAngle = [AKGenerics angleForDeviceOrientation:deviceOrientation];
    if (!newOrientationAngle) return;
    
    CGFloat angle = [newOrientationAngle floatValue];
    CGFloat rotation = angle-self.deviceOrientationAngle;
    if (rotation > M_PI) rotation -= 2.0f*M_PI;
    else if (rotation < -1.0f*M_PI) rotation += 2.0f*M_PI;
    self.rotationAngle += rotation;
    if (deviceOrientation != UIDeviceOrientationPortraitUpsideDown)
    {
        [AKGenerics rotateViewsAnimated:@[self.buttonShutter, self.buttonCameraRoll, self.buttonCameraRollIcon, self.buttonSwitchCamera, self.buttonFlash, self.buttonCancel] fromAngle:[[AKGenerics angleForDeviceOrientation:self.deviceOrientation] floatValue] byAngle:self.rotationAngle withDuration:ANIMATION_DURATION_ROTATION completion:^{
            [self setRotationAngle:0.0f];
        }];
        [self setDeviceOrientation:deviceOrientation];
    }
    [self setDeviceOrientationAngle:angle];
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_NOTIFICATION_CENTER, AKD_UI] message:nil];
    
    [self.cameraPreviewLayer.connection setVideoOrientation:[AKGenerics convertInterfaceOrientationToVideoOrientation:[[UIApplication sharedApplication] statusBarOrientation]]];
}

- (void)assetsLibraryDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    ALAssetsLibrary *oldLibrary = [notification.userInfo objectForKey:NOTIFICATION_OLD_KEY];
    if (oldLibrary) [self removeObserversFromAssetsLibrary:oldLibrary];
    
    ALAssetsLibrary *newLibrary = [notification.userInfo objectForKey:NOTIFICATION_OBJECT_KEY];
    if (newLibrary) [self addObserversToAssetsLibrary:newLibrary];
    
    [self loadCameraRollThumbnail];
}

- (void)cameraRollDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [self loadCameraRollThumbnail];
}

- (void)didTakePhotoWithImage:(UIImage *)image
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified customCategories:@[AKD_DATA, AKD_UI] message:nil];
    
    [self.constraintEditToolbarBottom setActive:YES];
    [self.editToolbar setNeedsUpdateConstraints];
    [self.editToolbar setUserInteractionEnabled:YES];
    [self.imageView setImage:image];
    [self.buttonFlashVisualEffectView setHidden:YES];
    [self.buttonSwitchCameraVisualEffectView setHidden:YES];
    [self.buttonShutterActivityIndicator stopAnimating];
}

#pragma mark - // PRIVATE METHODS (Actions) //

- (IBAction)actionShutter:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self.cameraToolbar setUserInteractionEnabled:NO];
//    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeDebug methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:[NSString stringWithFormat:@"About to request a capture from: %@", self.stillImageOutput]];
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
//        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//        if (exifAttachments)
//        {
//            // Do something with the attachments.
//            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeDebug methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:[NSString stringWithFormat:@"Attachments: %@", exifAttachments]];
//        }
        [self.cameraPreviewLayer.connection setEnabled:NO];
        [self.buttonShutterActivityIndicator startAnimating];
        UIImage *image = [[UIImage alloc] initWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer]];
        CGFloat scale = fminf(image.size.width/self.viewfinder.frame.size.width, image.size.height/self.viewfinder.frame.size.height);
        CGRect cropRect = [self.viewfinder convertRect:self.imageView.frame fromView:self.imageView.superview];
        cropRect = CGRectMake(cropRect.origin.x*scale+(image.size.width-self.viewfinder.frame.size.width*scale)*0.5f, cropRect.origin.y*scale+(image.size.height-self.viewfinder.frame.size.height*scale)*0.5f, self.imageView.frame.size.width*scale, self.imageView.frame.size.height*scale);
        image = [AKGenerics cropImage:image toFrame:cropRect];
        [self didTakePhotoWithImage:image];
     }];
}

- (IBAction)actionCameraRoll:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self presentViewController:self.imagePickerController animated:YES completion:NULL];
}

- (IBAction)actionSwitchCameraTouchDown:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self.buttonSwitchCameraVisualEffectView setBackgroundColor:BUTTON_SWITCHCAMERA_COLOR];
}

- (IBAction)actionSwitchCamera:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self.view setUserInteractionEnabled:NO];
    [self.buttonSwitchCameraVisualEffectView setBackgroundColor:[UIColor clearColor]];
    [self.session beginConfiguration];
    AVCaptureDeviceInput *currentCameraInput = [self.session.inputs firstObject];
    AVCaptureDeviceInput *newCameraInput;
    if ([AKGenerics object:currentCameraInput isEqualToObject:self.backCameraInput]) newCameraInput = self.frontCameraInput;
    else newCameraInput = self.backCameraInput;
    UIView *flipView = self.view;
    [AKGenerics flipView:flipView horizontally:YES toPosition:M_PI_2 withAnimations:^{
        [flipView setAlpha:0.0];
    } duration:ANIMATION_DURATION_FLIP/2.0 options:UIViewAnimationOptionCurveLinear completion:^(BOOL finished) {
        [self.session removeInput:currentCameraInput];
        [self.session addInput:newCameraInput];
        [self.session commitConfiguration];
        [self setVideoConnection:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (newCameraInput.device.hasFlash)
            {
                [self.buttonFlashVisualEffectView setHidden:NO];
            }
            else
            {
                [self.buttonFlashVisualEffectView setHidden:YES];
            }
        });
        [flipView setAlpha:0.1];
        [AKGenerics flipView:flipView horizontally:YES toPosition:0.0 withAnimations:^{
            [flipView setAlpha:1.0];
        } duration:ANIMATION_DURATION_FLIP/2.0 options:UIViewAnimationOptionCurveEaseOut completion:^(BOOL finished){
            [self.view setUserInteractionEnabled:YES];
        }];
    }];
}

- (IBAction)actionFlash:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self setFlash:!self.flash];
}

- (IBAction)actionRetake:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self.editToolbar setUserInteractionEnabled:NO];
    [self.cameraPreviewLayer.connection setEnabled:YES];
    [self.imageView setImage:nil];
    [self.constraintEditToolbarBottom setActive:NO];
    [self.editToolbar setNeedsUpdateConstraints];
    [self.buttonFlashVisualEffectView setHidden:NO];
    [self.buttonSwitchCameraVisualEffectView setHidden:NO];
    [self.cameraToolbar setUserInteractionEnabled:YES];
}

- (IBAction)actionSegueContinue:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    if (!self.segueName) return;
    
    [self performSegueWithIdentifier:self.segueName sender:self];
}

- (IBAction)actionSegueCancel:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - // PRIVATE METHODS (Camera) //

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:@[AKD_UI] message:nil];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    
    return nil;
}

+ (NSString *)imageQuality
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter customCategories:nil message:nil];
    
//    if ([AKSystemInfo isReachableViaWiFi]) return IMAGE_QUALITY_WIFI;
//    
//    return IMAGE_QUALITY_3G;
    
    return IMAGE_QUALITY_BEST;
}

//- (void)focusAtPoint:(CGPoint)point
//{
//    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
//    
//    AVCaptureDevice *device = ((AVCaptureDeviceInput *)[self.session.inputs firstObject]).device;
//    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
//    {
//        NSError *error;
//        BOOL success = [device lockForConfiguration:&error];
//        if (error)
//        {
//            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
//        }
//        if (!success)
//        {
//            id delegate = [self delegate];
//            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)])
//            {
//                [delegate acquiringDeviceLockFailedWithError:error];
//            }
//            return;
//        }
//        
//        [device setFocusPointOfInterest:point];
//        [device setFocusMode:AVCaptureFocusModeAutoFocus];
//        [device unlockForConfiguration];
//    }
//}
//
//- (void)exposeAtPoint:(CGPoint)point
//{
//    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction customCategories:@[AKD_UI] message:nil];
//    
//    // missing implementation
//}

@end