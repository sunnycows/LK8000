//
//  InternalPort.cpp
//  LK8000
//
//  Created by Nicola Ferruzzi on 14/09/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#include "InternalPort.hpp"
#import "LKCLHelper.h"

InternalPort::InternalPort(int idx, const tstring& sName) : NullComPort(idx, sName) {
}

InternalPort::~InternalPort() {
    sensors = nil;
}

bool InternalPort::Initialize() {
    sensors = [[InternalSensors alloc] init:GetPortIndex()];
    [[LKCLHelper sharedInstance] subscribe:sensors];
    return NullComPort::Initialize();
}

bool InternalPort::Close() {
    [[LKCLHelper sharedInstance] unsubscribe:sensors];
    return NullComPort::Close();
}

