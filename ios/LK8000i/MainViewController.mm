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
@property (weak, nonatomic) IBOutlet UIButton *buttonRUN;
@property (assign, nonatomic) BOOL running;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai;
@property (weak, nonatomic) IBOutlet UILabel *labelDec;
//@property (strong, nonatomic) InternalSensors *internalSensors;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.internalSensors = [InternalSensors new];

    __weak typeof(self) wself = self;
    _buttonRUN.enabled = false;

    static ArchiveUnzip *archive = [ArchiveUnzip new];

    id block = ^(NSError * error) {
        // Wait for decompression; LK8000 requires a proper data folders in order
        // to initialize properly
        NSLog(@"Decompression done: %@", error);
        [wself performSelectorOnMainThread:@selector(requestLocation) withObject:nil waitUntilDone:NO];
    };

    [archive performSelectorInBackground:@selector(startDecompression:) withObject:block];
}

- (void)requestLocation {
    _labelDec.text = NSLocalizedString(@"Permissions...", @"Permissions...");
    __weak typeof(self) wself = self;
    __block BOOL once = TRUE;

    [[LKCLHelper sharedInstance] requestLocationIfPossibleWithUI:YES
                                                           block:^bool(LKCLHelperStatus status, CLLocation *location, CMAltitudeData *altitude) {
                                                               if (once) {
                                                                   [wself.ai stopAnimating];
                                                                   wself.labelDec.text = NSLocalizedString(@"Ready!", @"Ready!");
                                                                   wself.buttonRUN.hidden = false;
                                                                   wself.buttonRUN.enabled = true;
                                                                   once = FALSE;
                                                               }

//                                                               if (GlobalRunning && wself.running) {
//                                                                   if (location) {
//                                                                       [wself.internalSensors sendLocation:location];
//                                                                   }
//
//                                                                   if (altitude) {
//                                                                       [wself.internalSensors sendAltitude:altitude];
//                                                                   }
//                                                               }

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

@end
