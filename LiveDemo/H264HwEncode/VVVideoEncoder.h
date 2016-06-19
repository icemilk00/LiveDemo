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

typedef  void(^VideoEncodeCompleteBlock)(VVVideoEncodeFrame *encodeFrame, NSError *error);

@class VVVideoConfigure;

@interface VVVideoEncoder : NSObject

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp completeBlock:(VideoEncodeCompleteBlock)completeBlock;

@end


@interface VVVideoConfigure : NSObject

@property (nonatomic, assign) CGSize videoSize;

@end