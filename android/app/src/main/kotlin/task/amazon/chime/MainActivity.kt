package task.amazon.chime

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.app.Activity

class MainActivity : FlutterActivity() {
    private var twilioSdkMethodHandler: TwilioSdkMethodHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Twilio Video SDK method handler
        twilioSdkMethodHandler = TwilioSdkMethodHandler(
            flutterEngine.dartExecutor,
            this
        )
        
        // Register platform view factory for video rendering
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "twilio_video_view",
            TwilioVideoViewFactory(twilioSdkMethodHandler!!)
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        twilioSdkMethodHandler?.dispose()
        twilioSdkMethodHandler = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        twilioSdkMethodHandler?.onScreenCapturePermissionResult(requestCode, resultCode, data)
    }
}
