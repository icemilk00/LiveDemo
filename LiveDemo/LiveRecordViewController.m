//
//  LiveRecordViewController.m
//  LiveDemo
//
//  Created by hp on 16/5/27.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "LiveRecordViewController.h"

#import "VVLiveAudioConfiguration.h"
#import "VVLiveVideoConfiguration.h"
#import "VVLiveSession.h"



@interface LiveRecordViewController ()
{
    /*
    AVCaptureSession *_avSession;
    dispatch_queue_t _videoQueue;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureConnection *_videoConnection;
    AVCaptureConnection *_audioConnection;
    
    AVCaptureVideoPreviewLayer *_previewLayer;
     */
    VVLiveSession *_session;
    
    GPUImageVideoCamera *videoCamera;
    VVLiveVideoConfiguration *videoConfig;
}

@end

@implementation LiveRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self configLiveSession];
    [self configVideoCamera];
    [_session start];
}

-(void)configLiveSession
{
    _session = [[VVLiveSession alloc] initWithRtmpUrlStr:@"rtmp://192.168.16.156:5920/rtmplive/room"];
    
}

-(void)configVideoCamera
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:[_session videoConfigure].avSessionPreset cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.delegate = self;
    videoCamera.outputImageOrientation = [_session videoConfigure].orientation;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    videoCamera.frameRate = (int32_t)[_session videoConfigure].videoFrameRate;
    
    GPUImageHighlightShadowFilter *customFilter = [[GPUImageHighlightShadowFilter alloc] init];
    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [filteredVideoView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [filteredVideoView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [filteredVideoView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    
    [videoCamera addTarget:customFilter];
    [customFilter addTarget:filteredVideoView];
    
    if(videoCamera.cameraPosition == AVCaptureDevicePositionFront) [filteredVideoView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    else [filteredVideoView setInputRotation:kGPUImageNoRotation atIndex:0];
    
    [videoCamera addAudioInputsAndOutputs];
    
    [videoCamera startCameraCapture];
    
    [self.view addSubview:filteredVideoView];
}


- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer andType:(GPUImageMediaType)mediaType
{
    if (mediaType == MediaTypeAudio) {
        [_session audioEncodeWithSampBuffer:sampleBuffer];
    }
    else if (mediaType == MediaTypeVideo)
    {
        [_session videoEncodeWithSampBuffer:sampleBuffer];
    }
}

-(void)dealloc
{
    [videoCamera stopCameraCapture];
}

@end


/*
-(void)beginLive
{
    _avSession = [[AVCaptureSession alloc] init];
    
    NSError *error = nil;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"error is : %@", error.description);
    }
    
    if ([_avSession canAddInput:videoInput]) {
        [_avSession addInput:videoInput];
    }
    
    _videoQueue =  dispatch_queue_create("Video Queue", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    
    NSDictionary *captureSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_avSession canAddOutput:_videoOutput]) {
        [_avSession addOutput:_videoOutput];
    }
    
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [_avSession startRunning];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_avSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [[_previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    _previewLayer.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:_previewLayer];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == _videoConnection) {
        NSLog(@"1");
    }
    else if(connection == _audioConnection)
    {
        NSLog(@"2");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


