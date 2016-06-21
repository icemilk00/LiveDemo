//
//  VVLiveVideoConfiguration.m
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVLiveVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@implementation VVLiveVideoConfiguration

#pragma mark -- LifeCycle
+ (instancetype)defaultConfiguration{
    VVLiveVideoConfiguration *configuration = [VVLiveVideoConfiguration defaultConfigurationForQuality:VVLiveVideoQuality_Default];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(VVLiveVideoQuality)videoQuality{
    VVLiveVideoConfiguration *configuration = [VVLiveVideoConfiguration defaultConfigurationForQuality:videoQuality orientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(VVLiveVideoQuality)videoQuality orientation:(UIInterfaceOrientation)orientation{
    VVLiveVideoConfiguration *configuration = [VVLiveVideoConfiguration new];
    switch (videoQuality) {
        case VVLiveVideoQuality_Low1:
        {
            configuration.sessionPreset = VVCaptureSessionPreset360x640;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 500 * 1024;
            configuration.videoMaxBitRate = 600 * 1024;
            configuration.videoMinBitRate = 250 * 1024;
        }
            break;
        case VVLiveVideoQuality_Low2:
        {
            configuration.sessionPreset = VVCaptureSessionPreset360x640;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_Low3:
        {
            configuration.sessionPreset = VVCaptureSessionPreset360x640;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_Medium1:
        {
            configuration.sessionPreset = VVCaptureSessionPreset540x960;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_Medium2:
        {
            configuration.sessionPreset = VVCaptureSessionPreset540x960;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_Medium3:
        {
            configuration.sessionPreset = VVCaptureSessionPreset540x960;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_High1:
        {
            configuration.sessionPreset = VVCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case VVLiveVideoQuality_High2:
        {
            configuration.sessionPreset = VVCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 800 * 1024;
        }
            break;
        case VVLiveVideoQuality_High3:
        {
            configuration.sessionPreset = VVCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        default:
            break;
    }
    configuration.sessionPreset = [configuration supportSessionPreset:configuration.sessionPreset];
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate*2;
    configuration.orientation = orientation;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        configuration.videoSize = CGSizeMake(368, 640);
    }else{
        configuration.videoSize = CGSizeMake(640, 368);
    }
    
    return configuration;
}

#pragma mark -- Setter Getter
- (NSString*)avSessionPreset{
    NSString *avSessionPreset = nil;
    switch (self.sessionPreset) {
        case VVCaptureSessionPreset360x640:
        {
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
        case VVCaptureSessionPreset540x960:
        {
            avSessionPreset = AVCaptureSessionPresetiFrame960x540;
        }
            break;
        case VVCaptureSessionPreset720x1280:
        {
            avSessionPreset = AVCaptureSessionPreset1280x720;
        }
            break;
        default:{
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
    }
    return avSessionPreset;
}

- (void)setVideoMaxBitRate:(NSUInteger)videoMaxBitRate{
    if(videoMaxBitRate <= _videoBitRate) return;
    _videoMaxBitRate = videoMaxBitRate;
}

- (void)setVideoMinBitRate:(NSUInteger)videoMinBitRate{
    if(videoMinBitRate >= _videoBitRate) return;
    _videoMinBitRate = videoMinBitRate;
}

- (void)setVideoMaxFrameRate:(NSUInteger)videoMaxFrameRate{
    if(videoMaxFrameRate <= _videoFrameRate) return;
    _videoMaxFrameRate = videoMaxFrameRate;
}

- (void)setVideoMinFrameRate:(NSUInteger)videoMinFrameRate{
    if(videoMinFrameRate >= _videoFrameRate) return;
    _videoMinFrameRate = videoMinFrameRate;
}


#pragma mark -- Custom Method
- (VVLiveVideoSessionPreset)supportSessionPreset:(VVLiveVideoSessionPreset)sessionPreset{
    NSString *avSessionPreset = [self avSessionPreset];
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if(![session canSetSessionPreset:avSessionPreset]){
        if(sessionPreset == VVCaptureSessionPreset720x1280){
            sessionPreset = VVCaptureSessionPreset540x960;
            if(![session canSetSessionPreset:avSessionPreset]){
                sessionPreset = VVCaptureSessionPreset360x640;
            }
        }else if(sessionPreset == VVCaptureSessionPreset540x960){
            sessionPreset = VVCaptureSessionPreset360x640;
        }
    }
    return sessionPreset;
}

- (BOOL)isClipVideo{
    return self.sessionPreset == VVCaptureSessionPreset360x640 ? YES : NO;
}

@end
