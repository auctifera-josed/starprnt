//
//  StarPRNT.m
//  
//
//  Created by Jose Angarita on 5/17/16.
//
//

#import "StarPRNT.h"

@implementation StarPRNT

static NSString *dataCallbackId = nil;

- (void)connect:(CDVInvokedUrlCommand *)command {
    NSString *portName = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
    }
    
    if (_starIoExtManager == nil) {
        _starIoExtManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeStandard
                                                          portName:portName
                                                      portSettings:@""
                                                   ioTimeoutMillis:10000];
        
        _starIoExtManager.delegate = self;
    }
    
    if (_starIoExtManager.port != nil) {
        [_starIoExtManager disconnect];
    }
    
    dataCallbackId = command.callbackId;
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[_starIoExtManager connect]];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:dataCallbackId];
}

- (void)portDiscovery:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *portType = @"All";
        
        if (command.arguments.count > 0) {
            portType = [command.arguments objectAtIndex:0];
        }
        
        NSMutableArray *info = [[NSMutableArray alloc] init];
        
        if ([portType isEqualToString:@"All"] || [portType isEqualToString:@"Bluetooth"]) {
            NSArray *btPortInfoArray = [SMPort searchPrinter:@"BT:"];
            for (PortInfo *p in btPortInfoArray) {
                [info addObject:[self portInfoToDictionary:p]];
            }
        }
        
        if ([portType isEqualToString:@"All"] || [portType isEqualToString:@"LAN"]) {
            NSArray *lanPortInfoArray = [SMPort searchPrinter:@"LAN:"];
            for (PortInfo *p in lanPortInfoArray) {
                [info addObject:[self portInfoToDictionary:p]];
            }
        }
        
        if ([portType isEqualToString:@"All"] || [portType isEqualToString:@"USB"]) {
            NSArray *usbPortInfoArray = [SMPort searchPrinter:@"USB:"];
            for (PortInfo *p in usbPortInfoArray) {
                [info addObject:[self portInfoToDictionary:p]];
            }
        }
        
        CDVPluginResult	*result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:info];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)printReceipt:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
        SCBAlignmentPosition alignment = SCBAlignmentPositionCenter;
        SCBInternationalType international = SCBInternationalTypeUSA;
        SCBFontStyleType fontStyle = SCBFontStyleTypeA;
        BOOL printResult = false;
        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    
        NSMutableData *commands = [NSMutableData data];
        NSString *portName = nil;
        NSString *content = nil;
        NSString *receiptid = nil;
        SMPort *port = nil;
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
        
        if (_starIoExtManager == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not connected" message:@"Please connect to the printer before printing out." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        } else if (_starIoExtManager.port == nil){
            port = [SMPort getPort:portName :@"" :10000];
        } else {
            port = [_starIoExtManager port];
        }

        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            content = [command.arguments objectAtIndex:1];
            receiptid = [command.arguments objectAtIndex:2];
            //Alignment
            NSString *align = [command.arguments objectAtIndex:3];
            NSString *intern = [command.arguments objectAtIndex:4];
            NSString *font = [command.arguments objectAtIndex:5];

            if (align != nil && align != (id)[NSNull null]){
                if ([align isEqualToString:@"left"])
                    alignment = SCBAlignmentPositionLeft;
                else if ([align isEqualToString:@"center"])
                    alignment = SCBAlignmentPositionCenter;
                else if ([align isEqualToString:@"right"])
                    alignment = SCBAlignmentPositionRight;
            }
            //international
            if (intern != nil && intern != (id)[NSNull null]){
                if ([intern isEqualToString:@"US"])
                    international = SCBInternationalTypeUSA;
                else if ([intern isEqualToString:@"FR"])
                    international = SCBInternationalTypeFrance;
                else if ([intern isEqualToString:@"UK"])
                    international = SCBInternationalTypeUK;
            }
            //font
            if (font != nil && font != (id)[NSNull null]){
                if ([font isEqualToString:@"A"])
                    fontStyle = SCBFontStyleTypeA;
                else if ([font isEqualToString:@"B"])
                    fontStyle = SCBFontStyleTypeB;
            }
        }
        
        NSData *data = [content dataUsingEncoding:encoding];

        NSError * error = nil;
        id receipt = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!receipt) { //Not JSON, printing data
            [builder beginDocument];
            [builder appendCodePage:SCBCodePageTypeCP1252];
            [builder appendInternational:international];
            [builder appendAlignment:alignment];
            [builder appendFontStyle:fontStyle];
            [builder appendData:data];
            [builder appendUnitFeed:32];
            [builder appendQrCodeDataWithAlignment:[receiptid dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelQ cell:6 position:SCBAlignmentPositionCenter];
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        
            [builder endDocument];
        }else {//getting JSON
            NSDictionary *results = receipt;

            for (id key in results){
                NSLog(@"key=%@ value=%@", key, [results objectForKey:key]);
            }
        }

        commands = [builder.commands copy];
        
        if (commands != nil && port != nil) {
            [_starIoExtManager.lock lock];
            
            printResult = [Communication sendCommands:commands port:port];
            
            [_starIoExtManager.lock unlock];
        }
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:printResult];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

//Printer events
-(void)didPrinterCoverOpen {
    [self sendData:@"printerCoverOpen" data:nil];
}

-(void)didPrinterCoverClose {
    [self sendData:@"printerCoverClose" data:nil];
}

-(void)didPrinterImpossible {
    [self sendData:@"printerImpossible" data:nil];
}

-(void)didPrinterOnline {
    [self sendData:@"printerOnline" data:nil];
}

-(void)didPrinterOffline {
    [self sendData:@"printerOffline" data:nil];
}

-(void)didPrinterPaperEmpty {
    [self sendData:@"printerPaperEmpty" data:nil];
}

-(void)didPrinterPaperNearEmpty {
    [self sendData:@"printerPaperNearEmpty" data:nil];
}

-(void)didPrinterPaperReady {
    [self sendData:@"printerPaperReady" data:nil];
}

//Utilities

- (NSMutableDictionary*)portInfoToDictionary:(PortInfo *)portInfo {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[portInfo portName] forKey:@"portName"];
    [dict setObject:[portInfo macAddress] forKey:@"macAddress"];
    [dict setObject:[portInfo modelName] forKey:@"modelName"];
    return dict;
}

- (void)sendData:(NSString *)dataType data:(NSString *)data {
    if (dataCallbackId != nil) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:dataType forKey:@"dataType"];
        if (data != nil) {
            [dict setObject:data forKey:@"data"];
        }
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:dataCallbackId];
    }
}

@end
