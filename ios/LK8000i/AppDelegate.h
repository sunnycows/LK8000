//
//  AppDelegate.h
//  LK8000i
//
//  Created by Nicola Ferruzzi on 05/03/16.
//  Copyright © 2016 Nicola Ferruzzi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;

+ (int)convertToNativeSize:(int)value;

@end



