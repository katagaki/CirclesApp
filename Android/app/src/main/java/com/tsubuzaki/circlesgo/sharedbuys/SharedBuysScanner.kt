package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import androidx.core.net.toUri
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning

/**
 * Scans the code shown by SharedBuysSheet and hands back the join URL.
 *
 * The code is a circles-app://buys-join link, so a member who already has the app can
 * point the system camera at it and be taken straight in. A guest cannot: they arrive at
 * a login screen with no way to feed it a URL. This is that way in.
 *
 * Play Services owns the camera here, which is why Guest Mode needs no CAMERA permission
 * and no viewfinder of its own -- the trade is that a device without Play Services cannot
 * scan, and reports that through onError.
 */
object SharedBuysScanner {

    fun scan(
        context: Context,
        onJoin: (android.net.Uri) -> Unit,
        onCancel: () -> Unit = {},
        onError: (Exception) -> Unit = {}
    ) {
        val options = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .enableAutoZoom()
            .build()
        GmsBarcodeScanning.getClient(context, options)
            .startScan()
            .addOnSuccessListener { barcode ->
                val raw = barcode.rawValue
                if (raw == null) {
                    onCancel()
                    return@addOnSuccessListener
                }
                val uri = runCatching { raw.toUri() }.getOrNull()
                // Anything that is not a join link is somebody else's QR code. Whether
                // the key inside a link that does look right is usable is join()'s call
                // to make, not ours.
                if (uri?.scheme == "circles-app" && uri.host == SharedBuysSession.JOIN_HOST) {
                    onJoin(uri)
                } else {
                    onCancel()
                }
            }
            .addOnCanceledListener { onCancel() }
            .addOnFailureListener { error -> onError(error as? Exception ?: Exception(error)) }
    }
}
