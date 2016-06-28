# StarPRNT Plugin

Cordova plugin for [Star micronics printers](http://www.starmicronics.com/printer/home.aspx)

This plugin defines global cordova.starprnt object.

Although in the global scope, it is not available until after the deviceready event.
```
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(cordova.starprnt);
}
```

## Install

Install using `cordova plugin add https://github.com/auctifera-josed/starprnt`

## Example

`var printer = cordova.starprnt;//window.starprnt, cordova.plugins.starprnt`

```
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
```
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

```
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

#### Syntax
`portDiscovery(type,success,error)`

#### Parameters
##### type*
Port types are: 'All', 'Bluetooth', 'USB', 'LAN'
##### success*/error*
callbacks

#### Description
The portDiscovery function gets a list of ports where star printers are currently connected.

### Connect to the printer 

#### Syntax
`connect(port,callback)`
#### Parameters

##### port*
The port of the printer. e.g. BT:9100
##### callback*
callback

#### Description
The connect function allows to 'connect' to the printer, to keep alive the connection between the device and the printer.

**you need to connect before printing out**

### Print receipt

#### Syntax
`printReceipt(port, receipt, success, error, [receiptId, alignment, international, font])`

#### Parameters

##### port*
The port of the printer. e.g. BT:9100

##### receipt*
The text to be printed. e.g. "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n"

##### success*/error*
callbacks

##### receiptId
Text to be printed as QR code at the end of the receipt

##### alignment (optional)
Alignment of the text, options are:
- left
- center
- right

##### international (optional)
The international character mode, options are:
- US
- FR
- UK

##### font (optional)
Font style, options are:
- A: SCBFontStyleTypeA ... Font-A (12 x 24 dots) /
Specify 7 x 9 font (half dots)
- B: CBFontStyleTypeB ... Font-B (9 x 24 dots) / Specify 5 x 9 font (2P-1)

#### Description
The printReceipt function allows to print a given text to the printer connected at the given port, it supports the customization of alignment, international chars and font style. 

### Printer events

#### Syntax
```
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

#### Description
Listen to printer events as cases of the **starPrntData** event, cases are:
- Printer cover open: printerCoverOpen
- Printer cover close: printerCoverClose
- Printer impossible: printerImpossible
- Printer online: printerOnline 
- Printer offline: printerOffline
- Printer paper empty: printerPaperEmpty
- Printer paper near empty: printerPaperNearEmpty
- Printer paper ready: printerPaperReady

**Note:** This is based on the work from the guys at [InteractiveObject](https://github.com/InteractiveObject/StarIOPlugin)



