//
//  InternalSensors.h
//  LK8000
//
//  Created by Nicola Ferruzzi on 03/08/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class CMAltitudeData;

@interface InternalSensors : NSObject

- (void)sendLocation:(CLLocation *)location;
- (void)sendAltitude:(CMAltitudeData *)altitude;

@end
