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

-(void)start;
-(void)sendFrame:(VVEncodeFrame *)frame;

@end
