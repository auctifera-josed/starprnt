//
//  Port.h
//  StarIOPort
//
//  Created by Mac Build PC on 12/02/24.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SMPort.h"

@interface Port : SMPort {

}
+ (Port *)getPort:(NSString *)portName :(NSString *)portSettings :(u_int32_t)ioTimeoutMillis;
@end
