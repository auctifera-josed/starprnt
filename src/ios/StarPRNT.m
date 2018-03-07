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

- (void)disconnect:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        if (_printerManager != nil && _printerManager.port != nil) {
            [_printerManager disconnect];
        }
    }];
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
            NSString *printerPort = nil;
        
        if (command.arguments.count > 0) {
            printerPort = [command.arguments objectAtIndex:0];
        }

        if (printerPort != nil && printerPort != (id)[NSNull null]){
            _printerManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeStandard
                                                              portName:printerPort
                                                          portSettings:@""
                                                       ioTimeoutMillis:10000];
            
            _printerManager.delegate = self;
        }

        if (_printerManager.port != nil) {
            [_printerManager disconnect];
        }

        if (_printerManager != nil){
            [_printerManager connect];
        }

        dataCallbackId = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        // CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[_printerManager connect]];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:dataCallbackId];
    }];
}
- (void)checkStatus:(CDVInvokedUrlCommand *)command {
    //NSLog(@"Checking status");
    [self.commandDelegate runInBackground:^{
        NSString *portName = nil;
        NSString *emulation = nil;
        CDVPluginResult    *result = nil;
        StarPrinterStatus_2 status;
        SMPort *port = nil;
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
        }
        NSString *portSettings = [self getPortSettingsOption:emulation];
        @try {
            
            port = [SMPort getPort:portName :portSettings :10000];     // 10000mS!!!
            
            // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
     
            NSOperatingSystemVersion version = {11, 0, 0};
            BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
            if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
                [NSThread sleepForTimeInterval:0.2];
            }
            
            [port getParsedStatus:&status :2];
            NSDictionary *firmwareInformation = [[NSMutableDictionary alloc] init];
            @try {
                firmwareInformation = [port getFirmwareInformation];
            }
            @catch (PortException *exception) {
                //unable to get Firmware
            }
          
            NSDictionary *statusDictionary = [self portStatusToDictionary:status :firmwareInformation];
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:statusDictionary];
        }
        @catch (PortException *exception) {
            NSLog(@"Port exception");
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[exception reason]];
        }
        @finally {
            if (port != nil) {
                [SMPort releasePort:port];
            }
        }
        
        //NSLog(@"Sending status result");
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

-(void)printRawText:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{

        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
        NSString *portName = nil;
        NSString *emulation = nil;
        NSDictionary *printObj = nil;
        
  
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
            printObj = [command.arguments objectAtIndex:2];
        };
        
        NSString *portSettings = [self getPortSettingsOption:emulation];
        NSString *text = [printObj valueForKey:@"text"];
        BOOL cutReceipt = ([[printObj valueForKey:@"cutReceipt"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        BOOL openCashDrawer = ([[printObj valueForKey:@"openCashDrawer"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        [builder beginDocument];
        
        [builder appendData:[text dataUsingEncoding:encoding]];
        
        if(cutReceipt == YES){
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        }
        
        if(openCashDrawer == YES){
            [builder appendPeripheral:SCBPeripheralChannelNo1];
            [builder appendPeripheral:SCBPeripheralChannelNo2];
        }
        
        [builder endDocument];
        
          [self sendCommand:[builder.commands copy]
                   portName:portName
               portSettings:portSettings
                    timeout:10000
                 callbackId:command.callbackId];
    }];
}
-(void)printRasterReceipt:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        
        NSString *portName = nil;
        NSString *emulation = nil;
        NSDictionary *printObj = nil;
        
        
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
            printObj = [command.arguments objectAtIndex:2];
        };
        
        NSString *portSettings = [self getPortSettingsOption:emulation];
        NSString *text = [printObj valueForKey:@"text"];
        NSInteger fontSize = ([printObj valueForKey:@"fontSize"]) ? [[printObj valueForKey:@"fontSize"] intValue] : 25;
        CGFloat paperWidth = ([printObj valueForKey:@"paperWidth"]) ? [[printObj valueForKey:@"paperWidth"] floatValue] : 576;
        BOOL cutReceipt = ([[printObj valueForKey:@"cutReceipt"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        BOOL openCashDrawer = ([[printObj valueForKey:@"openCashDrawer"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        UIFont *font = [UIFont fontWithName:@"Menlo" size:fontSize];
        
        UIImage *image = [self imageWithString:text font:font width:paperWidth];
        
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        [builder beginDocument];
        
         [builder appendBitmap:image diffusion:NO];
        
        if(cutReceipt == YES){
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        }
        
        if(openCashDrawer == YES){
            [builder appendPeripheral:SCBPeripheralChannelNo1];
            [builder appendPeripheral:SCBPeripheralChannelNo2];
        }
        
        [builder endDocument];
        
        [self sendCommand:[builder.commands copy]
                 portName:portName
             portSettings:portSettings
                  timeout:10000
               callbackId:command.callbackId];
    }];
}

-(void)printRasterData:(CDVInvokedUrlCommand *)command { //print image
    [self.commandDelegate runInBackground:^{
        
        NSString *portName = nil;
        NSString *emulation = nil;
        NSDictionary *printObj = nil;
        
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
            printObj = [command.arguments objectAtIndex:2];
        };
        
        NSString *portSettings = [self getPortSettingsOption:emulation];
        NSString *uri = [printObj valueForKey:@"uri"];
        CGFloat paperWidth = ([printObj valueForKey:@"paperWidth"]) ? [[printObj valueForKey:@"paperWidth"] floatValue] : 576;
        BOOL cutReceipt = ([[printObj valueForKey:@"cutReceipt"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        BOOL openCashDrawer = ([[printObj valueForKey:@"openCashDrawer"] caseInsensitiveCompare:@"true"]  == NSOrderedSame) ? YES : NO;
        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        NSURL *imageURL = [NSURL URLWithString:uri];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *image = [UIImage imageWithData:imageData];

        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        [builder beginDocument];
        
        [builder appendBitmap:image diffusion:YES width:paperWidth bothScale:YES];
        
        if(cutReceipt == YES){
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        }
        
        if(openCashDrawer == YES){
            [builder appendPeripheral:SCBPeripheralChannelNo1];
            [builder appendPeripheral:SCBPeripheralChannelNo2];
        }
        
        [builder endDocument];
        
        [self sendCommand:[builder.commands copy]
                 portName:portName
             portSettings:portSettings
                  timeout:10000
               callbackId:command.callbackId];
    }];
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
            NSArray *lanPortInfoArray = [SMPort searchPrinter:@"TCP:"];
            for (PortInfo *p in lanPortInfoArray) {
                [info addObject:[self portInfoToDictionary:p]];
            }
        }
        
        if ([portType isEqualToString:@"All"] || [portType isEqualToString:@"BluetoothLE"]) {
            NSArray *btPortInfoArray = [SMPort searchPrinter:@"BLE:"];
            for (PortInfo *p in btPortInfoArray) {
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

- (void)openCashDrawer:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        [builder beginDocument];
        
        [builder appendPeripheral:SCBPeripheralChannelNo1];
        [builder appendPeripheral:SCBPeripheralChannelNo2];
        
        [builder endDocument];
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)printRawData:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        NSString *content = nil;
        
        if (command.arguments.count > 0) {
            content = [command.arguments objectAtIndex:0];
        }        
        
        [builder appendData:[content dataUsingEncoding:NSWindowsCP1252StringEncoding]];
        
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)printData:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        SCBAlignmentPosition alignment = SCBAlignmentPositionCenter;
        SCBInternationalType international = SCBInternationalTypeUSA;
        SCBFontStyleType fontStyle = SCBFontStyleTypeA;
        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
        NSString *content = nil;
        NSString *receiptid = nil;
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        if (command.arguments.count > 0) {
            content = [command.arguments objectAtIndex:0];
            receiptid = [command.arguments objectAtIndex:1];
            alignment = [self getAlignment:[command.arguments objectAtIndex:2]];
            international = [self getInternational:[command.arguments objectAtIndex:3]];
            fontStyle = [self getFont:[command.arguments objectAtIndex:4]];
        }
        
        [builder beginDocument];
        [builder appendCodePage:SCBCodePageTypeCP1252];
        [builder appendInternational:international];
        [builder appendAlignment:alignment];
        [builder appendFontStyle:fontStyle];
        [builder appendData:[content dataUsingEncoding:encoding]];
        [builder appendUnitFeed:32];
        if (receiptid)
            [builder appendQrCodeDataWithAlignment:[receiptid dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelQ cell:6 position:SCBAlignmentPositionCenter];
        [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
        [builder endDocument];

        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)printReceipt:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
        NSString *content = nil;
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        

        if (command.arguments.count > 0) {
            content = [command.arguments objectAtIndex:0];
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
            if (body[@"subtotal"]){
                [builder appendData:[@"Subtotal" dataUsingEncoding:encoding]];
                [builder appendBytes:twoTabs length:sizeof(twoTabs)];
                [builder appendDataWithLineFeed:[body[@"subtotal"] dataUsingEncoding:encoding]];
            }
            if (body[@"tax"]) {
                [builder appendData:[@"Tax" dataUsingEncoding:encoding]];
                [builder appendBytes:twoTabs length:sizeof(twoTabs)];
                [builder appendDataWithLineFeed:[body[@"tax"] dataUsingEncoding:encoding]];
            }
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
                [builder appendAlignment:SCBAlignmentPositionCenter];
                if ([receipt[@"barcode"] boolValue]){
                    if ([receipt[@"barcode_type"] isEqualToString:@"Code39"]){
                        [builder appendBarcodeData:[transaction_id dataUsingEncoding:encoding] symbology:SCBBarcodeSymbologyCode39 width:SCBBarcodeWidthMode1 height:40 hri:YES];
                    } else if ([receipt[@"barcode_type"] isEqualToString:@"QR"]) {
                        [builder appendQrCodeData:[transaction_id dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelL cell:[receipt[@"barcode_cell_size"] intValue]];
                        [builder appendLineFeed:1];
                        [builder appendDataWithLineFeed:[transaction_id dataUsingEncoding:encoding]];
                    }
                } else {
                    [builder appendDataWithLineFeed:[transaction_id dataUsingEncoding:encoding]];
                }
            }
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
            [builder endDocument];
        } else {
            [builder beginDocument];
            [builder appendDataWithLineFeed:[@"The string isn't formatted correctly\nRemember to send a stringified JSON" dataUsingEncoding:encoding]];
            [builder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
            [builder endDocument];
        }

        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)printTicket:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSStringEncoding encoding = NSWindowsCP1252StringEncoding;
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        NSString *content = nil;
        
        if (command.arguments.count > 0) {
            content = [command.arguments objectAtIndex:0];
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
            if ([ticket[@"barcode_type"] isEqualToString:@"Code39"])
                [builder appendBarcodeData:[ticket[@"ticket_id"] dataUsingEncoding:encoding] symbology:SCBBarcodeSymbologyCode39 width:SCBBarcodeWidthMode1 height:[ticket[@"barcode_cell_size"] intValue] hri:YES];
            else if ([ticket[@"barcode_type"] isEqualToString:@"QR"]) {
                [builder appendQrCodeData:[ticket[@"ticket_id"] dataUsingEncoding:encoding] model:SCBQrCodeModelNo2 level:SCBQrCodeLevelL cell:[ticket[@"barcode_cell_size"] intValue]];
                [builder appendLineFeed:1];
                [builder appendDataWithLineFeed:[ticket[@"ticket_id"] dataUsingEncoding:encoding]];
            }
            [builder appendCutPaper:SCBCutPaperActionFullCutWithFeed];
            [builder endDocument];
            
        } else { //Not JSON
            [builder beginDocument];
            [builder appendData:[@"The string isn't formatted correctly\nRemember to send a stringified JSON" dataUsingEncoding:encoding]];
            [builder appendLineFeed:1];
            [builder appendCutPaper:SCBCutPaperActionFullCutWithFeed];
            // [builder endDocument];
        }
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

//Printer configuration methods

- (void)hardReset:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        unsigned char hardReset[] = {0x1B, 0x3F, 0x0A, 0x00};
        [builder appendBytes:hardReset length:sizeof(hardReset)];
        
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
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
    
//     [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
// }

- (void)activateBlackMarkSensor:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        unsigned char setBit[] = {0x1B, 0x1D, 0x23, 0x2B, 0x31, 0x30, 0x31, 0x30, 0x30, 0x0A, 0x00};
        unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
            
        [builder appendBytes:setBit length:sizeof(setBit)];
        [builder appendBytes:writeReset length:sizeof(writeReset)];
        
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)cancelBlackMarkSensor:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        unsigned char clearBit[] = {0x1B, 0x1D, 0x23, 0x2D, 0x31, 0x30, 0x31, 0x30, 0x30, 0x0A, 0x00};
        unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
            
        [builder appendBytes:clearBit length:sizeof(clearBit)];
        [builder appendBytes:writeReset length:sizeof(writeReset)];

        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];
    }];
}

- (void)setToDefaultSettings:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
        
        unsigned char defaultSettings[] = {0x1B, 0x1D, 0x23, 0x2A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
        unsigned char writeReset[] = {0x1B, 0x1D, 0x23, 0x57, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0A, 0x00};
         
        [builder appendBytes:defaultSettings length:sizeof(defaultSettings)];
        [builder appendBytes:writeReset length:sizeof(writeReset)];
        
        [self sendCommand:[builder.commands copy] callbackId:command.callbackId];   
    }];
}

#pragma mark -
#pragma mark Printer Events
#pragma mark -
-(void)didPrinterCoverOpen {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerCoverOpen" data:nil];
    }];
}

-(void)didPrinterCoverClose {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerCoverClose" data:nil];
    }];
}

-(void)didPrinterImpossible {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerImpossible" data:nil];
    }];
}

-(void)didPrinterOnline {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerOnline" data:nil];
    }];
}

-(void)didPrinterOffline {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerOffline" data:nil];
    }];
}

-(void)didPrinterPaperEmpty {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerPaperEmpty" data:nil];
    }];
}

-(void)didPrinterPaperNearEmpty {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerPaperNearEmpty" data:nil];
    }];
}

-(void)didPrinterPaperReady {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"printerPaperReady" data:nil];
    }];
}

#pragma mark -
#pragma mark Cash drawer events
#pragma mark -

-(void)didCashDrawerOpen {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"cashDrawerOpen" data:nil];
    }];
}
-(void)didCashDrawerClose {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"cashDrawerClose" data:nil];
    }];
}

// - (void)onAppTerminate
// {
//     NSLog(@"%@ onAppTerminate!", [self class]);
//     if (_drawerManager != nil && _drawerManager.port != nil) {
//         [_drawerManager disconnect];
//     }

//     if (_printerManager != nil && _printerManager.port != nil) {
//         [_printerManager disconnect];
//     }
// }

// - (void)onMemoryWarning
// {
//     NSLog(@"%@ onMemoryWarning!", [self class]);
// }

// - (void)onReset
// {
//     NSLog(@"%@ onReset!", [self class]);
// }

// - (void)onPause
// {
//     NSLog(@"%@ onReset!", [self class]);
// }

// - (void)dispose
// {
//     NSLog(@"%@ dispose!", [self class]);
//     if (_drawerManager != nil && _drawerManager.port != nil) {
//         [_drawerManager disconnect];
//     }

//     if (_printerManager != nil && _printerManager.port != nil) {
//         [_printerManager disconnect];
//     }
// }

#pragma mark -
#pragma mark Util
#pragma mark -

- (unsigned char *)getCommandAsBytes:(NSMutableArray *)command {
    unsigned char *buffer = (unsigned char *)calloc([command count], sizeof(unsigned char));
    for (int i=0; i<[command count]; i++)
        buffer[i] = [[command objectAtIndex:i] unsignedCharValue];
    return buffer;
}

- (void)sendCommand:(NSMutableData *)commands callbackId:(NSString *)callbackId{
    [self.commandDelegate runInBackground:^{
        BOOL printResult = false;
        
        SMPort *port = nil;
        
        if (_printerManager == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not connected" message:@"Please connect to the printer before sending commands." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        } else if (_printerManager.port == nil){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Port not found" message:@"Please re connect to the printer, something is not working as expected." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        } else {
            port = [_printerManager port];
        }

        if (commands != nil && port != nil) {
            [_printerManager.lock lock];
            
            printResult = [Communication sendCommands:commands port:port];
            
            [_printerManager.lock unlock];
        }

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:printResult];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}
- (void)sendCommand:(NSMutableData *)commands
           portName:(NSString *)portName
       portSettings:(NSString *)portSettings
            timeout:(NSInteger)timeout
         callbackId:(NSString *)callbackId{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = nil;
        BOOL result = NO;
        NSString *title   = @"";
        NSString *message = @"";
        
        SMPort *port = nil;
        @try{
            while(YES){
            port = [SMPort getPort:portName :portSettings :(uint32_t) timeout];
               
                if (port == nil) {
                    title = @"Fail to Open Port";
                    break;
                }
                
            // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
            // (Refer Readme for details)
            NSOperatingSystemVersion version = {11, 0, 0};
            BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
                if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
                    [NSThread sleepForTimeInterval:0.2];
                }
                StarPrinterStatus_2 printerStatus;
                
                [port beginCheckedBlock:&printerStatus :2];
                
                if (printerStatus.offline == SM_TRUE) {
                    title   = @"Printer Error";
                    message = @"Printer is offline (BeginCheckedBlock)";
                    break;
                }
                
                NSDate *startDate = [NSDate date];
                
                uint32_t total = 0;
                
                while (total < (uint32_t) commands.length) {
                    uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total];
                    
                    total += written;
                    
                    if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                        title   = @"Printer Error";
                        message = @"Write port timed out";
                        break;
                    }
                }
                
                if (total < (uint32_t) commands.length) {
                    break;
                }
                
                port.endCheckedBlockTimeoutMillis = 30000;     // 30000mS!!!
                
                [port endCheckedBlock:&printerStatus :2];
                
                if (printerStatus.offline == SM_TRUE) {
                    title   = @"Printer Error";
                    message = @"Printer is offline (EndCheckedBlock)";
                    break;
                }
                
                title   = @"Send Commands";
                message = @"Success";
                
                result = YES;
                break;
            }
        }
        @catch(PortException *exception){
            title   = @"Printer Error";
            message = @"Write port timed out (PortException)";
        }
        @finally{
            if (port != nil) {
                [SMPort releasePort:port];
                
                port = nil;
            }
        }
        if(result == YES){
           pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Success!"];
        }else{
            NSString *messageResult = [title stringByAppendingString: @": "];
            messageResult = [messageResult stringByAppendingString: message];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:messageResult];
        }
       
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        
    }];
}
-(NSString *)getPortSettingsOption:(NSString *)emulation {
    NSString *portSettings = [NSString string];
    
    if([emulation isEqualToString:@"EscPosMobile"]){
        portSettings = [@"mini" stringByAppendingString:portSettings];
    }else if([emulation isEqualToString:@"EscPos"]){
        portSettings = [@"escpos" stringByAppendingString:portSettings];
    }else if([emulation isEqualToString:@"StarPRNT"] || [emulation isEqualToString:@"StarPRNTL"]){
        portSettings = [@"Portable;l" stringByAppendingString:portSettings];
    }
    return portSettings;
}
-(StarIoExtEmulation)getEmulation:(NSString *)emulation{
    
    if([emulation isEqualToString:@"StarPRNT"]) return StarIoExtEmulationStarPRNT;
    else if ([emulation isEqualToString:@"StarPRNTL"]) return StarIoExtEmulationStarPRNTL;
    else if ([emulation isEqualToString:@"StarLine"]) return StarIoExtEmulationStarLine;
    else if ([emulation isEqualToString:@"StarGraphic"]) return StarIoExtEmulationStarGraphic;
    else if ([emulation isEqualToString:@"EscPos"]) return StarIoExtEmulationEscPos;
    else if ([emulation isEqualToString:@"EscPosMobile"]) return StarIoExtEmulationEscPosMobile;
    else if ([emulation isEqualToString:@"StarDotImpact"]) return StarIoExtEmulationStarDotImpact;
    else return StarIoExtEmulationStarLine;
}
- (UIImage *)imageWithString:(NSString *)string font:(UIFont *)font width:(CGFloat)width {
    NSDictionary *attributeDic = @{NSFontAttributeName:font};
    
    CGSize size = [string boundingRectWithSize:CGSizeMake(width, 10000)
                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                                    attributes:attributeDic
                                       context:nil].size;
    
    if ([UIScreen.mainScreen respondsToSelector:@selector(scale)]) {
        if (UIScreen.mainScreen.scale == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
        } else {
            UIGraphicsBeginImageContext(size);
        }
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] set];
    
    CGRect rect = CGRectMake(0, 0, size.width + 1, size.height + 1);
    
    CGContextFillRect(context, rect);
    
    NSDictionary *attributes = @ {
    NSForegroundColorAttributeName:[UIColor blackColor],
    NSFontAttributeName:font
    };
    
    [string drawInRect:rect withAttributes:attributes];
    
    UIImage *imageToPrint = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageToPrint;
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
- (NSMutableDictionary*)portStatusToDictionary:(StarPrinterStatus_2)status :(NSDictionary*)firmwareInformation {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithBool:status.coverOpen == SM_TRUE] forKey:@"coverOpen"];
    [dict setObject:[NSNumber numberWithBool:status.offline == SM_TRUE] forKey:@"offline"];
    [dict setObject:[NSNumber numberWithBool:status.overTemp == SM_TRUE] forKey:@"overTemp"];
    [dict setObject:[NSNumber numberWithBool:status.cutterError == SM_TRUE] forKey:@"cutterError"];
    [dict setObject:[NSNumber numberWithBool:status.receiptPaperEmpty == SM_TRUE] forKey:@"receiptPaperEmpty"];
    [dict addEntriesFromDictionary:firmwareInformation];
    
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
