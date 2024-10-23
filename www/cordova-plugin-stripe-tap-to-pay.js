var exec = require('cordova/exec');
exports.echo = function(callback,failureCallback) {
  return exec(callback, failureCallback, "CDVStripeTapToPay", "echo", []);
};