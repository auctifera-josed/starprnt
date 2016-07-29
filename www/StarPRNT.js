var exec = require('cordova/exec');

exports.printReceipt = function(port, receipt, success, error, receiptId, alignment, international, font) {
    exec(success, error, "StarPRNT", "printData", [port, receipt, receiptId, alignment, international, font]);
};

exports.printFormattedReceipt = function(port, receipt, success, error) {
    exec(success, error, "StarPRNT", "printReceipt", [port, receipt]);
}

exports.portDiscovery = function(type, success, error) {
    exec(success, error, "StarPRNT", "portDiscovery", [type]);
};

exports.setBlackMarkSensor = function(port, success, error) {
    exec(success, error, "StarPRNT", "setBlackMarkSensor", [port]);
};

exports.clearBlackMarkSensor = function(port, success, error) {
    exec(success, error, "StarPRNT", "clearBlackMarkSensor", [port]);
};

exports.connect = function (port, callback) {
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
    }, 'StarPRNT', 'connect', [port]);
}
