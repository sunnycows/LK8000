//
//  MainViewController.m
//  LK8000
//
//  Created by Nicola Ferruzzi on 29/07/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#import "MainViewController.h"
#import "LKCLHelper.h"
#import "ArchiveUnzip.h"
#import "CLLocation+NMEA.h"
#import "InternalSensors.h"

extern "C" {
#include "../Pods/sdl2/include/SDL.h"
#include "../Pods/sdl2/include/SDL_events.h"
#include "../Pods/sdl2/src/SDL_internal.h"
#include "../Pods/sdl2/src/events/SDL_windowevents_c.h"
#include "../Pods/sdl2/src/events/SDL_events_c.h"
#include "../Pods/sdl2/src/video/SDL_sysvideo.h"
}

#include "externs.h"

extern bool GlobalRunning;
extern int DeviceRegisterCount;



@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelGPSAltitude;
@property (weak, nonatomic) IBOutlet UILabel *labelRelativeAltitudeFromBARO;
@property (weak, nonatomic) IBOutlet UILabel *labelPressure;
@property (weak, nonatomic) IBOutlet UILabel *labelGPSQuality;
@property (weak, nonatomic) IBOutlet UIButton *buttonRUN;
@property (weak, nonatomic) IBOutlet UILabel *labelBAROAltitude;
@property (assign, nonatomic) double QNH;
@property (assign, nonatomic) double zeroAltitude;
@property (assign, nonatomic) double currentPressure;
@property (assign, nonatomic) double currentAltitude;
@property (assign, nonatomic) double currentRelativeAltitude;
@property (assign, nonatomic) bool setQNH;
@property (assign, nonatomic) bool sendBAROAltitude;
@property (assign, nonatomic) BOOL running;
@property (strong, nonatomic) InternalSensors *internalSensors;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.internalSensors = [InternalSensors new];
    
    __weak typeof(self) wself = self;
    _buttonRUN.enabled = false;

    static ArchiveUnzip *archive = [ArchiveUnzip new];
    [archive startDecompression:^(NSError *error) {
        // Wait for decompression; LK8000 requires a proper data folders in order
        // to initialize properly
        NSLog(@"Decompression done: %@", error);
        wself.buttonRUN.enabled = false;
        [wself requestLocation];
    }];
}

- (void)requestLocation {
    __weak typeof(self) wself = self;
    [[LKCLHelper sharedInstance] requestLocationIfPossibleWithUI:YES
                                                           block:^bool(LKCLHelperStatus status, CLLocation *location, CMAltitudeData *altitude) {
                                                               wself.buttonRUN.enabled = true;

                                                               if (location) {
                                                                   wself.currentAltitude = (double)location.altitude;
                                                                   wself.labelGPSAltitude.text = [NSString stringWithFormat:@"Current GPS altitude: %.3f meters", location.altitude];
                                                                   wself.labelGPSQuality.text = [NSString stringWithFormat:@"Vertical accuracy: %.3f meters", location.verticalAccuracy];
                                                               }

                                                               if (altitude) {
                                                                   wself.currentPressure = altitude.pressure.doubleValue*10.0;
                                                                   wself.currentRelativeAltitude = altitude.relativeAltitude.doubleValue;
                                                                   wself.labelPressure.text = [NSString stringWithFormat:@"Current pressure: %.3f hPa", wself.currentPressure];
                                                                   wself.labelRelativeAltitudeFromBARO.text = [NSString stringWithFormat:@"Relative BARO altitude: %.3f meters", altitude.relativeAltitude.doubleValue];

                                                                   if (wself.sendBAROAltitude) {
                                                                       double alt = wself.zeroAltitude + altitude.relativeAltitude.doubleValue;
                                                                       wself.labelBAROAltitude.text = [NSString stringWithFormat:@"BARO altitude: %.3f", alt];
                                                                   }
                                                               }

                                                               if (GlobalRunning && wself.running) {
                                                                   if (location) {
                                                                       [wself.internalSensors sendLocation:location];
                                                                   }

                                                                   if (altitude) {
                                                                       [wself.internalSensors sendAltitude:altitude];
                                                                   }
                                                               }

                                                               return TRUE;
                                                           }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onRunLK8000:(id)sender {
    _running = TRUE;
    SDL_SetMainReady();
    SDL_iPhoneSetEventPump(SDL_TRUE);
    LK8000_main(0, NULL);
    SDL_iPhoneSetEventPump(SDL_FALSE);
    _running = FALSE;
    GlobalRunning = FALSE;
    DeviceRegisterCount = 0;
}

- (IBAction)onGPSPermissions:(id)sender {
}

- (IBAction)onSetQNH:(id)sender {
    _QNH = _currentPressure;
    _zeroAltitude = _currentAltitude + _currentRelativeAltitude;
    _setQNH = TRUE;
    _sendBAROAltitude = TRUE;

    NSString *msg = [NSString stringWithFormat:@"Relative pressure: %.3f kPa associated to GPS height: %.3f", _QNH, _zeroAltitude];
    UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"Settings" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [ctrl addAction:action];

    [self presentViewController:ctrl animated:TRUE completion:nil];
}

@end
