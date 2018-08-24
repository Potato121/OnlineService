//
//  AppleSpeechSynthesize.h
//  HuaXiApp
//
//  Created by hedy on 2018/7/11.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AppleSpeechSynthesizeDelegate<NSObject>

@required
- (void)appleSynthesizerWithResult:(NSString *)status info:(NSString *)info token:(NSString *)token;;

@end

@interface AppleSpeechSynthesize : NSObject

@property (nonatomic ,assign) id<AppleSpeechSynthesizeDelegate>delegate;

- (void)appleStartSpeak:(NSString *)string token:(NSString *)token;
- (void)appleStopSpeak;
- (void)appleCancel;

@end

