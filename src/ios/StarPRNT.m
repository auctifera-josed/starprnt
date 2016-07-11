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

- (void)printData:(CDVInvokedUrlCommand *)command {
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
            alignment = [self getAlignment:[command.arguments objectAtIndex:3]];
            international = [self getInternational:[command.arguments objectAtIndex:4]];
            fontStyle = [self getFont:[command.arguments objectAtIndex:5]];
        }
        
        [builder beginDocument];
        [builder appendCodePage:SCBCodePageTypeCP1252];
        [builder appendInternational:international];
        [builder appendAlignment:alignment];
        [builder appendFontStyle:fontStyle];
        [builder appendData:[content dataUsingEncoding:encoding]];
        [builder appendUnitFeed:32];
        if (receiptid != nil && receiptid != (id)[NSNull null])
            [builder appendQrCodeDataWithAlignment:[receiptid dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelQ cell:6 position:SCBAlignmentPositionCenter];
        [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        [builder endDocument];

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

- (void)printReceipt:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
        BOOL printResult = false;
        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    
        NSMutableData *commands = [NSMutableData data];
        NSString *portName = nil;
        NSString *content = nil;
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
        }
        
        // NSError * error = nil;
        id receipt = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:encoding] options:0 error:nil];
        if (receipt) { //JSON
            unsigned char setHorizontalTab[] = {0x1b, 0x44, 0x7, 0x29, 0x00};
            unsigned char twoTabs[] = {0x09, 0x09};
            
            NSDictionary    *main = receipt,
                            *header = main[@"header"],
                            *body = main[@"body"],
                            *footer = main[@"footer"],
                            *notice = footer[@"notice"];
            NSString    *company_name = header[@"company_name"],
                        *company_street = header[@"company_street"],
                        *company_country = header[@"company_country"],
                        *seller = header[@"seller"],
                        *date = header[@"date"],
                        *time = header[@"time"],
                        *phone = footer[@"phone"],
                        *fax = footer[@"fax"],
                        *email = footer[@"email"],
                        *transaction_id = main[@"transaction_id"];
            int     descriptionMaxSize = 30;
            
            [builder beginDocument];
            [builder appendCodePage:SCBCodePageTypeCP1252];
            [builder appendInternational:[self getInternational:main[@"international"]]];
            [builder appendAlignment:[self getAlignment:header[@"alignment"]]];
            [builder appendFontStyle:[self getFont:main[@"font"]]];
            //Start header
            if (company_name != nil && company_name != (id)[NSNull null]){
                [builder appendDataWithMultiple:[company_name dataUsingEncoding:encoding] width:2 height:2];
                [builder appendLineFeed:1];
            }
            if (company_street != nil && company_street != (id)[NSNull null]){
                [builder appendData:[company_street dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            if (company_country != nil && company_country != (id)[NSNull null]){
                [builder appendData:[company_country dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            [builder appendLineFeed:1];
            if (seller != nil && seller != (id)[NSNull null]){
                [builder appendData:[seller dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            [builder appendAlignment:SCBAlignmentPositionLeft];
            if (date != nil && date != (id)[NSNull null]){
                [builder appendData:[date dataUsingEncoding:encoding]];
                if (time != nil && time != (id)[NSNull null]){
                    [builder appendData:[@"                                 " dataUsingEncoding:encoding]];
                    [builder appendData:[time dataUsingEncoding:encoding]];
                    [builder appendLineFeed:1];
                }
            }
            if ([header[@"divider"] intValue] == 1){
                [builder appendData:[@"------------------------------------------------" dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            //Start body
            [builder appendBytes:setHorizontalTab length:sizeof(setHorizontalTab)];
            [builder appendData:[@"Qty." dataUsingEncoding:encoding]];
            [builder appendByte:0x09];
            [builder appendData:[@"Description" dataUsingEncoding:encoding]];
            [builder appendByte:0x09];
            [builder appendData:[@"Amount" dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
             
            for (NSDictionary *product in (NSArray *) body[@"product_list"]){
                if (product[@"quantity"] != nil && product[@"quantity"] != (id)[NSNull null] && product[@"description"] != nil && product[@"description"] != (id)[NSNull null] && product[@"amount"] != nil && product[@"amount"] != (id)[NSNull null]){
                    [builder appendData:[[NSString stringWithFormat:@"%@", product[@"quantity"]]  dataUsingEncoding:encoding]];
                    //dividing description in substrings to write in multiple lines
                    NSString *description = product[@"description"];
                    NSUInteger descLength = [description length];
                    // NSMutableArray *descriptionAsList = [[NSMutableArray alloc] init];
                    if (descLength > descriptionMaxSize){
                        int cont = 1,
                        location = 0;
                        do {
                            [builder appendByte:0x09];
                            [builder appendData:[[description substringWithRange:NSMakeRange(location, descriptionMaxSize)] dataUsingEncoding:encoding]];
                            if (cont == 1){
                                [builder appendByte:0x09];
                                [builder appendData:[[NSString stringWithFormat:@"%@", product[@"amount"]] dataUsingEncoding:encoding]];
                            }
                            [builder appendLineFeed:1];
                            cont++;
                            location += descriptionMaxSize;
                        } while (cont <= descLength / descriptionMaxSize);
                        if (descLength % descriptionMaxSize != 0){
                            [builder appendByte:0x09];
                            [builder appendData:[[description substringFromIndex:location] dataUsingEncoding:encoding]]; 
                        }
                    } else {
                        [builder appendByte:0x09];
                        [builder appendData:[description dataUsingEncoding:encoding]];
                        [builder appendByte:0x09];
                        [builder appendData:[[NSString stringWithFormat:@"%@", product[@"amount"]] dataUsingEncoding:encoding]];  
                    }
                    [builder appendLineFeed:1];
                }
            }
            [builder appendLineFeed:1];
            [builder appendData:[@"Subtotal" dataUsingEncoding:encoding]];
            [builder appendBytes:twoTabs length:sizeof(twoTabs)];
            [builder appendData:[body[@"subtotal"] dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
            [builder appendData:[@"Tax" dataUsingEncoding:encoding]];
            [builder appendBytes:twoTabs length:sizeof(twoTabs)];
            [builder appendData:[body[@"tax"] dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
            [builder appendData:[@"Total" dataUsingEncoding:encoding]];
            unsigned char setHorizontalTab2[] = {0x1b, 0x44, 0x7, 0x22, 0x00};
            [builder appendBytes:setHorizontalTab2 length:sizeof(setHorizontalTab2)];
            [builder appendBytes:twoTabs length:sizeof(twoTabs)];
            [builder appendDataWithMultiple:[body[@"total"] dataUsingEncoding:encoding] width:2 height:2];
            [builder appendLineFeed:1];
            if ([body[@"divider"] intValue] == 1){
                [builder appendData:[@"------------------------------------------------" dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            [builder appendAlignment:[self getAlignment:footer[@"alignment"]]];
            [builder appendUnitFeed:32];
            //Start footer
            if (phone != nil && phone != (id)[NSNull null]){
                [builder appendData:[@"Tel. " dataUsingEncoding:encoding]];
                [builder appendData:[phone dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            if (fax != nil && fax != (id)[NSNull null]){
                [builder appendData:[@"Fax. " dataUsingEncoding:encoding]];
                [builder appendData:[fax dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            if (email != nil && email != (id)[NSNull null]){
                [builder appendData:[@"Email. " dataUsingEncoding:encoding]];
                [builder appendData:[email dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
            }
            [builder appendLineFeed:1];
            if (notice != nil && notice != (id)[NSNull null]){
                if ([notice[@"invert"] intValue] == 1)     
                    [builder appendDataWithInvert:[notice[@"title"] dataUsingEncoding:encoding]];
                else
                    [builder appendData:[notice[@"title"] dataUsingEncoding:encoding]];
                [builder appendLineFeed:1];
                [builder appendData:[notice[@"text"] dataUsingEncoding:encoding]];
            }
            [builder appendLineFeed:2];
            if (transaction_id != nil && transaction_id != (id)[NSNull null]){
                NSLog(@"transaction_id: %@", transaction_id);
                if ([main[@"barcode"] intValue] == 1)
                    [builder appendBarcodeDataWithAlignment:[transaction_id dataUsingEncoding:encoding] symbology:SCBBarcodeSymbologyCode39 width:SCBBarcodeWidthMode1 height:40 hri:YES position:SCBAlignmentPositionCenter];
                else
                    [builder appendData:[transaction_id dataUsingEncoding:encoding]];
            }
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
            [builder endDocument];
        } else {
            [builder beginDocument];
            [builder appendData:[@"The given string isn't formatted correctly (JSON)" dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
            [builder endDocument];
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

- (SCBAlignmentPosition)getAlignment:(NSString *)alignment {
    if (alignment != nil && alignment != (id)[NSNull null]){
        if ([alignment isEqualToString:@"left"])
            return SCBAlignmentPositionLeft;
        else if ([alignment isEqualToString:@"center"])
            return SCBAlignmentPositionCenter;
        else if ([alignment isEqualToString:@"right"])
           return SCBAlignmentPositionRight;
        else 
            return SCBAlignmentPositionCenter;
    } else {
        return SCBAlignmentPositionCenter;
    }
}

- (SCBInternationalType)getInternational:(NSString *)internationl {
    if (internationl != nil && internationl != (id)[NSNull null]){
        if ([internationl isEqualToString:@"US"])
            return SCBInternationalTypeUSA;
        else if ([internationl isEqualToString:@"FR"])
            return SCBInternationalTypeFrance;
        else if ([internationl isEqualToString:@"UK"])
            return SCBInternationalTypeUK;
        else
            return SCBInternationalTypeUSA;
    } else
        return SCBInternationalTypeUSA;
}

- (SCBFontStyleType)getFont:(NSString *)font {
    if (font != nil && font != (id)[NSNull null]){
        if ([font isEqualToString:@"A"])
            return SCBFontStyleTypeA;
        else if ([font isEqualToString:@"B"])
            return SCBFontStyleTypeB;
        else
            return SCBFontStyleTypeA;
    } else
        return SCBFontStyleTypeA;
}

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
