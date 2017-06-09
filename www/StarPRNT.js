var exec = require('cordova/exec');

module.exports = {
    openCashDrawer: function (port, success, error) {
        exec(success, error, "StarPRNT", "openCashDrawer", [port]);
    },
    printReceipt: function (port, receipt, success, error, receiptId, alignment, international, font) {
        exec(success, error, "StarPRNT", "printData", [port, receipt, receiptId, alignment, international, font]);
    },
    printData: function (port, text, success, error) {
        exec(success, error, "StarPRNT", "printRawData", [port, text]);
    },
    printFormattedReceipt: function(port, receipt, success, error) {
        exec(success, error, "StarPRNT", "printReceipt", [port, receipt]);
    },
    printTicket: function(port, ticket, success, error) {
        exec(success, error, "StarPRNT", "printTicket", [port, ticket]);
    },
    portDiscovery: function(type, success, error) {
        exec(success, error, "StarPRNT", "portDiscovery", [type]);
    },
    activateBlackMarkSensor: function(port, success, error) {
        exec(success, error, "StarPRNT", "activateBlackMarkSensor", [port]);
    },
    cancelBlackMarkSensor: function(port, success, error) {
        exec(success, error, "StarPRNT", "cancelBlackMarkSensor", [port]);
    },
    setDefaultSettings: function(port, success, error) {
        exec(success, error, "StarPRNT", "setToDefaultSettings", [port]);
    },
    // setPrintDirection: function(port, direction, success, error) {
    //     exec(success, error, "StarPRNT", "setPrintDirection", [port, direction]);
    // },
    hardReset: function(port, success, error) {
        exec(success, error, "StarPRNT", "hardReset", [port]);
    },
    disconnect: function (success, error) {
        exec(success, error, "StarPRNT", "disconnect", []);
    },
    connect: function (printerPort, drawerPort, callback) {
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
        }, 'StarPRNT', 'connect', [printerPort, drawerPort]);
    }
};

