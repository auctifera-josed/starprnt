# StarPRNT Plugin

Cordova plugin for [Star micronics printers](http://www.starmicronics.com/printer/home.aspx)

This plugin defines global cordova.starprnt object.

Although in the global scope, it is not available until after the deviceready event.
```javascript
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(cordova.starprnt);
}
```

## Install

Install using `cordova plugin add https://github.com/auctifera-josed/starprnt`

## Example

`var printer = cordova.starprnt;//window.starprnt, cordova.plugins.starprnt`

```javascript
printer.portDiscovery('All',
	function(res){
		console.log(res);
	},
	function(err){
		console.log(err);
	}
)
```
Log will be something like: [{modelName: "Star Micronics", macAddress: "", portName: "BT:9100"}]
```javascript
printer.connect('BT:9100',
	function(err,res){
		if(err)
			console.log(err);
		else 
			console.log(res);
	}
)
```
true = success | false = error

```javascript
printer.printReceipt('BT:9100',
	'Hello World',
	function(res){
		console.log(res);
	},
	function(res){
		console.log(res);
	},
	'12345'
	'left',
	'US',
	'A'
);
```

## API

### Port/Printer discovery
The `portDiscovery(type, success, error)` function gets a list of ports where star printers are currently connected.
`portDiscovery(type,success,error)`

#### type*
Port types are: 'All', 'Bluetooth', 'USB', 'LAN'
#### success*/error*
callbacks

### Connect to the printer 
The `connect` function allows to 'connect' to the printer, to keep alive the connection between the device and the printer.

**you need to connect before printing out**
`connect(port,callback)`

#### port*
The port of the printer. e.g. BT:9100

#### callback*
callback

### Print formatted receipt
The `printFormattedReceipt(port, JSON.stringify(receipt), success, error)` function allows to print a receipt on a predefined format with 3 sections (header, body and footer), each section with multiple **optional** parameters.

#### port*
The port of the printer. e.g. BT:9100

#### receipt* **Remember to send it as a string with JSON.stringify()**
The formatted (as JSON) receipt as follows:

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
#### success*/error*
callbacks

### Print ticket
The `printTicket(port, ticket, success, error)` function allows to print a given ticket previously formatted, it supports some customizations.

#### port*
The port of the printer. e.g. BT:9100

#### ticket* **Remember to send it as a string with JSON.stringify()**
The formatted (as JSON) ticket as follows:

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

### Print receipt
The `printReceipt(port, receipt, success, error[, receiptId, alignment, international, font])` function allows to print a given text to the printer connected at the given port, it supports the customization of alignment, international chars and font style. 
`printReceipt(port, receipt, success, error, [receiptId, alignment, international, font])`

#### port*
The port of the printer. e.g. BT:9100

#### receipt*
The text to be printed. e.g. "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n"

#### success*/error*
callbacks

#### receiptId
Text to be printed as QR code at the end of the receipt. Null or undefined will avoid printing QR code

#### alignment (optional)
Alignment of the text, options are:
- left
- center
- right

#### international (optional)
The international character mode, options are:
- US
- FR
- UK

#### font (optional)
Font style, options are:
- A: SCBFontStyleTypeA ... Font-A (12 x 24 dots) /
Specify 7 x 9 font (half dots)
- B: CBFontStyleTypeB ... Font-B (9 x 24 dots) / Specify 5 x 9 font (2P-1)

### Print Data
The `printData(port, data, success, error)`

### Printer events

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
      break;
    case 'printerCoverClose':
      break;
    case 'printerImpossible':
      break;
    case 'printerOnline':
      break;
    case 'printerOffline':
      break;
    case 'printerPaperEmpty':
      break;
    case 'printerPaperNearEmpty':
      break;
    case 'printerPaperReady':
      break;
  }
});
```

**Note:** This is based on the work from the guys at [InteractiveObject](https://github.com/InteractiveObject/StarIOPlugin)



