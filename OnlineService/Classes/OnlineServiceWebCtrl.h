//
//  OnlineServerWebCtrl.h
//  TKApp
//
//  Created by hedy on 2018/7/30.
//  Copyright © 2018年 liubao. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "OnlineServiceDelegate.h"
@interface OnlineServerWebCtrl : UIViewController<UIWebViewDelegate,UIScrollViewDelegate>

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic ,strong) UIWebView *webView;
@property (nonatomic ,copy) NSString *URLString;
@property(nonatomic,assign)id<OnlineServiceDelegate> delegate;
@end
