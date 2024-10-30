var exec = require('cordova/exec');
exports.hello=function (input, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "CDVStripeTapToPay", "hello", [input]);
}
exports.ensurePermissions=function (input, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "CDVStripeTapToPay", "ensurePermissions", [input]);
}
exports.checkVersion=function(){
  var failure_reason='';
  if(!window.device){
    return 'this is only available in phonegap/cordova app';
  }
  if(window.device.platform=='iOS'){
    var versionInfo=window.device.version.split('.');
    //var versionInfo=('16.2').split('.');
    var minVersion='16.4';
    // var testMinVersionFail='17.7';
    // minVersion=testMinVersionFail;
    minVersionInfo=minVersion.split('.');
    var ios_fcb_msg='Minimum iOS version is '+minVersion+', you are currently running iOS version '+window.device.version+'.  Please update your device OS.';
    var info={
      min:{
        major:parseInt(minVersionInfo[0],10),
        minor:parseInt(minVersionInfo[1],10)
      },
      current:{
        major:parseInt(versionInfo[0],10),
        minor:parseInt(versionInfo[1],10)
      }
    }
    //console.log(info);
    if(info.current.major<=info.min.major){
      if(info.current.major==info.min.major){
        if(info.current.minor<info.min.minor){
          failure_reason=ios_fcb_msg;
        }
      }else{
        failure_reason=ios_fcb_msg;
      }
    }
  }
  if(window.device.platform=='Android'){

  }
  return failure_reason;
}
exports.initialize = function(callback,failureCallback,options){
  //version detect
  if(this.checkVersion()) return failureCallback(this.checkVersion())
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
    onFailConfirmPaymentIntent:function(){console.log('onFailConfirmPaymentIntent')},
    onSuccessConfirmPaymentIntent:function(){console.log('onSuccessConfirmPaymentIntent')},
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