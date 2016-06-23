//
//  VVAudioEncoder.h
//  LiveDemo
//
//  Created by hp on 16/6/17.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "VVAudioEncodeFrame.h"
#import "VVLiveAudioConfiguration.h"


@protocol VVAudioEncoderDelegate <NSObject>

-(void)audioEncodeComplete:(VVAudioEncodeFrame *)encodeFrame;

@end


@interface VVAudioEncoder : NSObject

@property (nonatomic, strong) VVLiveAudioConfiguration *currentAudioEncodeConfig;

-(id)initWithConfig:(VVLiveAudioConfiguration *)config;
-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;

@property (nonatomic, assign) id <VVAudioEncoderDelegate> delegate;
@end
