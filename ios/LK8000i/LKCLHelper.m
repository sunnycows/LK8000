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

#define KUserDefaultsKey @"LKCLHelperStatus@"

@interface LKCLHelper () <CLLocationManagerDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) bool (^callback)(LKCLHelperStatus, CLLocation *, CMAltitudeData *);
@property (nonatomic, weak) UIAlertView *av_appspecific;
@property (nonatomic, weak) UIAlertView *av_systemdisallow;
@property (nonatomic, assign) BOOL requesting_userpermission;
@property (nonatomic, assign) BOOL iosseven;
@property (nonatomic, strong) CMAltimeter *altimeter;
@property (nonatomic, strong) CMAltitudeData *altitudeData;
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
        self.iosseven = ![self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)];
        self.manager.delegate = self;
        self.manager.desiredAccuracy = kCLLocationAccuracyBest;
        self.manager.headingFilter = 1.0f;
        self.manager.allowsBackgroundLocationUpdates = true;
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            self.status = kLKCLHelperStatus_AppSpecific_NotDetermined;
            if (self.requesting_userpermission) {
                [self showAppspecificRequest];
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
            self.status = kLKCLHelperStatus_SystemRequest_Disallow;
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
        BOOL keep = self.callback(self.status, locations.lastObject, nil);
        if (keep == NO) {
            [self stopTracking];
            self.callback = nil;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;

    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
    NSLog(@"Heading: %f", theHeading);
}


- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    self.callback = nil;
    [self stopTracking];
}

- (void)requestLocationIfPossibleWithUI:(BOOL)ui
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
    
    self.requesting_userpermission = ui;

    if (ui == NO) {
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
            case kLKCLHelperStatus_AppSpecific_NotDetermined:
            case kLKCLHelperStatus_AppSpecific_Disallow:
                // request user popup
                [self showAppspecificRequest];
                break;
                
            case kLKCLHelperStatus_SystemRequest_Disallow:
                // we need permissions from main Settings
                if (self.iosseven) {
                    block(self.status, nil, nil);
                    self.callback = nil;
                }
                [self showSystemDisallowed];
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

- (void)showAppspecificRequest {
    NSString *title = NSLocalizedString(@"Warning", @"Warning");
    NSString *msg = NSLocalizedString(@"LK8000 requires your position.", @"LK8000 requires your position to show fly informations and create IGC log files");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Do not allow", @"Do not allow")
                                          otherButtonTitles:NSLocalizedString(@"Ok", @"Ok"), nil];
    self.av_appspecific = alert;
    [alert show];
}

- (void)showSystemDisallowed {
    NSString *title = NSLocalizedString(@"Error", @"Error");
    NSString *msg = NSLocalizedString(@"LK8000 has not been not allowed to receive your position.", @"LK8000 has not been not allowed to receive your position.");
    NSMutableString *mmsg = [NSMutableString new];
    
    [mmsg appendString:msg];
    
    if (self.iosseven) {
        [mmsg appendString:NSLocalizedString(@"Per abilitare la posizione dell'utente apri Impostazioni -> Privacy -> Posizione -> attiva LK8000", @"Per abilitare la posizione dell'utente apri Impostazioni -> Privacy -> Posizione -> attiva LK8000")];
    } else {
        [mmsg appendString:NSLocalizedString(@"To enable location updates tap here.", @"To enable location updates tap here.")];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:mmsg
                                                   delegate:self.iosseven ? nil : self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                          otherButtonTitles:nil];
    self.av_systemdisallow = alert;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.av_appspecific) {
        if (buttonIndex == 1) {
            // ok
            self.status = kLKCLHelperStatus_AppSpecific_Allow;
            
            if (!self.iosseven) {
                // iOS >= 8
                [self.manager requestAlwaysAuthorization];
            } else {
                // iOS == 7
                [self startTracking];
            }
        } else  {
            // no
            self.status = kLKCLHelperStatus_AppSpecific_Disallow;
            self.callback(self.status, nil, nil);
            self.callback = nil;
        }
    }
    
    if (alertView == self.av_systemdisallow) {
        if (buttonIndex == 0) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (IBAction)startTrackingAltitude {
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return;
    }
    
    self.altimeter = [[CMAltimeter alloc] init];

    __weak typeof(self) wself = self;

    [self.altimeter startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error) {
                                                NSLog(@"%@", altitudeData.pressure);
                                                wself.altitudeData = altitudeData;
                                                if (wself.callback) {
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


@end
