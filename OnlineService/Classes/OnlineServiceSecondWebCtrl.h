//
//  OnlineServerSecondWebCtrl.h
//  TKApp
//
//  Created by hedy on 2018/7/30.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

#define APP_Frame_Height   [[UIScreen mainScreen] bounds].size.height
#define App_Frame_Width    [[UIScreen mainScreen] bounds].size.width

#define kStatusBarHeight (kDevice_Is_iPhoneX ? 44 : 20)
#define kNaviBarHeight (kDevice_Is_iPhoneX ? 88 : 64)

#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

// 获取RGB颜色
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)
#define BACKCOLOR RGB(232, 234, 235)
#define zhNewColor(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 green:((float)((hexValue & 0xFF00) >> 8))/255.0 blue:((float)(hexValue & 0xFF))/255.0 alpha:1.0]

@protocol JSObjcDelegate <JSExport>
- (void)call;
@end

@interface OnlineServerSecondWebCtrl : UIViewController<UIWebViewDelegate,JSObjcDelegate>
@property (nonatomic, strong) JSContext *jsContext;
@property (strong, nonatomic) UIWebView *webView;
@property(strong,nonatomic) NSString *urlStr;
@property(strong,nonatomic) NSString *titlestr;
@property(strong,nonatomic) UILabel *titleView;
- (id)initWithUrl:(NSString*)url;

@end
