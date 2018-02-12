//
//  GlobalQueueManager.m
//  ObjectiveC SDK
//
//  Created by u3237 on 2017/06/23.
//  Copyright © 2017 Star Micronics. All rights reserved.
//

#import "GlobalQueueManager.h"

@implementation GlobalQueueManager

static GlobalQueueManager *sharedInstance = nil;

+ (GlobalQueueManager *)sharedManager {
    if (sharedInstance == nil) {
        sharedInstance = [[GlobalQueueManager alloc] init2];
    }
    
    return sharedInstance;
}

- (instancetype)init2 {
    self = [super init];
    if (self != nil) {
        _serialQueue = dispatch_queue_create("objc-sdk", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    
    return self;
}

@end
