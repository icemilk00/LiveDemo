//
//  VVLiveAudioConfiguration.h
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 音频码率
typedef NS_ENUM(NSUInteger, VVLiveAudioBitRate) {
    /// 32Kbps 音频码率
    VVLiveAudioBitRate_32Kbps = 32000,
    /// 64Kbps 音频码率
    VVLiveAudioBitRate_64Kbps = 64000,
    /// 96Kbps 音频码率
    VVLiveAudioBitRate_96Kbps = 96000,
    /// 128Kbps 音频码率
    VVLiveAudioBitRate_128Kbps = 128000,
    /// 默认音频码率，默认为 64Kbps
    VVLiveAudioBitRate_Default = VVLiveAudioBitRate_64Kbps
};

/// 采样率 (默认44.1Hz iphoneg6以上48Hz)
typedef NS_ENUM(NSUInteger, VVLiveAudioSampleRate){
    /// 44.1Hz 采样率
    VVLiveAudioSampleRate_44100Hz = 44100,
    /// 48Hz 采样率
    VVLiveAudioSampleRate_48000Hz = 48000,
    /// 默认音频码率，默认为 64Kbps
    VVLiveAudioSampleRate_Default = VVLiveAudioSampleRate_44100Hz
};

///  Audio Live quality（音频质量）
typedef NS_ENUM(NSUInteger, VVLiveAudioQuality){
    /// 高音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 32Kbps
    VVLiveAudioQuality_Low = 0,
    /// 高音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 64Kbps
    VVLiveAudioQuality_Medium = 1,
    /// 高音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 96Kbps
    VVLiveAudioQuality_High = 2,
    /// 高音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 128Kbps
    VVLiveAudioQuality_VeryHigh = 3,
    /// 默认音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 64Kbps
    VVLiveAudioQuality_Default = VVLiveAudioQuality_Medium
};

@interface VVLiveAudioConfiguration : NSObject

/// 默认音频配置
+ (instancetype)defaultConfiguration;
/// 音频配置
+ (instancetype)defaultConfigurationForQuality:(VVLiveAudioQuality)audioQuality;

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/// 声道数目(default 2)
@property (nonatomic, assign) NSUInteger numberOfChannels;
/// 采样率
@property (nonatomic, assign) VVLiveAudioSampleRate audioSampleRate;
// 码率
@property (nonatomic, assign) VVLiveAudioBitRate audioBitrate;
/// flv编码音频头 44100 为0x12 0x10
@property (nonatomic ,assign,readonly) char *asc;

@end
