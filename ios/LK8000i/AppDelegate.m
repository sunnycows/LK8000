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

#include "externs.h"
#include "Parser.h"

extern NMEA_INFO GPS_INFO;

#pragma mark 

@interface AppDelegate ()
@end

@implementation AppDelegate

- (NSArray *)getGeolocationWithCoreLocation:(CLLocation *)location {
    // 10進数の緯度経度を60進数の緯度経度に変換します。
    CLLocationDegrees latitude = [self convertCLLocationDegreesToNmea:location.coordinate.latitude];
    CLLocationDegrees longitude = [self convertCLLocationDegreesToNmea:location.coordinate.longitude];
    
    // GPGGAレコード
    NSMutableString *nmea0183GPGGA = [[NSMutableString alloc] init];
    NSDateFormatter *nmea0183GPGGATimestampFormatter = [[NSDateFormatter alloc] init];
    [nmea0183GPGGATimestampFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [nmea0183GPGGATimestampFormatter setDateFormat:@"HHmmss.SSS"];
    [nmea0183GPGGA appendString:@"GPGGA,"];
    [nmea0183GPGGA appendFormat:@"%@,", [nmea0183GPGGATimestampFormatter stringFromDate:location.timestamp]]; // 測位時刻
    [nmea0183GPGGA appendFormat:@"%08.4f,", latitude]; // 緯度
    [nmea0183GPGGA appendFormat:@"%@,", (latitude > 0.0 ? @"N" : @"S")]; // 北緯、南緯
    [nmea0183GPGGA appendFormat:@"%08.4f,", longitude]; // 経度
    [nmea0183GPGGA appendFormat:@"%@,", (longitude > 0.0 ? @"E" : @"W")]; // 東経、西経
    [nmea0183GPGGA appendString:@"1,"]; // 位置特定品質: 単独測位
    [nmea0183GPGGA appendString:@"08,"]; // 受信衛星数: 8?
    [nmea0183GPGGA appendString:@"1.0,"]; // 水平精度低下率: 1.0?
    [nmea0183GPGGA appendFormat:@"%1.1f,", location.altitude]; // アンテナの海抜高さ
    [nmea0183GPGGA appendString:@"M,"]; // アンテナの海抜高さ単位: メートル
    [nmea0183GPGGA appendFormat:@"%1.1f,", location.altitude]; // ジオイド高さ
    [nmea0183GPGGA appendString:@"M,"]; // ジオイド高さ: メートル
    [nmea0183GPGGA appendString:@","]; // DGPSデータの寿命: 不使用
    [nmea0183GPGGA appendString:@","]; // 差動基準地点ID: 不使用
    unichar nmea0183GPGGAChecksum = 0;
    for (NSInteger index = 0; index < nmea0183GPGGA.length; index++) {
        nmea0183GPGGAChecksum ^= [nmea0183GPGGA characterAtIndex:index];
    }
    nmea0183GPGGAChecksum &= 0x0ff;
    [nmea0183GPGGA insertString:@"$" atIndex:0];
    [nmea0183GPGGA appendString:@"*"];
    [nmea0183GPGGA appendFormat:@"%02lX\n", (long)nmea0183GPGGAChecksum]; // チェックサム
    
    // GPRMCレコード
    NSMutableString *nmea0183GPRMC = [[NSMutableString alloc] init];
    NSDateFormatter *nmea0183GPRMCTimestampFormatter = [[NSDateFormatter alloc] init];
    [nmea0183GPRMCTimestampFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [nmea0183GPRMCTimestampFormatter setDateFormat:@"HHmmss.SSS"];
    NSDateFormatter *nmea0183GPRMCDateFormatter = [[NSDateFormatter alloc] init];
    [nmea0183GPRMCDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [nmea0183GPRMCDateFormatter setDateFormat:@"ddMMyy"];
    [nmea0183GPRMC appendString:@"GPRMC,"];
    [nmea0183GPRMC appendFormat:@"%@,", [nmea0183GPRMCTimestampFormatter stringFromDate:location.timestamp]]; // 測位時刻
    [nmea0183GPRMC appendString:@"A,"]; // ステータス: 有効
    [nmea0183GPRMC appendFormat:@"%08.4f,", latitude]; // 緯度
    [nmea0183GPRMC appendFormat:@"%@,", (latitude > 0.0 ? @"N" : @"S")]; // 北緯、南緯
    [nmea0183GPRMC appendFormat:@"%08.4f,", longitude]; // 経度
    [nmea0183GPRMC appendFormat:@"%@,", (longitude > 0.0 ? @"E" : @"W")]; // 東経、西経
    [nmea0183GPRMC appendFormat:@"%04.1f,", (location.course > 0.0 ? location.speed * 3600.0 / 1000.0 * 0.54 : 0.0)]; // 移動速度(ノット毎時)
    [nmea0183GPRMC appendFormat:@"%04.1f,", (location.course > 0.0 ? location.course : 0.0)]; // 移動方向
    [nmea0183GPRMC appendFormat:@"%@,", [nmea0183GPRMCDateFormatter stringFromDate:location.timestamp]]; // 測位日付
    [nmea0183GPRMC appendString:@","]; // 地磁気の偏角: 不使用
    [nmea0183GPRMC appendString:@","]; // 地磁気の偏角の方向: 不使用
    [nmea0183GPRMC appendString:@"A"]; // モード: 単独測位
    unichar nmea0183GPRMCChecksum = 0;
    for (NSInteger index = 0; index < nmea0183GPRMC.length; index++) {
        nmea0183GPRMCChecksum ^= [nmea0183GPRMC characterAtIndex:index];
    }
    nmea0183GPRMCChecksum &= 0x0ff;
    [nmea0183GPRMC insertString:@"$" atIndex:0];
    [nmea0183GPRMC appendString:@"*"];
    [nmea0183GPRMC appendFormat:@"%02lX\n", (long)nmea0183GPRMCChecksum]; // チェックサム
    
    // カメラに位置情報を設定します。
    return @[nmea0183GPGGA, nmea0183GPRMC];
}

- (NSString *)nmeaChecksum:(NSString *)sentence {
    unichar nmea0183GPRMCChecksum = 0;
    
    for (NSInteger index = 0; index < sentence.length; index++) {
        nmea0183GPRMCChecksum ^= [sentence characterAtIndex:index];
    }
    nmea0183GPRMCChecksum &= 0x0ff;
    
    NSString *check = [NSString stringWithFormat:@"$%@*%02lX\n", sentence, (long)nmea0183GPRMCChecksum];
    return check;
}

- (double)convertCLLocationDegreesToNmea:(CLLocationDegrees)degrees {
    double degreeSign = ((degrees > 0.0) ? +1 : ((degrees < 0.0) ? -1 : 0));
    double degree = ABS(degrees);
    double degreeDecimal = floor(degree);
    double degreeFraction = degree - degreeDecimal;
    double minutes = degreeFraction * 60.0;
    double nmea = degreeSign * (degreeDecimal * 100.0 + minutes);
    return nmea;
}

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
        // to initialize properly; unfortunately SDL-iOS delegate (subclassed by this class)
        // does not provide an hook to call the "SDL main" on demand.
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
        NSArray *nmeas = [self getGeolocationWithCoreLocation:location];
        for (NSString *nmea in nmeas) {
            NSLog(@"%@", nmea);
            const char *ct = [nmea UTF8String];
            strcpy(t, ct);
            NMEAParser::ParseNMEAString(0, t, &GPS_INFO);
        }
    }
    
    if (altitude) {
        NSString *nmea = [self nmeaChecksum:[NSString stringWithFormat:@"PGRMZ,%.4f,f", [altitude.pressure floatValue]]];
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

