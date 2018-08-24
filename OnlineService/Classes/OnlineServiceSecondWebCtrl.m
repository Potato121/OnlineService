//
//  OnlineServerSecondWebCtrl.m
//  TKApp
//
//  Created by hedy on 2018/7/30.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "OnlineServiceSecondWebCtrl.h"

@interface OnlineServerSecondWebCtrl ()

@end

@implementation OnlineServerSecondWebCtrl
- (id)initWithUrl:(NSString*)url
{
    self=[super init];
    if(self)
    {
        self.urlStr=url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, kNaviBarHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-kNaviBarHeight-44)];
    self.webView.delegate = self;
    
    NSURL *url=[NSURL URLWithString:self.urlStr];
    NSURLRequest* request = [NSURLRequest requestWithURL:url] ;
    [self.webView loadRequest:request];
    
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addGoBack];
}

- (void)addGoBack {
    UIView *navView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, App_Frame_Width, kNaviBarHeight)];
    navView.backgroundColor=zhNewColor(0xDE4C39);
    
    [self.view addSubview:navView];
    
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(10, kStatusBarHeight+10, 50, 30)];
    [navView addSubview:backView];
    
    UIImageView *btnImageView=[[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 25, 25)];
    btnImageView.image=[UIImage imageNamed:@"OnlineService.bundle/close"];
    btnImageView.userInteractionEnabled=YES;
    [backView addSubview:btnImageView];
    
    UIControl *control = [[UIControl alloc] initWithFrame:backView.bounds];
    [control addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:control];
    
    UILabel *titleView=[[UILabel alloc] initWithFrame:CGRectMake((App_Frame_Width-250)/2, kStatusBarHeight+10, 250, 25)];
    titleView.textAlignment=NSTextAlignmentCenter;
    titleView.textColor=[UIColor whiteColor];
    titleView.backgroundColor=[UIColor clearColor];
    self.titleView=titleView;
    [navView addSubview:titleView];
    
    UIView *toolBarView=[[UIView alloc] initWithFrame:CGRectMake(0, APP_Frame_Height-44, App_Frame_Width, 44)];
    toolBarView.layer.borderWidth=0.5;
    toolBarView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    [self.view addSubview:toolBarView];
    
    UIButton *backBtn=[[UIButton alloc] initWithFrame:CGRectMake(App_Frame_Width*0.25, 10, 15, 20)];
    [backBtn setBackgroundImage:[UIImage imageNamed:@"OnlineService.bundle/back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:backBtn];
    
    UIButton *forwardBtn=[[UIButton alloc] initWithFrame:CGRectMake(App_Frame_Width*0.75, 10, 15, 20)];
    [forwardBtn setBackgroundImage:[UIImage imageNamed:@"OnlineService.bundle/foward"] forState:UIControlStateNormal];
    [forwardBtn addTarget:self action:@selector(forward) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:forwardBtn];
}

- (void)back {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)forward {
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"tianbai"] = self;
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        //NSLog(@"异常信息：%@", exceptionValue);
    };
    self.titlestr = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.titleView.text = self.titlestr;
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.titlestr = @"加载中...";
    self.titleView.text = self.titlestr;
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.titlestr = @"加载失败";
    self.titleView.text = self.titlestr;
}

#pragma mark - JSObjcDelegate
- (void)call {
    
}
@end
