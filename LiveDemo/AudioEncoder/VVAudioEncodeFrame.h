//
//  VVAudioEncodeFrame.h
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVEncodeFrame.h"

@interface VVAudioEncodeFrame : VVEncodeFrame

/// flv打包中aac的header,AACAUDIODATA 这里用固定的 0x12、0x10
@property (nonatomic, strong) NSData *audioInfo;

@end
