//
//  VVLiveVideoConfiguration.h
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 视频分辨率(都是16：9 当此设备不支持当前分辨率，自动降低一级)
typedef NS_ENUM(NSUInteger, VVLiveVideoSessionPreset){
    /// 低分辨率
    VVCaptureSessionPreset360x640 = 0,
    /// 中分辨率
    VVCaptureSessionPreset540x960 = 1,
    /// 高分辨率
    VVCaptureSessionPreset720x1280 = 2
};

/// 视频质量
typedef NS_ENUM(NSUInteger, VVLiveVideoQuality){
    /// 分辨率： 360 *640 帧数：15 码率：500Kps
    VVLiveVideoQuality_Low1 = 0,
    /// 分辨率： 360 *640 帧数：24 码率：800Kps
    VVLiveVideoQuality_Low2 = 1,
    /// 分辨率： 360 *640 帧数：30 码率：800Kps
    VVLiveVideoQuality_Low3 = 2,
    /// 分辨率： 540 *960 帧数：15 码率：800Kps
    VVLiveVideoQuality_Medium1 = 3,
    /// 分辨率： 540 *960 帧数：24 码率：800Kps
    VVLiveVideoQuality_Medium2 = 4,
    /// 分辨率： 540 *960 帧数：30 码率：800Kps
    VVLiveVideoQuality_Medium3 = 5,
    /// 分辨率： 720 *1280 帧数：15 码率：1000Kps
    VVLiveVideoQuality_High1 = 6,
    /// 分辨率： 720 *1280 帧数：24 码率：1200Kps
    VVLiveVideoQuality_High2 = 7,
    /// 分辨率： 720 *1280 帧数：30 码率：1200Kps
    VVLiveVideoQuality_High3 = 8,
    /// 默认配置
    VVLiveVideoQuality_Default = VVLiveVideoQuality_Low2
};

@interface VVLiveVideoConfiguration : NSObject

/// 默认视频配置
+ (instancetype)defaultConfiguration;
/// 视频配置(质量)
+ (instancetype)defaultConfigurationForQuality:(VVLiveVideoQuality)videoQuality;

/// 视频配置(质量 & 方向)
+ (instancetype)defaultConfigurationForQuality:(VVLiveVideoQuality)videoQuality orientation:(UIInterfaceOrientation)orientation;

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/// 视频的分辨率，宽高务必设定为 2 的倍数，否则解码播放时可能出现绿边
@property (nonatomic, assign) CGSize videoSize;

/// 视频输出方向
@property (nonatomic, assign) UIInterfaceOrientation orientation;

/// 视频的帧率，即 fps
@property (nonatomic, assign) NSUInteger videoFrameRate;

/// 视频的最大帧率，即 fps
@property (nonatomic, assign) NSUInteger videoMaxFrameRate;

/// 视频的最小帧率，即 fps
@property (nonatomic, assign) NSUInteger videoMinFrameRate;

/// 最大关键帧间隔，可设定为 fps 的2倍，影响一个 gop 的大小
@property (nonatomic, assign) NSUInteger videoMaxKeyframeInterval;

/// 视频的码率，单位是 bps
@property (nonatomic, assign) NSUInteger videoBitRate;

/// 视频的最大码率，单位是 bps
@property (nonatomic, assign) NSUInteger videoMaxBitRate;

/// 视频的最小码率，单位是 bps
@property (nonatomic, assign) NSUInteger videoMinBitRate;

///< 分辨率
@property (nonatomic, assign) VVLiveVideoSessionPreset sessionPreset;

///< ≈sde3分辨率
@property (nonatomic, assign,readonly) NSString *avSessionPreset;

///< 是否裁剪
@property (nonatomic, assign,readonly) BOOL isClipVideo;


@end
