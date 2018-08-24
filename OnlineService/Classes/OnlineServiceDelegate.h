//
//  YichatWebDelegate.h
//  YiChatIOSAndH5
//
//  Created by 曹宗华 on 2018/6/20.
//  Copyright © 2018年 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OnlineServiceDelegate <NSObject>
@required
/**
 获取app登录信息

 @param dic H5传递过来的参数
 @return 从原生获取的用户登录信息
 */
- (NSDictionary*)getAppInfo:(NSDictionary*)dic;


/**
 分享链接

 @param title 消息title
 @param titleUrl Titleurl
 @param text 消息文字
 @param imagePath 图片链接
 @param url url地址
 */
- (void)showShareTitle:(NSString*)title TitleUrl:(NSString*)titleUrl Text:(NSString*)text ImagePath:(NSString*)imagePath Url:(NSString*)url;


/**
 跳转开户

 @param url 开户链接地址
 @param vc 跳转开户页面的VC
 */
- (void)openAccount:(NSString*)url withVC:(UIViewController *)vc;


/**
 跳转业务办理

 @param vc 要跳转业务办理的VC
 */
- (void)openBusinessHandleWithVC:(UIViewController *)vc;
@end
