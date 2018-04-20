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

@property (nonatomic) StarIoExtManager *printerManager;

- (void)portDiscovery:(CDVInvokedUrlCommand *)command;
- (void)checkStatus:(CDVInvokedUrlCommand *)command;
- (void)printRawText:(CDVInvokedUrlCommand *)command;
- (void)printRasterReceipt:(CDVInvokedUrlCommand *)command;
- (void)printRasterData:(CDVInvokedUrlCommand *)command;
- (void)print:(CDVInvokedUrlCommand *)command;
- (void)printData:(CDVInvokedUrlCommand *)command;
- (void)printRawData:(CDVInvokedUrlCommand *)command;
- (void)printReceipt:(CDVInvokedUrlCommand *)command;
- (void)printTicket:(CDVInvokedUrlCommand *)command;
- (void)activateBlackMarkSensor:(CDVInvokedUrlCommand *)command;
- (void)cancelBlackMarkSensor:(CDVInvokedUrlCommand *)command;
- (void)setToDefaultSettings:(CDVInvokedUrlCommand *)command;
// - (void)setPrintDirection:(CDVInvokedUrlCommand *)command;Not supported in TSP700II
- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;
- (void)hardReset:(CDVInvokedUrlCommand *)command;
- (void)openCashDrawer:(CDVInvokedUrlCommand *)command;

@end
