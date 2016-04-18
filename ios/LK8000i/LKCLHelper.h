//
//  LKCLHelper.h
//  LK8000i
//
//  Created by Nicola Ferruzzi on 28/08/15.
//  Copyright (c) 2016 Nicola Ferruzzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

typedef enum : NSUInteger {
    kLKCLHelperStatus_AppSpecific_NotDermined_Requesting,
    kLKCLHelperStatus_AppSpecific_NotDetermined,
    kLKCLHelperStatus_AppSpecific_Disallow,
    kLKCLHelperStatus_AppSpecific_Allow,
    kLKCLHelperStatus_SystemRequest_Requesting,
    kLKCLHelperStatus_SystemRequest_Disallow,
    kLKCLHelperStatus_SystemRequest_Allow,
} LKCLHelperStatus;

@interface LKCLHelper : NSObject

@property (nonatomic, assign) LKCLHelperStatus status;
@property (nonatomic, strong) CLLocationManager *manager;

+ (instancetype)sharedInstance;

- (void)requestLocationIfPossibleWithUI:(BOOL)ui
                                  block:(bool (^)(LKCLHelperStatus status,
                                                  CLLocation *location,
                                                  CMAltitudeData *altitude))block;

@end
