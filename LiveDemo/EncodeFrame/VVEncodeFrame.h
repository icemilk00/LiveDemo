//
//  VVEncodeFrame.h
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VVEncodeFrame : NSObject

@property (nonatomic, assign) uint64_t timeStamp;
@property (nonatomic, strong) NSData *encodeData;

@end
