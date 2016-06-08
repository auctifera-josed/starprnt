# StarPRNT Plugin

Cordova plugin for [Star micronics printers](http://www.starmicronics.com/printer/home.aspx)

How to use:

Install using `cordova plugin add https://github.com/auctifera-josed/starprnt`

This is based on the work from the guys at [InteractiveObject](https://github.com/InteractiveObject/StarIOPlugin)

## API

var printer = window.starprnt;

### Port/Printer discovery

#### Syntax
`portDiscovery(type,success,error)`

#### Parameters
##### type*
Port types are: 'All', 'Bluetooth', 'USB', 'LAN'

#### Description
The portDiscovery function gets a list of ports where star printers are currently connected.

#### Example
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

### Connect to the printer 

#### Syntax
`connect(port,callback)`
#### Parameters

##### port*
The port of the printer. e.g. BT:9100

#### Description
The connect function allows to 'connect' to the printer, to keep alive the connection between the device and the printer.

**you need to connect before printing out**

#### Example

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

### Print receipt

#### Syntax
`printReceipt(port, receipt, success, error, [alignment, international, font])`

#### Parameters

##### port*
The port of the printer. e.g. BT:9100

##### receipt*
The text to be printed. e.g. "Star Clothing Boutique\n123 Star Road\nCity, State 12345\n"

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

#### Example

```
printer.printReceipt('BT:9100',
	'Hello World',
	function(res){
		console.log(res);
	},
	function(res){
		console.log(res);
	},
	'left',
	'US',
	'A'
);
``` 



