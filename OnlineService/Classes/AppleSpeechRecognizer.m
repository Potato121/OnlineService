//
//  AppleSpeechRecognizer.m
//  HuaXiApp
//
//  Created by hedy on 2018/7/11.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "AppleSpeechRecognizer.h"
#import <Speech/Speech.h>

@interface AppleSpeechRecognizer()

@property (nonatomic ,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

@end

@implementation AppleSpeechRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initAppleSpeechRecognizer];
    }
    return self;
}

- (void)initAppleSpeechRecognizer {
    if (!self.speechRecognizer) {
        // 设置语言
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
        self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    }
    if (!self.audioEngine) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
}

- (void)startRecognizer {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] <= 10.0) {
        [[[UIAlertView alloc]initWithTitle:@"温馨提示:" message:@"iOS10以下的设备暂不支持语音识别！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil] show];
        return;
    }
    
    //检查语音识别授权
    if (![[self validateRecognizerAuthorStatus] isEqualToString:@"3"]) {
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            NSLog(@"status %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"授权成功" : @"授权失败");
        }];
    }
    
    if (![[self validateAuthorizationStatus] isEqualToString:@"2"]) {
        //检查麦克风授权
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {}];
    }
    
    //设置语音播放模式
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    if (self.recognitionRequest) {
        [self.recognitionRequest endAudio];
        self.recognitionRequest = nil;
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.recognitionRequest.shouldReportPartialResults = YES;
    
    [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        NSLog(@"is final: %d  result: %@", result.isFinal, result.bestTranscription.formattedString);
        if (result.isFinal) {
            NSString *tempStr1 = [result.bestTranscription.formattedString stringByReplacingOccurrencesOfString:@"？" withString:@""];
            NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"，" withString:@""];
            NSString *tempStr3 = [tempStr2 stringByReplacingOccurrencesOfString:@"。" withString:@""];
            NSString *tempStr4 = [tempStr3 stringByReplacingOccurrencesOfString:@"！" withString:@""];
            if (self.delegate && [self.delegate respondsToSelector:@selector(stopAppleRecognizer:)]) {
                [self.delegate stopAppleRecognizer:tempStr4];
            }
        } else {
            if (error && [error.localizedDescription isEqualToString:@"Retry"]) {
                //这表示用户没说话  返回空值，页面会有小西的提示
                if (self.delegate && [self.delegate respondsToSelector:@selector(stopAppleRecognizer:)]) {
                    [self.delegate stopAppleRecognizer:@" "];
                }
            }
        }
    }];
    
    AVAudioFormat *recordingFormat = [[self.audioEngine inputNode] outputFormatForBus:0];
    [[self.audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:nil];
}

#pragma mark - 检查是否具有语音识别使用权限
- (NSString *)validateRecognizerAuthorStatus {
    NSString *flag = @"0";
    //请求权限
    SFSpeechRecognizerAuthorizationStatus authStatus = [SFSpeechRecognizer authorizationStatus];
    switch (authStatus) {
        case SFSpeechRecognizerAuthorizationStatusNotDetermined:
            flag = @"0";
            break;
        case SFSpeechRecognizerAuthorizationStatusDenied:
            flag = @"1";
            break;
        case SFSpeechRecognizerAuthorizationStatusRestricted:
            flag = @"2";
            break;
        case SFSpeechRecognizerAuthorizationStatusAuthorized:
            flag = @"3";
            break;
        default:
            break;
    }
    return flag;
}

#pragma mark - 检测是否具麦克风使用权限
- (NSString *)validateAuthorizationStatus {
    NSString *flag = @"0";
    AVAuthorizationStatus authStatus = [AVCaptureDevice  authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
            //没有询问是否开启麦克风
            flag = @"1";
            break;
        case AVAuthorizationStatusRestricted:
            //未授权，家长限制
            flag = @"0";
            break;
        case AVAuthorizationStatusDenied:
            //玩家未授权
            flag = @"0";
            break;
        case AVAuthorizationStatusAuthorized:
            //玩家授权
            flag = @"2";
            break;
        default:
            break;
    }
    return flag;
}

- (void)stopRecognizer {
    [[self.audioEngine inputNode] removeTapOnBus:0];
    [self.audioEngine stop];
    
    [self.recognitionRequest endAudio];
    self.recognitionRequest = nil;
}

- (void)cancelRecognizer {
    [[self.audioEngine inputNode] removeTapOnBus:0];
    [self.audioEngine stop];
    
    [self.recognitionRequest endAudio];
    self.recognitionRequest = nil;
    self.speechRecognizer = nil;
    self.audioEngine = nil;
}

@end
