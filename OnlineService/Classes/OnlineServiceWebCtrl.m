//
//  OnlineServerWebCtrl.m
//  TKApp
//
//  Created by hedy on 2018/7/30.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "OnlineServiceWebCtrl.h"
#import "OnlineServiceSecondWebCtrl.h"

//语音识别
#import <AVFoundation/AVFoundation.h>
#import "AppleSpeechRecognizer.h"
#import "AppleSpeechSynthesize.h"

#import <CoreLocation/CoreLocation.h>
#import "LocationOperate.h"
#import "WebProgressLine.h"

@interface OnlineServerWebCtrl ()< LocationOperateDelegate,AppleSpeechRecognizerDelegate,AppleSpeechSynthesizeDelegate>

@property (nonatomic,copy) NSString *resultStr;
@property (nonatomic ,strong) AppleSpeechRecognizer *appleRecognizer; /**< Apple语音识别*/
@property (nonatomic ,strong) AppleSpeechSynthesize *appleSpeechSynthesize; /**< Apple语音合成*/
@property (nonatomic ,strong) LocationOperate *locationOperate; /**< 定位操作*/

@property (nonatomic ,assign) BOOL h5CallBack; /**< 在线客服首页调用返回*/
@property (nonatomic ,assign) BOOL resignActivite;

@property (nonatomic, strong) WebProgressLine  *progressLine;

@end

@implementation OnlineServerWebCtrl
{
    int keyboardHeight;
    NSString *tokenStr;  //token
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self settingUA];
    }
    return self;
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.h5CallBack = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.webView.delegate = self;
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.delegate = self;
    //如果是iOS 11调用
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        if (@available(iOS 11.0, *)) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    //解决push出的viewController中，顶部UIWebView有20单位的灰条
    //让布局从navigation bar的底部开始
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.progressLine = [[WebProgressLine alloc] initWithFrame:CGRectMake(0, 20, App_Frame_Width, 2)];
    self.progressLine.lineColor = RGB(222, 76, 57);
    [self.webView addSubview:self.progressLine];
    [self.view addSubview:self.webView];
    [self loadPage];
    
    //apple 语音识别
    self.appleRecognizer = [[AppleSpeechRecognizer alloc] init];
    self.appleRecognizer.delegate = self;
    
    //apple 语音合成
    self.appleSpeechSynthesize = [[AppleSpeechSynthesize alloc] init];
    self.appleSpeechSynthesize.delegate = self;
    
    //定位操作
    self.locationOperate = [[LocationOperate alloc] init];
    self.locationOperate.delegate = self;
    
    //监听程序是否失活
    self.resignActivite=NO;
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:@"UIApplicationWillResignActiveNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:@"UIApplicationDidBecomeActiveNotification" object:nil];
}
    
#pragma mark - 设置UA
- (void)settingUA {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *oldAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    if (![oldAgent containsString:@"thinkive_ios_yichat"]) { // 修改UIWebView的UserAgent
        NSString *customUserAgent = [NSString stringWithFormat:@"%@/%@",oldAgent,@"thinkive_ios_yichat"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent":customUserAgent}];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationOperate stopUpdatingLocation];
}

#pragma mark - 程序失活/唤起控制中心的时候通知
- (void)willResignActive {
    self.resignActivite = YES;
}

#pragma mark - 程序可用
- (void)didBecomeActive {
    self.resignActivite = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 加载页面
- (void)loadPage {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString]];
    [self.webView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.progressLine endLoadingAnimation];
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //JavaScript的tianbai是一个对象，充当原生应用和web页面之间的一个桥梁。用来调用方法webview加载完成调用代理
    self.jsContext[@"tianbai"] = self;
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"在线客服异常信息：%@", exceptionValue);
    };
}
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *URL = request.URL;
    NSString *scheme = [URL scheme];
    if ([scheme isEqualToString:@"yichat"]) {
        [self handleCustomAction:URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.progressLine startLoadingAnimation];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.progressLine endLoadingAnimation];
}

#pragma mark - private method
- (void)handleCustomAction:(NSURL *)URL
{
    NSString *host = [URL host];
    JSValue *callByNative = self.jsContext[@"callByNative"];
    NSMutableArray *tempArray = [NSMutableArray array];
    NSDictionary *dic;
    
    NSString *tokenA = [[URL.absoluteString componentsSeparatedByString:@"?"]lastObject];
    tokenStr = [[tokenA componentsSeparatedByString:@"="]lastObject];
    
    if ([host isEqualToString:@"checkRecordPerm"]) {
        // 检测录音权限之后在回调js的方法callByNative把内容传出去
        if(self.resignActivite == YES) {
            return;
        }
        JSValue *callByNative = self.jsContext[@"callByNative"];
        //传值给web端
        if ([self canRecord]) {
            dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success",@"hasRecordPermissionFlag":@(1)};
            [tempArray addObject:dic];
            [callByNative callWithArguments:tempArray];
        }else
        {
            dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success",@"hasRecordPermissionFlag":@(0)};
            [tempArray addObject:dic];
            [callByNative callWithArguments:tempArray];
        }
        
    } else if ([host isEqualToString:@"getKeypadHeight"]) {
        //增加监听，当键盘出现或改变时收出消息
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        //获取键盘高度
        JSValue *callByNative = self.jsContext[@"callByNative"];
        [callByNative callWithArguments:@[@"checkRecordPerm",[NSString stringWithFormat:@"height:%d",keyboardHeight]]];
        
    } else if ([host isEqualToString:@"cancelKeypad"]) {
        //隐藏键区
        [callByNative callWithArguments:@[@"cancelKeypad",@"cancel"]];
    } else if ([host isEqualToString:@"voiceStart"]) {
        if(self.resignActivite == NO) {
            [self.appleRecognizer startRecognizer];
        } else {
            //程序失去激活后的回调,不启动语音识别
            JSValue *callByNative = self.jsContext[@"callByNative"];
            dic = @{@"token":tokenStr,@"resultCode":@"1",@"resignActivite":@(1)};
            [tempArray addObject:dic];
            [callByNative callWithArguments:tempArray];
        }
    } else if ([host isEqualToString:@"voiceEnd"]) {
        if(self.resignActivite == YES) {
            return;
        } else {
            [self.appleRecognizer stopRecognizer];
        }
    } else if ([host isEqualToString:@"playText"]) {
        NSString *urlString = [URL.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *strA = [urlString substringFromIndex:5];
        NSString *strB = [strA componentsSeparatedByString:@"&"][0];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:strB];
        [self.appleSpeechSynthesize appleStartSpeak:[string string] token:tokenStr];
        
        JSValue *callByNative = self.jsContext[@"callByNative"];
        [callByNative callWithArguments:@[@"playText",string]];
    }else if ([host isEqualToString:@"stopSpeak"]) {
        //停止播放文字
        [self.appleSpeechSynthesize appleStopSpeak];
        
        dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success"};
        [tempArray addObject:dic];
        [callByNative callWithArguments:tempArray];
    }
    else if ([host isEqualToString:@"jumpUrl"]) {
        //跳转新页面
        NSString *jumpUrl=[URL.absoluteString substringFromIndex:21];
        NSArray *tempArray2=[jumpUrl componentsSeparatedByString:@"&"];
        NSString *newUrl=nil;
        if([tempArray2 count]==3) //移除最后两项hasTitle=true&token=4
        {
            newUrl=[tempArray2 firstObject];
        }else if([tempArray2 count]>3) //移除最后两项hasTitle=true&token=4
        {
            NSMutableArray *urlParmAry=[NSMutableArray arrayWithArray:tempArray2];
            [urlParmAry removeLastObject];
            [urlParmAry removeLastObject];
            newUrl=[urlParmAry componentsJoinedByString:@"&"];
        }
        OnlineServerSecondWebCtrl *secondVC = [[OnlineServerSecondWebCtrl alloc]initWithUrl:newUrl];
        [self presentViewController:secondVC animated:YES completion:nil];
    } else if([host isEqualToString:@"getAppInfo"]) {
        NSRange  range=[tokenA rangeOfString:@"&"];
        if(range.location==NSNotFound)//只有一个参数
        {
            JSValue *callByNative = self.jsContext[@"callByNative"];
            NSArray *paramAry=[tokenA componentsSeparatedByString:@"="];
            NSDictionary *paramdic=@{[paramAry firstObject]:[paramAry lastObject]};
            NSDictionary *returnDic= [self.delegate getAppInfo:paramdic];
            
            if(returnDic != nil) {
                [tempArray removeAllObjects];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                [dic setObject:tokenStr forKey:@"token"];
                [dic setObject:@"0" forKey:@"resultCode"];
                [dic setObject:@"success" forKey:@"resultMsg"];
                [dic setObject:returnDic[@"eno"] forKey:@"eno"];
                [dic setObject:returnDic[@"login"] forKey:@"login"];
                [dic setObject:returnDic[@"tel"] forKey:@"tel"];
                [tempArray addObject:dic];
                [callByNative callWithArguments:(NSArray *)tempArray];
            }
        }
    } else if([host isEqualToString:@"showShare"]) {
        NSString *showShareParam=[URL.absoluteString substringFromIndex:19];
        
        NSString *title=nil;
        NSString *titleUrl=nil;
        NSString *text=nil;
        NSString *imagePath=nil;
        NSString *url=nil;
        NSString *token=nil;
        NSArray *paramAry=[showShareParam componentsSeparatedByString:@"&"];
        int length= (int)[paramAry count];
        for (int i=0;i<length;i++) {
            if ([[paramAry objectAtIndex:i] hasPrefix:@"title="]) {
                title=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }else if ([[paramAry objectAtIndex:i] hasPrefix:@"titleUrl="]) {
                titleUrl=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }else if ([[paramAry objectAtIndex:i] hasPrefix:@"text="]) {
                text=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }else if ([[paramAry objectAtIndex:i] hasPrefix:@"imagePath="]) {
                imagePath=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }else if ([[paramAry objectAtIndex:i] hasPrefix:@"url="]) {
                url=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }else if ([[paramAry objectAtIndex:i] hasPrefix:@"token="]) {
                token=[NSString stringWithFormat:@"%@",[[[paramAry objectAtIndex:i] componentsSeparatedByString:@"="] lastObject]];
            }
        }
        [self.delegate showShareTitle:title TitleUrl:titleUrl Text:text ImagePath:imagePath Url:url];
    } else if([host isEqualToString:@"getLocation"]) {
        [self.locationOperate startLocation:self];
    } else if([host isEqualToString:@"navigation"])
    {
        NSString *navigationParam=[URL.absoluteString substringFromIndex:20];
        NSArray *navParamAry=[navigationParam componentsSeparatedByString:@"&"];
        
        NSString *dLongitudeStr=[NSString stringWithFormat:@"%@",[[[navParamAry objectAtIndex:0] componentsSeparatedByString:@"="] lastObject]];
        NSString *dLatitude=[NSString stringWithFormat:@"%@",[[[navParamAry objectAtIndex:1] componentsSeparatedByString:@"="] lastObject]];
        NSString *dname=[[NSString stringWithFormat:@"%@",[[[navParamAry objectAtIndex:2] componentsSeparatedByString:@"="] lastObject]] stringByRemovingPercentEncoding];
        NSArray *endLocation=[NSArray arrayWithObjects:dLongitudeStr,dLatitude,dname,nil];
        
        [self.locationOperate navigationWithEndLocation:endLocation vc:self];
    }else if([host isEqualToString:@"goBack"]) {
        [self goback];
    }else if([host isEqualToString:@"callPhone"]) {
        NSArray *callParam=[tokenA componentsSeparatedByString:@"&"];
        NSString *phoneNum=[NSString stringWithFormat:@"telprompt://%@",[[[callParam firstObject] componentsSeparatedByString:@"="] lastObject]];
        CGFloat version = [[[UIDevice currentDevice]systemVersion]floatValue];
        if (version >= 10.0) {
            /// 大于等于10.0系统使用此openURL方法
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNum] options:@{} completionHandler:nil];
            }
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNum]];
        }
    } else if ([host isEqualToString:@"openAppKH"]) {
        NSString *openURL = [URL.absoluteString substringFromIndex:23];
        NSMutableArray *seperatorArr = [NSMutableArray arrayWithArray:[openURL componentsSeparatedByString:@"&"]];
        [seperatorArr removeLastObject]; //移除token
        NSString *url = [seperatorArr componentsJoinedByString:@"&"];
        //唤起开户
        if (self.delegate && [self.delegate conformsToProtocol:@protocol(OnlineServiceDelegate)]) {
            [self.delegate openAccount:url withVC:self];
        }
    } else if ([host isEqualToString:@"openBusinessHandling"]) {
        //跳转业务办理
        if (self.delegate && [self.delegate conformsToProtocol:@protocol(OnlineServiceDelegate)]) {
            [self.delegate openBusinessHandleWithVC:self];
        }
    }
}

#pragma mark - 首页调用返回
- (void)goback {
    self.h5CallBack = YES;
    [self.appleRecognizer cancelRecognizer];
    self.appleRecognizer.delegate = nil;
    self.appleRecognizer = nil;
    
    [self.appleSpeechSynthesize appleCancel];
    self.appleSpeechSynthesize.delegate = nil;
    self.appleSpeechSynthesize = nil;
    
    self.delegate = nil;
    self.webView.delegate = nil;
    self.webView.scrollView.delegate = nil;
    self.webView = nil;
    
    self.jsContext[@"tianbai"] = nil;
    self.jsContext = nil;
    
    [self.locationOperate unInstallLocation];
    self.locationOperate.delegate = nil;
    self.locationOperate = nil;
    
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if ( self.presentedViewController) {
        [super dismissViewControllerAnimated:flag completion:completion];
    } else {
        if (YES == self.h5CallBack) { //在线客服首页调用返回按钮
            if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}

- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                bCanRecord = granted;
            }];
        }
    }
    return bCanRecord;
}
//当键盘出现或改变时调用
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    //获取键盘的高度
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    // 之后在回调js的方法callByNative把内容传出去
    JSValue *callByNative = self.jsContext[@"callByNative"];
    if (userInfo !=nil) {
        keyboardHeight = keyboardRect.size.height;
        [callByNative callWithArguments:@[@"checkRecordPerm",[NSString stringWithFormat:@"height:%d",keyboardHeight]]];
    } else
    {
        keyboardHeight = 0;
        [callByNative callWithArguments:@[@"checkRecordPerm",[NSString stringWithFormat:@"height:%d",keyboardHeight]]];
    }
}

//当键退出时调用
- (void)keyboardWillHide:(NSNotification *)aNotification{
    
}

#pragma mark - AppleSpeechRecognizerDelegate
- (void)startAppleRecognizer:(NSString *)str {
    JSValue *callByNative = self.jsContext[@"callByNative"];
    NSDictionary *dic;
    NSMutableArray *tempArray = [NSMutableArray array];
    dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success"};
    [tempArray addObject:dic];
    [callByNative callWithArguments:tempArray];
}

- (void)stopAppleRecognizer:(NSString *)str {
    JSValue *callByNative = self.jsContext[@"callByNative"];
    self.resultStr = [[NSString alloc] init];
    self.resultStr = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSDictionary *dic;
    NSMutableArray *tempArray = [NSMutableArray array];
    
    if(str != nil && self.resultStr.length > 0) {
        dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success",@"data":self.resultStr};
        [tempArray addObject:dic];
    } else {
        self.resultStr=@"录音为空";
        dic = @{@"token":tokenStr,@"resultCode":@"-5",@"resultMsg":@"success",@"data":self.resultStr};
        [tempArray addObject:dic];
    }
    [callByNative callWithArguments:tempArray];
}

#pragma mark - AppleSpeechSynthesizeDelegate
- (void)appleSynthesizerWithResult:(NSString *)status info:(NSString *)info token:(NSString *)token {
    JSValue *callByNative = self.jsContext[@"callByNative"];
    NSDictionary *dic = @{@"token":token,@"resultCode":@"0",@"resultMsg":@"success"};
    NSMutableArray *tempArray = [NSMutableArray array];
    if([status isEqualToString:@"语音合成结束"]) {
        //语音合成结束发送了回调
        [tempArray addObject:dic];
        [callByNative callWithArguments:tempArray];
    }
    if([status isEqualToString:@"语音合成取消"]) {
        //语音合成取消发送了回调
        [tempArray addObject:dic];
        [callByNative callWithArguments:tempArray];
    }
}

#pragma mark - LocationOperateDelegate
- (void)didFailWithError:(NSError *)error {
    //定位失败  检查用户授权
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"定位授权" message:@"益理财需要您的位置获得所在城市和附近的营业部" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
        [alertVC addAction:openAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertVC addAction:cancelAction];
        
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

-(void)locationDidUpdateWithLatitude:(double)latitude longitude:(double)longitude {
    //定位成功  回调JS
    JSValue *callByNative = self.jsContext[@"callByNative"];
    NSMutableArray *tempArray = [NSMutableArray array];
    NSDictionary *dic;
    dic = @{@"token":tokenStr,@"resultCode":@"0",@"resultMsg":@"success",@"latitude":@(latitude),@"longitude":@(longitude)};
    [tempArray addObject:dic];
    [callByNative callWithArguments:tempArray];
}

@end
