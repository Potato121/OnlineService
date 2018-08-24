//
//  AppleSpeechSynthesize.m
//  HuaXiApp
//
//  Created by hedy on 2018/7/11.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "AppleSpeechSynthesize.h"
#import <Speech/Speech.h>

@interface AppleSpeechSynthesize()<AVSpeechSynthesizerDelegate>

@property (nonatomic ,strong) AVSpeechSynthesizer *synthesizer;  //合成器
@property (nonatomic ,strong) AVSpeechSynthesisVoice *synthesizeVoice; //声音
@property (nonatomic ,strong) AVSpeechUtterance *speechUtterance; //文字
@property (nonatomic ,copy) NSString *currToken; //当前播放的Token
@property (nonatomic ,copy) NSString *lastToken; //之前播放的Token

@end

@implementation AppleSpeechSynthesize

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lastToken = @"";
        self.currToken = @"";
        [self initAppleSysthesize];
    }
    return self;
}

- (void)initAppleSysthesize {
    
    /*
     AVSpeechSynthesizer: 语音合成器, 可以假想成一个可以说话的人, 是最主要的接口
     AVSpeechSynthesisVoice: 可以假想成人的声音
     AVSpeechUtterance: 可以假想成要说的一段话
     */
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.delegate = self;
    self.synthesizeVoice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
}


- (void)appleStartSpeak:(NSString *)string token:(NSString *)token {
    //开始语音合成
    if (string != nil) {
        NSString *tempStr = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (tempStr.length > 0) {
            if (self.synthesizer.isSpeaking) {
                //暂停说话
                BOOL stoped = [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
                if (stoped) {
                    if (![self.currToken isEqualToString:token]) {
                        //记录在播放中被取消的token，方便回调
                        self.lastToken = [NSString stringWithFormat:@"%@",self.currToken];
                        self.currToken = @"";
                    }
                    [self speechWithString:tempStr];
                }
            } else {
                [self speechWithString:tempStr];
            }
            self.currToken = token;
        }
    }
}

- (void)speechWithString:(NSString *)string {
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    [avSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [avSession setActive:YES error:nil];
    
    self.speechUtterance = [AVSpeechUtterance speechUtteranceWithString:string];
    self.speechUtterance.voice = self.synthesizeVoice;
    self.speechUtterance.rate = 0.525; //设置语速
    self.speechUtterance.volume = 1.0; //设置音量
    self.speechUtterance.pitchMultiplier = 0.80; //设置语调
    [self.synthesizer speakUtterance:self.speechUtterance];
}

- (void)appleStopSpeak {
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)appleCancel {
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    self.synthesizer.delegate = nil;
    self.synthesizer = nil;
    self.synthesizeVoice = nil;
    self.speechUtterance = nil;
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    //语音合成开始
    [self.delegate appleSynthesizerWithResult:@"语音合成开始" info:@"1" token:self.currToken];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    //语音合成结束
    [self.delegate appleSynthesizerWithResult:@"语音合成结束" info:@"3" token:self.currToken];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    //语音合成取消
    if (self.lastToken != nil && ![self.lastToken isEqualToString:@""] && self.lastToken.length > 0) {
        [self.delegate appleSynthesizerWithResult:@"语音合成取消" info:@"2" token:self.lastToken];
        self.lastToken = @"";
    } else {
        [self.delegate appleSynthesizerWithResult:@"语音合成取消" info:@"2" token:self.currToken];
    }
}

@end
