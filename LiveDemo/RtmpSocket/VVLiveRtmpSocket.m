//
//  VVLiveRtmpSocket.m
//  LiveDemo
//
//  Created by hp on 16/6/20.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVLiveRtmpSocket.h"
#import "VVVideoEncodeFrame.h"
#import "VVAudioEncodeFrame.h"
#import "rtmp.h"

#define RTMP_RECEIVE_TIMEOUT   2

@interface VVLiveRtmpSocket()
{
    RTMP *_rtmp;
    
    BOOL _hasSendFirstVideoFrame;
    BOOL _hasSendFirstAudioFrame;

    BOOL _isSending;
    BOOL _isConnected;
    BOOL _isConnecting;
    BOOL _isReconnecting;
    
    dispatch_semaphore_t _frameSortSemaphore;
}

@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, strong) NSMutableArray *frameBuffer;
@property (nonatomic, strong) NSMutableArray *sortFrameBuffer;

@property (nonatomic, strong) NSString *rtmpUrlStrl;

@end

@implementation VVLiveRtmpSocket

-(id)initWithRtmpUrlStr:(NSString *)rtmpUrlStrl
{
    self = [super init];
    if (self) {
        _isSending = NO;
        _isConnected = NO;
        _isConnecting = NO;
        _isReconnecting = NO;
        
        _hasSendFirstVideoFrame = NO;
        _hasSendFirstAudioFrame = NO;
        
        self.sortFrameBuffer = [[NSMutableArray alloc] init];
        self.rtmpUrlStrl = rtmpUrlStrl;
        
        _frameSortSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

-(void)start
{
    dispatch_async(self.socketQueue, ^{
        
        if (_isConnecting || _rtmp != NULL) {
            return;
        }
        
        [self connectRtmp];
    });
}

-(void)stop
{
    dispatch_async(self.socketQueue, ^{
        if(_rtmp != NULL){
            RTMP_Close(_rtmp);
            RTMP_Free(_rtmp);
            _rtmp = NULL;
        }
        [self clean];
    });
}

-(void)connectRtmp
{
    _isConnecting = YES;
    
    if(_rtmp != NULL){
        RTMP_Close(_rtmp);
        RTMP_Free(_rtmp);
    }
    
    _rtmp = RTMP_Alloc();
    RTMP_Init(_rtmp);
    
    //设置URL
    char *push_url = (char *)[self.rtmpUrlStrl cStringUsingEncoding:NSASCIIStringEncoding];
    if (RTMP_SetupURL(_rtmp, push_url) < 0){
        //log(LOG_ERR, "RTMP_SetupURL() failed!");
        goto Failed;
    }
    
    //设置可写，即发布流，这个函数必须在连接前使用，否则无效
    RTMP_EnableWrite(_rtmp);
    _rtmp->Link.timeout = RTMP_RECEIVE_TIMEOUT;
    
    //连接服务器
    if (RTMP_Connect(_rtmp, NULL) < 0){
        goto Failed;
    }
    
    //连接流
    if (RTMP_ConnectStream(_rtmp, 0) < 0) {
        goto Failed;
    }
    
    _isConnected = YES;
    _isConnecting = NO;
    _isReconnecting = NO;
    _isSending = NO;
    return;
    
Failed:
    RTMP_Close(_rtmp);
    RTMP_Free(_rtmp);
    [self clean];
}


- (void)clean{
    _isConnecting = NO;
    _isReconnecting = NO;
    _isSending = NO;
    _isConnected = NO;
    _hasSendFirstVideoFrame = NO;
    _hasSendFirstAudioFrame = NO;
    
    dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
    [self.frameBuffer removeAllObjects];
    [self.sortFrameBuffer removeAllObjects];
    dispatch_semaphore_signal(_frameSortSemaphore);
    
}

-(void)sendFrame
{
    if(!_isSending && self.frameBuffer.count > 0){

        if(!_isConnected ||  _isReconnecting || _isConnecting || !_rtmp) return;
        
         _isSending = YES;
        // 调用发送接口
        VVEncodeFrame *frame;
        dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
        frame = [self.frameBuffer firstObject];
        [self.frameBuffer removeObjectAtIndex:0];
        dispatch_semaphore_signal(_frameSortSemaphore);

        if([frame isKindOfClass:[VVVideoEncodeFrame class]]){
            if(!_hasSendFirstVideoFrame){
                _hasSendFirstVideoFrame = YES;
                [self sendVideoHeader:(VVVideoEncodeFrame*)frame];
            }else{
                [self sendVideo:(VVVideoEncodeFrame*)frame];
            }
        }else{
            if(!_hasSendFirstAudioFrame){
                _hasSendFirstAudioFrame = YES;
                [self sendAudioHeader:(VVAudioEncodeFrame*)frame];
            }else{
                [self sendAudio:(VVAudioEncodeFrame*)frame];
            }
            
        }
    }
}

#pragma mark -- Rtmp Send
- (void)sendVideoHeader:(VVVideoEncodeFrame*)videoFrame{
    if(!videoFrame || !videoFrame.sps || !videoFrame.pps) return;
    
    unsigned char * body=NULL;
    NSInteger iIndex = 0;
    NSInteger rtmpLength = 1024;
    const char *sps = videoFrame.sps.bytes;
    const char *pps = videoFrame.pps.bytes;
    NSInteger sps_len = videoFrame.sps.length;
    NSInteger pps_len = videoFrame.pps.length;
    
    body = (unsigned char*)malloc(rtmpLength);
    memset(body,0,rtmpLength);
    
    body[iIndex++] = 0x17;
    body[iIndex++] = 0x00;
    
    body[iIndex++] = 0x00;
    body[iIndex++] = 0x00;
    body[iIndex++] = 0x00;
    
    body[iIndex++] = 0x01;
    body[iIndex++] = sps[1];
    body[iIndex++] = sps[2];
    body[iIndex++] = sps[3];
    body[iIndex++] = 0xff;
    
    /*sps*/
    body[iIndex++]   = 0xe1;
    body[iIndex++] = (sps_len >> 8) & 0xff;
    body[iIndex++] = sps_len & 0xff;
    memcpy(&body[iIndex],sps,sps_len);
    iIndex +=  sps_len;
    
    /*pps*/
    body[iIndex++]   = 0x01;
    body[iIndex++] = (pps_len >> 8) & 0xff;
    body[iIndex++] = (pps_len) & 0xff;
    memcpy(&body[iIndex], pps, pps_len);
    iIndex +=  pps_len;
    
    [self sendPacket:RTMP_PACKET_TYPE_VIDEO data:body size:iIndex nTimestamp:0];
    free(body);
}


- (void)sendVideo:(VVVideoEncodeFrame*)frame{
    if(!frame || !frame.encodeData || frame.encodeData.length < 11) return;
    
    NSInteger i = 0;
    NSInteger rtmpLength = frame.encodeData.length+9;
    unsigned char *body = (unsigned char*)malloc(rtmpLength);
    memset(body,0,rtmpLength);
    
    if(frame.isKeyFrame){
        body[i++] = 0x17;// 1:Iframe  7:AVC
    } else{
        body[i++] = 0x27;// 2:Pframe  7:AVC
    }
    body[i++] = 0x01;// AVC NALU
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = (frame.encodeData.length >> 24) & 0xff;
    body[i++] = (frame.encodeData.length >> 16) & 0xff;
    body[i++] = (frame.encodeData.length >>  8) & 0xff;
    body[i++] = (frame.encodeData.length ) & 0xff;
    memcpy(&body[i],frame.encodeData.bytes,frame.encodeData.length);
    NSLog(@"video timeStamp = %llu", frame.timeStamp);
    [self sendPacket:RTMP_PACKET_TYPE_VIDEO data:body size:(rtmpLength) nTimestamp:frame.timeStamp];
    free(body);
}

- (void)sendAudioHeader:(VVAudioEncodeFrame*)audioFrame{
    if(!audioFrame || !audioFrame.audioInfo) return;
    
    NSInteger rtmpLength = audioFrame.audioInfo.length + 2;/*spec data长度,一般是2*/
    unsigned char * body = (unsigned char*)malloc(rtmpLength);
    memset(body,0,rtmpLength);
    
    /*AF 00 + AAC RAW data*/
    body[0] = 0xAF;
    body[1] = 0x00;
    memcpy(&body[2],audioFrame.audioInfo.bytes,audioFrame.audioInfo.length); /*spec_buf是AAC sequence header数据*/
    [self sendPacket:RTMP_PACKET_TYPE_AUDIO data:body size:rtmpLength nTimestamp:0];
    free(body);
}

- (void)sendAudio:(VVAudioEncodeFrame*)frame{
    if(!frame) return;
    
    NSInteger rtmpLength = frame.encodeData.length + 2;/*spec data长度,一般是2*/
    unsigned char * body = (unsigned char*)malloc(rtmpLength);
    memset(body,0,rtmpLength);
    
    /*AF 01 + AAC RAW data*/
    body[0] = 0xAF;
    body[1] = 0x01;
    memcpy(&body[2],frame.encodeData.bytes,frame.encodeData.length);
    NSLog(@"audio timeStamp = %llu", frame.timeStamp);
    [self sendPacket:RTMP_PACKET_TYPE_AUDIO data:body size:rtmpLength nTimestamp:frame.timeStamp];
    free(body);
}

-(NSInteger) sendPacket:(unsigned int)nPacketType data:(unsigned char *)data size:(NSInteger) size nTimestamp:(uint64_t) nTimestamp{
    NSInteger rtmpLength = size;
    RTMPPacket rtmp_pack;
    RTMPPacket_Reset(&rtmp_pack);
    RTMPPacket_Alloc(&rtmp_pack,(uint32_t)rtmpLength);
    
    rtmp_pack.m_nBodySize = (uint32_t)size;
    memcpy(rtmp_pack.m_body,data,size);
    rtmp_pack.m_hasAbsTimestamp = 0;
    rtmp_pack.m_packetType = nPacketType;
    if(_rtmp) rtmp_pack.m_nInfoField2 = _rtmp->m_stream_id;
    rtmp_pack.m_nChannel = 0x04;
    rtmp_pack.m_headerType = RTMP_PACKET_SIZE_LARGE;
    if (RTMP_PACKET_TYPE_AUDIO == nPacketType && size !=4){
        rtmp_pack.m_headerType = RTMP_PACKET_SIZE_MEDIUM;
    }
    rtmp_pack.m_nTimeStamp = (uint32_t)nTimestamp;
    
    NSInteger nRet = [self RtmpPacketSend:&rtmp_pack];
    
    RTMPPacket_Free(&rtmp_pack);
    return nRet;
}

- (NSInteger)RtmpPacketSend:(RTMPPacket*)packet{
    if (RTMP_IsConnected(_rtmp)){
        int success = RTMP_SendPacket(_rtmp,packet,0);
        if(success){
            _isSending = NO;
            [self sendFrame];
        }
        return success;
    }
    
    return -1;
}

-(void)sendFrame:(VVEncodeFrame *)frame
{
    __weak typeof(self) _self = self;
    dispatch_async(self.socketQueue, ^{
        
        __strong typeof(_self) self = _self;
        if(!frame) return;
        
        dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
        [self appendObject:frame];
        dispatch_semaphore_signal(_frameSortSemaphore);
        
        [self sendFrame];
    });
}

#pragma mark - frame sort
static const NSUInteger defaultSortBufferMaxCount = 10;///< 排序10个内

- (void)appendObject:(VVEncodeFrame*)frame{
    if(!frame) return;
    
    if(self.sortFrameBuffer.count < defaultSortBufferMaxCount){
        [self.sortFrameBuffer addObject:frame];
    }else{
        ///< 排序
        [self.sortFrameBuffer addObject:frame];
        NSArray *sortedSendQuery = [self.sortFrameBuffer sortedArrayUsingFunction:frameDataCompare context:NULL];
        [self.sortFrameBuffer removeAllObjects];
        [self.sortFrameBuffer addObjectsFromArray:sortedSendQuery];
        /// 丢帧
//        [self removeExpireFrame];
        /// 添加至缓冲区
        VVEncodeFrame *firstFrame = [self.sortFrameBuffer firstObject];
        [self.sortFrameBuffer removeObjectAtIndex:0];
        if(firstFrame) [self.frameBuffer addObject:firstFrame];
    }
}

NSInteger frameDataCompare(id obj1, id obj2, void *context){
    VVEncodeFrame* frame1 = (VVEncodeFrame*) obj1;
    VVEncodeFrame *frame2 = (VVEncodeFrame*) obj2;
    
    if (frame1.timeStamp == frame2.timeStamp)
        return NSOrderedSame;
    else if(frame1.timeStamp > frame2.timeStamp)
        return NSOrderedDescending;
    return NSOrderedAscending;
}

#pragma mark -- Getter Setter
- (dispatch_queue_t)socketQueue{
    if(!_socketQueue){
        _socketQueue = dispatch_queue_create("VVLiveRtmpSocketQueue", NULL);
    }
    return _socketQueue;
}

-(NSMutableArray *)frameBuffer
{
    if (!_frameBuffer) {
        _frameBuffer = [[NSMutableArray alloc] init];
    }
    return _frameBuffer;
}

#pragma mark - other
-(void)dealloc
{
    
}

@end
