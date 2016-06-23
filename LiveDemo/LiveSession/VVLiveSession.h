//
//  VVLiveSession.h
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVLiveRtmpSocket.h"
#import "VVVideoEncoder.h"
#import "VVAudioEncoder.h"

@interface VVLiveSession : NSObject

//推流
@property (nonatomic, strong) VVLiveRtmpSocket *rtmpSocket;

//视频编码器
@property (nonatomic, strong) VVVideoEncoder *videoEncoder;

//音频编码器
@property (nonatomic, strong) VVAudioEncoder *audioEncoder;


-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl;
-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl andVideoConfig:(VVLiveVideoConfiguration *)videoConfig andAudiConfig:(VVLiveAudioConfiguration *)audioConfig;

-(void)start;
-(void)stop;

-(void)audioEncodeWithSampBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)videoEncodeWithSampBuffer:(CMSampleBufferRef)sampleBuffer;

-(VVLiveVideoConfiguration *)videoConfigure;
-(VVLiveAudioConfiguration *)audioConfigure;

@end
