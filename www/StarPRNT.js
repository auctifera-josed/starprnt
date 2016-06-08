var exec = require('cordova/exec');

exports.printReceipt = function(port, receipt, success, error, alignment, international, font) {
    exec(success, error, "StarPRNT", "printReceipt", [port, receipt, alignment, international, font]);
};

exports.portDiscovery = function(type, success, error) {
    exec(success, error, "StarPRNT", "portDiscovery", [type]);
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
