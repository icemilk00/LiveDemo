//
//  VVLiveRtmpSocket.h
//  LiveDemo
//
//  Created by hp on 16/6/20.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVEncodeFrame.h"

@interface VVLiveRtmpSocket : NSObject

-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl;

-(void)start;
-(void)stop;
-(void)sendFrame:(VVEncodeFrame *)frame;

@end
