//
//  CLLocation+NMEA.h
//  LK8000
//
//  Created by Nicola Ferruzzi on 29/07/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (NMEA)

+ (NSString *)nmeaChecksum:(NSString *)sentence;
- (NSArray *)getNMEA;

@end
