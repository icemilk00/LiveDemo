//
//  LiveRecordViewController.m
//  LiveDemo
//
//  Created by hp on 16/5/27.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "LiveRecordViewController.h"
#import "VVAudioEncoder.h"
#import "VVLiveAudioConfiguration.h"
#import "VVVideoEncoder.h"
#import "VVLiveVideoConfiguration.h"
#import "VVLiveRtmpSocket.h"

#define NOW (CACurrentMediaTime()*1000)

@interface LiveRecordViewController () <VVVideoEncoderDelegate, VVAudioEncoderDelegate>
{
    /*
    AVCaptureSession *_avSession;
    dispatch_queue_t _videoQueue;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureConnection *_videoConnection;
    AVCaptureConnection *_audioConnection;
    
    AVCaptureVideoPreviewLayer *_previewLayer;
     */
    GPUImageVideoCamera *videoCamera;
    VVVideoEncoder *videoEncoder;
    VVLiveVideoConfiguration *videoConfig;
    VVAudioEncoder *audioEncoder;
    VVLiveRtmpSocket *rtmpSocket;
    
    NSMutableData *_audioEncodedData;
    NSMutableData *_videoEncodedData;
    
    dispatch_semaphore_t _timeSemaphore;
}

@property (nonatomic, strong) VVLiveRtmpSocket *rtmpSocket;

@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, assign) BOOL isFirstFrame;
@property (nonatomic, assign) uint64_t currentTimestamp;
@end

@implementation LiveRecordViewController
@synthesize rtmpSocket;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
     _timeSemaphore = dispatch_semaphore_create(1);
    self.timestamp = 0;
    self.isFirstFrame = YES;
    _audioEncodedData = [[NSMutableData alloc] init];
    _videoEncodedData = [[NSMutableData alloc] init];
    [self configRtmpSocket];
    [self configVideoEncoder];
    [self configAudioEncoder];
    [self configVideoCamera];
}

-(void)configRtmpSocket
{
    rtmpSocket = [[VVLiveRtmpSocket alloc] init];
    [rtmpSocket start];
}

-(void)configVideoEncoder
{
    videoConfig = [VVLiveVideoConfiguration defaultConfigurationForQuality:VVLiveVideoQuality_Medium2];
    
    videoEncoder = [[VVVideoEncoder alloc] initWithConfig:videoConfig];
    videoEncoder.delegate = self;

}

-(void)configAudioEncoder
{
    audioEncoder = [[VVAudioEncoder alloc] init];
    audioEncoder.delegate = self;
}


-(void)configVideoCamera
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:videoConfig.avSessionPreset cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.delegate = self;
    videoCamera.outputImageOrientation = videoConfig.orientation;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    videoCamera.frameRate = (int32_t)videoConfig.videoFrameRate;
    
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
        [audioEncoder encodeSampleBuffer:sampleBuffer timeStamp:self.currentTimestamp];
    }
    else if (mediaType == MediaTypeVideo)
    {
        [videoEncoder encodeSampleBuffer:sampleBuffer timeStamp:self.currentTimestamp];
    }
}

-(void)audioEncodeComplete:(VVAudioEncodeFrame *)encodeFrame
{
    [rtmpSocket sendFrame:encodeFrame];
}

-(void)videoEncodeComplete:(VVVideoEncodeFrame *)encodeFrame
{
    [rtmpSocket sendFrame:encodeFrame];
}

- (uint64_t)currentTimestamp{
    dispatch_semaphore_wait(_timeSemaphore, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    if(_isFirstFrame == true) {
        _timestamp = NOW;
        _isFirstFrame = false;
        currentts = 0;
    }
    else {
        currentts = NOW - _timestamp;
    }
    _currentTimestamp = currentts;
    dispatch_semaphore_signal(_timeSemaphore);
    return _currentTimestamp;
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


