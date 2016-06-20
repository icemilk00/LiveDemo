//
//  LiveRecordViewController.m
//  LiveDemo
//
//  Created by hp on 16/5/27.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "LiveRecordViewController.h"
#import "VVAudioEncoder.h"
#import "VVVideoEncoder.h"

#import "VVLiveRtmpSocket.h"
#define NOW (CACurrentMediaTime()*1000)

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
    GPUImageVideoCamera *videoCamera;
    VVVideoEncoder *h264Encoder;
    VVAudioEncoder *audioEncoder;
    VVLiveRtmpSocket *rtmpSocket;
    
    NSMutableData *_audioEncodedData;
    NSMutableData *_videoEncodedData;
    
     dispatch_semaphore_t _lock;
}

@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, assign) BOOL isFirstFrame;
@property (nonatomic, assign) uint64_t currentTimestamp;
@end

@implementation LiveRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
     _lock = dispatch_semaphore_create(1);
    self.timestamp = 0;
    self.isFirstFrame = YES;
    _audioEncodedData = [[NSMutableData alloc] init];
    _videoEncodedData = [[NSMutableData alloc] init];
    [self configRtmpSocket];
    [self configH264Encoder];
    [self configAudioEncoder];
    [self configVideoCamera];
}

-(void)configRtmpSocket
{
    rtmpSocket = [[VVLiveRtmpSocket alloc] init];
    [rtmpSocket start];
}

-(void)configVideoCamera
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.delegate = self;
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageHighlightShadowFilter *customFilter = [[GPUImageHighlightShadowFilter alloc] init];
    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    [videoCamera addTarget:customFilter];
    [customFilter addTarget:filteredVideoView];
    
    [videoCamera addAudioInputsAndOutputs];
    
    [videoCamera startCameraCapture];
    
    [self.view addSubview:filteredVideoView];
}

-(void)configH264Encoder
{
    VVVideoConfigure *videoConfig = [[VVVideoConfigure alloc] init];
    videoConfig.videoSize = self.view.bounds.size;
    
    h264Encoder = [[VVVideoEncoder alloc] initWithConfig:videoConfig];

}

-(void)configAudioEncoder
{
    audioEncoder = [[VVAudioEncoder alloc] init];
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer andType:(GPUImageMediaType)mediaType
{
    if (mediaType == MediaTypeAudio) {
        [audioEncoder encodeSampleBuffer:sampleBuffer timeStamp:self.currentTimestamp completeBlock:^(VVAudioEncodeFrame *encodeFrame) {
            NSLog(@"audio encode frame = %@", encodeFrame);
            [rtmpSocket sendFrame:encodeFrame];
        }];
    }
    else if (mediaType == MediaTypeVideo)
    {
        [h264Encoder encodeSampleBuffer:sampleBuffer timeStamp:self.currentTimestamp completeBlock:^(VVVideoEncodeFrame *encodeFrame) {
            NSLog(@"video encode frame = %@", encodeFrame);
            [rtmpSocket sendFrame:encodeFrame];
        }];
    }
    
}

- (uint64_t)currentTimestamp{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
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
    dispatch_semaphore_signal(_lock);
    return _currentTimestamp;
}

//- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
//{
//    
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    [_videoEncodedData appendData:ByteHeader];
//    [_videoEncodedData appendData:sps];
//    [_videoEncodedData appendData:ByteHeader];
//    [_videoEncodedData appendData:pps];
//}
//
//#pragma mark
//#pragma mark - 视频数据回调
//- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
//{
//    NSLog(@"Video data (%lu): %@", (unsigned long)data.length, data.description);
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    
//    [_videoEncodedData appendData:ByteHeader];
//    [_videoEncodedData appendData:data];
//
//}

-(void)dealloc
{
//    [h264Encoder End];
    
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


