# StarPRNT Plugin

Cordova plugin for [Star micronics printers](http://www.starmicronics.com/printer/home.aspx)

This plugin defines global starprnt object.

Although in the global scope, it is not available until after the deviceready event.
```javascript
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(starprnt);
}
```

# Install

Install using `cordova plugin add https://github.com/auctifera-josed/starprnt`

# Example

```javascript
var q = function(res){console.log(res)};
starprnt.portDiscovery('All',q,q);
```
Success Log Example: [{modelName: "SAC10", macAddress: "", portName: "BT:DK-AirCash"}, {modelName: "Star Micronics", macAddress: "", portName: "BT:9100"}]

```javascript
starprnt.connect("BT:9100","BT:DK-AirCash",function(err,res){});
starprnt.printData("BT:9100","Star Clothing Boutique\n123 Star Road\nCity, State 12345\n\n",q,q); 
starprnt.openCashDrawer("BT:DK-AirCash",q,q);
```

# API Reference
- [portDiscovery(type, success, error)](#port-discovery)
- [connect(printerPort, drawerPort, callback)](#connect)
- [printFormattedReceipt(port, receipt, success, error)](#print-formatted-receipt)
- [printTicket(port, ticket, success, error)](#print-ticket)
- [printData(port, text, success, error)](#print-data)
- [activateBlackMarkSensor(port, success, error)](#activate-black-mark-sensor)
- [cancelBlackMarkSensor(port, success, error)](#cancel-black-mark-sensor)
- [setDefaultSettings(port, success, error)](#set-default-settings)
- [hardReset(port, success, error)](#hard-reset)
- [printReceipt(port, receipt, success, error[, receiptId, alignment, international, font])](#print-receipt)
- [openCashDrawer(port, success, error)](#open-cash-drawer)

# Functions
Almost all the methods take success an error functions as parameters, this are callback functions to execute in either case. They are not listed in the parameters for simplicity.

* indicates a required parameter

E.g: 
```javascript
var callbackFunction = function(r){console.log(r);}
```

## Open Cash Drawer
The `openCashDrawer(port, success, error)` function sends an open command to the drawer.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The cash drawer port  | String: "BT:DK-AirCash" |

## Port discovery
The `portDiscovery(type, success, error)` function gets a list of ports where star printers are currently connected.

| Paremeter | Description | Type/Example |
| ----------- | -------- | ---------- |
| type* | Port types are: 'All', 'Bluetooth', 'USB', 'LAN' | String |

## Connect
The `connect(printerPort, drawerPort, function(err,res){})` function allows to 'connect' to the peripheral (s), to keep alive the connection between the device and the peripherals (s).

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| printerPort | The printer port  | String: "BT:9100" |
| drawerPort | The cash drawer port  | String: "BT:DK-AirCash" |
| callback* | A callback function | function(err, res){} |

Example:
```javascript
starprnt.connect("BT:9100","BT:DK-AirCash",function(err,res){});
starprnt.connect("BT:9100",null,function(err,res){});
starprnt.connect(undefined,"BT:DK-AirCash",function(err,res){});
```

**Notes:**
- You need to connect before printing out
- You should call this function on app resume event

## Print formatted receipt
The `printFormattedReceipt(port, JSON.stringify(receipt), success, error)` function allows to print a receipt on a predefined format with 3 sections (header, body and footer), each section with multiple **optional** parameters.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |
| receipt* | The formatted (as JSON) receipt. **Remember to send it as a string with JSON.stringify()**  | String (see example below) |

Receipt parameter JSON description:
1. International: Sets the international for the entire receipt, options are:
  - US
  - FR
  - UK
2. paper_inches: not yet implemented (will be use to support different paper size)
3. transaction_id: The receipt ID to be printed center-bottom of the receipt
4. barcode: Boolean value to indicate if the transaction_id should be displayed with a barcode
5. font: The font for the entire receipt, options are: 
  - A
  - B (currently font B has weird behaviour due to different width)
6. divider: If true, a dashed divider will be shown below the section
7. alignment: can be set separately for header, body and footer 
8. header
  8. date: Needs to be exactly of length 10 to display correctly
  8. time: Needs to be exactly of length 5 to display correctly
9. body
  9. product_list: An array of objects, all children's fields (quantity, description, amount) are required in order to display an item
10. footer
  10. notice
    10. invert: If true, the title will be shown with black background and white letters (inverted)

JSON example:
```javascript
{
  "international": "EN",
  "paper_inches": 3, /*For future development*/
  "transaction_id": "P-1235667",
  "barcode": true,
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
The `printTicket(port, ticket, success, error)` function allows to print a given ticket previously formatted, it supports some customizations.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |
| ticket* | The formatted (as JSON) ticket. **Remember to send it as a string with JSON.stringify()** | String (see example below) |

Ticket parameter JSON description:
1. font: The font for the entire receipt, options are: 
  - A
  - B
2. margin: //Uses the left edge as a standard to set the left margin as (current ANK character pitch x n).
  2. left: n; 
  2. right: n;
3. barcode_type: options are:
  - 1D
  - 2D
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
  "barcode_type": "2D",
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
The `printData(port, text, success, error)` function, prints a given text to the printer of the given port.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |
| text* | The text to be printed | String: "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n" |

## Activate Black Mark Sensor
The `activateBlackMarkSensor(port, success, error)` function, activates the black mark sensor in the printer.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |

## Cancel Black Mark Sensor
The `cancelBlackMarkSensor(port, success, error)` function, deactivates the black mark sensor in the printer.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |

## Set Default Settings
The `setDefaultSettings(port, success, error)` resets the printer to default settings.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |

## Hard Reset
The `hardReset(port, success, error)` function, resets (doesn't change configurations) the printer and executes a self print.

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port | The printer port  | String: "BT:9100" |

## Print receipt
The `printReceipt(port, receipt, success, error, receiptId, alignment, international, font)` function allows to print a given text to the printer connected at the given port, it supports the customization of alignment, international chars and font style. 

| Parameter | Description | Type/Example |
| ----------- | -------- | ---------- |
| port* | The printer port  | String: "BT:9100" |
| receipt* | The text to be printed. | String: "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n" |
| receiptId | Text to be printed as QR code at the end of the receipt. Null or undefined will avoid printing QR code | String: "R-12322" |
| alignment | Alignment of the text, options are: left, center, right | String: "center" |
| international | The international character mode, options are: US, FR, UK | String: "US" |
| font | Font style, options are: A (12 x 24 dots), B (9 x 24 dots) | String: "A" |

# Printer events
Listen to printer events as cases of the **starPrntData** event, cases are:

- Printer cover open: printerCoverOpen
- Printer cover close: printerCoverClose
- Printer impossible: printerImpossible
- Printer online: printerOnline 
- Printer offline: printerOffline
- Printer paper empty: printerPaperEmpty
- Printer paper near empty: printerPaperNearEmpty
- Printer paper ready: printerPaperReady

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

**Note:** This is based on the work from the guys at [InteractiveObject](https://github.com/InteractiveObject/StarIOPlugin)



