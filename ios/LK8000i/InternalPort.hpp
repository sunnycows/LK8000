//
//  InternalPort.hpp
//  LK8000
//
//  Created by Nicola Ferruzzi on 14/09/2018.
//  Copyright © 2018 Nicola Ferruzzi. All rights reserved.
//

#ifndef InternalPort_hpp
#define InternalPort_hpp

#include <externs.h>
#include <Comm/NullComPort.h>
#import "InternalSensors.h"

class InternalPort : public NullComPort {

public:
    InternalPort(int idx, const tstring& sName);
    ~InternalPort();

    InternalPort( const InternalPort& ) = delete;
    InternalPort& operator=( const InternalPort& ) = delete;

    InternalPort( InternalPort&& ) = delete;
    InternalPort& operator=( InternalPort&& ) = delete;

    bool Initialize() override;
    bool Close() override;

private:
    InternalSensors *sensors;

};

#endif /* InternalPort_hpp */
