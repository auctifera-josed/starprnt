var exec = require('cordova/exec');

module.exports = {

    //Android and iOS functions

    portDiscovery: function(type, success, error) {
        exec(success, error, "StarPRNT", "portDiscovery", [type]);
    },
    checkStatus: function (port, emulation, success, error) {
        exec(success, error, 'StarPRNT', 'checkStatus', [port, emulation]);
    },
    printRawText: function (port, emulation, printObj, success, error) {  //connects to printer and disconnects when done
        exec(success, error, "StarPRNT", "printRawText", [port, emulation, printObj]);
    },
    printRasterReceipt: function (port, emulation, printObj, success, error) {  //connects to printer and disconnects when done
        exec(success, error, "StarPRNT", "printRasterReceipt", [port, emulation, printObj]);
    },

    printImage: function (port, emulation, printObj, success, error) {  //connects to printer and disconnects when done
        exec(success, error, "StarPRNT", "printRasterData", [port, emulation, printObj]);
    },

    openCashDrawer: function (port, emulation, success, error) {
        exec(success, error, "StarPRNT", "openCashDrawer", [port, emulation]);
    },

    print: function(port, emulation, printCommands, success, error){ //exposes all methods for the CommandBuilderInterface / ISCBBuilderInterface
        exec(success, error, "StarPRNT", "print", [port, emulation, printCommands]);
    },
    disconnect: function (success, error) {
        exec(success, error, "StarPRNT", "disconnect", []);
    },
    connect: function (printerPort, emulation, hasBarcodeReader, callback) {
        var connected = false;
        exec(function (result) {
            if (!connected) {
                callback(null, result);
                connected = true;
            } else {
                cordova.fireWindowEvent("starPrntData", result);
            }
        },
        function (error) {
            callback(error)
        }, 'StarPRNT', 'connect', [printerPort, emulation, !!hasBarcodeReader]);
    },

// iOS only functions (Deprecated, use Super function print to access all the CommandBuilderInterface/ISCBBuilderInterface methods )

    printReceipt: function (receipt, success, error, receiptId, alignment, international, font) {
        exec(success, error, "StarPRNT", "printData", [receipt, receiptId, alignment, international, font]);
    },
    printData: function (text, emulation, success, error) {
        exec(success, error, "StarPRNT", "printRawData", [text]);
    },
    printFormattedReceipt: function(receipt, success, error) {
        exec(success, error, "StarPRNT", "printReceipt", [receipt]);
    },
    printTicket: function(ticket, success, error) {
        exec(success, error, "StarPRNT", "printTicket", [ticket]);
    },
    activateBlackMarkSensor: function(success, error) {
        exec(success, error, "StarPRNT", "activateBlackMarkSensor", []);
    },
    cancelBlackMarkSensor: function(success, error) {
        exec(success, error, "StarPRNT", "cancelBlackMarkSensor", []);
    },
    setDefaultSettings: function(success, error) {
        exec(success, error, "StarPRNT", "setToDefaultSettings", []);
    },
    hardReset: function(success, error) {
        exec(success, error, "StarPRNT", "hardReset", []);
    }
};

