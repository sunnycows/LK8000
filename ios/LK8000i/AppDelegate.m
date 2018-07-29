//
//  AppDelegate.m
//  LK8000i
//
//  Created by Nicola Ferruzzi on 05/03/16.
//  Copyright © 2016 Nicola Ferruzzi. All rights reserved.
//
// libPNG requires: -DPNG_ARM_NEON_OPT=0

#import <Objc/runtime.h>

extern "C" {
    #include "../Pods/sdl2/include/SDL.h"
    #include "../Pods/sdl2/include/SDL_events.h"
    #include "../Pods/sdl2/src/SDL_internal.h"
    #include "../Pods/sdl2/src/events/SDL_windowevents_c.h"
    #include "../Pods/sdl2/src/events/SDL_events_c.h"
    #include "../Pods/sdl2/src/video/SDL_sysvideo.h"
}

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"
#import "ArchiveUnzip.h"
#import "LKCLHelper.h"
#import "CLLocation+NMEA.h"

#include "externs.h"
#include "Parser.h"

extern NMEA_INFO GPS_INFO;

#pragma mark 

@interface AppDelegate ()
@end

@implementation AppDelegate

static void SDLCALL
SDL_IdleTimerDisabledChanged(void *userdata, const char *name, const char *oldValue, const char *hint)
{
    BOOL disable = (hint && *hint != '0');
    [UIApplication sharedApplication].idleTimerDisabled = disable;
}

- (bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];

    SDL_AddHintCallback(SDL_HINT_IDLE_TIMER_DISABLED, SDL_IdleTimerDisabledChanged, NULL);

    UIScreen *screen = [UIScreen mainScreen];
    self.window = [[UIWindow alloc]initWithFrame:screen.bounds];
    UIViewController *uv = [[UIViewController alloc] init];
    uv.view.backgroundColor = [UIColor yellowColor];
    
    [self.window setRootViewController:uv];
    [self.window makeKeyAndVisible];

    static ArchiveUnzip *archive = [ArchiveUnzip new];
    [archive startDecompression:^(NSError *error) {
        // Wait for decompression; LK8000 requires a proper data folders in order
        // to initialize properly
        NSLog(@"Decompression done: %@", error);
        [self performSelector:@selector(requestPosition) withObject:nil];
    }];

    return YES;
}

- (void)requestPosition{
    __block BOOL canRunLK8000 = true;
    __weak typeof(self) wself = self;

    [[LKCLHelper sharedInstance] requestLocationIfPossibleWithUI:YES
                                                           block:^bool(LKCLHelperStatus status, CLLocation *location, CMAltitudeData *altitude) {
                                                               if (canRunLK8000) {
                                                                   canRunLK8000 = false;
                                                                   [wself performSelector:@selector(runLK8000) withObject:nil];
                                                               }
                                                               [self sendLocation:location altitude:altitude];
                                                               return TRUE;
                                                           }];

}

- (void)runLK8000 {
    SDL_SetMainReady();
    SDL_iPhoneSetEventPump(SDL_TRUE);
    LK8000_main(0, NULL);
    SDL_iPhoneSetEventPump(SDL_FALSE);
}

- (void)sendLocation:(CLLocation *)location altitude:(CMAltitudeData *)altitude {
    static char t[1024];
    
    if (location) {
        NSArray *nmeas = [location getNMEA];
        for (NSString *nmea in nmeas) {
            NSLog(@"%@", nmea);
            const char *ct = [nmea UTF8String];
            strcpy(t, ct);
            NMEAParser::ParseNMEAString(0, t, &GPS_INFO);
        }
    }
    
    if (altitude) {
        NSString *nmea = [CLLocation nmeaChecksum:[NSString stringWithFormat:@"PGRMZ,%.4f,f", [altitude.pressure floatValue]]];
        NSLog(@"%@", nmea);
        const char *ct = [nmea UTF8String];
        strcpy(t, ct);
        NMEAParser::ParseNMEAString(0, t, &GPS_INFO);
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    SDL_SendAppEvent(SDL_APP_TERMINATING);
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    SDL_SendAppEvent(SDL_APP_LOWMEMORY);
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation
{
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(application.statusBarOrientation);
    SDL_VideoDevice *_this = SDL_GetVideoDevice();

    if (_this && _this->num_displays > 0) {
        SDL_DisplayMode *desktopmode = &_this->displays[0].desktop_mode;
        SDL_DisplayMode *currentmode = &_this->displays[0].current_mode;

        /* The desktop display mode should be kept in sync with the screen
         * orientation so that updating a window's fullscreen state to
         * SDL_WINDOW_FULLSCREEN_DESKTOP keeps the window dimensions in the
         * correct orientation. */
        if (isLandscape != (desktopmode->w > desktopmode->h)) {
            int height = desktopmode->w;
            desktopmode->w = desktopmode->h;
            desktopmode->h = height;
        }

        /* Same deal with the current mode + SDL_GetCurrentDisplayMode. */
        if (isLandscape != (currentmode->w > currentmode->h)) {
            int height = currentmode->w;
            currentmode->w = currentmode->h;
            currentmode->h = height;
        }

        int w = (int) currentmode->w;
        int h = (int) currentmode->h;

        for (SDL_Window *window = _this->windows; window != nil; window = window->next) {
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_RESIZED, w, h);
        }
    }
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    if (_this) {
        SDL_Window *window;
        for (window = _this->windows; window != nil; window = window->next) {
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_FOCUS_LOST, 0, 0);
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
        }
    }
    SDL_SendAppEvent(SDL_APP_WILLENTERBACKGROUND);
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    SDL_SendAppEvent(SDL_APP_DIDENTERBACKGROUND);
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    SDL_SendAppEvent(SDL_APP_WILLENTERFOREGROUND);
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    SDL_SendAppEvent(SDL_APP_DIDENTERFOREGROUND);

    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    if (_this) {
        SDL_Window *window;
        for (window = _this->windows; window != nil; window = window->next) {
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_FOCUS_GAINED, 0, 0);
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_RESTORED, 0, 0);
        }
    }
}

@end

