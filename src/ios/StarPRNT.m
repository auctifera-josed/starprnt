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
        if (_printerManager != nil) {
            [_printerManager disconnect];
        }
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printer Disconnected!"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
            NSString *printerPort = nil;
            NSString *emulation = @"StarLine";
            NSNumber *hasBarcodeReader = nil;
        
        if (command.arguments.count > 0) {
            printerPort = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
            hasBarcodeReader = [command.arguments objectAtIndex:2];
        }
        NSString *portSettings = [self getPortSettingsOption:emulation];
        
        if (printerPort != nil && printerPort != (id)[NSNull null]){
            if ([hasBarcodeReader isEqual:@(YES)]) {
                _printerManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeWithBarcodeReader
                                                                portName:printerPort
                                                            portSettings:portSettings
                                                         ioTimeoutMillis:10000];
            } else {
            _printerManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeStandard
                                                              portName:printerPort
                                                          portSettings:portSettings
                                                       ioTimeoutMillis:10000];
            }
            
            _printerManager.delegate = self;
        }

        if (_printerManager.port != nil) {
            [_printerManager disconnect];
        }

        BOOL connectResult = NO;
        
        if (_printerManager != nil){
            connectResult = [_printerManager connect];
        }

        CDVPluginResult *result = nil;

        if (connectResult == YES) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printer Connected"];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Printer not connected"];
        }

        dataCallbackId = command.callbackId;
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
        BOOL cutReceipt = ([printObj valueForKey:@"cutReceipt"]) ? YES : NO;
        BOOL openCashDrawer = ([printObj valueForKey:@"openCashDrawer"]) ? YES : NO;
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

        if(portName != nil && portName != (id)[NSNull null]){
            
                [self sendCommand:[builder.commands copy]
                         portName:portName
                     portSettings:portSettings
                          timeout:10000
                       callbackId:command.callbackId];
            
            }else{ //Use StarIOExtManager and send command to connected printer
                
            [self sendCommand:[builder.commands copy]
                   callbackId:command.callbackId];
                
        }
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
        BOOL cutReceipt = ([printObj valueForKey:@"cutReceipt"]) ? YES : NO;
        BOOL openCashDrawer = ([printObj valueForKey:@"openCashDrawer"]) ? YES : NO;
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
        if(portName != nil && portName != (id)[NSNull null]){
            
            [self sendCommand:[builder.commands copy]
                     portName:portName
                 portSettings:portSettings
                      timeout:10000
                   callbackId:command.callbackId];
            
        }else{ //Use StarIOExtManager and send command to connected printer
            
            [self sendCommand:[builder.commands copy]
                   callbackId:command.callbackId];
            
        }

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
        BOOL cutReceipt = ([printObj valueForKey:@"cutReceipt"]) ? YES : NO;
        BOOL openCashDrawer = ([printObj valueForKey:@"openCashDrawer"]) ? YES : NO;
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
        
        if(portName != nil && portName != (id)[NSNull null]){
            
            [self sendCommand:[builder.commands copy]
                     portName:portName
                 portSettings:portSettings
                      timeout:10000
                   callbackId:command.callbackId];
            
        }else{ //Use StarIOExtManager and send command to connected printer
            
            [self sendCommand:[builder.commands copy]
                   callbackId:command.callbackId];
            
        }
    }];
}
-(void)print:(CDVInvokedUrlCommand *)command { //print ISCCommandBuilder methods 
    [self.commandDelegate runInBackground:^{
        
        NSString *portName = nil;
        NSString *emulation = nil;
        NSArray *printCommands = nil;
        
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
            printCommands = [command.arguments objectAtIndex:2];
        };
        
        NSString *portSettings = [self getPortSettingsOption:emulation];

        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        [builder beginDocument];
        
        [self appendCommands:builder
               printCommands:printCommands];

        [builder endDocument];
        
        if(portName != nil && portName != (id)[NSNull null]){
            
            [self sendCommand:[builder.commands copy]
                     portName:portName
                 portSettings:portSettings
                      timeout:10000
                   callbackId:command.callbackId];
            
        }else{ //Use StarIOExtManager and send command to connected printer
            
            [self sendCommand:[builder.commands copy]
                   callbackId:command.callbackId];
            
        }
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

        NSString *portName = nil;
        NSString *emulation = nil;
        
        if (command.arguments.count > 0) {
            portName = [command.arguments objectAtIndex:0];
            emulation = [command.arguments objectAtIndex:1];
        };
        
        NSString *portSettings = [self getPortSettingsOption:emulation];
        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        [builder beginDocument];
        
        [builder appendPeripheral:SCBPeripheralChannelNo1];
        [builder appendPeripheral:SCBPeripheralChannelNo2];
        
        [builder endDocument];
        if(portName != nil && portName != (id)[NSNull null]){
            
            [self sendCommand:[builder.commands copy]
                     portName:portName
                 portSettings:portSettings
                      timeout:10000
                   callbackId:command.callbackId];
            
        }else{ //Use StarIOExtManager and send command to connected printer
            
            [self sendCommand:[builder.commands copy]
                   callbackId:command.callbackId];
            
        }
    }];
}

- (void)printRawData:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        
        NSString *content = nil;
        NSString *emulation = @"StarLine";
        
        if (command.arguments.count > 0) {
            content = [command.arguments objectAtIndex:0];
        }
        StarIoExtEmulation Emulation = [self getEmulation:emulation];
        
        ISCBBuilder *builder = [StarIoExt createCommandBuilder:Emulation];
        
        
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


-(void)didBarcodeReaderImpossible {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"barcodeReaderImpossible" data:nil];
    }];
}

-(void)didBarcodeReaderConnect {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"barcodeReaderConnect" data:nil];
    }];
}

-(void)didBarcodeReaderDisconnect {
    [self.commandDelegate runInBackground:^{
        [self sendData:@"barcodeReaderDisconnect" data:nil];
    }];
}

- (void)didBarcodeDataReceive:(NSData *)data {
    [self.commandDelegate runInBackground:^{
        NSMutableString *text = [NSMutableString stringWithString:@""];
        const uint8_t *p = [data bytes];
        for (int i = 0; i < data.length; i++) {
            uint8_t ch = *(p + i);
            if(ch >= 0x20 && ch <= 0x7f) {
                [text appendFormat:@"%c", (char) ch];
            }
            else if (ch == 0x0d) {
                // text = [NSMutableString stringWithString:@""];
            }
        }
            
        [self sendData:@"barcodeDataReceive" data:text];
    }];
}

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
        CDVPluginResult *pluginResult = nil;
        BOOL result = NO;
        
        NSString *title   = @"";
        NSString *message = @"";
        
        SMPort *port = nil;
        @try{
            while(YES){
                
                if (_printerManager == nil) {
                    title   = @"Not connected";
                    message = @"Please connect to the printer before sending commands.";
                    break;
                    
                } else if (_printerManager.port == nil){
                    title   = @"Fail to Open Port";
                    message = @"Please re-connect to the printer";
                    break;
                } else {
                    port = [_printerManager port];
                }
                
                // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
                // (Refer Readme for details)
                NSOperatingSystemVersion version = {11, 0, 0};
                BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
                if ((isOSVer11OrLater) && ([port.portName.uppercaseString hasPrefix:@"BT:"])) {
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

-(void)appendCommands:(ISCBBuilder *)builder
       printCommands:(NSArray *)printCommands {
    
    NSStringEncoding encoding = NSASCIIStringEncoding;
    
    for (id command in printCommands){
        if ([command valueForKey:@"appendInternational"]) [builder appendInternational:[self getInternational:[command valueForKey:@"appendInternational"]]];
        else if ([command valueForKey:@"appendCharacterSpace"]) [builder appendCharacterSpace:[[command valueForKey:@"appendCharacterSpace"] intValue]];
        else if ([command valueForKey:@"appendEncoding"]) encoding = [self getEncoding:[command valueForKey:@"appendEncoding"]];
        else if ([command valueForKey:@"appendCodePage"]) [builder appendCodePage:[self getCodePageType:[command valueForKey:@"appendCodePage"]]];
        else if ([command valueForKey:@"append"]) [builder appendData:[[command valueForKey:@"append"] dataUsingEncoding:encoding]];
        else if ([command valueForKey:@"appendRaw"]) [builder appendRawData:[[command valueForKey:@"appendRaw"] dataUsingEncoding:encoding]];
        else if ([command valueForKey:@"appendEmphasis"]) [builder appendDataWithEmphasis:[[command valueForKey:@"appendEmphasis"] dataUsingEncoding:encoding]];
        else if ([command valueForKey:@"enableEmphasis"]) [builder appendEmphasis:[[command valueForKey:@"enableEmphasis"] boolValue]];
        else if ([command valueForKey:@"appendInvert"]) [builder appendDataWithInvert:[[command valueForKey:@"appendInvert"] dataUsingEncoding:encoding]];
        else if ([command valueForKey:@"enableInvert"]) [builder appendInvert:[[command valueForKey:@"enableInvert"] boolValue]];
        else if ([command valueForKey:@"appendUnderline"]) [builder appendDataWithUnderLine:[[command valueForKey:@"appendUnderline"] dataUsingEncoding:encoding]];
        else if ([command valueForKey:@"enableUnderline"]) [builder appendUnderLine:[[command valueForKey:@"enableUnderline"] boolValue]];
        else if ([command valueForKey:@"appendLineFeed"]) [builder appendLineFeed:[[command valueForKey:@"appendLineFeed"] intValue]];
        else if ([command valueForKey:@"appendUnitFeed"]) [builder appendUnitFeed:[[command valueForKey:@"appendUnitFeed"] intValue]];
        else if ([command valueForKey:@"appendLineSpace"]) [builder appendLineSpace:[[command valueForKey:@"appendLineSpace"] intValue]];
        else if ([command valueForKey:@"appendFontStyle"])[builder appendFontStyle:[self getFont:[command valueForKey:@"appendFontStyle"]]];
        else if ([command valueForKey:@"appendCutPaper"]) [builder appendCutPaper:[self getCutPaperAction:[command valueForKey:@"appendCutPaper"]]];
        else if ([command valueForKey:@"openCashDrawer"])[builder appendPeripheral:[self getPeripheralChannel:[command valueForKey:@"openCashDrawer"]]];
        else if ([command valueForKey:@"appendBlackMark"]) [builder appendBlackMark:[self getBlackMarkType:[command valueForKey:@"appendBlackMark"]]];
        else if ([command valueForKey:@"appendBytes"]){
            NSMutableArray *byteArray = nil;
            byteArray = [command valueForKey:@"appendBytes"];
            int count = (int)[byteArray count];
            unsigned char buffer[count + 1];
            for (int i=0; i< count; i++){
                buffer[i] = [[byteArray objectAtIndex:i] unsignedCharValue];
            }
            [builder appendBytes:buffer length:sizeof(buffer)-1];
        }
        else if ([command valueForKey:@"appendRawBytes"]){
            NSMutableArray *rawByteArray = nil;
            rawByteArray = [command valueForKey:@"appendRawBytes"];
            int rawCount = (int)[rawByteArray count];
            unsigned char rawBuffer[rawCount + 1];
            for (int i=0; i< rawCount; i++){
                rawBuffer[i] = [[rawByteArray objectAtIndex:i] unsignedCharValue];
            }
            [builder appendRawBytes:rawBuffer length:sizeof(rawBuffer)-1];
        }
        else if ([command valueForKey:@"appendAbsolutePosition"]){
            if([command valueForKey:@"data"]) [builder appendDataWithAbsolutePosition:[[command valueForKey:@"data"] dataUsingEncoding:encoding]
                                                                             position:[[command valueForKey:@"appendAbsolutePosition"] intValue]];
            else [builder appendAbsolutePosition:[[command valueForKey:@"appendAbsolutePosition"] intValue]];
        }
        else if ([command valueForKey:@"appendAlignment"]) {
             if([command valueForKey:@"data"]) [builder appendDataWithAlignment:[[command valueForKey:@"data"] dataUsingEncoding:encoding]
                                                                       position:[self getAlignment:[command valueForKey:@"appendAlignment"]]];
             else [builder appendAlignment:[self getAlignment:[command valueForKey:@"appendAlignment"]]];
        }
        else if ([command valueForKey:@"appendHorizontalTabPosition"]) {
            NSArray<NSNumber *> *tabPositionArray = nil;
            tabPositionArray = [command valueForKey:@"appendHorizontalTabPosition"];
            if (tabPositionArray != nil && tabPositionArray != (id)[NSNull null])[builder appendHorizontalTabPosition:tabPositionArray];
        }
        else if ([command valueForKey:@"appendMultiple"]) {
            int width = ([[command valueForKey:@"width"] intValue]) ? [[command valueForKey:@"width"] intValue]: 2;
            int height = ([[command valueForKey:@"height"] intValue]) ? [[command valueForKey:@"height"] intValue]: 2;
            [builder appendDataWithMultiple:[[command valueForKey:@"appendMultiple"] dataUsingEncoding:encoding] width:width height:height];
        }
        else if ([command valueForKey:@"enableMultiple"]) {
            int width = ([[command valueForKey:@"width"] intValue]) ? [[command valueForKey:@"width"] intValue]: 1;
            int height = ([[command valueForKey:@"height"] intValue]) ? [[command valueForKey:@"height"] intValue]: 1;
            if([[command valueForKey:@"enableMultiple"] boolValue] == YES){
                [builder appendMultiple:width height:height];
            }else{
                [builder appendMultiple:1 height:1];
            }
        }
        else if ([command valueForKey:@"appendLogo"]) {
            if([command valueForKey:@"logoSize"]) [builder appendLogo:[self getLogoSize:[command valueForKey:@"logoSize"]]
                                                               number:[[command valueForKey:@"appendLogo"] intValue]];
            else [builder appendLogo:SCBLogoSizeNormal number:[[command valueForKey:@"appendLogo"] intValue]];
        }
        else if ([command valueForKey:@"appendBarcode"]) {
            SCBBarcodeSymbology barcodeSymbology = [self getBarcodeSymbology:[command valueForKey:@"BarcodeSymbology"]];
            SCBBarcodeWidth barcodeWidth = [self getBarcodeWidth:[command valueForKey:@"BarcodeWidth"]];
            int height = ([command valueForKey:@"height"]) ? [[command valueForKey:@"height"] intValue]: 40;
            BOOL hri = ([[command valueForKey:@"hri"] boolValue]  == NO) ? NO : YES;
            
            if([command valueForKey:@"absolutePosition"]){
                int position = ([[command valueForKey:@"absolutePosition"] intValue]) ? [[command valueForKey:@"absolutePosition"] intValue]: 40;
                [builder appendBarcodeDataWithAbsolutePosition:[[command valueForKey:@"appendBarcode"] dataUsingEncoding:encoding]
                                                     symbology:barcodeSymbology width:barcodeWidth height:height hri:hri position:position];
            }
            else if ([command valueForKey:@"alignment"]){
                SCBAlignmentPosition alignment = [self getAlignment:[command valueForKey:@"alignment"]];
                [builder appendBarcodeDataWithAlignment:[[command valueForKey:@"appendBarcode"] dataUsingEncoding:encoding]
                                              symbology:barcodeSymbology width:barcodeWidth height:height hri:hri position:alignment];
            }
            else [builder appendBarcodeData:[[command valueForKey:@"appendBarcode"] dataUsingEncoding:encoding]
                                  symbology:barcodeSymbology width:barcodeWidth height:height hri:hri];
            
        }
        else if ([command valueForKey:@"appendQrCode"]) {
            SCBQrCodeModel qrCodeModel = [self getQrCodeModel:[command valueForKey:@"QrCodeModel"]];
            SCBQrCodeLevel qrCodeLevel = [self getQrCodeLevel:[command valueForKey:@"QrCodeLevel"]];
            int cell = ([[command valueForKey:@"cell"] intValue]) ? [[command valueForKey:@"cell"] intValue]: 4;
            
            if([command valueForKey:@"absolutePosition"]){
                int position = ([[command valueForKey:@"absolutePosition"] intValue]) ? [[command valueForKey:@"absolutePosition"] intValue]: 40;
                [builder appendQrCodeDataWithAbsolutePosition:[[command valueForKey:@"appendQrCode"] dataUsingEncoding:encoding]
                                                          model:qrCodeModel level:qrCodeLevel cell:cell position:position];
            }
            else if ([command valueForKey:@"alignment"]){
                SCBAlignmentPosition alignment = [self getAlignment:[command valueForKey:@"alignment"]];
                [builder appendQrCodeDataWithAlignment:[[command valueForKey:@"appendQrCode"] dataUsingEncoding:encoding]
                                                 model:qrCodeModel level:qrCodeLevel cell:cell position:alignment];
            }
            else [builder appendQrCodeData:[[command valueForKey:@"appendQrCode"] dataUsingEncoding:encoding]
                                     model:qrCodeModel level:qrCodeLevel cell:cell];
            }
        else if ([command valueForKey:@"appendBitmap"]) {
            NSString *urlString = [command valueForKey:@"appendBitmap"];
            NSInteger width = ([command valueForKey:@"width"]) ? [[command valueForKey:@"width"] intValue] : 576;
            BOOL diffusion = ([[command valueForKey:@"diffusion"] boolValue] == NO) ? NO : YES;
            BOOL bothScale = ([[command valueForKey:@"bothScale"] boolValue]  == NO) ? NO : YES;
            SCBBitmapConverterRotation rotation = [self getBitmapConverterRotation:[command valueForKey:@"rotation"]];
            NSURL *imageURL = [NSURL URLWithString:urlString];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *image = [UIImage imageWithData:imageData];
            
            if([command valueForKey:@"absolutePosition"]){
                int position = ([[command valueForKey:@"absolutePosition"] intValue]) ? [[command valueForKey:@"absolutePosition"] intValue]: 40;
                [builder appendBitmapWithAbsolutePosition:image diffusion:diffusion width:width bothScale:bothScale rotation:rotation position:position];
            }
            else if ([command valueForKey:@"alignment"]){
                SCBAlignmentPosition alignment = [self getAlignment:[command valueForKey:@"alignment"]];
                [builder appendBitmapWithAlignment:image diffusion:diffusion width:width bothScale:bothScale rotation:rotation position:alignment];
            }
            else [builder appendBitmap:image diffusion:diffusion width:width bothScale:bothScale rotation:rotation];
        }
        
    }
    
}

- (NSStringEncoding)getEncoding:(NSString *)encoding {
    if (encoding != nil && encoding != (id)[NSNull null]){
        if ([encoding isEqualToString:@"US-ASCII"]) return NSASCIIStringEncoding; //English
        else if ([encoding isEqualToString:@"Windows-1252"]) return NSWindowsCP1252StringEncoding; //French, German, Portuguese, Spanish
        else if ([encoding isEqualToString:@"Shift-JIS"]) return NSShiftJISStringEncoding; //Japanese
        else if ([encoding isEqualToString:@"Windows-1251"]) return NSWindowsCP1251StringEncoding; //Russian
        else if ([encoding isEqualToString:@"GB2312"]) return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000); // Simplified Chinese
        else if ([encoding isEqualToString:@"Big5"]) return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5); // Traditional Chinese
        else if ([encoding isEqualToString:@"UTF-8"]) return NSUTF8StringEncoding; // UTF-8
        return NSWindowsCP1252StringEncoding;

    } else {
        return NSWindowsCP1252StringEncoding;
    }
}


#pragma mark -
#pragma mark ISCBBuilder Constants
#pragma mark -

- (SCBAlignmentPosition)getAlignment:(NSString *)alignment {
    if (alignment != nil && alignment != (id)[NSNull null]){
        if ([alignment caseInsensitiveCompare:@"left"] == NSOrderedSame) return SCBAlignmentPositionLeft;
        else if ([alignment caseInsensitiveCompare:@"center"] == NSOrderedSame) return SCBAlignmentPositionCenter;
        else if ([alignment caseInsensitiveCompare:@"right"] == NSOrderedSame)  return SCBAlignmentPositionRight;
        else return SCBAlignmentPositionLeft;
    } else {
        return SCBAlignmentPositionLeft;
    }
}

- (SCBInternationalType)getInternational:(NSString *)internationl {
    if (internationl != nil && internationl != (id)[NSNull null]){
        if ([internationl isEqualToString:@"US"] || [internationl isEqualToString:@"USA"]) return SCBInternationalTypeUSA;
        else if ([internationl isEqualToString:@"FR"] || [internationl isEqualToString:@"France"]) return SCBInternationalTypeFrance;
        else if ([internationl isEqualToString:@"UK"]) return SCBInternationalTypeUK;
        else if ([internationl isEqualToString:@"Germany"]) return SCBInternationalTypeGermany;
        else if ([internationl isEqualToString:@"Denmark"]) return SCBInternationalTypeDenmark;
        else if ([internationl isEqualToString:@"Sweden"]) return SCBInternationalTypeSweden;
        else if ([internationl isEqualToString:@"Italy"]) return SCBInternationalTypeItaly;
        else if ([internationl isEqualToString:@"Spain"]) return SCBInternationalTypeSpain;
        else if ([internationl isEqualToString:@"Japan"]) return SCBInternationalTypeJapan;
        else if ([internationl isEqualToString:@"Norway"]) return SCBInternationalTypeNorway;
        else if ([internationl isEqualToString:@"Denmark2"]) return SCBInternationalTypeDenmark2;
        else if ([internationl isEqualToString:@"Spain2"]) return SCBInternationalTypeSpain2;
        else if ([internationl isEqualToString:@"LatinAmerica"]) return SCBInternationalTypeLatinAmerica;
        else if ([internationl isEqualToString:@"Korea"]) return SCBInternationalTypeKorea;
        else if ([internationl isEqualToString:@"Ireland"]) return SCBInternationalTypeIreland;
        else if ([internationl isEqualToString:@"Legal"]) return SCBInternationalTypeLegal;
        else return SCBInternationalTypeUSA;
    } else
        return SCBInternationalTypeUSA;
}

- (SCBFontStyleType)getFont:(NSString *)font {
    if (font != nil && font != (id)[NSNull null]){
        if ([font isEqualToString:@"A"]) return SCBFontStyleTypeA;
        else if ([font isEqualToString:@"B"]) return SCBFontStyleTypeB;
        else return SCBFontStyleTypeA;
    } else
        return SCBFontStyleTypeA;
}

- (SCBCodePageType)getCodePageType:(NSString *)codePageType {
    if (codePageType != nil && codePageType != (id)[NSNull null]){
        if ([codePageType isEqualToString:@"CP437"]) return SCBCodePageTypeCP437;
        else if ([codePageType isEqualToString:@"CP737"]) return SCBCodePageTypeCP737;
        else if ([codePageType isEqualToString:@"CP772"]) return SCBCodePageTypeCP772;
        else if ([codePageType isEqualToString:@"CP774"]) return SCBCodePageTypeCP774;
        else if ([codePageType isEqualToString:@"CP851"]) return SCBCodePageTypeCP851;
        else if ([codePageType isEqualToString:@"CP852"]) return SCBCodePageTypeCP852;
        else if ([codePageType isEqualToString:@"CP855"]) return SCBCodePageTypeCP855;
        else if ([codePageType isEqualToString:@"CP857"]) return SCBCodePageTypeCP857;
        else if ([codePageType isEqualToString:@"CP858"]) return SCBCodePageTypeCP858;
        else if ([codePageType isEqualToString:@"CP860"]) return SCBCodePageTypeCP860;
        else if ([codePageType isEqualToString:@"CP861"]) return SCBCodePageTypeCP861;
        else if ([codePageType isEqualToString:@"CP862"]) return SCBCodePageTypeCP862;
        else if ([codePageType isEqualToString:@"CP863"]) return SCBCodePageTypeCP863;
        else if ([codePageType isEqualToString:@"CP864"]) return SCBCodePageTypeCP864;
        else if ([codePageType isEqualToString:@"CP865"]) return SCBCodePageTypeCP866;
        else if ([codePageType isEqualToString:@"CP869"]) return SCBCodePageTypeCP869;
        else if ([codePageType isEqualToString:@"CP874"]) return SCBCodePageTypeCP874;
        else if ([codePageType isEqualToString:@"CP928"]) return SCBCodePageTypeCP928;
        else if ([codePageType isEqualToString:@"CP932"]) return SCBCodePageTypeCP932;
        else if ([codePageType isEqualToString:@"CP999"]) return SCBCodePageTypeCP999;
        else if ([codePageType isEqualToString:@"CP1001"]) return SCBCodePageTypeCP1001;
        else if ([codePageType isEqualToString:@"CP1250"]) return SCBCodePageTypeCP1250;
        else if ([codePageType isEqualToString:@"CP1251"]) return SCBCodePageTypeCP1251;
        else if ([codePageType isEqualToString:@"CP1252"]) return SCBCodePageTypeCP1252;
        else if ([codePageType isEqualToString:@"CP2001"]) return SCBCodePageTypeCP2001;
        else if ([codePageType isEqualToString:@"CP3001"]) return SCBCodePageTypeCP3001;
        else if ([codePageType isEqualToString:@"CP3002"]) return SCBCodePageTypeCP3002;
        else if ([codePageType isEqualToString:@"CP3011"]) return SCBCodePageTypeCP3011;
        else if ([codePageType isEqualToString:@"CP3012"]) return SCBCodePageTypeCP3012;
        else if ([codePageType isEqualToString:@"CP3021"]) return SCBCodePageTypeCP3021;
        else if ([codePageType isEqualToString:@"CP3041"]) return SCBCodePageTypeCP3041;
        else if ([codePageType isEqualToString:@"CP3840"]) return SCBCodePageTypeCP3840;
        else if ([codePageType isEqualToString:@"CP3841"]) return SCBCodePageTypeCP3841;
        else if ([codePageType isEqualToString:@"CP3843"]) return SCBCodePageTypeCP3843;
        else if ([codePageType isEqualToString:@"CP3845"]) return SCBCodePageTypeCP3845;
        else if ([codePageType isEqualToString:@"CP3846"]) return SCBCodePageTypeCP3846;
        else if ([codePageType isEqualToString:@"CP3847"]) return SCBCodePageTypeCP3847;
        else if ([codePageType isEqualToString:@"CP3848"]) return SCBCodePageTypeCP3848;
        else if ([codePageType isEqualToString:@"UTF8"]) return SCBCodePageTypeUTF8;
        else if ([codePageType isEqualToString:@"Blank"]) return SCBCodePageTypeBlank;
        else return SCBCodePageTypeCP998;
    } else
        return SCBCodePageTypeCP998;
}

-(SCBCutPaperAction)getCutPaperAction:(NSString *)cutPaperAction {
    if (cutPaperAction != nil && cutPaperAction != (id)[NSNull null]){
        if([cutPaperAction isEqualToString:@"FullCut"]) return SCBCutPaperActionFullCut;
        else if([cutPaperAction isEqualToString:@"FullCutWithFeed"]) return SCBCutPaperActionFullCutWithFeed;
        else if([cutPaperAction isEqualToString:@"PartialCut"]) return SCBCutPaperActionPartialCut;
        else if([cutPaperAction isEqualToString:@"PartialCutWithFeed"]) return SCBCutPaperActionPartialCutWithFeed;
        else return SCBCutPaperActionPartialCutWithFeed;
    }else
        return SCBCutPaperActionPartialCutWithFeed;
}
-(SCBPeripheralChannel) getPeripheralChannel:(NSNumber *)peripheralChannel{
    if (peripheralChannel != nil ){
        if([peripheralChannel intValue]  == 1) return SCBPeripheralChannelNo1;
        else if([peripheralChannel intValue] == 2) return SCBPeripheralChannelNo2;
        else return SCBPeripheralChannelNo1;
    }else
        return SCBPeripheralChannelNo1;
}
-(SCBBlackMarkType) getBlackMarkType:(NSString *) blackMarkType{
    if (blackMarkType != nil && blackMarkType != (id)[NSNull null]){
        if([blackMarkType isEqualToString:@"Valid"]) return SCBBlackMarkTypeValid;
        else if([blackMarkType isEqualToString:@"Invalid"]) return SCBBlackMarkTypeInvalid;
        else if([blackMarkType isEqualToString:@"ValidWithDetection"]) return SCBBlackMarkTypeValidWithDetection;
            else return SCBBlackMarkTypeValid;
    }else
        return SCBBlackMarkTypeValid;
}
-(SCBLogoSize) getLogoSize:(NSString *) logoSize{
    if (logoSize != nil && logoSize != (id)[NSNull null]){
        if([logoSize isEqualToString:@"Normal"]) return SCBLogoSizeNormal;
        else if([logoSize isEqualToString:@"DoubleWidth"]) return SCBLogoSizeDoubleWidth;
        else if([logoSize isEqualToString:@"DoubleHeight"]) return SCBLogoSizeDoubleHeight;
        else if([logoSize isEqualToString:@"DoubleWidthDoubleHeight"]) return SCBLogoSizeDoubleWidthDoubleHeight;
        else return SCBLogoSizeNormal;
    }else
  return SCBLogoSizeNormal;
}
-(SCBBarcodeSymbology) getBarcodeSymbology:(NSString *) barcodeSymbology{
    if (barcodeSymbology != nil && barcodeSymbology != (id)[NSNull null]){
        if([barcodeSymbology isEqualToString:@"Code128"]) return SCBBarcodeSymbologyCode128;
        else if([barcodeSymbology isEqualToString:@"Code39"]) return SCBBarcodeSymbologyCode39;
        else if([barcodeSymbology isEqualToString:@"Code93"]) return SCBBarcodeSymbologyCode128;
        else if([barcodeSymbology isEqualToString:@"ITF"]) return SCBBarcodeSymbologyITF;
        else if([barcodeSymbology isEqualToString:@"JAN8"]) return SCBBarcodeSymbologyJAN8;
        else if([barcodeSymbology isEqualToString:@"JAN13"]) return SCBBarcodeSymbologyJAN13;
        else if([barcodeSymbology isEqualToString:@"NW7"]) return SCBBarcodeSymbologyNW7;
        else if([barcodeSymbology isEqualToString:@"UPCA"]) return SCBBarcodeSymbologyUPCA;
        else if([barcodeSymbology isEqualToString:@"UPCE"]) return SCBBarcodeSymbologyUPCE;
        else return SCBBarcodeSymbologyCode128;
    }else
        return SCBBarcodeSymbologyCode128;
}
-(SCBBarcodeWidth) getBarcodeWidth:(NSString *) barcodeWidth{
    if (barcodeWidth != nil && barcodeWidth != (id)[NSNull null]){
        if([barcodeWidth isEqualToString:@"Mode1"]) return SCBBarcodeWidthMode1;
        else if([barcodeWidth isEqualToString:@"Mode2"]) return SCBBarcodeWidthMode2;
        else if([barcodeWidth isEqualToString:@"Mode3"]) return SCBBarcodeWidthMode3;
        else if([barcodeWidth isEqualToString:@"Mode4"]) return SCBBarcodeWidthMode4;
        else if([barcodeWidth isEqualToString:@"Mode5"]) return SCBBarcodeWidthMode5;
        else if([barcodeWidth isEqualToString:@"Mode6"]) return SCBBarcodeWidthMode6;
        else if([barcodeWidth isEqualToString:@"Mode7"]) return SCBBarcodeWidthMode7;
        else if([barcodeWidth isEqualToString:@"Mode8"]) return SCBBarcodeWidthMode8;
        else if([barcodeWidth isEqualToString:@"Mode9"]) return SCBBarcodeWidthMode9;
        else return SCBBarcodeWidthMode2;
    }else
        return SCBBarcodeWidthMode2;
}
-(SCBQrCodeModel) getQrCodeModel:(NSString *) qrCodeModel{
    if (qrCodeModel != nil && qrCodeModel != (id)[NSNull null]){
        if([qrCodeModel isEqualToString:@"No1"]) return SCBQrCodeModelNo1;
        else if([qrCodeModel isEqualToString:@"No2"]) return SCBQrCodeModelNo2;
        else return SCBQrCodeModelNo1;
    }else
        return SCBQrCodeModelNo1;
}
-(SCBQrCodeLevel) getQrCodeLevel:(NSString *) qrCodeLevel {
    if (qrCodeLevel != nil && qrCodeLevel != (id)[NSNull null]){
        if([qrCodeLevel isEqualToString:@"H"]) return SCBQrCodeLevelH;
        else if([qrCodeLevel isEqualToString:@"L"]) return SCBQrCodeLevelL;
        else if([qrCodeLevel isEqualToString:@"M"]) return SCBQrCodeLevelM;
        else if([qrCodeLevel isEqualToString:@"Q"]) return SCBQrCodeLevelQ;
        else return SCBQrCodeLevelH;
    }else
        return SCBQrCodeLevelH;
}
-(SCBBitmapConverterRotation) getBitmapConverterRotation:(NSString *) rotation {
    if (rotation != nil && rotation != (id)[NSNull null]){
        if([rotation isEqualToString:@"Normal"]) return SCBBitmapConverterRotationNormal;
        else if([rotation isEqualToString:@"Left90"]) return SCBBitmapConverterRotationLeft90;
        else if([rotation isEqualToString:@"Right90"]) return SCBBitmapConverterRotationRight90;
        else if([rotation isEqualToString:@"Rotate180"]) return SCBBitmapConverterRotationRotate180;
        else return SCBBitmapConverterRotationNormal;
    }else
        return SCBBitmapConverterRotationNormal;
}

@end
