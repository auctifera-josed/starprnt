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

- (void)printRawData:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    NSString *portName = nil;
    NSString *content = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
        content = [command.arguments objectAtIndex:1];
    }        
    // unsigned char leftMargin[] = {0x1B, 0x6C, 0x4};
    
    // [builder appendBytes:leftMargin length:sizeof(leftMargin)];
    [builder appendData:[content dataUsingEncoding:encoding]];
    // [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

- (void)printData:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    SCBAlignmentPosition alignment = SCBAlignmentPositionCenter;
    SCBInternationalType international = SCBInternationalTypeUSA;
    SCBFontStyleType fontStyle = SCBFontStyleTypeA;
    NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    NSString *portName = nil;
    NSString *content = nil;
    NSString *receiptid = nil;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    
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

    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
        
}

- (void)printReceipt:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    NSString *portName = nil;
    NSString *content = nil;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    

    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
        content = [command.arguments objectAtIndex:1];
    }
        
    // NSError * error = nil;
    id receipt = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (receipt) { //JSON
        unsigned char setHorizontalTab[] = {0x1b, 0x44, 0x7, 0x29, 0x00};
        unsigned char twoTabs[] = {0x09, 0x09};
        
        NSDictionary    *header = receipt[@"header"],
                        *body = receipt[@"body"],
                        *footer = receipt[@"footer"],
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
                    *transaction_id = receipt[@"transaction_id"];
        int     descriptionMaxSize = 30;
        
        [builder beginDocument];
        [builder appendCodePage:SCBCodePageTypeCP1252];
        [builder appendInternational:[self getInternational:receipt[@"international"]]];
        [builder appendAlignment:[self getAlignment:header[@"alignment"]]];
        [builder appendFontStyle:[self getFont:receipt[@"font"]]];
        //Start header
        if (company_name){
            [builder appendDataWithMultiple:[company_name dataUsingEncoding:encoding] width:2 height:2];
            [builder appendLineFeed:1];
        }
        [builder appendDataWithLineFeed:[company_street dataUsingEncoding:encoding]];
        [builder appendDataWithLineFeed:[company_country dataUsingEncoding:encoding]];
        [builder appendLineFeed:1];
        [builder appendDataWithLineFeed:[seller dataUsingEncoding:encoding]];
        [builder appendAlignment:SCBAlignmentPositionLeft];
        if (date){
            [builder appendData:[date dataUsingEncoding:encoding]];
            if (time){
                [builder appendData:[@"                                 " dataUsingEncoding:encoding]];
                [builder appendDataWithLineFeed:[time dataUsingEncoding:encoding]];
            }
        }
        if ([header[@"divider"] boolValue])
            [builder appendDataWithLineFeed:[@"------------------------------------------------" dataUsingEncoding:encoding]];
        //Start body
        [builder appendBytes:setHorizontalTab length:sizeof(setHorizontalTab)];
        [builder appendData:[@"Qty." dataUsingEncoding:encoding]];
        [builder appendByte:0x09];
        [builder appendData:[@"Description" dataUsingEncoding:encoding]];
        [builder appendByte:0x09];
        [builder appendDataWithLineFeed:[@"Amount" dataUsingEncoding:encoding]];
         
        for (NSDictionary *product in (NSArray *) body[@"product_list"]){
            if (product[@"quantity"] && product[@"description"] && product[@"amount"]){
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
        [builder appendDataWithLineFeed:[body[@"subtotal"] dataUsingEncoding:encoding]];
        [builder appendData:[@"Tax" dataUsingEncoding:encoding]];
        [builder appendBytes:twoTabs length:sizeof(twoTabs)];
        [builder appendDataWithLineFeed:[body[@"tax"] dataUsingEncoding:encoding]];
        [builder appendData:[@"Total" dataUsingEncoding:encoding]];
        unsigned char setHorizontalTab2[] = {0x1b, 0x44, 0x7, 0x22, 0x00};
        [builder appendBytes:setHorizontalTab2 length:sizeof(setHorizontalTab2)];
        [builder appendBytes:twoTabs length:sizeof(twoTabs)];
        [builder appendDataWithMultiple:[body[@"total"] dataUsingEncoding:encoding] width:2 height:2];
        [builder appendLineFeed:1];
        if ([body[@"divider"] boolValue])
            [builder appendDataWithLineFeed:[@"------------------------------------------------" dataUsingEncoding:encoding]];
        [builder appendAlignment:[self getAlignment:footer[@"alignment"]]];
        [builder appendUnitFeed:32];
        //Start footer
        if (phone){
            [builder appendData:[@"Tel. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[phone dataUsingEncoding:encoding]];
        }
        if (fax){
            [builder appendData:[@"Fax. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[fax dataUsingEncoding:encoding]];
        }
        if (email){
            [builder appendData:[@"Email. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[email dataUsingEncoding:encoding]];
        }
        [builder appendLineFeed:1];
        if (notice){
            if ([notice[@"invert"] boolValue])     
                [builder appendDataWithInvert:[notice[@"title"] dataUsingEncoding:encoding]];
            else
                [builder appendData:[notice[@"title"] dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
            [builder appendData:[notice[@"text"] dataUsingEncoding:encoding]];
        }
        [builder appendLineFeed:2];
        if (transaction_id){
            if ([receipt[@"barcode"] boolValue])
                [builder appendBarcodeDataWithAlignment:[transaction_id dataUsingEncoding:encoding] symbology:SCBBarcodeSymbologyCode39 width:SCBBarcodeWidthMode1 height:40 hri:YES position:SCBAlignmentPositionCenter];
            else
                [builder appendData:[transaction_id dataUsingEncoding:encoding]];
        }
        [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        [builder endDocument];
    } else {
        [builder beginDocument];
        [builder appendDataWithLineFeed:[@"The given string isn't formatted correctly\nRemember to send a stringified JSON" dataUsingEncoding:encoding]];
        [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        [builder endDocument];
    }

    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

- (void)printTicket:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSString *portName = nil;
    NSString *content = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
        content = [command.arguments objectAtIndex:1];
    }
        
    // NSError * error = nil;
    id ticket = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (ticket) { //JSON
        NSDictionary    *address = ticket[@"address"],
                        *margin = ticket[@"margin"];
        
        NSMutableArray  *leftMarginCommand = [NSMutableArray arrayWithObjects:@27, @108, nil],
                        *rightMarginCommand = [NSMutableArray arrayWithObjects:@27, @81, nil],
                        *barcodeLeftMarginCommand = [NSMutableArray arrayWithObjects:@27, @108, @6, nil];
        
        [leftMarginCommand addObject:@([margin[@"left"] intValue])];
        [rightMarginCommand addObject:@([margin[@"right"] intValue])];
        [barcodeLeftMarginCommand replaceObjectAtIndex:2 withObject:@([ticket[@"barcode_left_margin"] intValue])];

        unsigned char *leftMargin = [self getCommandAsBytes:leftMarginCommand];
        unsigned char *rightMargin = [self getCommandAsBytes:rightMarginCommand];
        unsigned char *barcodeLeftMargin = [self getCommandAsBytes:barcodeLeftMarginCommand];

        [builder beginDocument];
        //Left Margin
        if (margin[@"left"])
            [builder appendBytes:leftMargin length:sizeof(leftMargin)];
        //Right Margin
        if (margin[@"right"])
            [builder appendBytes:rightMargin length:sizeof(rightMargin)];
        [builder appendCodePage:SCBCodePageTypeCP1252];
        [builder appendFontStyle:[self getFont:ticket[@"font"]]];
        [builder appendAlignment:SCBAlignmentPositionLeft];
        [builder appendDataWithMultiple:[ticket[@"title"] dataUsingEncoding:encoding] width:[ticket[@"title_font_size"] intValue] height:[ticket[@"title_font_size"] intValue]];
        [builder appendLineFeed:1];
        [builder appendDataWithMultiple:[ticket[@"subtitle"] dataUsingEncoding:encoding] width:[ticket[@"subtitle_font_size"] intValue] height:[ticket[@"subtitle_font_size"] intValue]];
        [builder appendLineFeed:1];
        [builder appendDataWithLineFeed:[ticket[@"date"] dataUsingEncoding:encoding] line:[ticket[@"space_to_address"] intValue]];
        [builder appendDataWithLineFeed:[ticket[@"place"] dataUsingEncoding:encoding]];
        [builder appendDataWithLineFeed:[address[@"street"] dataUsingEncoding:encoding]];
        [builder appendDataWithLineFeed:[address[@"city"] dataUsingEncoding:encoding] line:2];
        [builder appendFontStyle:SCBFontStyleTypeB];
        [builder appendData:[ticket[@"type"] dataUsingEncoding:encoding]];
        [builder appendData:[@" - " dataUsingEncoding:encoding]];
        [builder appendDataWithLineFeed:[ticket[@"ticket_id"] dataUsingEncoding:encoding]];
        [builder appendDataWithLineFeed:[ticket[@"website"] dataUsingEncoding:encoding] line:[ticket[@"space_to_removable"] intValue]];
        [builder appendFontStyle:[self getFont:ticket[@"font"]]];
        // [builder appendAlignment:SCBAlignmentPositionCenter];
        [builder appendBytes:barcodeLeftMargin length:sizeof(barcodeLeftMargin)];
        [builder appendDataWithLineFeed:[ticket[@"type_abbr"] dataUsingEncoding:encoding]];
        if ([ticket[@"barcode_type"] isEqualToString:@"1D"])
            [builder appendBarcodeData:[ticket[@"ticket_id"] dataUsingEncoding:encoding] symbology:SCBBarcodeSymbologyCode39 width:SCBBarcodeWidthMode1 height:[ticket[@"barcode_cell_size"] intValue] hri:YES];
        else{
            [builder appendQrCodeData:[ticket[@"ticket_id"] dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelL cell:[ticket[@"barcode_cell_size"] intValue]];
            [builder appendLineFeed:1];
            [builder appendDataWithLineFeed:[ticket[@"ticket_id"] dataUsingEncoding:encoding]];
        }
        [builder appendCutPaper:SCBCutPaperActionFullCutWithFeed];
        [builder endDocument];
        
    } else { //Not JSON
        [builder beginDocument];
        [builder appendData:[@"The given string isn't formatted correctly\nRemember to send a stringified JSON" dataUsingEncoding:encoding]];
        [builder appendLineFeed:1];
        [builder appendCutPaper:SCBCutPaperActionFullCutWithFeed];
        // [builder endDocument];
    }
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

//Printer configuration methods

- (void)hardReset:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSString *portName = nil;

    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
    }   

    unsigned char hardReset[] = {0x1B, 0x3F, 0x0A, 0x00};
    [builder appendBytes:hardReset length:sizeof(hardReset)];
    
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

//Page Mode is NOT supported in TSP700II
// - (void)setPrintDirection:(CDVInvokedUrlCommand *)command {
//     NSLog(@"setting print direction");
//     StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
//     ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
//     NSString *portName = nil;
    
//     if (command.arguments.count > 0) {
//         portName = [command.arguments objectAtIndex:0];
//     }        
    
//     unsigned char setPageMode[] = {0x1B, 0x1D, 0x50, 0x30};
//     unsigned char setDirection[] = {0x1B, 0x1D, 0x50, 0x32, 0x32};
    
//     [builder appendBytes:setPageMode length:sizeof(setPageMode)];
//     [builder appendBytes:setDirection length:sizeof(setDirection)];
    
//     [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
// }

- (void)activateBlackMarkSensor:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSString *portName = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
    }        
    
    unsigned char setBit[] = {0x1B, 0x1D, 0x23, 0x2B, 0x31, 0x30, 0x31, 0x30, 0x30, 0x0A, 0x00};
    unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
        
    [builder appendBytes:setBit length:sizeof(setBit)];
    [builder appendBytes:writeReset length:sizeof(writeReset)];
    
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

- (void)cancelBlackMarkSensor:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSString *portName = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
    } 

    unsigned char clearBit[] = {0x1B, 0x1D, 0x23, 0x2D, 0x31, 0x30, 0x31, 0x30, 0x30, 0x0A, 0x00};
    unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
        
    [builder appendBytes:clearBit length:sizeof(clearBit)];
    [builder appendBytes:writeReset length:sizeof(writeReset)];
    
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];
}

- (void)setToDefaultSettings:(CDVInvokedUrlCommand *)command {
    StarIoExtEmulation emulation = StarIoExtEmulationStarLine;
    ISCBBuilder *builder = [StarIoExt createCommandBuilder:emulation];
    NSString *portName = nil;
    
    if (command.arguments.count > 0) {
        portName = [command.arguments objectAtIndex:0];
    } 

    unsigned char defaultSettings[] = {0x1B, 0x1D, 0x23, 0x2A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
    unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
     
    [builder appendBytes:defaultSettings length:sizeof(defaultSettings)];
    [builder appendBytes:writeReset length:sizeof(writeReset)];
    
    [self sendCommand:[builder.commands copy] portName:portName callbackId:command.callbackId];   
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

- (unsigned char *)getCommandAsBytes:(NSMutableArray *)command {
    unsigned char *buffer = (unsigned char *)calloc([command count], sizeof(unsigned char));
    for (int i=0; i<[command count]; i++)
        buffer[i] = [[command objectAtIndex:i] unsignedCharValue];
    return buffer;
}

- (void)sendCommand:(NSMutableData *)commands portName:(NSString *)portName callbackId:(NSString *)callbackId{
    [self.commandDelegate runInBackground:^{
        BOOL printResult = false;
        
        SMPort *port = nil;
        
        if (_starIoExtManager == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not connected" message:@"Please connect to the printer before sending commands." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        } else if (_starIoExtManager.port == nil){
            port = [SMPort getPort:portName :@"" :10000];
        } else {
            port = [_starIoExtManager port];
        }

        if (commands != nil && port != nil) {
            [_starIoExtManager.lock lock];
            
            printResult = [Communication sendCommands:commands port:port];
            
            [_starIoExtManager.lock unlock];
        }

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:printResult];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

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
