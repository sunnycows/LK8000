//
//  LKCLHelper.m
//  LK8000i
//
//  Created by Nicola Ferruzzi on 28/08/15.
//  Copyright (c) 2016 Nicola Ferruzzi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "LKCLHelper.h"
#import "InternalSensors.h"

#define KUserDefaultsKey @"LKCLHelperStatus@"

@interface LKCLHelper () <CLLocationManagerDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) bool (^callback)(LKCLHelperStatus, CLLocation *, CMAltitudeData *);
@property (nonatomic, assign) BOOL requesting_userpermission;
@property (nonatomic, strong) CMAltimeter *altimeter;
@property (nonatomic, strong) CMAltitudeData *altitudeData;
@property (nonatomic, strong) NSMutableSet *subscribers;
@property (nonatomic, weak) UIViewController *parentVC;
@end

@implementation LKCLHelper

+ (instancetype)sharedInstance {
    static LKCLHelper *helper;
    if (!helper) {
        helper = [LKCLHelper new];
    }
    return helper;
}

- (id)init {
    self = [super init];
    if (self) {
        self.status = kLKCLHelperStatus_AppSpecific_NotDermined_Requesting;

        self.manager = [[CLLocationManager alloc] init];
        self.manager.delegate = self;
        self.manager.desiredAccuracy = kCLLocationAccuracyBest;
        self.manager.headingFilter = 1.0f;
        self.manager.allowsBackgroundLocationUpdates = true;
        self.subscribers = [NSMutableSet new];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            self.status = kLKCLHelperStatus_AppSpecific_NotDetermined;
            if (self.requesting_userpermission) {
                self.status = kLKCLHelperStatus_AppSpecific_Allow;
                [self.manager requestAlwaysAuthorization];
                return;
            }
            break;

        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.status = kLKCLHelperStatus_SystemRequest_Allow;
            if (self.callback) {
                [self startTracking];
            }
            return;
            break;

        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        if (self.status != kLKCLHelperStatus_AppSpecific_Disallow) {
            [self askForLocationInApp:NO];
        }
            break;
            
        default:
            NSAssert(0, @"Unknown condition");
            break;
    }
    
    if (self.callback) {
        self.callback(self.status, nil, nil);
        self.callback = nil;
    }
}

- (void)startTracking {
    [self.manager startUpdatingLocation];
    if ([CLLocationManager headingAvailable])
        [self.manager startUpdatingHeading];
    [self startTrackingAltitude];
}

- (void)stopTracking {
    [self.manager stopUpdatingLocation];
    if ([CLLocationManager headingAvailable])
        [self.manager stopUpdatingHeading];
    [self stopTrackingAltitude];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.callback) {
        for (InternalSensors *sensor in _subscribers) {
            [sensor sendLocation:locations.lastObject];
        }
        BOOL keep = self.callback(self.status, locations.lastObject, nil);
        if (keep == NO) {
            [self stopTracking];
            self.callback = nil;
        }
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    self.callback = nil;
    [self stopTracking];
}

- (void)requestLocationIfPossibleWithParent:(UIViewController *)parentVC
                                  block:(bool (^)(LKCLHelperStatus status,
                                                  CLLocation *location,
                                                  CMAltitudeData *data))block {

    //NSAssert(self.callback == nil, @"Can't register 2 callbacks");
    //NSAssert(self.status != kLKCLHelperStatus_Location, @"Already updating location");
    
    // Doouble tap filter
    if (self.callback) {
        self.callback(self.status, nil, nil);
        self.callback = nil;
    }
    
    self.requesting_userpermission = (parentVC != nil);
    self.parentVC = parentVC;

    if (!parentVC) {
        switch (self.status) {
            case kLKCLHelperStatus_AppSpecific_NotDermined_Requesting:
            case kLKCLHelperStatus_AppSpecific_NotDetermined:
            case kLKCLHelperStatus_AppSpecific_Disallow:
            case kLKCLHelperStatus_SystemRequest_Disallow:
                block(self.status, nil, nil);
                return;
                break;
                
            default:
                self.callback = block;
                break;
        }
        
        if (self.status == kLKCLHelperStatus_SystemRequest_Allow) {
            [self startTracking];
        }
    } else {
        self.callback = block;
        
        switch (self.status) {
            case kLKCLHelperStatus_AppSpecific_Disallow:
                // request user popup
                [self askForLocationInApp:YES];
                break;
                
            case kLKCLHelperStatus_SystemRequest_Disallow:
                [self askForLocationInApp:NO];
                return;
                break;
                
            default:
                break;
        }
        
        if (self.status == kLKCLHelperStatus_SystemRequest_Allow) {
            [self startTracking];
        }
    }
    
    return;
}

- (void)askForLocationInApp:(BOOL)possibleInApp {
    NSString *message = possibleInApp ? NSLocalizedString(@"LK8000 requires your position to show fly informations and create IGC log files", "") : NSLocalizedString(@"LK8000 has not been not allowed to receive your position. To enable location updates tap here.", "");

    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"LK8000 requires your position.", "") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", "") style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        if (possibleInApp) {
            self.status = kLKCLHelperStatus_AppSpecific_Disallow;
            self.callback(self.status, nil, nil);
            self.callback = nil;
        } else {
            self.status = kLKCLHelperStatus_SystemRequest_Disallow;
        }
    }]];

    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Allow", "") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if (possibleInApp) {
            self.status = kLKCLHelperStatus_AppSpecific_Allow;
            [self.manager requestAlwaysAuthorization];
        } else {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
        }
    }]];

    [self.parentVC presentViewController:alertVC animated:YES completion:nil];
}

- (IBAction)startTrackingAltitude {
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return;
    }
    
    self.altimeter = [CMAltimeter new];

    __weak typeof(self) wself = self;

    [self.altimeter startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error) {
                                                wself.altitudeData = altitudeData;
                                                if (wself.callback) {
                                                    for (InternalSensors *sensor in wself.subscribers) {
                                                        [sensor sendAltitude:altitudeData];
                                                    }

                                                    bool keep = wself.callback(wself.status, nil, altitudeData);

                                                    if (keep == NO) {
                                                        [wself stopTracking];
                                                        wself.callback = nil;
                                                    }
                                                }
    }];
}

- (void)stopTrackingAltitude {
    [self.altimeter stopRelativeAltitudeUpdates];
}

- (void)subscribe:(InternalSensors *)sensors {
    [self.subscribers addObject:sensors];
}

- (void)unsubscribe:(InternalSensors *)sensors {
    [self.subscribers removeObject:sensors];
}


@end
