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

@interface VVAudioEncoder : NSObject

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp completeBlock:(void (^)(VVAudioEncodeFrame *encodeFrame))completeBlock;

@end
