//
//  CLLocation+NMEA.m
//  LK8000
//
//  Created by Nicola Ferruzzi on 29/07/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#import "CLLocation+NMEA.h"

@implementation CLLocation (NMEA)

- (NSArray *)getNMEA {
    // 10進数の緯度経度を60進数の緯度経度に変換します。
    CLLocationDegrees latitude = [self convertCLLocationDegreesToNmea:self.coordinate.latitude];
    CLLocationDegrees longitude = [self convertCLLocationDegreesToNmea:self.coordinate.longitude];

    // GPGGAレコード
    NSMutableString *nmea0183GPGGA = [[NSMutableString alloc] init];
    NSDateFormatter *nmea0183GPGGATimestampFormatter = [[NSDateFormatter alloc] init];
    [nmea0183GPGGATimestampFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [nmea0183GPGGATimestampFormatter setDateFormat:@"HHmmss.SSS"];
    [nmea0183GPGGA appendString:@"GPGGA,"];
    [nmea0183GPGGA appendFormat:@"%@,", [nmea0183GPGGATimestampFormatter stringFromDate:self.timestamp]]; // 測位時刻
    [nmea0183GPGGA appendFormat:@"%08.4f,", latitude]; // 緯度
    [nmea0183GPGGA appendFormat:@"%@,", (latitude > 0.0 ? @"N" : @"S")]; // 北緯、南緯
    [nmea0183GPGGA appendFormat:@"%08.4f,", longitude]; // 経度
    [nmea0183GPGGA appendFormat:@"%@,", (longitude > 0.0 ? @"E" : @"W")]; // 東経、西経
    [nmea0183GPGGA appendString:@"1,"]; // 位置特定品質: 単独測位
    [nmea0183GPGGA appendString:@"08,"]; // 受信衛星数: 8?
    [nmea0183GPGGA appendString:@"1.0,"]; // 水平精度低下率: 1.0?
    [nmea0183GPGGA appendFormat:@"%1.1f,", self.altitude]; // アンテナの海抜高さ
    [nmea0183GPGGA appendString:@"M,"]; // アンテナの海抜高さ単位: メートル
    [nmea0183GPGGA appendFormat:@"%1.1f,", self.altitude]; // ジオイド高さ
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
    [nmea0183GPRMC appendFormat:@"%@,", [nmea0183GPRMCTimestampFormatter stringFromDate:self.timestamp]]; // 測位時刻
    [nmea0183GPRMC appendString:@"A,"]; // ステータス: 有効
    [nmea0183GPRMC appendFormat:@"%08.4f,", latitude]; // 緯度
    [nmea0183GPRMC appendFormat:@"%@,", (latitude > 0.0 ? @"N" : @"S")]; // 北緯、南緯
    [nmea0183GPRMC appendFormat:@"%08.4f,", longitude]; // 経度
    [nmea0183GPRMC appendFormat:@"%@,", (longitude > 0.0 ? @"E" : @"W")]; // 東経、西経
    [nmea0183GPRMC appendFormat:@"%04.1f,", (self.course > 0.0 ? self.speed * 3600.0 / 1000.0 * 0.54 : 0.0)]; // 移動速度(ノット毎時)
    [nmea0183GPRMC appendFormat:@"%04.1f,", (self.course > 0.0 ? self.course : 0.0)]; // 移動方向
    [nmea0183GPRMC appendFormat:@"%@,", [nmea0183GPRMCDateFormatter stringFromDate:self.timestamp]]; // 測位日付
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

+ (NSString *)nmeaChecksum:(NSString *)sentence {
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

@end
