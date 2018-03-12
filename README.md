# StarPRNT Plugin

Cordova plugin for using [Star micronics printers](http://www.starmicronics.com/pages/All-Products) from a cordova, phonegap or Ionic application.

**Note:** This is based on the work from the guys at [InteractiveObject](https://github.com/InteractiveObject/StarIOPlugin)

This plugin defines global starprnt object.

Although in the global scope, it is not available until after the deviceready event.
```javascript
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(starprnt);
}
```

# Example
**Ionic 1 example app:** [https://github.com/infoxicator/StarprntDemo-Ionic1](https://github.com/infoxicator/StarprntDemo-Ionic1)


# Install

Cordova: `cordova plugin add https://github.com/auctifera-josed/starprnt`
Ionic 2+: `ionic cordova plugin add https://github.com/auctifera-josed/starprnt`

**Warning:** when updating you should run first `ionic cordova plugin rm cordova-plugin-starprnt` and then install again

# Example

```javascript
starprnt.portDiscovery('All', 
function(result){ console.log(result)}, function(error){ console.log(error) });
```
Success Log Example: ```console[{modelName: "TSP700II", macAddress: "00:00:00:00", portName: "TCP:192.168.1.1"}]```

# SMPort Example
SMPort opens the connection to the printer and closes it after the commands are successfully sent.
```javascript

printObj = {
text:"Star Clothing Boutique\n123 Star Road\nCity, State 12345\n\n",
cutReceipt:"true",
openCashDrawer: "true"
}
starprnt.printRawText("TCP:192.168.1.1","StarLine", printObj, 
function(result){console.log(result)}, function(error){ console.log(error) }); 
```

# StarIOExtManager Example
StarIOExtManager Allows you to connect to the printer and listen for hardware events, you will need to manually open and close the connection.

```javascript
starprnt.connect("BT:9100",function(err,res){});
starprnt.printData("Star Clothing Boutique\n123 Star Road\nCity, State 12345\n\n"function(result){
console.log(result)}, function(error){console.log(error)}); 
```
# API Reference: SMPort Android and iOS

- [portDiscovery(type, success, error)](#port-discovery)
- [checkStatus(portName, emulation, success, error)](#check-status)
- [printRawText(portName, emulation, printObj, success, error)](#print-raw-text)
- [printRasterReceipt(portName, emulation, printObj, success, error)](#print-raster-receipt)
- [printImage(portName, emulation, printObj, success, error)](#print-image)


# API Reference: StarIOExtManager iOS only (Android coming soon)
- [activateBlackMarkSensor(success, error)](#activate-black-mark-sensor)
- [cancelBlackMarkSensor(success, error)](#cancel-black-mark-sensor)
- [connect(printerPort, drawerPort, callback)](#connect)
- [disconnect(success, error)](#disconnect)
- [hardReset(success, error)](#hard-reset)
- [openCashDrawer(success, error)](#open-cash-drawer)
- [portDiscovery(type, success, error)](#port-discovery)
- [printData(text, success, error)](#print-data)
- [printFormattedReceipt(receipt, success, error)](#print-formatted-receipt)
- [printReceipt(receipt, success, error[, receiptId, alignment, international, font])](#print-receipt)
- [printTicket(ticket, success, error)](#print-ticket)
- [setDefaultSettings(success, error)](#set-default-settings)

# SMPort Functions
SMPort opens the connection to the printer and closes it after the commands are successfully sent.
Almost all the methods take success an error functions as parameters, these are callback functions to execute in either case. They are not listed in the parameters for simplicity.

Note: asterisk (*) indicates a required parameter

## Check Status
The `checkStatus(portName, emulation, success, error)` returns the current status of the printer, as well as model number and firmware information.

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| portName* | Port name returned by portDiscovery | String: "TCP:192.168.1.1" |
| emulation* | Emulation type depending on the printer model | String: [Emulation](#emulation) |

## Print Raw Text
The `printRawText(portName, emulation, printObj, success, error)` prints text without formatting

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| portName* | Port name returned by portDiscovery | String: "TCP:192.168.1.1" |
| emulation* | Emulation type depending on the printer model | String: [Emulation](#emulation) |
| printObj* | Object containing the text and printer options | Object: Example Below |

```javascript
var printObj = {
text:"Star Clothing Boutique\n123 Star Road\nCity, State 12345\n\n",
cutReceipt:"true", // optional - Defaults to true
openCashDrawer: "true" // optional -Defaults to true
}
```

## Print Raster Receipt

The `printRasterReceipt(portName, emulation, printObj, success, error)`  converts the text into an bitmap image and prints on the desired paper width and font size

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| portName* | Port name returned by portDiscovery | String: "TCP:192.168.1.1" |
| emulation* | Emulation type depending on the printer model | String: [Emulation](#emulation) |
| printObj* | Object containing the text and printer options | Object: Example Below |

```javascript
var printObj = {
        text : "        Star Clothing Boutique\n" +
        "             123 Star Road\n" +
        "           City, State 12345\n" +
        "\n" +
        "Date:MM/DD/YYYY          Time:HH:MM PM\n" +
        "--------------------------------------\n" +
        "SALE\n" +
        "SKU            Description       Total\n" +
        "300678566      PLAIN T-SHIRT     10.99\n" +
        "300692003      BLACK DENIM       29.99\n" +
        "300651148      BLUE DENIM        29.99\n" +
        "300642980      STRIPED DRESS     49.99\n" +
        "30063847       BLACK BOOTS       35.99\n" +
        "\n" +
        "Subtotal                        156.95\n" +
        "Tax                               0.00\n" +
        "--------------------------------------\n" +
        "Total                          $156.95\n" +
        "--------------------------------------\n" +
        "\n" +
        "Charge\n" +
        "156.95\n" +
        "Visa XXXX-XXXX-XXXX-0123\n" +
        "Refunds and Exchanges\n" +
        "Within 30 days with receipt\n" +
        "And tags attached\n",
        fontSize: 25,       //Defaults to 25
        paperWidth: 576,    // options: 384 = 2", 576 = 3", 832 = 4"
        cutReceipt:"true", // Defaults to true
        openCashDrawer:"true" // Defaults to true
        };
```

## Print Image

The `printImage(portName, emulation, printObj, success, error)` prints a picture from the photo library or camera

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| portName* | Port name returned by portDiscovery | String: "TCP:192.168.1.1" |
| emulation* | Emulation type depending on the printer model | String: [Emulation](#emulation) |
| printObj* | Object containing the URI and printer options | Object: Example Below |

```javascript
 var printObj = {
    uri: 'file:///var/mobile/Containers/Data/Application/1B4B8C4C-6487-45AB-B950-0AC3633542F5/tmp/cdv_photo_002.jpg',
    width: 576 // options: 384 = 2", 576 = 3", 832 = 4"
    cutReceipt:"true", // Defaults to true
    openCashDrawer:"true" // Defaults to true
};
```


# StarIOExtManager Functions
Almost all the methods take success an error functions as parameters, this are callback functions to execute in either case. They are not listed in the parameters for simplicity.

Note: asterisk (*) indicates a required parameter

E.g: 
```javascript
var callbackFunction = function(r){console.log(r);}
```

## Open Cash Drawer
The `openCashDrawer(success, error)` function sends an open command to the drawer.

Example:
```javascript
//All print commands also call openCashDrawer method, but you can call it directly if required
starprnt.openCashDrawer(q,q);
```

## Port discovery
The `portDiscovery(type, success, error)` function gets a list of ports where star printers are currently connected.

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| type* | Port types are: 'All', 'Bluetooth', 'USB', 'LAN' | String |

## Connect
The `connect(printerPort, function(err,res){})` function allows to 'connect' to the peripheral, to keep alive the connection between the device and the peripheral.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| printerPort | The printer port  | String: "BT:9100" |
| callback* | A callback function | function(err, res){} |

Example:
```javascript
starprnt.connect("BT:9100",function(err,res){});
```

**Notes:**
- You need to connect before printing out
- You should call this function on app **resume** event if you have disconnected on **pause** event

## Disconnect
The `disconnect(success, error)` function allows to disconnect (i.e. close the connection to the peripherals), this is useful to avoid keeping alive a connection when not in the app to save device battery (or energy consumption).

**Notes:**
- You should call this function on app **pause** event

## Print formatted receipt
The `printFormattedReceipt(JSON.stringify(receipt), success, error)` function allows to print a receipt on a predefined format with 3 sections (header, body and footer), each section with multiple **optional** parameters.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| receipt* | The formatted (as JSON) receipt. **Remember to send it as a string with JSON.stringify()**  | String (see example below) |

Receipt parameter JSON description:
1. International: Sets the international for the entire receipt, options are:
    - US
    - FR
    - UK
2. paper_inches: not yet implemented (will be use to support different paper size)
3. transaction_id: The receipt ID to be printed center-bottom of the receipt
4. barcode: Boolean value to indicate if the transaction_id should be displayed with a barcode
5. barcode_type: The type of barcode to print, options are:
    - QR (2D)
    - Code39 (1D)
5. barcode_cell_size: When using QR (2D), this is the size of the QR code
5. font: The font for the entire receipt, options are: 
    - A
    - B (currently font B has weird behaviour due to different width)
6. divider: If true, a dashed divider will be shown below the section
7. alignment: can be set separately for header, body and footer 
8. header
    - date: Needs to be exactly of length 10 to display correctly
    - time: Needs to be exactly of length 5 to display correctly
9. body
    - product_list: An array of objects, all children's fields (quantity, description, amount) are required in order to display an item
10. footer
    - notice
    - invert: If true, the title will be shown with black background and white letters (inverted)

JSON example:
```javascript
{
  "international": "EN",
  "paper_inches": 3, /*For future development*/
  "transaction_id": "P-1235667",
  "barcode": true,
  "barcode_type":"QR",
  "barcode_cell_size": 8,
  "font": "A",
  "header": {
    "company_name": "Veevart",
    "company_street": "False Street 123",
    "company_country": "City, State 12345",
    "seller": "Seller: Amy",
    "date": "01/01/2016",
    "time": "13:24",
    "divider": true,
    "alignment": "center"
  },
  "body": {
    "subtotal": "$100",
    "tax": "$10",
    "total": "$110",
    "product_list": [
      {
        "quantity": 1,
        "description": "description1",
        "amount": 50.0
      },
      {
        "quantity": 2,
        "description": "description2",
        "amount": 25.0
      }
    ],
    "divider": true
  },
  "footer": {
    "phone": "55555555",
    "fax": "44444444",
    "email": "fake@email.com",
    "notice": {
      "title": "Refunds and Exchanges",
      "text": "Within 30 days with receipt",
      "invert" : true
    },
    "alignment": "left"
  }
}
```

## Print ticket
The `printTicket(JSON.stringify(ticket), success, error)` function allows to print a given ticket previously formatted, it supports some customizations.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| ticket* | The formatted (as JSON) ticket. **Remember to send it as a string with JSON.stringify()** | String (see example below) |

Ticket parameter JSON description:
1. font: The font for the entire receipt, options are: 
    - A
    - B
2. margin: //Uses the left edge as a standard to set the left margin as (current ANK character pitch x n).
    2. left: n; 
    2. right: n;
3. barcode_type: The type of barcode to print, options are:
    - QR (2D)
    - Code39 (1D)
3. barcode_cell_size: When using QR (2D), this is the size of the QR code
4. space_to_removable: lines from address to removable
5. space_to_address: lines from date to address

JSON example:
```
{
  "font": "A",
  "margin": {
    "left": 4,
    "right": 2
  },
  "type": "Reservation",
  "type_abbr": "RE",
  "ticket_id": "R-123123",
  "barcode_left_margin": 8,
  "barcode_type": "QR",
  "barcode_cell_size": 8,
  "website": "www.veevart.com",
  "space_to_removable": 3,
  "title": "Veevart",
  "title_font_size": 4,
  "subtitle": "Picasso Exposition",
  "subtitle_font_size": 1,
  "date": "June 21, 2017",
  "space_to_address": 11,
  "place": "Museum",
  "address": {
    "street": "123 Street",
    "city": "New York, NY, 10001"
  }
}
```

## Print Data
The `printData(text, success, error)` function, prints a given text to the printer of the given port.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| text* | The text to be printed | String: "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n" |

## Activate Black Mark Sensor
The `activateBlackMarkSensor(success, error)` function, activates the black mark sensor in the printer.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |

## Cancel Black Mark Sensor
The `cancelBlackMarkSensor(success, error)` function, deactivates the black mark sensor in the printer.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |

## Set Default Settings
The `setDefaultSettings(success, error)` resets the printer to default settings.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |

## Hard Reset
The `hardReset(success, error)` function, resets (doesn't change configurations) the printer and executes a self print.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port | The printer port  | String: "BT:9100" |

## Print receipt
The `printReceipt(receipt, success, error, receiptId, alignment, international, font)` function allows to print a given text to the printer connected at the given port, it supports the customization of alignment, international chars and font style. 

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| receipt* | The text to be printed. | String: "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n" |
| receiptId | Text to be printed as QR code at the end of the receipt. Null or undefined will avoid printing QR code | String: "R-12322" |
| alignment | Alignment of the text, options are: left, center, right | String: "center" |
| international | The international character mode, options are: US, FR, UK | String: "US" |
| font | Font style, options are: A (12 x 24 dots), B (9 x 24 dots) | String: "A" |

# Events
Listen to printer events as cases of the **starPrntData** event, cases are:

## Printer Events
- Printer cover open: printerCoverOpen
- Printer cover close: printerCoverClose
- Printer impossible: printerImpossible
- Printer online: printerOnline 
- Printer offline: printerOffline
- Printer paper empty: printerPaperEmpty
- Printer paper near empty: printerPaperNearEmpty
- Printer paper ready: printerPaperReady

## Cash Drawer Events
- Cash drawer open: cashDrawerOpen
- Cash drawer close: cashDrawerClose

```javascript
window.addEventListener('starPrntData', function (e) {
  switch (e.dataType) {
    case 'printerCoverOpen':
      console.log(data);
      break;
    default:
      console.log(data);
      break;
  }
});
```

## Emulation

Source: Star SDK Documentation
| Printer Models | Emulation | 
| ----------- | -------- |
| mPOP  | StarPRNT |
| FVP10  | StarLine |
| TSP100  | StarGraphic |
| TSP650II  | StarLine |
| TSP700II  | StarLine |
| TSP800II  | StarLine |
| SP700  | StarDotImpact |
| SM-S210i  | EscPosMobile |
| SM-S220i  | EscPosMobile |
| SM-S230i  | EscPosMobile |
| SM-T300i/T300  | EscPosMobile |
| SM-T400i  | EscPosMobile |
| SM-L200  | StarPRNT |
| SM-L300  | StarPRNT |
| BSC10  | EscPos |
| SM-S210i StarPRNT  | StarPRNT |
| SM-S220i StarPRNT | StarPRNT |
| SM-S230i StarPRNT | StarPRNT |
| SM-T300i/T300 StarPRNT  | StarPRNT |
| SM-T400i StarPRNT  | StarPRNT |


