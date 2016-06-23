//
//  VVLiveSession.m
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVLiveSession.h"

#define NOW_TIME (CACurrentMediaTime() * 1000)  //获取当前时间

@interface VVLiveSession() <VVVideoEncoderDelegate, VVAudioEncoderDelegate>
{
    NSString *_rtmpUrlStr;
    
    BOOL _isSendingFirstFrame;
    uint64_t timeRecord;
    dispatch_semaphore_t _timeStampSemaphore;
    
}
@end

@implementation VVLiveSession


-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl andVideoConfig:(VVLiveVideoConfiguration *)videoConfig andAudiConfig:(VVLiveAudioConfiguration *)audioConfig
{
    self = [super init];
    if (self) {
        _rtmpUrlStr = rtmpUrlStrl;
        
        self.rtmpSocket = [[VVLiveRtmpSocket alloc] initWithRtmpUrlStr:_rtmpUrlStr];
        
        self.videoEncoder = [[VVVideoEncoder alloc] initWithConfig:videoConfig];
        _videoEncoder.delegate = self;
        
        self.audioEncoder = [[VVAudioEncoder alloc] init];
        _audioEncoder.delegate = self;
        
        _isSendingFirstFrame = YES;
        _timeStampSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl
{
    self = [self initWithRtmpUrlStr:rtmpUrlStrl andVideoConfig:[VVLiveVideoConfiguration defaultConfiguration] andAudiConfig:[VVLiveAudioConfiguration defaultConfiguration]];
    if (self) {
        
    }
    return self;
}

#pragma mark - socket control
-(void)start
{
    if (_rtmpSocket) [_rtmpSocket start];
}

-(void)stop
{
    if (_rtmpSocket) [_rtmpSocket stop];
}

#pragma mark - audio & video encode
-(void)audioEncodeWithSampBuffer:(CMSampleBufferRef)sampleBuffer
{
    [_audioEncoder encodeSampleBuffer:sampleBuffer timeStamp:[self sessionTimeStamp]];
}

-(void)videoEncodeWithSampBuffer:(CMSampleBufferRef)sampleBuffer
{
    [_videoEncoder encodeSampleBuffer:sampleBuffer timeStamp:[self sessionTimeStamp]];
}

#pragma mark - audio & video complete delegate
-(void)audioEncodeComplete:(VVAudioEncodeFrame *)encodeFrame
{
    [_rtmpSocket sendFrame:encodeFrame];
}

-(void)videoEncodeComplete:(VVVideoEncodeFrame *)encodeFrame
{
    [_rtmpSocket sendFrame:encodeFrame];
}

#pragma mark - audio & video config info
-(VVLiveVideoConfiguration *)videoConfigure
{
    return _videoEncoder.currentVideoEncodeConfig;
}

-(VVLiveAudioConfiguration *)audioConfigure
{
    return _audioEncoder.currentAudioEncodeConfig;
}

#pragma mark - timeStamp maker
-(uint64_t)sessionTimeStamp
{
    dispatch_semaphore_wait(_timeStampSemaphore, DISPATCH_TIME_FOREVER);
    uint64_t currentTimeStamp;
    if (_isSendingFirstFrame) {
        timeRecord = NOW_TIME;
        currentTimeStamp = 0;
        _isSendingFirstFrame = NO;
    }
    else
    {
        currentTimeStamp = NOW_TIME - timeRecord;
    }
    
    dispatch_semaphore_signal(_timeStampSemaphore);
    return currentTimeStamp;
}

#pragma mark - other
-(void)dealloc
{
    
}
@end
