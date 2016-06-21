//
//  VVVideoEncoder.h
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "VVVideoEncodeFrame.h"
#import "VVLiveVideoConfiguration.h"

@class VVVideoConfigure;

@protocol VVVideoEncoderDelegate <NSObject>

-(void)videoEncodeComplete:(VVVideoEncodeFrame *)encodeFrame;

@end

@interface VVVideoEncoder : NSObject

-(id)initWithConfig:(VVLiveVideoConfiguration *)config;
-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;

@property (nonatomic, assign) id <VVVideoEncoderDelegate> delegate;

@end

