//
//  StarPRNT.h
//  
//
//  Created by Jose Angarita on 5/17/16.
//
//

#import <Cordova/CDVPlugin.h>
#import <Foundation/Foundation.h>
#import <StarIO/SMPort.h>
#import <StarIO_Extension/StarIoExt.h>
#import <StarIO_Extension/StarIoExtManager.h>
#import <Cordova/CDV.h>

#import "Communication.h"

@interface StarPRNT : CDVPlugin <StarIoExtManagerDelegate> {}

@property (nonatomic) StarIoExtManager *starIoExtManager;

- (void)portDiscovery:(CDVInvokedUrlCommand *)command;
- (void)printData:(CDVInvokedUrlCommand *)command;
- (void)printReceipt:(CDVInvokedUrlCommand *)command;
- (void)connect:(CDVInvokedUrlCommand *)command;

@end
