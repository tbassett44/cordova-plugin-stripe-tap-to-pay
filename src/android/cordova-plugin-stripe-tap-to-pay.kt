package cordova.plugin

import android.Manifest
import org.apache.cordova.*
import org.json.JSONArray
import org.json.JSONException
import android.util.Log
import com.stripe.*
import java.io.*
import java.net.*
import com.stripe.stripeterminal.external.callable.*
import com.stripe.stripeterminal.*
import com.stripe.stripeterminal.log.*
import android.app.Application
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.stripe.stripeterminal.external.models.*

private val CordovaWebViewEngine.webView: Any
    get() {
        return this;
    }
class StripeTerminalApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        TerminalApplicationDelegate.onCreate(this)
    }
}
class CustomConnectionTokenProvider : ConnectionTokenProvider {
    var tokenUrl: String=""
    fun getJsonDataFromUrl(url: String): JsonObject {
        val connection = URL(url).openConnection()
        val reader = BufferedReader(InputStreamReader(connection.getInputStream()))
        val jsonData = StringBuilder()

        var line: String?
        while (reader.readLine().also { line = it } != null) {
            jsonData.append(line)
        }
        reader.close()
        val jsonObject: JsonObject = Gson().fromJson(jsonData.toString(), JsonObject::class.java)

        return jsonObject;
    }
    override fun fetchConnectionToken(callback: ConnectionTokenCallback) {
        try {
            // Your backend should call /v1/terminal/connection_tokens and return the
            // JSON response from Stripe. When the request to your backend succeeds,
            // return the `secret` from the response to the SDK.
            println("trying to load secret");
            val apiResponse =getJsonDataFromUrl(tokenUrl);
            println(apiResponse);
            callback.onSuccess(apiResponse["secret"].asString);
        } catch (e: Exception) {

        }
    }
}
data class CDVStripeTapToPayOptions(
    val locationId: String,
    val amount: Long,
    val simulated: Boolean,
    val tokenUrl: String
)
class CDVStripeTapToPay : CordovaPlugin() {
    lateinit var context: CallbackContext
    var discoverCancelable: Cancelable? = null
    var REQUEST_CODE_LOCATION: Int = 0;
    @Throws(JSONException::class)
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        context = callbackContext
        var result = true
        try {
            if(action == "ensurePermissions"){
                if (ActivityCompat.checkSelfPermission(cordova.context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    val permissions = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
                    // Define the REQUEST_CODE_LOCATION on your app level
                    ActivityCompat.requestPermissions(cordova.activity, permissions, REQUEST_CODE_LOCATION)
                }
            }
            if (action == "initialize") {
                val input = data.getString(0)
                val options: CDVStripeTapToPayOptions? = Gson().fromJson(input, CDVStripeTapToPayOptions::class.java)
                val locationId= options!!.locationId;
                val simulated= options!!.simulated;
                val amount= options!!.amount;
                val tokenUrl= options!!.tokenUrl;
                //if one is already going, cancel it!
//                Terminal.getInstance().disconnectReader(
//                    object : Callback {
//                        override fun onSuccess() {
//                            // Placeholder for handling successful operation
//                            //println("onSuccessReaderDiscovery")
//                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessReaderDisconnect')");
//                        }
//
//                        override fun onFailure(e: TerminalException) {
//                            // Placeholder for handling exception
//                           // println("onFailReaderDiscovery")
//                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailReaderDisconnect')");
//                        }
//                    }
//                )
                //Terminal.getInstance().clearCachedCredentials();
                val listener = object : TerminalListener {
                    override fun onUnexpectedReaderDisconnect(reader: com.stripe.stripeterminal.external.models.Reader) {
                        println("onUnexpectedReaderDisconnect")
                    }
                }
                val logLevel = LogLevel.VERBOSE
                val tokenProvider = CustomConnectionTokenProvider()
                tokenProvider.tokenUrl=tokenUrl;
                // Pass in the current application context, your desired logging level, your token provider, and the listener you created
                if (!Terminal.isInitialized()) {
                    Terminal.initTerminal(cordova.context, logLevel, tokenProvider, listener)
                }
                val config = DiscoveryConfiguration.LocalMobileDiscoveryConfiguration(
                    isSimulated = simulated,
                )
                disconnectReader();
                discoverCancelable = Terminal.getInstance().discoverReaders(
                    config,
                    object : DiscoveryListener {
                        override fun onUpdateDiscoveredReaders(readers: List<com.stripe.stripeterminal.external.models.Reader>) {
                            println("onUpdateDiscoveredReaders")
                            val config = ConnectionConfiguration.LocalMobileConnectionConfiguration(locationId)
                            Terminal.getInstance().connectLocalMobileReader(
                                readers[0],
                                config,
                                object : ReaderCallback {
                                    override fun onSuccess(reader: com.stripe.stripeterminal.external.models.Reader) {
                                        // Placeholder for handling successful operation
                                        evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessfulReaderConnect')");
                                        val params = PaymentIntentParameters.Builder()
                                            .setAmount(amount)
                                            .setCurrency("usd")
                                            .build()
                                        Terminal.getInstance().createPaymentIntent(
                                            params,
                                            object : PaymentIntentCallback {
                                                override fun onSuccess(paymentIntent: PaymentIntent) {
                                                    // Placeholder for handling successful operation
                                                    val cancelable = Terminal.getInstance().collectPaymentMethod(
                                                        paymentIntent,
                                                        object : PaymentIntentCallback {
                                                            override fun onSuccess(paymentIntent: PaymentIntent) {
                                                                evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessfulPaymentMethodCollect')");
                                                                // Placeholder for handling successful operation
                                                                Terminal.getInstance().confirmPaymentIntent(
                                                                    paymentIntent,
                                                                    object : PaymentIntentCallback {
                                                                        override fun onSuccess(paymentIntent: PaymentIntent) {
                                                                            // Placeholder handling successful operation
                                                                            val stripeId=paymentIntent.id;
                                                                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessfulPaymentIntent',{stripeId:\"$stripeId\"})");
                                                                        }

                                                                        override fun onFailure(e: TerminalException) {
                                                                            // Placeholder for handling exception
                                                                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailConfirmPaymentIntent')")
                                                                        }
                                                                    }
                                                                )
                                                            }

                                                            override fun onFailure(e: TerminalException) {
                                                                // Placeholder for handling exception
                                                                evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailPaymentMethodCollect')");
                                                            }
                                                        }
                                                    )
                                                }

                                                override fun onFailure(e: TerminalException) {
                                                    // Placeholder for handling exception
                                                    evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailPaymentIntent')");
                                                }
                                            }
                                        )
                                    }

                                    override fun onFailure(e: TerminalException) {
                                        // Placeholder for handling exception
                                        evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailReaderConnect')");
                                    }
                                }
                            )
                        }
                    },
                    object : Callback {
                        override fun onSuccess() {
                            // Placeholder for handling successful operation
                            println("onSuccessReaderDiscovery")
                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessReaderDiscovery')");
                        }

                        override fun onFailure(e: TerminalException) {
                            // Placeholder for handling exception
                            println("onFailReaderDiscovery")
                            val msg=e.toString()
                            evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailReaderDiscovery','$msg')");
                        }
                    }
                )
                evaluateJavaScriptInCordova("console.log('Message from plugin!')");
                callbackContext.success("success")

            } else {
                handleError("Invalid action")
                result = false
            }
        } catch (e: Exception) {
            handleException(e)
            result = false
        }

        return result
    }
    private fun evaluateJavaScriptInCordova(jsCode: String) {
        cordova.activity.runOnUiThread {
            // Code to run on the UI thread
            (webView.engine.webView as CordovaWebViewEngine).evaluateJavascript(jsCode) { result ->
                // This callback handles any result from the JavaScript execution
                println("JavaScript execution result: $result")
            }
        }
    }
    private fun disconnectReader(){
        if(Terminal.getInstance().connectedReader != null) Terminal.getInstance().disconnectReader(
            object : Callback {
                override fun onSuccess() {
                    // Placeholder for handling successful operation
                    //println("onSuccessReaderDiscovery")
                    //evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onSuccessReaderDisconnect')");
                }

                override fun onFailure(e: TerminalException) {
                    // Placeholder for handling exception
                    // println("onFailReaderDiscovery")
                    //evaluateJavaScriptInCordova("window.cordova.plugins.stripeTapToPay.callbackHandler('onFailReaderDisconnect')");
                }
            }
        )
    }
    /**
     * Handles an error while executing a plugin API method.
     * Calls the registered Javascript plugin error handler callback.
     *
     * @param errorMsg Error message to pass to the JS error handler
     */
    private fun handleError(errorMsg: String) {
        try {
            Log.e(TAG, errorMsg)
            context.error(errorMsg)
        } catch (e: Exception) {
            Log.e(TAG, e.toString())
        }

    }

    private fun handleException(exception: Exception) {
        handleError(exception.toString())
    }

    companion object {

        protected val TAG = "CDVStripeTapToPay"
    }
}