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
        if (company_name != nil && company_name != (id)[NSNull null]){
            [builder appendDataWithMultiple:[company_name dataUsingEncoding:encoding] width:2 height:2];
            [builder appendLineFeed:1];
        }
        if (company_street != nil && company_street != (id)[NSNull null])
            [builder appendDataWithLineFeed:[company_street dataUsingEncoding:encoding]];
        if (company_country != nil && company_country != (id)[NSNull null])
            [builder appendDataWithLineFeed:[company_country dataUsingEncoding:encoding]];
        [builder appendLineFeed:1];
        if (seller != nil && seller != (id)[NSNull null])
            [builder appendDataWithLineFeed:[seller dataUsingEncoding:encoding]];
        [builder appendAlignment:SCBAlignmentPositionLeft];
        if (date != nil && date != (id)[NSNull null]){
            [builder appendData:[date dataUsingEncoding:encoding]];
            if (time != nil && time != (id)[NSNull null]){
                [builder appendData:[@"                                 " dataUsingEncoding:encoding]];
                [builder appendDataWithLineFeed:[time dataUsingEncoding:encoding]];
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
        [builder appendDataWithLineFeed:[@"Amount" dataUsingEncoding:encoding]];
         
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
        if ([body[@"divider"] intValue] == 1){
            [builder appendDataWithLineFeed:[@"------------------------------------------------" dataUsingEncoding:encoding]];
        }
        [builder appendAlignment:[self getAlignment:footer[@"alignment"]]];
        [builder appendUnitFeed:32];
        //Start footer
        if (phone != nil && phone != (id)[NSNull null]){
            [builder appendData:[@"Tel. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[phone dataUsingEncoding:encoding]];
        }
        if (fax != nil && fax != (id)[NSNull null]){
            [builder appendData:[@"Fax. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[fax dataUsingEncoding:encoding]];
        }
        if (email != nil && email != (id)[NSNull null]){
            [builder appendData:[@"Email. " dataUsingEncoding:encoding]];
            [builder appendDataWithLineFeed:[email dataUsingEncoding:encoding]];
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
            if ([receipt[@"barcode"] intValue] == 1)
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
        int leftMargin = [margin[@"left"] intValue],
            rightMargin = [margin[@"right"] intValue];

        [builder beginDocument];
        //Left Margin
        if (leftMargin == 0)
            [builder appendBytes:"\x1B\x6C\x0" length:sizeof("\x1B\x6C\x0") - 1];
        else if (leftMargin == 1)
            [builder appendBytes:"\x1B\x6C\x1" length:sizeof("\x1B\x6C\x1") - 1];
        else if (leftMargin == 2)
           [builder appendBytes:"\x1B\x6C\x2" length:sizeof("\x1B\x6C\x2") - 1];
        else if (leftMargin == 3)
           [builder appendBytes:"\x1B\x6C\x3" length:sizeof("\x1B\x6C\x3") - 1];
        else if (leftMargin == 4)
           [builder appendBytes:"\x1B\x6C\x4" length:sizeof("\x1B\x6C\x4") - 1];
        else if (leftMargin == 5)
           [builder appendBytes:"\x1B\x6C\x5" length:sizeof("\x1B\x6C\x5") - 1];
        else if (leftMargin == 6)
           [builder appendBytes:"\x1B\x6C\x6" length:sizeof("\x1B\x6C\x6") - 1];
        else if (leftMargin == 7)
           [builder appendBytes:"\x1B\x6C\x7" length:sizeof("\x1B\x6C\x7") - 1];
        else if (leftMargin == 8)
           [builder appendBytes:"\x1B\x6C\x8" length:sizeof("\x1B\x6C\x8") - 1];
        else if (leftMargin == 9)
            [builder appendBytes:"\x1B\x6C\x9" length:sizeof("\x1B\x6C\x9") - 1];       
        //Right Margin
        if (rightMargin == 0)
            [builder appendBytes:"\x1B\x51\x0" length:sizeof("\x1B\x51\x0") - 1];
        else if (rightMargin == 1)
            [builder appendBytes:"\x1B\x51\x1" length:sizeof("\x1B\x51\x1") - 1];
        else if (rightMargin == 2)
           [builder appendBytes:"\x1B\x51\x2" length:sizeof("\x1B\x51\x2") - 1];
        else if (rightMargin == 3)
           [builder appendBytes:"\x1B\x51\x3" length:sizeof("\x1B\x51\x3") - 1];
        else if (rightMargin == 4)
           [builder appendBytes:"\x1B\x51\x4" length:sizeof("\x1B\x51\x4") - 1];
        else if (rightMargin == 5)
           [builder appendBytes:"\x1B\x51\x5" length:sizeof("\x1B\x51\x5") - 1];
        else if (rightMargin == 6)
           [builder appendBytes:"\x1B\x51\x6" length:sizeof("\x1B\x51\x6") - 1];
        else if (rightMargin == 7)
           [builder appendBytes:"\x1B\x51\x7" length:sizeof("\x1B\x51\x7") - 1];
        else if (rightMargin == 8)
           [builder appendBytes:"\x1B\x51\x8" length:sizeof("\x1B\x51\x8") - 1];
        else if (rightMargin == 9)
            [builder appendBytes:"\x1B\x51\x9" length:sizeof("\x1B\x51\x9") - 1];       
        
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
        [builder appendAlignment:SCBAlignmentPositionCenter];
        [builder appendDataWithLineFeed:[ticket[@"type_abbr"] dataUsingEncoding:encoding]];
        if (ticket[@"barcode_type"] == "1D")
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
