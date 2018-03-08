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
    //Android functions

    printImage: function (port, emulation, printObj, success, error) {  //connects to printer and disconnects when done
        exec(success, error, "StarPRNT", "printRasterData", [port, emulation, printObj]);
    },

// iOS only functions

    openCashDrawer: function (port, emulation, success, error) {
        exec(success, error, "StarPRNT", "openCashDrawer", [port, emulation]);
    },
    printReceipt: function (receipt, success, error, receiptId, alignment, international, font) {
        exec(success, error, "StarPRNT", "printData", [receipt, receiptId, alignment, international, font]);
    },
    printData: function (text, success, error) {
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
    // setPrintDirection: function(, direction, success, error) {
    //     exec(success, error, "StarPRNT", "setPrintDirection", [, direction]);
    // },
    hardReset: function(success, error) {
        exec(success, error, "StarPRNT", "hardReset", []);
    },
    disconnect: function (success, error) {
        exec(success, error, "StarPRNT", "disconnect", []);
    },
    connect: function (printerPort, callback) {
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
        }, 'StarPRNT', 'connect', [printerPort]);
    }
};

