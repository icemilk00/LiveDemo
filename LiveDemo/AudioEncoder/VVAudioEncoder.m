//
//  VVAudioEncoder.m
//  LiveDemo
//
//  Created by hp on 16/6/17.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVAudioEncoder.h"

@interface VVAudioEncoder()
{
    AudioConverterRef _audioCoverter;   //编码器
    
    dispatch_queue_t _encodeQueue;      //编码队列
    dispatch_queue_t _callBackQueue;    //执行回调队列
    
    size_t _pcmBufferSize;
    char *_pcmBuffer;
    
    uint8_t *_aacBuffer;
    UInt32 _aacBufferSize;
}

@end

@implementation VVAudioEncoder

-(id)init
{
    self = [super init];
    if (self) {
        _encodeQueue = dispatch_queue_create("AudioEncodeQueue", DISPATCH_QUEUE_SERIAL);
        _callBackQueue = dispatch_queue_create("AudioEncodeCallBackQueue", DISPATCH_QUEUE_SERIAL);
        
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
    }
    return self;
}

/*
 *  根据采集的源数据来定义编码器的参数
 */
-(void)makeAudioConverterFromInPutSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    //获取源流的参数描述
    AudioStreamBasicDescription inputAudioStreamDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    AudioStreamBasicDescription outputAudioStreamDescription = {0};
    
    //采样率：保持和源数据的一致
    outputAudioStreamDescription.mSampleRate = inputAudioStreamDescription.mSampleRate;
    //编码为AAC格式
    outputAudioStreamDescription.mFormatID = kAudioFormatMPEG4AAC;
    outputAudioStreamDescription.mFormatFlags = kMPEG4Object_AAC_LC;
    //每个包中含有的数据量,由于是可变不固定的，设置为0
    outputAudioStreamDescription.mBytesPerPacket = 0;
    //每个包中含有的音频数据帧量
    outputAudioStreamDescription.mFramesPerPacket = 1024;
    //每个数据帧中的字节，
    outputAudioStreamDescription.mBytesPerFrame = 0;
    // 1:单声道；2:立体声,不能为0
    outputAudioStreamDescription.mChannelsPerFrame = 1;
    // 每个数据帧中每个通道样本的位数
    outputAudioStreamDescription.mBitsPerChannel = 0;
    outputAudioStreamDescription.mReserved = 0;
    
    AudioClassDescription *inClassDescriptions = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];

    //这里也可以使用AudioConverterNew进行创建，AudioConverterNew会使用默认编码方式，有硬编硬编没硬编软编码，AudioConverterNewSpecific可以直接指定编码方式，这里用软编
    OSStatus status = AudioConverterNewSpecific(&inputAudioStreamDescription, &outputAudioStreamDescription, 1, inClassDescriptions, &_audioCoverter);
    if (status != 0) {
        NSLog(@"make converter status = %d", status);
    }
}

-(AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription inClassDescription;
    
    UInt32 encoderSpecifier = type;
    OSStatus status;
    
    UInt32 size;
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (status) {
        NSLog(@"error getting audio format propery info: %d", (int)(status));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (status) {
        NSLog(@"error getting audio format propery: %d", (int)(status));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&inClassDescription, &(descriptions[i]), sizeof(inClassDescription));
            return &inClassDescription;
        }
    }
    
    return nil;
}

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completeBlock:(void (^)(NSData *encodeData, NSError *error))completeBlock
{
    CFRetain(sampleBuffer);
    dispatch_async(_encodeQueue, ^{
        
        if (!_audioCoverter) {
            [self makeAudioConverterFromInPutSampleBuffer:sampleBuffer];
        }
        
        /*
         CMBlockBuffer是在处理系统中用于移动内存块的对象。它表示在可能的非连续内存区域中，数据的连续值。怎么理解？我的理解是，可能CMBlockBuffer中的数据存
         放在不同的区域中，可能来自内存块，也可能来自其他的buffer reference，使用CMBlockBuffer就隐藏了具体的存储细节，让你可以简单地使用0到
         CMBlockBufferGetDataLength的索引来定位数据。
        */
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        
        //获取_pcmBuffer大小和初始指针
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        memset(_aacBuffer, 0, _aacBufferSize);
        
        AudioBufferList outputAudioBufferList = {0};
        outputAudioBufferList.mNumberBuffers = 1;
        outputAudioBufferList.mBuffers[0].mDataByteSize = _aacBufferSize;
        outputAudioBufferList.mBuffers[0].mData = _aacBuffer;
        
        AudioStreamPacketDescription outputPacketDescription = {0};
        UInt32 ioOutputDataPacketSize = 1;
        
        status = AudioConverterFillComplexBuffer(_audioCoverter, incodeDataProc, (__bridge void * _Nullable)(self), &ioOutputDataPacketSize, &outputAudioBufferList, &outputPacketDescription);
        NSData *data = nil;
        if (status == 0) {
            NSData *rawAAC = [NSData dataWithBytes:outputAudioBufferList.mBuffers[0].mData length:outputAudioBufferList.mBuffers[0].mDataByteSize];
            NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            data = fullData;
        } else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        if (completeBlock) {
            dispatch_async(_callBackQueue, ^{
                completeBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
        
    });
}

static OSStatus incodeDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    VVAudioEncoder *encoder = (__bridge VVAudioEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    //NSLog(@"Number of packets requested: %d", (unsigned int)requestedPackets);
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //NSLog(@"PCM buffer isn't full enough!");
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    //NSLog(@"Copied %zu samples into ioData", copiedSamples);
    return noErr;
}

- (size_t) copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = _pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}

/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

-(void)dealloc
{
    AudioConverterDispose(_audioCoverter);
    free(_aacBuffer);
}

@end
