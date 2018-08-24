//
//  WebProgressLine.m
//  HuaXiApp
//
//  Created by hedy on 2018/7/27.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "WebProgressLine.h"

@implementation WebProgressLine

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

-(void)setLineColor:(UIColor *)lineColor{
    _lineColor = lineColor;
    self.backgroundColor = lineColor;
}

-(void)startLoadingAnimation{
    self.hidden = NO;
    CGRect frame = self.frame;
    frame.size.width = 0.0;
    self.frame = frame;
    
    __weak UIView *weakSelf = self;
    
    [UIView animateWithDuration:0.4 animations:^{
        CGRect frame = weakSelf.frame;
        frame.size.width = [[UIScreen mainScreen] bounds].size.width  * 0.6;
        weakSelf.frame = frame;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            CGRect frame = weakSelf.frame;
            frame.size.width = [[UIScreen mainScreen] bounds].size.width  * 0.8;
            weakSelf.frame = frame;
        }];
    }];
}

-(void)endLoadingAnimation{
    __weak UIView *weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = weakSelf.frame;
        frame.size.width = [[UIScreen mainScreen] bounds].size.width;
        weakSelf.frame = frame;
    } completion:^(BOOL finished) {
        weakSelf.hidden = YES;
    }];
}


@end
