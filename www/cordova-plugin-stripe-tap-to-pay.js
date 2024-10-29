var exec = require('cordova/exec');
exports.initialize = function(callback,failureCallback,options){
  if(options.callbacks){
    window.cordova.plugins.stripeTapToPay.callbacks=options.callbacks;
    delete options.callbacks;
  }else{
    window.cordova.plugins.stripeTapToPay.callbacks={};
  }
  return exec(callback, failureCallback, "CDVStripeTapToPay", "initialize", [options]);  
}
exports.log = function(msg){
  console.log('<==stripeTapToPay==> '+msg);
}
exports.callbackHandler = function(method,data){
  var defaultCallbacks={
    onFailReaderDiscovery:function(){console.log('onFailReaderDiscovery')},
    onSuccessReaderDiscovery:function(){console.log('onSuccessReaderDiscovery')},
    onFailPaymentIntent:function(){console.log('onFailPaymentIntent')},
    onFailPaymentMethodCollect:function(){console.log('onFailPaymentMethodCollect')},
    onSuccessfulPaymentMethodCollect:function(){console.log('onSuccessfulPaymentMethodCollect')},
    onSuccessfulPaymentIntent:function(resp){console.log('onSuccessfulPaymentIntent',resp)},
    onCreatePaymentIntentFail:function(){console.log('onCreatePaymentIntentFail')},
    onSuccessfulReaderConnect:function(){console.log('onSuccessfulReaderConnect')},
    onFailReaderConnect:function(){console.log('onFailReaderConnect')},
    didReportUnexpectedReaderDisconnect:function(){console.log('didReportUnexpectedReaderDisconnect')},
    didChangeConnectionStatus:function(){console.log('didChangeConnectionStatus')},
    didChangePaymentStatus:function(){console.log('didChangePaymentStatus')},
    didStartInstallingUpdate:function(){console.log('didStartInstallingUpdate')},
    errorInstalling:function(){console.log('errorInstalling')},
    successInstalling:function(){console.log('successInstalling')},
    onDownloadProgress:function(data){console.log('onDownloadProgress',data)},
    onProgress:function(prog){console.log(prog)}
  }
  var incrimentProgress=['onSuccessfulPaymentMethodCollect','onSuccessReaderDiscovery','onSuccessfulReaderConnect','successInstalling','onDownloadProgress'];
  if(method=='onSuccessReaderDiscovery'){
    window.cordova.plugins.stripeTapToPay.progress=0;
  }
  if(incrimentProgress.indexOf(method)>=0){
    window.cordova.plugins.stripeTapToPay.progress++;
    if(window.cordova.plugins.stripeTapToPay.callbacks.onProgress) window.cordova.plugins.stripeTapToPay.callbacks.onProgress(window.cordova.plugins.stripeTapToPay.progress)
  }
  if(window.cordova.plugins.stripeTapToPay.callbacks[method]){
    if(data) window.cordova.plugins.stripeTapToPay.callbacks[method](data);
    else window.cordova.plugins.stripeTapToPay.callbacks[method]();
  }else if(defaultCallbacks[method]){
    if(data) defaultCallbacks[method](data);
    else defaultCallbacks[method]();
  }else{
    alert('Callback Method ['+method+'] not found in initialize options.callbacks');
  }
}