//
//  VVVideoEncodeFrame.h
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVEncodeFrame.h"

@interface VVVideoEncodeFrame : VVEncodeFrame

@property (nonatomic, assign) BOOL isKeyFrame;
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;

@end
