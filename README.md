cordova-plugin-stripe-tap-to-pay
===================

Usage
```
cordova.plugins.stripeTapToPay.initialize(function(){
	console.log('success')
	},function(err){
	console.log(err);
},{
	amount:1000,//amount in USD cents
	simulated:false,//true||false,//you will need to do false until you get permission from apple
	description:"descriptor on charge/payment",
	merchantName:"Merchant Name",
	locationId:"location ID from Stripe",
	tokenUrl:"<url>",
	callbacks:{
		onFailReaderDiscovery:function(){console.log('onFailReaderDiscovery')},
	    onSuccessReaderDiscovery:function(){console.log('onSuccessReaderDiscovery')},
	    onFailPaymentIntent:function(){console.log('onFailPaymentIntent')},
	    onFailPaymentMethodCollect:function(){console.log('onFailPaymentMethodCollect')},
	    onFailConfirmPaymentIntent:function(){console.log('onFailConfirmPaymentIntent')},
    onSuccessConfirmPaymentIntent:function(){console.log('onSuccessConfirmPaymentIntent')},
	    onSuccessfulPaymentMethodCollect:function(){console.log('onSuccessfulPaymentMethodCollect')},
	    onSuccessfulPaymentIntent:function(resp){console.log('onSuccessfulPaymentIntent')},
	    onCreatePaymentIntentFail:function(){console.log('onCreatePaymentIntentFail')},
	    onSuccessfulReaderConnect:function(){console.log('onSuccessfulReaderConnect')},
	    onFailReaderConnect:function(){console.log('onFailReaderConnect')},
	    didReportUnexpectedReaderDisconnect:function(){console.log('didReportUnexpectedReaderDisconnect')},
	    didChangeConnectionStatus:function(){console.log('didChangeConnectionStatus')},
	    didChangePaymentStatus:function(){console.log('didChangePaymentStatus')},
	    didStartInstallingUpdate:function(){console.log('didStartInstallingUpdate')},
	    errorInstalling:function(){console.log('errorInstalling')},
	    successInstalling:function(){console.log('successInstalling')},
	    onDownloadProgress:function(data){console.log('onDownloadProgress',data)}
	}
})
```
## License

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
