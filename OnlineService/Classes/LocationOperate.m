//
//  LocationOperate.m
//  HuaXiApp
//
//  Created by hedy on 2018/7/17.
//  Copyright © 2018年 liubao. All rights reserved.
//

#import "LocationOperate.h"
#import <CoreLocation/CoreLocation.h>
#import "JZLocationConverter.h"

@interface LocationOperate()<CLLocationManagerDelegate>

@property (nonatomic ,assign) double currlatitude; /**< 当前的经度*/
@property (nonatomic ,assign) double currlontitude; /**< 当前的纬度*/

@end

@implementation LocationOperate
{
    CLLocationManager *locationmanager;//定位服务
    NSString *currentCity;//当前城市
    NSString *strlatitude;//经度
    NSString *strlongitude;//纬度
}

- (void)stopUpdatingLocation {
    [locationmanager stopUpdatingLocation];
}

- (void)unInstallLocation {
    locationmanager.delegate = nil;
}

- (void)startLocation:(UIViewController *)vc {
    if ([CLLocationManager locationServicesEnabled]) {
        //定位功能可用
        locationmanager = [[CLLocationManager alloc]init];
        locationmanager.delegate = self;
        [locationmanager requestAlwaysAuthorization];
        [locationmanager requestWhenInUseAuthorization];
        currentCity = [NSString new];
        
        //设置寻址精度
        locationmanager.desiredAccuracy = kCLLocationAccuracyBest;
        locationmanager.activityType = CLActivityTypeFitness;//设置定位数据的用途
        locationmanager.distanceFilter = 20.0;
        [locationmanager startUpdatingLocation];
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        //定位不能用
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
        
        [vc presentViewController:alertVC animated:YES completion:nil];
    }
}

#pragma mark - CLLocationManagerDelegate
//定位失败后调用此代理方法
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFailWithError:)] ) {
        [self.delegate didFailWithError:error];
    }
}

#pragma mark 定位成功后则执行此代理方法
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    //[locationmanager stopUpdatingHeading];
    //旧址
    CLLocation *currentLocation = [locations lastObject];
    CLGeocoder *geoCoder = [[CLGeocoder alloc]init];
    
    //保存当前的地理位置信息
    self.currlatitude = currentLocation.coordinate.latitude;
    self.currlontitude = currentLocation.coordinate.longitude;
    
    //转成百度坐标返回回去
    CLLocationCoordinate2D relLoc = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    CLLocationCoordinate2D bdLoc = [JZLocationConverter wgs84ToBd09:relLoc];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationDidUpdateWithLatitude:longitude:)]) {
        [self.delegate locationDidUpdateWithLatitude:bdLoc.latitude longitude:bdLoc.longitude];
    }
    //反地理编码
    [geoCoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            CLPlacemark *placeMark = placemarks[0];
            self->currentCity = placeMark.locality;
            if (!self->currentCity) {
                self->currentCity = @"无法定位当前城市";
            }
        }
    }];
}

- (void)navigationWithEndLocation:(NSArray *)endLocation vc:(UIViewController *)vc;
{
    NSMutableArray *maps = [NSMutableArray array];
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //网页返回的就是百度的坐标
    //原始坐标
    CLLocationCoordinate2D oriCurrLoc = CLLocationCoordinate2DMake(self.currlatitude, self.currlontitude);
    CLLocationCoordinate2D oriEndLoc = CLLocationCoordinate2DMake([endLocation[1] doubleValue], [endLocation[0] doubleValue]);
    
    //高德坐标
    CLLocationCoordinate2D gdCurPt = [JZLocationConverter bd09ToGcj02:oriCurrLoc];
    CLLocationCoordinate2D gdEndPt = [JZLocationConverter bd09ToGcj02:oriEndLoc];
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin=latlng:%lf,%lf|name:%@&destination=latlng:%lf,%lf|name:%@&mode=driving",oriCurrLoc.latitude,oriCurrLoc.longitude,@"我的位置",oriEndLoc.latitude,oriEndLoc.longitude,endLocation[2]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        //跳转路径规划
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://path?sourceApplication=益理财&sid=BGVIS1&slat=%f&slon=%f&sname=我的位置&did=BGVIS2&dlat=%lf&dlon=%lf&dname=%@&dev=0&m=0&t=0",gdCurPt.latitude,gdCurPt.longitude,gdEndPt.latitude,gdEndPt.longitude,endLocation[2]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    //地图选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSInteger index = maps.count;
    for (int i = 0; i < index; i++) {
        NSString * title = maps[i][@"title"];
        //苹果原生地图方法
        if (i == 0) {
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                NSArray *arr = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%lf",gdEndPt.latitude],[NSString stringWithFormat:@"%lf",gdEndPt.longitude],endLocation[2],nil];
                [self navAppleMapnavAppleMapWithArray:arr];
            }];
            [alert addAction:action];
            continue;
        }
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        [alert addAction:action];
    }
    UIAlertAction * action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:action];
    [vc presentViewController:alert animated:YES completion:nil];
}

//苹果地图
- (void)navAppleMapnavAppleMapWithArray:(NSArray*) array
{
    double lat = [[NSString stringWithFormat:@"%@", array[0]] doubleValue];
    double lon = [[NSString stringWithFormat:@"%@", array[1]] doubleValue];
    NSString *name = array.count > 2 ? array[2]:@"";
    //终点坐标
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(lat, lon);
    //用户位置
    MKMapItem *currentLoc = [MKMapItem mapItemForCurrentLocation];
    //终点位置
    MKMapItem *toLocation = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithCoordinate:loc addressDictionary:nil] ];
    NSArray *items = @[currentLoc,toLocation];
    toLocation.name = name;
    
    NSDictionary *dic = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,       MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),MKLaunchOptionsShowsTrafficKey : @(YES)};
    [MKMapItem openMapsWithItems:items launchOptions:dic];
}



@end
