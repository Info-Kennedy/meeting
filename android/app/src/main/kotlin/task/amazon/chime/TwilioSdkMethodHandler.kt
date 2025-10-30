package task.amazon.chime

import android.content.Context
import android.util.Log
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.platform.PlatformViewRegistry
import com.twilio.video.*
import com.twilio.video.Camera2Capturer
import tvi.webrtc.Camera2Enumerator
import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import task.amazon.chime.ScreenShareService
import android.media.AudioManager

/**
 * Method Channel Handler for Twilio Video SDK
 *
 * This class bridges Flutter calls to Twilio Video SDK for Android.
 *
 * Based on: https://www.twilio.com/docs/video/android-getting-started
 */
class TwilioSdkMethodHandler(
    private val messenger: BinaryMessenger,
    private val context: Context
) : MethodCallHandler {
    private val TAG = "TwilioSdkMethodHandler"

    // Platform channel names
    private val methodChannel = MethodChannel(messenger, "com.twilio.video/twilio_sdk")
    private val participantsEventChannel = EventChannel(messenger, "com.twilio.video/twilio_sdk_participants")
    private val roomEventChannel = EventChannel(messenger, "com.twilio.video/twilio_sdk_events")

    // Twilio Video SDK components
    private var room: Room? = null
    private var localParticipant: LocalParticipant? = null
    private var localVideoTrack: LocalVideoTrack? = null
    private var localAudioTrack: LocalAudioTrack? = null
    private var cameraCapturer: VideoCapturer? = null
    private var camera2Enumerator: Camera2Enumerator? = null

    // State tracking
    private var isAudioEnabled = false
    private var isVideoEnabled = false
    private var isScreenShareActive = false
    private val currentParticipants = mutableMapOf<String, MutableMap<String, Any>>()
    private val participantListeners = mutableMapOf<String, RemoteParticipant.Listener>()

    // Audio routing
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var previousAudioMode: Int = audioManager.mode
    private var previousSpeakerphoneOn: Boolean = audioManager.isSpeakerphoneOn
    
    // Screen share components
    private var screenCapturer: VideoCapturer? = null
    private var screenVideoTrack: LocalVideoTrack? = null
    private var pendingScreenShareResult: Result? = null
    private val REQUEST_SCREEN_CAPTURE = 10001
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingScreenPublish: Boolean = false
    private var screenVideoViewId: Int? = null
    private var screenFirstFrameSeen: Boolean = false
    private var screenInitRetried: Boolean = false
    
    // Video view tracking
    private var localVideoViewId: Int? = null
    private val remoteVideoViewIds = mutableMapOf<String, Int>()
    private val remoteVideoTracks = mutableMapOf<String, RemoteVideoTrack>()
    private var viewIdCounter = 1
    
    // Track which local tracks we've published
    private val publishedLocalAudioTracks = mutableSetOf<LocalAudioTrack>()
    private val publishedLocalVideoTracks = mutableSetOf<LocalVideoTrack>()
    
    // Expose video tracks for platform view factory
    fun getLocalVideoTrack(): LocalVideoTrack? = localVideoTrack
    fun getRemoteVideoTrack(participantId: String): RemoteVideoTrack? = remoteVideoTracks[participantId]
    fun getScreenVideoTrack(): LocalVideoTrack? = screenVideoTrack
    fun getScreenVideoViewId(): Int? = screenVideoViewId

    // Event stream handlers
    private val participantsStreamHandler = ParticipantsStreamHandler()
    private val roomEventStreamHandler = RoomEventStreamHandler()

    private var pendingCameraRepublish: Boolean = false // <--- Add flag for delayed republish

    init {
        methodChannel.setMethodCallHandler(this)

        // Set up event channel streams
        participantsEventChannel.setStreamHandler(participantsStreamHandler)
        roomEventChannel.setStreamHandler(roomEventStreamHandler)

        // Initialize camera enumerator
        camera2Enumerator = Camera2Enumerator(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "connectToRoom" -> {
                connectToRoom(call.arguments as Map<*, *>, result)
            }
            "disconnectFromRoom" -> {
                disconnectFromRoom(result)
            }
            "setAudioEnabled" -> {
                val args = call.arguments as Map<*, *>
                val enabled = args["enabled"] as? Boolean ?: false
                setAudioEnabled(enabled, result)
            }
            "isAudioEnabled" -> {
                result.success(isAudioEnabled)
            }
            "setVideoEnabled" -> {
                val args = call.arguments as Map<*, *>
                val enabled = args["enabled"] as? Boolean ?: false
                setVideoEnabled(enabled, result)
            }
            "isVideoEnabled" -> {
                result.success(isVideoEnabled)
            }
            "startScreenShare" -> {
                startScreenShare(result)
            }
            "stopScreenShare" -> {
                stopScreenShare(result)
            }
            "isScreenShareActive" -> {
                result.success(isScreenShareActive)
            }
            "getParticipants" -> {
                getParticipants(result)
            }
            "getLocalVideoViewId" -> {
                getLocalVideoViewId(result)
            }
            "getRemoteVideoViewId" -> {
                val args = call.arguments as Map<*, *>
                val participantId = args["participantId"] as? String ?: ""
                getRemoteVideoViewId(participantId, result)
            }
            "getLocalScreenShareViewId" -> {
                getLocalScreenShareViewId(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun connectToRoom(arguments: Map<*, *>, result: Result) {
        try {
            val accessToken = arguments["accessToken"] as? String ?: ""
            val roomName = arguments["roomName"] as? String ?: ""
            val identity = arguments["identity"] as? String
            val enableAudio = arguments["enableAudio"] as? Boolean ?: true
            val enableVideo = arguments["enableVideo"] as? Boolean ?: true

            Log.d(TAG, "connectToRoom: roomName=$roomName")

            // Create local audio track
            if (enableAudio && localAudioTrack == null) {
                localAudioTrack = LocalAudioTrack.create(context, true)
            }

            // Create local video track
            if (enableVideo && localVideoTrack == null) {
                if (cameraCapturer == null) {
                    try {
                        // Find front-facing camera using Camera2Enumerator
                        val enumerator = camera2Enumerator
                        if (enumerator != null) {
                            var frontCameraId: String? = null
                            for (cameraId in enumerator.deviceNames) {
                                if (enumerator.isFrontFacing(cameraId)) {
                                    frontCameraId = cameraId
                                    break
                                }
                            }
                            
                            if (frontCameraId != null) {
                                cameraCapturer = Camera2Capturer(context, frontCameraId)
                            } else {
                                // Fallback to first available camera
                                val deviceNamesList = enumerator.deviceNames
                                if (deviceNamesList.isNotEmpty()) {
                                    cameraCapturer = Camera2Capturer(context, deviceNamesList[0])
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error creating camera capturer: ${e.message}", e)
                        cameraCapturer = null
                    }
                }
                val capturer = cameraCapturer
                if (capturer != null) {
                    localVideoTrack = LocalVideoTrack.create(context, true, capturer)
                    // Generate view ID for local video
                    if (localVideoViewId == null) {
                        localVideoViewId = viewIdCounter++
                        Log.d(TAG, "Created local video view ID: $localVideoViewId")
                    }
                }
            }

            // Build connect options
            val connectOptionsBuilder = ConnectOptions.Builder(accessToken)
                .roomName(roomName)

            // Note: Identity is typically set via access token, not ConnectOptions

            // Add audio and video tracks if available
            localAudioTrack?.let { audioTrack ->
                connectOptionsBuilder.audioTracks(listOf<LocalAudioTrack>(audioTrack))
                // Track that this will be published via ConnectOptions
                publishedLocalAudioTracks.add(audioTrack)
            }
            localVideoTrack?.let { videoTrack ->
                connectOptionsBuilder.videoTracks(listOf<LocalVideoTrack>(videoTrack))
                // Track that this will be published via ConnectOptions
                publishedLocalVideoTracks.add(videoTrack)
            }

            val connectOptions = connectOptionsBuilder.build()

            // Connect to room with listener
            room = Video.connect(context, connectOptions, roomListener())

            isAudioEnabled = enableAudio
            isVideoEnabled = enableVideo

            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to room: ${e.message}", e)
            result.error("CONNECT_ERROR", "Failed to connect to room: ${e.message}", null)
        }
    }

    private fun roomListener(): Room.Listener {
        return object : Room.Listener {
            override fun onReconnecting(room: Room, error: TwilioException) {
                Log.d(TAG, "onReconnecting: ${room.name}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "room_reconnecting",
                    "error" to (error.message ?: "")
                ))
            }

            override fun onReconnected(room: Room) {
                Log.d(TAG, "onReconnected: ${room.name}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "room_reconnected",
                    "roomName" to room.name
                ))
            }

            override fun onConnected(room: Room) {
                Log.d(TAG, "onConnected: ${room.name}")
                localParticipant = room.localParticipant

                // Route audio to speaker for better meeting experience
                try {
                    previousAudioMode = audioManager.mode
                    previousSpeakerphoneOn = audioManager.isSpeakerphoneOn
                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    audioManager.isSpeakerphoneOn = true
                } catch (e: Exception) {
                    Log.e(TAG, "Error configuring audio routing: ${e.message}", e)
                }
                
                // Track local participant
                localParticipant?.let { participant ->
                    currentParticipants[participant.identity] = mutableMapOf(
                        "attendeeId" to participant.identity,
                        "name" to participant.identity,
                        "isAudioEnabled" to isAudioEnabled,
                        "isVideoEnabled" to isVideoEnabled
                    )
                }
                
                // Track existing remote participants and attach listeners
                for (rp in room.remoteParticipants) {
                    val pid = rp.identity
                    currentParticipants[pid] = mutableMapOf(
                        "attendeeId" to pid,
                        "name" to pid,
                        "isAudioEnabled" to false,
                        "isVideoEnabled" to false
                    )
                    rp.setListener(remoteParticipantListener(pid))
                }
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())

                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "room_connected",
                    "roomName" to room.name
                ))

                // If screen share was started before participant was ready, publish now
                tryPublishScreenTrack()
                tryRepublishCameraTrack() // <--- Try to republish camera if flagged
            }

            override fun onConnectFailure(room: Room, error: TwilioException) {
                Log.e(TAG, "onConnectFailure: ${error.message}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "room_connect_failure",
                    "error" to (error.message ?: "")
                ))
            }

            override fun onDisconnected(room: Room, error: TwilioException?) {
                Log.d(TAG, "onDisconnected: ${room.name}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "room_disconnected",
                    "error" to (error?.message)
                ))
                // Restore audio routing
                try {
                    audioManager.isSpeakerphoneOn = previousSpeakerphoneOn
                    audioManager.mode = previousAudioMode
                } catch (e: Exception) {
                    Log.e(TAG, "Error restoring audio routing: ${e.message}", e)
                }
                cleanup()
            }

            override fun onParticipantConnected(room: Room, participant: RemoteParticipant) {
                Log.d(TAG, "onParticipantConnected: ${participant.identity}")
                val participantId = participant.identity
                currentParticipants[participantId] = mutableMapOf(
                    "attendeeId" to participantId,
                    "name" to participantId,
                    "isAudioEnabled" to false,
                    "isVideoEnabled" to false
                )
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())

                // Listen to participant's tracks - create and register listener
                val listener = remoteParticipantListener(participantId)
                participantListeners[participantId] = listener
                participant.setListener(listener)
            }

            override fun onParticipantDisconnected(room: Room, participant: RemoteParticipant) {
                Log.d(TAG, "onParticipantDisconnected: ${participant.identity}")
                val participantId = participant.identity
                currentParticipants.remove(participantId)
                participantListeners.remove(participantId)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onRecordingStarted(room: Room) {
                Log.d(TAG, "onRecordingStarted: ${room.name}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "recording_started",
                    "roomName" to room.name
                ))
            }

            override fun onRecordingStopped(room: Room) {
                Log.d(TAG, "onRecordingStopped: ${room.name}")
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "recording_stopped",
                    "roomName" to room.name
                ))
            }
        }
    }

    private fun remoteParticipantListener(participantId: String): RemoteParticipant.Listener {
        return object : RemoteParticipant.Listener {
            override fun onAudioTrackPublished(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication
            ) {
                Log.d(TAG, "onAudioTrackPublished: ${remoteParticipant.identity}")
                // Track published, but not necessarily subscribed
            }

            override fun onVideoTrackPublished(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication
            ) {
                Log.d(TAG, "onVideoTrackPublished: ${remoteParticipant.identity}")
                // Track published, but not necessarily subscribed
            }

            override fun onDataTrackPublished(
                remoteParticipant: RemoteParticipant,
                remoteDataTrackPublication: RemoteDataTrackPublication
            ) {
                Log.d(TAG, "onDataTrackPublished: ${remoteParticipant.identity}")
                // Data track published, but not necessarily subscribed
            }

            override fun onDataTrackUnpublished(
                remoteParticipant: RemoteParticipant,
                remoteDataTrackPublication: RemoteDataTrackPublication
            ) {
                Log.d(TAG, "onDataTrackUnpublished: ${remoteParticipant.identity}")
                // Data tracks don't affect audio/video state, just log it
            }

            override fun onDataTrackSubscribed(
                remoteParticipant: RemoteParticipant,
                remoteDataTrackPublication: RemoteDataTrackPublication,
                remoteDataTrack: RemoteDataTrack
            ) {
                Log.d(TAG, "onDataTrackSubscribed: ${remoteParticipant.identity}")
                // Data tracks don't affect audio/video state, just log it
            }

            override fun onDataTrackSubscriptionFailed(
                remoteParticipant: RemoteParticipant,
                remoteDataTrackPublication: RemoteDataTrackPublication,
                twilioException: TwilioException
            ) {
                Log.e(TAG, "onDataTrackSubscriptionFailed: ${remoteParticipant.identity}, error: ${twilioException.message}")
                // Data track subscription failures don't affect participants list
            }

            override fun onDataTrackUnsubscribed(
                remoteParticipant: RemoteParticipant,
                remoteDataTrackPublication: RemoteDataTrackPublication,
                remoteDataTrack: RemoteDataTrack
            ) {
                Log.d(TAG, "onDataTrackUnsubscribed: ${remoteParticipant.identity}")
                // Data tracks don't affect audio/video state, just log it
            }

            override fun onAudioTrackEnabled(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication
            ) {
                Log.d(TAG, "onAudioTrackEnabled: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isAudioEnabled", true)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onAudioTrackDisabled(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication
            ) {
                Log.d(TAG, "onAudioTrackDisabled: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isAudioEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackEnabled(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication
            ) {
                Log.d(TAG, "onVideoTrackEnabled: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isVideoEnabled", true)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackDisabled(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication
            ) {
                Log.d(TAG, "onVideoTrackDisabled: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isVideoEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onAudioTrackSubscribed(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication,
                remoteAudioTrack: RemoteAudioTrack
            ) {
                Log.d(TAG, "onAudioTrackSubscribed: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isAudioEnabled", true)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackSubscribed(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication,
                remoteVideoTrack: RemoteVideoTrack
            ) {
                Log.d(TAG, "onVideoTrackSubscribed: ${remoteParticipant.identity}")
                // Store the remote video track
                remoteVideoTracks[participantId] = remoteVideoTrack
                // Always generate a NEW view ID for latest track to force Flutter to recreate the view
                remoteVideoViewIds[participantId] = viewIdCounter++
                Log.d(TAG, "Assigned new view ID ${remoteVideoViewIds[participantId]} for participant $participantId (new track)")
                currentParticipants[participantId]?.put("isVideoEnabled", true)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onAudioTrackUnsubscribed(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication,
                remoteAudioTrack: RemoteAudioTrack
            ) {
                Log.d(TAG, "onAudioTrackUnsubscribed: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isAudioEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackUnsubscribed(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication,
                remoteVideoTrack: RemoteVideoTrack
            ) {
                Log.d(TAG, "onVideoTrackUnsubscribed: ${remoteParticipant.identity}")
                // Remove video track when unsubscribed
                remoteVideoTracks.remove(participantId)
                // Note: Don't remove view ID as Flutter might still be using it
                currentParticipants[participantId]?.put("isVideoEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onAudioTrackUnpublished(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication
            ) {
                Log.d(TAG, "onAudioTrackUnpublished: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isAudioEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackUnpublished(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication
            ) {
                Log.d(TAG, "onVideoTrackUnpublished: ${remoteParticipant.identity}")
                currentParticipants[participantId]?.put("isVideoEnabled", false)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onAudioTrackSubscriptionFailed(
                remoteParticipant: RemoteParticipant,
                remoteAudioTrackPublication: RemoteAudioTrackPublication,
                twilioException: TwilioException
            ) {
                Log.e(TAG, "onAudioTrackSubscriptionFailed: ${remoteParticipant.identity}, error: ${twilioException.message}")
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }

            override fun onVideoTrackSubscriptionFailed(
                remoteParticipant: RemoteParticipant,
                remoteVideoTrackPublication: RemoteVideoTrackPublication,
                twilioException: TwilioException
            ) {
                Log.e(TAG, "onVideoTrackSubscriptionFailed: ${remoteParticipant.identity}, error: ${twilioException.message}")
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }
        }
    }

    private fun disconnectFromRoom(result: Result) {
        try {
            Log.d(TAG, "disconnectFromRoom")
            room?.disconnect()
            cleanup()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from room: ${e.message}", e)
            result.error("DISCONNECT_ERROR", "Failed to disconnect from room: ${e.message}", null)
        }
    }

    private fun setAudioEnabled(enabled: Boolean, result: Result) {
        try {
            Log.d(TAG, "setAudioEnabled: $enabled, room connected: ${room != null}, localParticipant: ${localParticipant != null}")
            if (enabled) {
                if (localAudioTrack == null) {
                    localAudioTrack = LocalAudioTrack.create(context, true)
                }
                localAudioTrack?.let { track ->
                    // Only publish if room is connected and participant exists
                    if (room != null && localParticipant != null) {
                        // Check if we've already published this track
                        val isPublished = publishedLocalAudioTracks.contains(track)
                        if (!isPublished) {
                            try {
                                localParticipant?.publishTrack(track)
                                publishedLocalAudioTracks.add(track)
                                Log.d(TAG, "Published audio track")
                            } catch (e: Exception) {
                                Log.e(TAG, "Error publishing audio track: ${e.message}", e)
                            }
                        } else {
                            Log.d(TAG, "Audio track already published")
                        }
                    }
                    isAudioEnabled = true
                } ?: run {
                    isAudioEnabled = false
                    result.error("AUDIO_ERROR", "Failed to create audio track", null)
                    return
                }
            } else {
                localAudioTrack?.let { track ->
                    // Unpublish if track is published
                    if (room != null && localParticipant != null && publishedLocalAudioTracks.contains(track)) {
                        try {
                            localParticipant?.unpublishTrack(track)
                            publishedLocalAudioTracks.remove(track)
                            Log.d(TAG, "Unpublished audio track")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error unpublishing audio track: ${e.message}", e)
                        }
                    }
                    // Release the track
                    track.release()
                    localAudioTrack = null
                }
                isAudioEnabled = false
            }
            // Update local participant state in list
            localParticipant?.let { p ->
                currentParticipants[p.identity]?.put("isAudioEnabled", isAudioEnabled)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }
            roomEventStreamHandler.sendRoomEvent(mapOf(
                "type" to "audioStateChanged",
                "enabled" to enabled
            ))
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting audio enabled: ${e.message}", e)
            result.error("AUDIO_ERROR", "Failed to set audio enabled: ${e.message}", null)
        }
    }

    private fun setVideoEnabled(enabled: Boolean, result: Result) {
        try {
            Log.d(TAG, "setVideoEnabled: $enabled")
            if (enabled) {
                if (localVideoTrack == null) {
                    if (cameraCapturer == null) {
                        try {
                            // Find front-facing camera using Camera2Enumerator
                            val enumerator = camera2Enumerator
                            if (enumerator != null) {
                                var frontCameraId: String? = null
                                for (cameraId in enumerator.deviceNames) {
                                    if (enumerator.isFrontFacing(cameraId)) {
                                        frontCameraId = cameraId
                                        break
                                    }
                                }
                                if (frontCameraId != null) {
                                    cameraCapturer = Camera2Capturer(context, frontCameraId)
                                } else {
                                    val deviceNamesList = enumerator.deviceNames
                                    if (deviceNamesList.isNotEmpty()) {
                                        cameraCapturer = Camera2Capturer(context, deviceNamesList[0])
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error creating camera capturer: ${e.message}", e)
                            cameraCapturer = null
                        }
                    }
                    val capturer = cameraCapturer
                    if (capturer != null) {
                        localVideoTrack = LocalVideoTrack.create(context, true, capturer)
                        if (room != null && localParticipant != null) {
                            try {
                                localParticipant?.publishTrack(localVideoTrack!!)
                                publishedLocalVideoTracks.add(localVideoTrack!!)
                                Log.d(TAG, "Created and published new local video track after turning ON video.")
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to publish new camera track after turning on: ${e.message}", e)
                            }
                        }
                        if (localVideoViewId == null) {
                            localVideoViewId = viewIdCounter++
                        }
                    } else {
                        Log.e(TAG, "No CameraCapturer available for localVideoTrack after turn ON.")
                    }
                } else {
                    // Track exists, ensure it's published if not already
                    localVideoTrack?.let { track ->
                        if (room != null && localParticipant != null) {
                            val isPublished = publishedLocalVideoTracks.contains(track)
                            if (!isPublished) {
                                try {
                                    localParticipant?.publishTrack(track)
                                    publishedLocalVideoTracks.add(track)
                                    Log.d(TAG, "Re-published camera video track after turning video ON.")
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error re-publishing camera video track: ${e.message}", e)
                                }
                            }
                        }
                    }
                }
                isVideoEnabled = true
            } else {
                localVideoTrack?.let { track ->
                    // Unpublish if track is published
                    if (room != null && localParticipant != null && publishedLocalVideoTracks.contains(track)) {
                        try {
                            localParticipant?.unpublishTrack(track)
                            publishedLocalVideoTracks.remove(track)
                            Log.d(TAG, "Unpublished video track")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error unpublishing video track: ${e.message}", e)
                        }
                    }
                    // Release the track
                    track.release()
                    localVideoTrack = null
                }
                isVideoEnabled = false
            }
            // Update local participant state in list
            localParticipant?.let { p ->
                currentParticipants[p.identity]?.put("isVideoEnabled", isVideoEnabled)
                participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            }
            roomEventStreamHandler.sendRoomEvent(mapOf(
                "type" to "videoStateChanged",
                "enabled" to enabled
            ))
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting video enabled: ${e.message}", e)
            result.error("VIDEO_ERROR", "Failed to set video enabled: ${e.message}", null)
        }
    }

    private fun startScreenShare(result: Result) {
        try {
            Log.d(TAG, "startScreenShare")
            if (isScreenShareActive) {
                result.success(true)
                return
            }
            val activity = context as? Activity
            if (activity == null) {
                result.error("SCREEN_SHARE_ERROR", "Activity not available", null)
                return
            }
            val projectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val captureIntent = projectionManager.createScreenCaptureIntent()
            pendingScreenShareResult = result
            // Start foreground service before requesting projection result on Android 14+
            try {
                val startIntent = Intent(context, ScreenShareService::class.java)
                startIntent.action = ScreenShareService.ACTION_START
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(startIntent)
                } else {
                    context.startService(startIntent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start foreground service: ${e.message}", e)
            }
            activity.startActivityForResult(captureIntent, REQUEST_SCREEN_CAPTURE)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting screen share: ${e.message}", e)
            result.error("SCREEN_SHARE_ERROR", "Failed to start screen share: ${e.message}", null)
        }
    }

    fun onScreenCapturePermissionResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_SCREEN_CAPTURE) return
        val activity = context as? Activity ?: return
        try {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "Screen capture permission granted")
                // Create screen capturer with proper constructor (context, resultCode, data, listener)
                screenFirstFrameSeen = false
                screenInitRetried = false
                screenCapturer = ScreenCapturer(activity, resultCode, data, object : ScreenCapturer.Listener {
                    override fun onScreenCaptureError(errorDescription: String) {
                        Log.e(TAG, "Screen capture error: $errorDescription")
                    }
                    override fun onFirstFrameAvailable() {
                        Log.d(TAG, "Screen capture first frame available")
                        screenFirstFrameSeen = true
                        // Publish if not already published and participant available
                        tryPublishScreenTrack()
                    }
                })
                // Dispose previous if exists
                screenVideoTrack?.let { old ->
                    try {
                        localParticipant?.unpublishTrack(old)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error unpublishing old screen track: ${e.message}", e)
                    }
                    old.release()
                    screenVideoTrack = null
                }
                // Create local video track from screen
                val capturer = screenCapturer
                if (capturer == null) {
                    pendingScreenShareResult?.error("SCREEN_SHARE_ERROR", "Screen capturer not created", null)
                    pendingScreenShareResult = null
                    return
                }
                screenVideoTrack = LocalVideoTrack.create(context, true, capturer)
                // Mark pending publish; will attempt now and on callbacks
                pendingScreenPublish = true
                // Assign a view id for screen track if not present
                if (screenVideoViewId == null) {
                    screenVideoViewId = viewIdCounter++
                    Log.d(TAG, "Created local screen view ID: $screenVideoViewId")
                }
                isScreenShareActive = true
                roomEventStreamHandler.sendRoomEvent(mapOf(
                    "type" to "screenShareStateChanged",
                    "active" to true
                ))
                // Attempt immediate publish; if participant not ready, will publish later
                tryPublishScreenTrack()
                // Report success to Flutter once permission is granted and we started capture
                pendingScreenShareResult?.success(true)
                pendingScreenShareResult = null

                // If first frame not seen quickly (some Samsung devices), recreate once
                mainHandler.postDelayed({
                    if (!screenFirstFrameSeen && !screenInitRetried) {
                        Log.w(TAG, "No first frame from screen capturer yet; retrying initialization once (device quirk)")
                        screenInitRetried = true
                        // Recreate capturer and track
                        try {
                            screenCapturer?.let { /* old capturer will be released with track */ }
                            screenVideoTrack?.let { old ->
                                try { localParticipant?.unpublishTrack(old) } catch (_: Exception) {}
                                old.release()
                            }
                            screenVideoTrack = null
                            // Recreate capturer and track
                            screenCapturer = ScreenCapturer(activity, resultCode, data, object : ScreenCapturer.Listener {
                                override fun onScreenCaptureError(errorDescription: String) {
                                    Log.e(TAG, "Screen capture error (retry): $errorDescription")
                                }
                                override fun onFirstFrameAvailable() {
                                    Log.d(TAG, "Screen capture first frame available (retry)")
                                    screenFirstFrameSeen = true
                                    tryPublishScreenTrack()
                                }
                            })
                            val cap2 = screenCapturer
                            if (cap2 != null) {
                                screenVideoTrack = LocalVideoTrack.create(context, true, cap2)
                                pendingScreenPublish = true
                                tryPublishScreenTrack()
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Retry screen capturer init failed: ${e.message}", e)
                        }
                    }
                }, 1500)
            } else {
                Log.w(TAG, "Screen capture permission denied or failed")
                // Immediately stop foreground service to remove notification
                try {
                    val stopIntent = Intent(context, ScreenShareService::class.java)
                    stopIntent.action = ScreenShareService.ACTION_STOP
                    context.startService(stopIntent)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to stop foreground service after denied: ${e.message}", e)
                }
                pendingScreenShareResult?.error("SCREEN_SHARE_PERMISSION_DENIED", "User denied screen capture permission.", null)
                pendingScreenShareResult = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "onScreenCapturePermissionResult error: ${e.message}", e)
            // Always try to cleanup notification
            try {
                val stopIntent = Intent(context, ScreenShareService::class.java)
                stopIntent.action = ScreenShareService.ACTION_STOP
                context.startService(stopIntent)
            } catch (ex: Exception) {
                Log.e(TAG, "Failed to stop foreground on exception: ${ex.message}", ex)
            }
            pendingScreenShareResult?.error("SCREEN_SHARE_ERROR", e.message, null)
            pendingScreenShareResult = null
        }
    }

    private fun tryPublishScreenTrack(): Boolean {
        val participant = localParticipant
        val track = screenVideoTrack
        if (!(pendingScreenPublish && participant != null && track != null)) {
            if (pendingScreenPublish) {
                Log.w(TAG, "Screen share pending but participant unavailable, will retry on onConnected event.")
            }
            return false
        }
        return try {
            participant.publishTrack(track)
            // Mark local participant as sharing screen
            currentParticipants[participant.identity]?.put("isScreenShareEnabled", true)
            participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            // Optionally unpublish camera track while sharing
            localVideoTrack?.let { camTrack ->
                if (publishedLocalVideoTracks.contains(camTrack)) {
                    participant.unpublishTrack(camTrack)
                    publishedLocalVideoTracks.remove(camTrack)
                }
            }
            pendingScreenPublish = false
            Log.d(TAG, "Screen share track published successfully.")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error publishing screen track: ${e.message}", e)
            false
        }
    }

    private fun stopScreenShare(result: Result) {
        try {
            Log.d(TAG, "stopScreenShare")
            if (!isScreenShareActive) {
                result.success(true)
                return
            }
            pendingScreenPublish = false
            // Unpublish and release screen track
            screenVideoTrack?.let { track ->
                try {
                    localParticipant?.unpublishTrack(track)
                    Log.d(TAG, "Unpublished screen share track")
                } catch (e: Exception) {
                    Log.e(TAG, "Error unpublishing screen track: ${e.message}", e)
                }
                track.release()
            }
            screenCapturer?.let { capturer ->
                // ScreenCapturer cleanup will occur with track release
            }
            // Stop foreground service
            try {
                val stopIntent = Intent(context, ScreenShareService::class.java)
                stopIntent.action = ScreenShareService.ACTION_STOP
                context.startService(stopIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop foreground service: ${e.message}", e)
            }
            screenVideoTrack = null
            screenCapturer = null
            screenVideoViewId = null
            isScreenShareActive = false
            // Clear local participant screen share state
            localParticipant?.let { currentParticipants[it.identity]?.put("isScreenShareEnabled", false) }
            participantsStreamHandler.sendParticipantsUpdate(getParticipantsList())
            roomEventStreamHandler.sendRoomEvent(mapOf(
                "type" to "screenShareStateChanged",
                "active" to false
            ))
            // Ensure camera is re-published (with race handling)
            if (localVideoTrack != null && !publishedLocalVideoTracks.contains(localVideoTrack)) {
                if (room != null && localParticipant != null) {
                    try {
                        localParticipant?.publishTrack(localVideoTrack!!)
                        publishedLocalVideoTracks.add(localVideoTrack!!)
                        Log.d(TAG, "Successfully re-published camera track after screen share.")
                        pendingCameraRepublish = false
                    } catch (e: Exception) {
                        Log.e(TAG, "Could not immediately re-publish camera track: ${e.message}", e)
                        pendingCameraRepublish = true // Will retry on room events
                    }
                } else {
                    Log.w(TAG, "Room/Participant not ready for camera republish, will try on reconnect.")
                    pendingCameraRepublish = true // Will retry on next room onConnected
                }
            } else {
                pendingCameraRepublish = false
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping screen share: ${e.message}", e)
            result.error("SCREEN_SHARE_ERROR", "Failed to stop screen share: ${e.message}", null)
        }
    }

    private fun getParticipants(result: Result) {
        try {
            Log.d(TAG, "getParticipants")
            val participantsList = getParticipantsList()
            result.success(participantsList)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting participants: ${e.message}", e)
            result.error("PARTICIPANTS_ERROR", "Failed to get participants: ${e.message}", null)
        }
    }

    private fun getParticipantsList(): List<Map<String, Any>> {
        return currentParticipants.values.map { participant ->
            mapOf(
                "attendeeId" to (participant["attendeeId"] ?: ""),
                "name" to (participant["name"] ?: ""),
                "isAudioEnabled" to (participant["isAudioEnabled"] ?: false),
                "isVideoEnabled" to (participant["isVideoEnabled"] ?: false),
                "isScreenShareEnabled" to (participant["isScreenShareEnabled"] ?: false)
            )
        }
    }

    private fun getLocalVideoViewId(result: Result) {
        try {
            Log.d(TAG, "getLocalVideoViewId: ${localVideoViewId}")
            result.success(localVideoViewId)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local video view ID: ${e.message}", e)
            result.error("VIEW_ID_ERROR", "Failed to get local video view ID: ${e.message}", null)
        }
    }

    private fun getRemoteVideoViewId(participantId: String, result: Result) {
        try {
            val viewId = remoteVideoViewIds[participantId]
            Log.d(TAG, "getRemoteVideoViewId: participantId=$participantId, viewId=$viewId")
            result.success(viewId)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting remote video view ID: ${e.message}", e)
            result.error("VIEW_ID_ERROR", "Failed to get remote video view ID: ${e.message}", null)
        }
    }

    private fun getLocalScreenShareViewId(result: Result) {
        try {
            Log.d(TAG, "getLocalScreenShareViewId: ${screenVideoViewId}")
            result.success(screenVideoViewId)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local screen share view ID: ${e.message}", e)
            result.error("VIEW_ID_ERROR", "Failed to get local screen share view ID: ${e.message}", null)
        }
    }

    private fun tryRepublishCameraTrack() {
        // Try to republish camera track if needed (after screen share stops)
        if (pendingCameraRepublish) {
            if (localVideoTrack != null && room != null && localParticipant != null && !publishedLocalVideoTracks.contains(localVideoTrack)) {
                try {
                    localParticipant?.publishTrack(localVideoTrack!!)
                    publishedLocalVideoTracks.add(localVideoTrack!!)
                    Log.d(TAG, "Successfully re-published camera track.")
                    pendingCameraRepublish = false
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to re-publish camera track: ${e.message}", e)
                }
            } else {
                Log.w(TAG, "Camera track could not be re-published yet – will try again on next possible event.")
            }
        }
    }

    private fun cleanup() {
        // Unpublish tracks before releasing
        localVideoTrack?.let { track ->
            if (publishedLocalVideoTracks.contains(track) && localParticipant != null) {
                try {
                    localParticipant?.unpublishTrack(track)
                    publishedLocalVideoTracks.remove(track)
                } catch (e: Exception) {
                    Log.e(TAG, "Error unpublishing video track during cleanup: ${e.message}", e)
                }
            }
            track.release()
        }
        localAudioTrack?.let { track ->
            if (publishedLocalAudioTracks.contains(track) && localParticipant != null) {
                try {
                    localParticipant?.unpublishTrack(track)
                    publishedLocalAudioTracks.remove(track)
                } catch (e: Exception) {
                    Log.e(TAG, "Error unpublishing audio track during cleanup: ${e.message}", e)
                }
            }
            track.release()
        }
        cameraCapturer?.let {
            // CameraCapturer cleanup if needed
        }
        localVideoTrack = null
        localAudioTrack = null
        isAudioEnabled = false
        isVideoEnabled = false
        isScreenShareActive = false
        currentParticipants.clear()
        participantListeners.clear()
        publishedLocalAudioTracks.clear()
        publishedLocalVideoTracks.clear()
        room = null
        localParticipant = null
    }

    /**
     * Event stream handler for participants updates
     */
    inner class ParticipantsStreamHandler : EventChannel.StreamHandler {
        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
            Log.d(TAG, "ParticipantsStreamHandler: onListen")
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
            Log.d(TAG, "ParticipantsStreamHandler: onCancel")
        }

        fun sendParticipantsUpdate(participants: List<Map<String, Any>>) {
            eventSink?.success(participants)
        }
    }

    /**
     * Event stream handler for room events
     */
    inner class RoomEventStreamHandler : EventChannel.StreamHandler {
        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
            Log.d(TAG, "RoomEventStreamHandler: onListen")
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
            Log.d(TAG, "RoomEventStreamHandler: onCancel")
        }

        fun sendRoomEvent(event: Map<String, Any?>) {
            eventSink?.success(event)
        }
    }

    fun dispose() {
        cleanup()
        methodChannel.setMethodCallHandler(null)
        participantsEventChannel.setStreamHandler(null)
        roomEventChannel.setStreamHandler(null)
        Log.d(TAG, "TwilioSdkMethodHandler disposed")
    }
}

/**
 * Platform View Factory for Twilio Video Views
 */
class TwilioVideoViewFactory(
    private val handler: TwilioSdkMethodHandler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *> ?: emptyMap<Any, Any>()
        val isLocal = params["isLocal"] as? Boolean ?: false
        val participantId = params["participantId"] as? String
        
        Log.d("TwilioVideoViewFactory", "Creating video view: viewId=$viewId, isLocal=$isLocal, participantId=$participantId")
        
        return TwilioVideoPlatformView(context, viewId, handler, isLocal, participantId)
    }
}

/**
 * Platform View that renders Twilio Video Track
 */
class TwilioVideoPlatformView(
    private val context: Context,
    private val viewId: Int,
    private val handler: TwilioSdkMethodHandler,
    private val isLocal: Boolean,
    private val participantId: String?
) : PlatformView {
    private val videoView: VideoView = VideoView(context)
    
    init {
        Log.d("TwilioVideoPlatformView", "Initializing view: viewId=$viewId, isLocal=$isLocal")
        
        // Set up video rendering
        if (isLocal) {
            // Support choosing screen vs camera based on participantId flag (null means choose camera by default)
            // We’ll decide by matching provided viewId to screen/camera stored ids
            val localScreenTrack = handler.getScreenVideoTrack()
            if (localScreenTrack != null && viewId == handler.getScreenVideoViewId()) {
                localScreenTrack.addSink(videoView)
                Log.d("TwilioVideoPlatformView", "Added local screen track to view")
            } else {
                handler.getLocalVideoTrack()?.addSink(videoView)
                Log.d("TwilioVideoPlatformView", "Added local camera track to view")
            }
        } else if (participantId != null) {
            val remoteTrack = handler.getRemoteVideoTrack(participantId)
            if (remoteTrack != null) {
                remoteTrack.addSink(videoView)
                Log.d("TwilioVideoPlatformView", "Added remote video track for participant: $participantId")
            } else {
                Log.w("TwilioVideoPlatformView", "Remote video track not available for participant: $participantId")
            }
        }
    }
    
    override fun getView(): View = videoView
    
    override fun dispose() {
        Log.d("TwilioVideoPlatformView", "Disposing view: viewId=$viewId")
        if (isLocal) {
            val localScreenTrack = handler.getScreenVideoTrack()
            if (localScreenTrack != null && viewId == handler.getScreenVideoViewId()) {
                handler.getScreenVideoTrack()?.removeSink(videoView)
            } else {
                handler.getLocalVideoTrack()?.removeSink(videoView)
            }
        } else if (participantId != null) {
            handler.getRemoteVideoTrack(participantId)?.removeSink(videoView)
        }
    }
}

