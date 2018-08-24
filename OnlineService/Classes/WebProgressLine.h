//
//  WebProgressLine.h
//  HuaXiApp
//
//  Created by hedy on 2018/7/27.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebProgressLine : UIView

//进度条颜色
@property (nonatomic,strong) UIColor  *lineColor;

//开始加载
-(void)startLoadingAnimation;

//结束加载
-(void)endLoadingAnimation;

@end
