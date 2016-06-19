//
//  VVVideoEncoder.m
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVVideoEncoder.h"

@interface VVVideoEncoder()
{
    VTCompressionSessionRef _videoCompressionSession;
    
    VVVideoConfigure *_currentVideoEncodeConfig;
    VideoEncodeCompleteBlock _videoEncodeCompleteBlock;
    
    NSInteger frameCount;
    
    dispatch_queue_t _encodeQueue;      //编码队列
    dispatch_queue_t _callBackQueue;    //执行回调队列
}
@end


@implementation VVVideoEncoder

-(id)initWithConfig:(VVVideoConfigure *)config
{
    self = [super init];
    if (self) {
        _encodeQueue = dispatch_queue_create("VideoEncodeQueue", DISPATCH_QUEUE_SERIAL);
        _callBackQueue = dispatch_queue_create("VideoEncodeCallBackQueue", DISPATCH_QUEUE_SERIAL);
        
        _currentVideoEncodeConfig = config;
        
        [self createCompressionSession];
        
    }
    return self;
}

-(void)createCompressionSession
{
    dispatch_sync(_encodeQueue, ^{
        OSStatus status =  VTCompressionSessionCreate(NULL, _currentVideoEncodeConfig.videoSize.width, _currentVideoEncodeConfig.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, compressionOutputCallback, (__bridge void * _Nullable)(self), &_videoCompressionSession);
        
        if (status != noErr) return;
        
        //是否实时编码，不清楚到底设为什么，这里设为不实时，是因为音画同步要更具时间戳来同步，可能不需要实时
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanFalse);
        //指定编码流的配置和水品设为自动
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        //是否允许帧重新排序，不清楚应该设为什么，音画同步按时间戳排，应该是程序手动排，所以这里设置为不允许自动排？
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        //编码H264的压缩方式，有CAVLC 和 CABAC ，这里选CABAC，CABAC质量高
        //CAVLC ：基于上下文的自适应可变长编码
        //CABAC ：基于上下文的自适应二进制算术编码
        //通常来说CABAC被认为比CAVLC效率高5%-15%。 这意味着，CABAC应该在码率低5-15%，的情况下，提供同等的，或者更高的视频质量
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
        VTCompressionSessionPrepareToEncodeFrames(_videoCompressionSession);
    });
}


-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp completeBlock:(VideoEncodeCompleteBlock)completeBlock
{
    dispatch_sync(_encodeQueue, ^{
        
        _videoEncodeCompleteBlock = completeBlock;

        frameCount++;
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
        
        VTEncodeInfoFlags flags;
        
        VTCompressionSessionEncodeFrame(_videoCompressionSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, (__bridge void * _Nullable)(@(timeStamp)), &flags);
    });
}



static void compressionOutputCallback(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    if (status != noErr) return;
    if (!sampleBuffer)   return;
    if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
    
    VVVideoEncoder *videoEncoder = (__bridge VVVideoEncoder *)(outputCallbackRefCon);
    
    BOOL keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    uint64_t timeStamp = [((__bridge_transfer NSNumber*)sourceFrameRefCon) longLongValue];
    
    if (keyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus status =CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (status == noErr) {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                
            }
        }
    }
}


@end
