package task.amazon.chime

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenShareService : Service() {
    companion object {
        const val CHANNEL_ID = "screen_share_channel"
        const val CHANNEL_NAME = "Screen Sharing"
        const val NOTIFICATION_ID = 1002
        const val ACTION_START = "task.amazon.chime.action.START_SCREEN_SHARE"
        const val ACTION_STOP = "task.amazon.chime.action.STOP_SCREEN_SHARE"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForegroundInternal()
            ACTION_STOP -> stopForegroundInternal()
            else -> startForegroundInternal()
        }
        return START_STICKY
    }

    private fun startForegroundInternal() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW)
            manager.createNotificationChannel(channel)
        }
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen sharing active")
            .setContentText("Your screen is being shared")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun stopForegroundInternal() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
}
