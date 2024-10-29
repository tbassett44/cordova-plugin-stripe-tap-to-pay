import StripeTerminal
import UIKit


extension Encodable {
    
    func toJSONString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
    
}
func instantiate<T: Decodable>(jsonString: String) -> T? {
    return try? JSONDecoder().decode(T.self, from: jsonString.data(using: .utf8)!)
}

@objc(CDVStripeTapToPay)
public class CDVStripeTapToPay: CDVPlugin, ConnectionTokenProvider,LocalMobileReaderDelegate, DiscoveryDelegate {
    private var pendingConnectionTokenCompletionBlock: ConnectionTokenCompletionBlock?
    private var pendingInstallUpdate: Cancelable?
    private var pendingCollectPaymentMethod: Cancelable?
    private var pendingReaderAutoReconnect: Cancelable?
    private var currentUpdate: ReaderSoftwareUpdate?
    private var currentPaymentIntent: PaymentIntent?
    private var cancelDiscoverReadersCall: CDVInvokedUrlCommand?
    private var isInitialized: Bool = false
    private var discoverCancelable: Cancelable?
    private var collectCancelable: Cancelable?
    static let shared = CDVStripeTapToPay()
    struct TapToPayOptions: Codable {
        var amount: UInt = 0;
        var intentClientSecret: String = "";
        var currency: String = "";
        var description: String = "";
        var locationId: String = "";
        var merchantName: String = "";
        var tokenUrl: String = "";
        var simulated: Bool = false;
    }
    private var TapToPayOptionsData=TapToPayOptions();
    struct PaymentIntentResponse: Codable {
        var stripeId: String = ""
        var offline: Bool = false
    }
    struct downloadProgress: Codable {
        var progress: Float = 0;
    }
    private var thread = DispatchQueue.init(label: "CapacitorStripeTerminal")

    private var readers: [Reader]?
    // Action for a "Discover Readers" button
    // ...
    func loadOptions(_ command: CDVInvokedUrlCommand) -> Bool{
        let opts=(command.arguments[0] as AnyObject);
        if((opts.value(forKey: "amount")) != nil){
            self.TapToPayOptionsData.amount=opts.value(forKey: "amount") as! UInt
        }
        if((opts.value(forKey: "intentClientSecret")) != nil){
            self.TapToPayOptionsData.intentClientSecret=opts.value(forKey: "intentClientSecret") as! String
        }
        if((opts.value(forKey: "currency")) != nil){
            self.TapToPayOptionsData.currency=opts.value(forKey: "currency") as! String
        }
        if((opts.value(forKey: "locationId")) != nil){
            self.TapToPayOptionsData.locationId=opts.value(forKey: "locationId") as! String
        }
        if((opts.value(forKey: "merchantName")) != nil){
            self.TapToPayOptionsData.merchantName=opts.value(forKey: "merchantName") as! String
        }
        if((opts.value(forKey: "tokenUrl")) != nil){
            self.TapToPayOptionsData.tokenUrl=opts.value(forKey: "tokenUrl") as! String
        }
        if((opts.value(forKey: "description")) != nil){
            self.TapToPayOptionsData.description=opts.value(forKey: "description") as! String
        }
        if((opts.value(forKey: "simulated")) != nil){
            self.TapToPayOptionsData.simulated=opts.value(forKey: "simulated") as! Bool
        }
        if(self.TapToPayOptionsData.currency.isEmpty){
            self.TapToPayOptionsData.currency="usd";//default
        }
        if(self.TapToPayOptionsData.amount <= 0){
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "error - amount must be more than 0"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return false;
        }
        if(self.TapToPayOptionsData.merchantName.isEmpty){
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "error - merchantName must be set"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return false;
        }
        if(self.TapToPayOptionsData.locationId.isEmpty){
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "error - locationId must be set"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return false;
        }
        if(self.TapToPayOptionsData.tokenUrl.isEmpty){
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "error - tokenUrl must be set"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return false;
        }
        if(self.TapToPayOptionsData.description.isEmpty){
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "error - description must be set"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return false;
        }
        return true;
    }
    @objc func initialize(_ command: CDVInvokedUrlCommand) {
        //load in options!
        self.sendLogToPlugin("Initialize!");
        if(!self.loadOptions(command)){
            return;//stop execution
        }
        print("===OPTIONS====")
        print(self.TapToPayOptionsData);
        //DispatchQueue.main.async {
            if !self.isInitialized {
                Terminal.setTokenProvider(self)
               //Terminal.shared.delegate = self.appDelegate()

                Terminal.setLogListener { logline in
                    self.onLogEntry(logline: logline)
                }
                // Terminal.shared.logLevel = LogLevel.verbose;

//                self.cancelDiscoverReaders(command)
//                self.cancelInstallUpdate(command)
                self.isInitialized = true
            }else{
                self.sendLogToPlugin("Trying to cancel a previously started reader");
                Terminal.shared.disconnectReader { error in
                    if let error = error {
                    } else {
                    }
                }
            }
        self.cancelDiscoverReaders();
        self.cancelInstallUpdate();
        //disconect if already connected!?!
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: "success"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            self.discoverReaders();
        //}
    }
    // Action for a "Discover Readers" button
    @objc func discoverReaders() {
        do {
            let config = try LocalMobileDiscoveryConfigurationBuilder().setSimulated(self.TapToPayOptionsData.simulated).build()
            
            self.discoverCancelable = Terminal.shared.discoverReaders(config, delegate: self) { error in
                self.discoverCancelable=nil;
                if let error = error {
                    self.sendLogToPlugin("discoverReaders failed: \(error)");
                    self.sendToPlugin("onFailReaderDiscovery");
                } else {
                    self.sendLogToPlugin("discoverReaders succeeded")
                    self.sendToPlugin("onSuccessReaderDiscovery");
                }
            }
        }catch{
            self.sendLogToPlugin("Error in discoverReaders");
        }
    }
    @objc func retrievePaymentIntent() {
        // ... Fetch the client secret from your backend
        Terminal.shared.retrievePaymentIntent(clientSecret: self.TapToPayOptionsData.intentClientSecret) { retrieveResult, retrieveError in
            if let error = retrieveError {
                self.sendLogToPlugin("retrievePaymentIntent failed: \(error)")
            }
            else if let paymentIntent = retrieveResult {
                self.sendLogToPlugin("retrievePaymentIntent succeeded: \(paymentIntent)")
                // ...
            }
        }
    }
    func sendToPlugin(_ action : String){
        self.commandDelegate!.evalJs("window.cordova.plugins.stripeTapToPay.callbackHandler('"+action+"')");
    }
    func sendDataToPlugin(_ action : String, _ data : Codable){
        let jsonStr = data.toJSONString()
        self.commandDelegate!.evalJs("window.cordova.plugins.stripeTapToPay.callbackHandler('"+action+"',"+jsonStr+")");
    }
    func sendLogToPlugin(_ str : String){
        print(str);
        self.commandDelegate!.evalJs("window.cordova.plugins.stripeTapToPay.log('"+str+"')");
    }
    @objc func createPaymentIntent() {
        do{
            let params = try PaymentIntentParametersBuilder(amount: self.TapToPayOptionsData.amount, currency: self.TapToPayOptionsData.currency).setStripeDescription(self.TapToPayOptionsData.description).build()
        Terminal.shared.createPaymentIntent(params) { createResult, createError in
            if let error = createError {
                self.sendLogToPlugin("createPaymentIntent failed: \(error)")
                self.sendToPlugin("onFailPaymentIntent");
            } else if let paymentIntent = createResult {
                self.sendLogToPlugin("createPaymentIntent succeeded")
                self.collectCancelable = Terminal.shared.collectPaymentMethod(paymentIntent) { collectResult, collectError in
                    if let error = collectError {
                        self.sendLogToPlugin("collectPaymentMethod failed: \(error)")
                        self.sendToPlugin("onFailPaymentMethodCollect");
                    } else if let collectPaymentMethodPaymentIntent = collectResult {
                        self.sendLogToPlugin("collectPaymentMethod succeeded")
                        self.sendToPlugin("onSuccessfulPaymentMethodCollect");
                        // ... Confirm the payment
                        Terminal.shared.confirmPaymentIntent(collectPaymentMethodPaymentIntent) { confirmResult, confirmError in
                            if let error = confirmError {
                                self.sendLogToPlugin("confirmPaymentIntent failed: \(error)")
                            } else if let confirmedPaymentIntent = confirmResult {
                                self.sendLogToPlugin("confirmPaymentIntent succeeded")
                                // Notify your backend to capture the PaymentIntent
                                if let stripeId = confirmedPaymentIntent.stripeId {
                                    self.sendLogToPlugin("Stripe ID: "+stripeId);
                                    let PaymentIntentResponse=PaymentIntentResponse(stripeId:stripeId,offline: false);
                                    self.sendDataToPlugin("onSuccessfulPaymentIntent",PaymentIntentResponse);
                                } else {
                                    self.sendLogToPlugin("Payment collected offline");
                                    let PaymentIntentResponse=PaymentIntentResponse(stripeId:confirmedPaymentIntent.stripeId ?? "",offline: true);
                                    self.sendDataToPlugin("onSuccessfulPaymentIntent",PaymentIntentResponse);
                                }
                            }
                        }
                    }
                }
            }
        }
        }catch{
            self.sendLogToPlugin("createPaymentIntent param builder fail");
            self.sendToPlugin("onCreatePaymentIntentFail");
            return;
        }
    }
    // MARK: DiscoveryDelegate
    func ensurePaymentIntent(){
        if(self.TapToPayOptionsData.intentClientSecret.isEmpty){
            self.createPaymentIntent();
        }else{
            self.retrievePaymentIntent();
        }
    }
    public func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        guard let reader = readers.first else { return }
        self.sendLogToPlugin("got reader!");
        do{
            let connectionConfig = try LocalMobileConnectionConfigurationBuilder.init(locationId: self.TapToPayOptionsData.locationId).setMerchantDisplayName(self.TapToPayOptionsData.merchantName).build()
            Terminal.shared.connectLocalMobileReader(reader, delegate: self, connectionConfig: connectionConfig) { reader, error in
                if let reader = reader {
                    self.sendLogToPlugin("Successfully connected to reader");
                    self.sendToPlugin("onSuccessfulReaderConnect");
                    self.ensurePaymentIntent()
                } else if let error = error {
                    self.sendLogToPlugin("connectLocalMobileReader failed: \(error)")
                    self.sendToPlugin("onFailReaderConnect");
                }
            }
        }catch{
            self.sendLogToPlugin("error connectLocalMobileReader");
            self.sendToPlugin("onFailReaderConnect");
        }
        
    }
    // MARK: TerminalDelegate

    @objc public func terminal(_: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
        self.sendLogToPlugin("didReportUnexpectedReaderDisconnect")
        self.sendToPlugin("didReportUnexpectedReaderDisconnect");
    }

    @objc public func terminal(_: Terminal, didChangeConnectionStatus status: ConnectionStatus) {
        self.sendLogToPlugin("didChangeConnectionStatus")
        self.sendToPlugin("didChangeConnectionStatus");
    }

    @objc public func terminal(_: Terminal, didChangePaymentStatus status: PaymentStatus) {
        self.sendLogToPlugin("didChangePaymentStatus")
        self.sendToPlugin("didChangePaymentStatus");
    }
    // MARK: LocalMobileReaderDelegate

    public func localMobileReader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        pendingInstallUpdate = cancelable
        currentUpdate = update
        self.sendLogToPlugin("didStartInstallingUpdate")
        self.sendToPlugin("didStartInstallingUpdate");
        //notifyListeners("didStartInstallingUpdate", data: ["update": StripeTerminalUtils.serializeUpdate(update: update)])
    }

    public func localMobileReader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        //notifyListeners("didReportReaderSoftwareUpdateProgress", data: ["progress": progress])
        self.sendLogToPlugin("didReportReaderSoftwareUpdateProgress: "+String(progress));
        var downloadProgress=downloadProgress(progress: progress);
         self.sendDataToPlugin("onDownloadProgress",downloadProgress);
    }

    public func localMobileReader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let error = error {
            self.sendLogToPlugin("error installing");
             self.sendToPlugin("errorInstalling");
            //notifyListeners("didFinishInstallingUpdate", data: ["error": error.localizedDescription as Any])
        } else if let update = update {
            //notifyListeners("didFinishInstallingUpdate", data: ["update": StripeTerminalUtils.serializeUpdate(update: update)])
            currentUpdate = nil
            self.sendLogToPlugin("done installing");
            self.sendToPlugin("successInstalling");
        }
    }
    
    public func localMobileReader(_: Reader, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
       // notifyListeners("didRequestReaderInput", data: ["value": inputOptions.rawValue])
        self.sendLogToPlugin("didRequestReaderInput")
    }

    public func localMobileReader(_: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        //notifyListeners("didRequestReaderDisplayMessage", data: ["value": displayMessage.rawValue])
        self.sendLogToPlugin("didRequestReaderDisplayMessage")
    }
    
    public func localMobileReaderDidAcceptTermsOfService(_: Reader) {
        //notifyListeners("localMobileReaderDidAcceptTermsOfService", data: nil)
        self.sendLogToPlugin("localMobileReaderDidAcceptTermsOfService")
    }
    public func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        guard let url = URL(string: self.TapToPayOptionsData.tokenUrl) else {
            fatalError("Invalid backend URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    // Warning: casting using `as? [String: String]` looks simpler, but isn't safe:
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let secret = json?["secret"] as? String {
                        completion(secret, nil)
                    }
                    else {
                        let error = NSError(domain: "com.stripe-terminal-ios.example",
                                            code: 2000,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing `secret` in ConnectionToken JSON response"])
                        completion(nil, error)
                    }
                }
                catch {
                    completion(nil, error)
                }
            }
            else {
                let error = NSError(domain: "com.stripe-terminal-ios.example",
                                    code: 1000,
                                    userInfo: [NSLocalizedDescriptionKey: "No data in response from ConnectionToken endpoint"])
                completion(nil, error)
            }
        }
        task.resume()
    }
    
//    @objc func getPermissions(_ command: CDVInvokedUrlCommand) {
//           requestPermissions(command)
//       }

//       @objc override public func checkPermissions(_ command: CDVInvokedUrlCommand) {
//           var pluginResult = CDVPluginResult(
//               status: CDVCommandStatus_OK,
//               messageAs: "not implimented"
//           )
//           self.commandDelegate!.send(
//               pluginResult,
//               callbackId: command.callbackId
//           )
//       }
//
//       @objc override public func requestPermissions(_ command: CDVInvokedUrlCommand) {
//           var pluginResult = CDVPluginResult(
//               status: CDVCommandStatus_OK,
//               messageAs: "not implimented"
//           )
//           self.commandDelegate!.send(
//               pluginResult,
//               callbackId: command.callbackId
//           )
//       }
    func onLogEntry(logline _: String) {
        // self.notifyListeners("log", data: ["logline": logline])
    }
    @objc func cancelDiscoverReaders() {
        print("cancelDiscoverReaders")
            guard let cancelable = discoverCancelable else {
                return
            }
            print("CANCEL")
            cancelable.cancel() { error in
                if let error = error as NSError? {
                    
                } else {
                    // do not call resolve, let discoverReaders call it when it is actually complete
                    //self.cancelDiscoverReadersCall = command
                    self.discoverCancelable = nil
                }
            }
            
        }
    @objc func cancelInstallUpdate() {
            if let cancelable = pendingInstallUpdate {
                cancelable.cancel { error in
                    if let error = error {
                        //call?.reject(error.localizedDescription, nil, error)
                    } else {
                        self.pendingInstallUpdate = nil
                       //call?.resolve()
                    }
                }

                return
            }
        }
}
