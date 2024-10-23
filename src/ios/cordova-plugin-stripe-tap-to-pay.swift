@objc(CDVStripeTapToPay) class CDVStripeTapToPay : CDVPlugin {
    // var gallery: GalleryController!
    // let editor: VideoEditing = VideoEditor();
    // var returncommand: CDVInvokedUrlCommand!;
    // var args: CDVImageGalleryOptions!;
    @objc(echo:)
    func echo(_ command:){
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: "successful communication!"
        )
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}
