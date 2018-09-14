//
//  InternalSensors.mm
//  LK8000
//
//  Created by Nicola Ferruzzi on 03/08/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//
//  Based on InternalSensors for Android

#import "InternalSensors.h"
#import "LKCLHelper.h"
#import "CLLocation+NMEA.h"

#include "externs.h"
#include "Parser.h"
#include "device.h"
#include "Math/SelfTimingKalmanFilter1d.hpp"
#include "Baro.h"

extern bool UpdateBaroSource(NMEA_INFO* pGPS, const short parserid, const PDeviceDescriptor_t d, const double fAlt);
extern DeviceDescriptor_t *pDevPrimaryBaroSource;

static BOOL IsBaroSource(PDeviceDescriptor_t d) {
    return TRUE;
}

const float KF_PRESSURE_SENSOR_NOISE_VARIANCE_FALLBACK = 0.05f;

@implementation InternalSensors

- (id)init:(size_t)index {
    self = [super init];
    if (self) {
        self.index = index;
    }
    return self;
}

- (int)approximatedNumberOfSatellites:(CLLocation *)location {
    // Warning: there is no scientific calculation behind this approximation!
    // This is just what *I* do feel like plausible; the better accuracy the more satellites
    int satellites = 0;

    if (location.verticalAccuracy < 300.0) {
        satellites += 1;
    }

    if (location.verticalAccuracy < 100.0) {
        satellites += 1;
    }

    if (location.verticalAccuracy < 50.0) {
        satellites += 1;
    }

    if (location.verticalAccuracy < 10.0) {
        satellites += 1;
    }

    if (location.verticalAccuracy < 5.0) {
        satellites += 1;
    }

    if (location.horizontalAccuracy < 200.0) {
        satellites += 1;
    }

    if (location.horizontalAccuracy < 60.0) {
        satellites += 1;
    }

    if (location.horizontalAccuracy < 30.0) {
        satellites += 1;
    }

    if (location.horizontalAccuracy < 10.0) {
        satellites += 1;
    }

    return satellites;
}

- (void)sendLocation:(CLLocation *)location {

    PDeviceDescriptor_t pdev = devX(_index);

    if (pdev) {
        pdev->nmeaParser.connected = true;
        pdev->nmeaParser.expire = false;
        pdev->nmeaParser.gpsValid = true;
        pdev->HB = LKHearthBeats;
        GPS_INFO.NAVWarning = false;
    }

    if(pdev && pdev->nmeaParser.activeGPS) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:location.timestamp];

        GPS_INFO.Time = components.hour * 3600 + components.minute * 60 + components.second;
        GPS_INFO.Year = (int)components.year;
        GPS_INFO.Month = (int)components.month;
        GPS_INFO.Day = (int)components.day;
        GPS_INFO.Hour = (int)components.hour;
        GPS_INFO.Minute = (int)components.minute;
        GPS_INFO.Second = (int)components.second;

        static int startday = -1;
        GPS_INFO.Time = TimeModify(&GPS_INFO, startday);
        GPS_INFO.Latitude = location.coordinate.latitude;
        GPS_INFO.Longitude = location.coordinate.longitude;
        int satellites = [self approximatedNumberOfSatellites:location];
        GPS_INFO.SatellitesUsed = (satellites > 0) ? satellites : -1;
        GPS_INFO.Altitude = location.altitude;
        GPS_INFO.TrackBearing = location.course;
        GPS_INFO.Speed = location.speed;

//            if (UseGeoidSeparation) {
//                double GeoidSeparation = LookupGeoidSeparation(GPS_INFO.Latitude, GPS_INFO.Longitude);
//                GPS_INFO.Altitude -= GeoidSeparation;
//            }

        TriggerGPSUpdate();
    }
}

- (void)sendAltitude:(CMAltitudeData *)altitude {
    static constexpr double KF_VAR_ACCEL(0.0075);
    static constexpr double KF_MAX_DT(60);
    static SelfTimingKalmanFilter1d kalman_filter(KF_MAX_DT, KF_VAR_ACCEL);

    PDeviceDescriptor_t pdev = devX(_index);

    if (pdev) {
        pdev->nmeaParser.connected = true;
        pdev->HB = LKHearthBeats;
        pdev->IsBaroSource = &IsBaroSource;

        double abs_pressure = altitude.pressure.doubleValue * 10.0;
        kalman_filter.Update(abs_pressure, KF_PRESSURE_SENSOR_NOISE_VARIANCE_FALLBACK);
        double filtered_pressure = kalman_filter.GetXAbs();
        double altitude = StaticPressureToQNHAltitude(filtered_pressure * 100.0);
        UpdateBaroSource(&GPS_INFO, 0, pdev, altitude);
    }
}

@end
