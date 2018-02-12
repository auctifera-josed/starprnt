//
//  GlobalQueueManager.h
//  ObjectiveC SDK
//
//  Created by u3237 on 2017/06/23.
//  Copyright © 2017 Star Micronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalQueueManager : NSObject

+ (nonnull GlobalQueueManager *)sharedManager;

- (nonnull instancetype)init __attribute__((unavailable("init not available, call sharedManager instead")));

- (nonnull instancetype)copy __attribute__((unavailable("copy not available, call sharedManager instead")));

+ (nonnull instancetype)new NS_UNAVAILABLE;

@property(strong, readonly) dispatch_queue_t _Nonnull serialQueue;

@end
