//
//  LKCLHelper.m
//  LK8000i
//
//  Created by Nicola Ferruzzi on 28/08/15.
//  Copyright (c) 2016 Nicola Ferruzzi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LKCLHelper.h"

#define KUserDefaultsKey @"LKCLHelperStatus@"

@interface LKCLHelper () <CLLocationManagerDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) BOOL (^callback)(LKCLHelperStatus, CLLocation *);
@property (nonatomic, weak) UIAlertView *av_appspecific;
@property (nonatomic, weak) UIAlertView *av_systemdisallow;
@property (nonatomic, assign) BOOL requesting_userpermission;
@property (nonatomic, assign) BOOL iosseven;
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
        
/*
        NSNumber *us = [[NSUserDefaults standardUserDefaults] objectForKey:KUserDefaultsKey];
        if (us != nil) {
            NNCLHelperStatus uss = (NNCLHelperStatus)[us unsignedIntegerValue];
            if (uss == kNNCLHelperStatus_AppSpecific_Disallow) {
                self.status = kNNCLHelperStatus_AppSpecific_Disallow;
            }
        }
 */
        
        self.manager = [[CLLocationManager alloc] init];
        self.iosseven = ![self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)];
        self.manager.delegate = self;
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
                [self.manager startUpdatingLocation];
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
        self.callback(self.status, nil);
        self.callback = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.callback) {
        BOOL keep = self.callback(self.status, locations.lastObject);
        if (keep == NO) {
            [self.manager stopUpdatingLocation];
            self.callback = nil;
        }
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    self.callback = nil;
    [self.manager stopUpdatingLocation];
}

- (void)requestLocationIfPossibleWithUI:(BOOL)ui
                                  block:(BOOL (^)(LKCLHelperStatus status, CLLocation *location))block {

    //NSAssert(self.callback == nil, @"Can't register 2 callbacks");
    //NSAssert(self.status != kLKCLHelperStatus_Location, @"Already updating location");
    
    // Doouble tap filter
    if (self.callback) {
        self.callback(self.status, nil);
        self.callback = nil;
    }
    
    self.requesting_userpermission = ui;

    if (ui == NO) {
        switch (self.status) {
            case kLKCLHelperStatus_AppSpecific_NotDermined_Requesting:
            case kLKCLHelperStatus_AppSpecific_NotDetermined:
            case kLKCLHelperStatus_AppSpecific_Disallow:
            case kLKCLHelperStatus_SystemRequest_Disallow:
                block(self.status, nil);
                return;
                break;
                
            default:
                self.callback = block;
                break;
        }
        
        if (self.status == kLKCLHelperStatus_SystemRequest_Allow) {
            [self.manager startUpdatingLocation];
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
                    block(self.status, nil);
                    self.callback = nil;
                }
                [self showSystemDisallowed];
                return;
                break;
                
            default:
                break;
        }
        
        if (self.status == kLKCLHelperStatus_SystemRequest_Allow) {
            [self.manager startUpdatingLocation];
        }
    }
    
    return;
}

- (void)showAppspecificRequest {
    NSString *title = NSLocalizedString(@"Attenzione", @"Attenzione");
    NSString *msg = NSLocalizedString(@"LK8000 vorrebbe accedere alla tua posizione.", @"LK8000 vorrebbe accedere alla tua posizione.");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Non permettere", @"Non permettere")
                                          otherButtonTitles:NSLocalizedString(@"Prosegui", @"Prosegui"), nil];
    self.av_appspecific = alert;
    [alert show];
}

- (void)showSystemDisallowed {
    NSString *title = NSLocalizedString(@"Attenzione", @"Attenzione");
    NSString *msg = NSLocalizedString(@"LK8000 non ha accesso alla tua posizione.", @"LK8000 non ha accesso alla tua posizione.");
    NSMutableString *mmsg = [NSMutableString new];
    
    [mmsg appendString:msg];
    
    if (self.iosseven) {
        [mmsg appendString:NSLocalizedString(@"Per abilitare la posizione dell'utente apri Impostazioni -> Privacy -> Posizione -> attiva LK8000", @"Per abilitare la posizione dell'utente apri Impostazioni -> Privacy -> Posizione -> attiva LK8000")];
    } else {
        [mmsg appendString:NSLocalizedString(@"Per abilitarla prosegui.", @"Per abilitarla prosegui.")];
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
                [self.manager requestWhenInUseAuthorization];
            } else {
                // iOS == 7
                [self.manager startUpdatingLocation];
            }
        } else  {
            // no
            self.status = kLKCLHelperStatus_AppSpecific_Disallow;
            self.callback(self.status, nil);
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


@end
