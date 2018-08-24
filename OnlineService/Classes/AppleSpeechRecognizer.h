//
//  AppleSpeechRecognizer.h
//  HuaXiApp
//
//  Created by hedy on 2018/7/11.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol AppleSpeechRecognizerDelegate<NSObject>

@required
- (void)startAppleRecognizer:(NSString *)str;
- (void)stopAppleRecognizer:(NSString *)str;

@end

@interface AppleSpeechRecognizer : NSObject

@property (nonatomic ,assign) id<AppleSpeechRecognizerDelegate>delegate;

- (void)startRecognizer;
- (void)stopRecognizer;
- (void)cancelRecognizer;

@end
