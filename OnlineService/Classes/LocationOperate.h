//
//  LocationOperate.h
//  HuaXiApp
//
//  Created by hedy on 2018/7/17.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol LocationOperateDelegate<NSObject>

@required
-(void)didFailWithError:(NSError *)error;
-(void)locationDidUpdateWithLatitude:(double)latitude longitude:(double)longitude;

@end

@interface LocationOperate : NSObject

@property (nonatomic ,assign) id<LocationOperateDelegate>delegate;

- (void)startLocation:(UIViewController *)vc;//开始定位
- (void)stopUpdatingLocation; //停止定位
- (void)unInstallLocation; //移除设置
- (void)navigationWithEndLocation:(NSArray *)endLocation vc:(UIViewController *)vc; //导航

@end
