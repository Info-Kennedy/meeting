import Flutter
import UIKit
import TwilioVideo

/**
 * Platform channel handler for Twilio Video SDK
 *
 * This class bridges Flutter calls to Twilio Video SDK for iOS.
 *
 * Based on: https://www.twilio.com/docs/video/ios-getting-started
 */
@objc public class TwilioSdkPlugin: NSObject, FlutterPlugin {
    private static let METHOD_CHANNEL = "com.twilio.video/twilio_sdk"
    private static let PARTICIPANTS_EVENT_CHANNEL = "com.twilio.video/twilio_sdk_participants"
    private static let ROOM_EVENT_CHANNEL = "com.twilio.video/twilio_sdk_events"

    private var methodChannel: FlutterMethodChannel?
    private var participantsEventChannel: FlutterEventChannel?
    private var roomEventChannel: FlutterEventChannel?

    // Twilio Video SDK components
    private var room: Room?
    private var localParticipant: LocalParticipant?
    private var localVideoTrack: LocalVideoTrack?
    private var localAudioTrack: LocalAudioTrack?
    private var camera: CameraSource?
    private var cameraCapturer: CameraCapturer?

    // State tracking
    private var isAudioEnabled = false
    private var isVideoEnabled = false
    private var isScreenShareActive = false
    private var currentParticipants: [String: [String: Any]] = [:]
    
    // Video view tracking
    private var localVideoViewId: Int? = nil
    private var remoteVideoViewIds: [String: Int] = [:]
    private var remoteVideoTracks: [String: RemoteVideoTrack] = [:]
    private var viewIdCounter: Int = 1

    // Event sinks for streaming
    private var participantsEventSink: FlutterEventSink?
    private var roomEventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TwilioSdkPlugin()

        // Method channel
        let methodChannel = FlutterMethodChannel(
            name: METHOD_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        methodChannel.setMethodCallHandler(instance)

        // Event channels with separate stream handlers
        let participantsEventChannel = FlutterEventChannel(
            name: PARTICIPANTS_EVENT_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        let participantsHandler = ParticipantsStreamHandler(plugin: instance)
        participantsEventChannel.setStreamHandler(participantsHandler)

        let roomEventChannel = FlutterEventChannel(
            name: ROOM_EVENT_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        let roomEventHandler = RoomEventStreamHandler(plugin: instance)
        roomEventChannel.setStreamHandler(roomEventHandler)

        instance.methodChannel = methodChannel
        instance.participantsEventChannel = participantsEventChannel
        instance.roomEventChannel = roomEventChannel
        
        // Register platform view factory for video rendering
        let videoFactory = TwilioVideoViewFactory(plugin: instance)
        registrar.registerViewFactory(videoFactory, withId: "twilio_video_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "connectToRoom":
            connectToRoom(call: call, result: result)
        case "disconnectFromRoom":
            disconnectFromRoom(result: result)
        case "setAudioEnabled":
            setAudioEnabled(call: call, result: result)
        case "isAudioEnabled":
            result(isAudioEnabled)
        case "setVideoEnabled":
            setVideoEnabled(call: call, result: result)
        case "isVideoEnabled":
            result(isVideoEnabled)
        case "startScreenShare":
            startScreenShare(result: result)
        case "stopScreenShare":
            stopScreenShare(result: result)
        case "isScreenShareActive":
            result(isScreenShareActive)
        case "getParticipants":
            getParticipants(result: result)
        case "getLocalVideoViewId":
            getLocalVideoViewId(result: result)
        case "getRemoteVideoViewId":
            getRemoteVideoViewId(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Internal Stream Management
    
    func setParticipantsEventSink(_ sink: FlutterEventSink?) {
        participantsEventSink = sink
    }
    
    func setRoomEventSink(_ sink: FlutterEventSink?) {
        roomEventSink = sink
    }

    // MARK: - Room Methods

    private func connectToRoom(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let accessToken = args["accessToken"] as? String,
              let roomName = args["roomName"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Missing required arguments: accessToken, roomName",
                details: nil
            ))
            return
        }

        let identity = args["identity"] as? String
        let enableAudio = args["enableAudio"] as? Bool ?? true
        let enableVideo = args["enableVideo"] as? Bool ?? true

        print("TwilioSdkPlugin: connectToRoom - roomName: \(roomName)")

        // Set up local media
        if enableAudio && localAudioTrack == nil {
            localAudioTrack = LocalAudioTrack(options: AudioOptions(), enabled: true, name: "microphone")
        }

        if enableVideo && localVideoTrack == nil {
            // Initialize camera
            if cameraCapturer == nil {
                if let camera = CameraSource(delegate: nil) {
                    self.camera = camera
                    cameraCapturer = CameraCapturer(source: camera, delegate: nil)
                }
            }

            if let capturer = cameraCapturer {
                localVideoTrack = LocalVideoTrack(source: capturer, enabled: true, name: "camera")
                // Generate view ID for local video
                if localVideoViewId == nil {
                    localVideoViewId = viewIdCounter
                    viewIdCounter += 1
                    print("TwilioSdkPlugin: Created local video view ID: \(localVideoViewId!)")
                }
            }
        }

        // Build connect options
        var connectOptionsBuilder = ConnectOptions(token: accessToken) { (builder) in
            builder.roomName = roomName
            if let identity = identity {
                builder.name = identity
            }
            if enableAudio, let audioTrack = self.localAudioTrack {
                builder.audioTracks = [audioTrack]
            }
            if enableVideo, let videoTrack = self.localVideoTrack {
                builder.videoTracks = [videoTrack]
            }
        }

        // Connect to room
        room = TwilioVideoSDK.connect(options: connectOptionsBuilder, delegate: self)

        isAudioEnabled = enableAudio
        isVideoEnabled = enableVideo

        result(true)
    }

    private func disconnectFromRoom(result: @escaping FlutterResult) {
        print("TwilioSdkPlugin: disconnectFromRoom")
        room?.disconnect()
        cleanup()
        result(true)
    }

    private func setAudioEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Missing enabled argument",
                details: nil
            ))
            return
        }

        print("TwilioSdkPlugin: setAudioEnabled - enabled: \(enabled)")

        if enabled {
            if localAudioTrack == nil {
                localAudioTrack = LocalAudioTrack(options: AudioOptions(), enabled: true, name: "microphone")
                localParticipant?.publishAudioTrack(track: localAudioTrack!)
            }
            localAudioTrack?.isEnabled = true
            isAudioEnabled = true
        } else {
            localAudioTrack?.isEnabled = false
            isAudioEnabled = false
        }

        sendRoomEvent([
            "type": "audioStateChanged",
            "enabled": enabled
        ])

        result(true)
    }

    private func setVideoEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Missing enabled argument",
                details: nil
            ))
            return
        }

        print("TwilioSdkPlugin: setVideoEnabled - enabled: \(enabled)")

        if enabled {
            if localVideoTrack == nil {
                if cameraCapturer == nil {
                    if let camera = CameraSource(delegate: nil) {
                        self.camera = camera
                        cameraCapturer = CameraCapturer(source: camera, delegate: nil)
                    }
                }
                if let capturer = cameraCapturer {
                    localVideoTrack = LocalVideoTrack(source: capturer, enabled: true, name: "camera")
                    localParticipant?.publishVideoTrack(track: localVideoTrack!)
                }
            }
            localVideoTrack?.isEnabled = true
            isVideoEnabled = true
        } else {
            localVideoTrack?.isEnabled = false
            isVideoEnabled = false
        }

        sendRoomEvent([
            "type": "videoStateChanged",
            "enabled": enabled
        ])

        result(true)
    }

    private func startScreenShare(result: @escaping FlutterResult) {
        print("TwilioSdkPlugin: startScreenShare")
        // Screen sharing implementation would go here
        // This requires ReplayKit integration
        isScreenShareActive = true
        sendRoomEvent([
            "type": "screenShareStateChanged",
            "active": true
        ])
        result(true)
    }

    private func stopScreenShare(result: @escaping FlutterResult) {
        print("TwilioSdkPlugin: stopScreenShare")
        isScreenShareActive = false
        sendRoomEvent([
            "type": "screenShareStateChanged",
            "active": false
        ])
        result(true)
    }

    private func getParticipants(result: @escaping FlutterResult) {
        print("TwilioSdkPlugin: getParticipants")
        let participantsList = getParticipantsList()
        result(participantsList)
    }
    
    private func getLocalVideoViewId(result: @escaping FlutterResult) {
        print("TwilioSdkPlugin: getLocalVideoViewId: \(localVideoViewId ?? -1)")
        result(localVideoViewId)
    }
    
    private func getRemoteVideoViewId(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let participantId = args["participantId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Missing participantId argument",
                details: nil
            ))
            return
        }
        let viewId = remoteVideoViewIds[participantId]
        print("TwilioSdkPlugin: getRemoteVideoViewId: participantId=\(participantId), viewId=\(viewId ?? -1)")
        result(viewId)
    }

    private func getParticipantsList() -> [[String: Any]] {
        return currentParticipants.values.map { participant -> [String: Any] in
            return [
                "attendeeId": participant["attendeeId"] ?? "",
                "name": participant["name"] ?? "",
                "isAudioEnabled": participant["isAudioEnabled"] ?? false,
                "isVideoEnabled": participant["isVideoEnabled"] ?? false,
                "isScreenShareEnabled": participant["isScreenShareEnabled"] ?? false
            ]
        }
    }

    private func cleanup() {
        localVideoTrack?.isEnabled = false
        localAudioTrack?.isEnabled = false
        localVideoTrack = nil
        localAudioTrack = nil
        cameraCapturer = nil
        camera = nil
        isAudioEnabled = false
        isVideoEnabled = false
        isScreenShareActive = false
        currentParticipants.removeAll()
        remoteVideoTracks.removeAll()
        remoteVideoViewIds.removeAll()
        localVideoViewId = nil
        room = nil
        localParticipant = nil
    }
    
    // Expose video tracks for platform view factory
    func getLocalVideoTrack() -> LocalVideoTrack? {
        return localVideoTrack
    }
    
    func getRemoteVideoTrack(participantId: String) -> RemoteVideoTrack? {
        return remoteVideoTracks[participantId]
    }

    private func sendParticipantsUpdate() {
        let participantsList = getParticipantsList()
        participantsEventSink?(participantsList)
    }

    private func sendRoomEvent(_ event: [String: Any]) {
        roomEventSink?(event)
    }
}

// MARK: - RoomDelegate
extension TwilioSdkPlugin: RoomDelegate {
    public func didConnect(to room: Room) {
        print("TwilioSdkPlugin: didConnect to room: \(room.name)")
        self.room = room
        localParticipant = room.localParticipant

        // Track local participant
        if let participant = localParticipant {
            currentParticipants[participant.identity] = [
                "attendeeId": participant.identity,
                "name": participant.identity,
                "isAudioEnabled": isAudioEnabled,
                "isVideoEnabled": isVideoEnabled
            ]
            sendParticipantsUpdate()
        }

        sendRoomEvent([
            "type": "room_connected",
            "roomName": room.name
        ])
    }

    public func room(_ room: Room, didFailToConnectWithError error: Error) {
        print("TwilioSdkPlugin: didFailToConnectWithError: \(error.localizedDescription)")
        sendRoomEvent([
            "type": "room_connect_failure",
            "error": error.localizedDescription
        ])
    }

    public func didDisconnect(from room: Room, error: Error?) {
        print("TwilioSdkPlugin: didDisconnect from room: \(room.name)")
        sendRoomEvent([
            "type": "room_disconnected",
            "error": error?.localizedDescription
        ])
        cleanup()
    }

    public func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        print("TwilioSdkPlugin: participantDidConnect: \(participant.identity)")
        currentParticipants[participant.identity] = [
            "attendeeId": participant.identity,
            "name": participant.identity,
            "isAudioEnabled": false,
            "isVideoEnabled": false
        ]
        sendParticipantsUpdate()

        // Listen to participant's tracks
        participant.delegate = self
    }

    public func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        print("TwilioSdkPlugin: participantDidDisconnect: \(participant.identity)")
        currentParticipants.removeValue(forKey: participant.identity)
        sendParticipantsUpdate()
    }
}

// MARK: - RemoteParticipantDelegate
extension TwilioSdkPlugin: RemoteParticipantDelegate {
    public func participant(_ participant: RemoteParticipant, didPublishVideoTrack videoTrack: RemoteVideoTrackPublication) {
        print("TwilioSdkPlugin: didPublishVideoTrack: \(participant.identity)")
        // Generate view ID if not exists
        if remoteVideoViewIds[participant.identity] == nil {
            remoteVideoViewIds[participant.identity] = viewIdCounter
            viewIdCounter += 1
            print("TwilioSdkPlugin: Created view ID \(remoteVideoViewIds[participant.identity]!) for participant \(participant.identity)")
        }
        currentParticipants[participant.identity]?["isVideoEnabled"] = true
        sendParticipantsUpdate()
    }
    
    public func participant(_ participant: RemoteParticipant, didSubscribeToVideoTrack videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication) {
        print("TwilioSdkPlugin: didSubscribeToVideoTrack: \(participant.identity)")
        // Store the remote video track
        remoteVideoTracks[participant.identity] = videoTrack
        // Generate view ID if not exists
        if remoteVideoViewIds[participant.identity] == nil {
            remoteVideoViewIds[participant.identity] = viewIdCounter
            viewIdCounter += 1
            print("TwilioSdkPlugin: Created view ID \(remoteVideoViewIds[participant.identity]!) for participant \(participant.identity)")
        }
        currentParticipants[participant.identity]?["isVideoEnabled"] = true
        sendParticipantsUpdate()
    }
    
    public func participant(_ participant: RemoteParticipant, didUnsubscribeFromVideoTrack videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication) {
        print("TwilioSdkPlugin: didUnsubscribeFromVideoTrack: \(participant.identity)")
        // Remove video track when unsubscribed
        remoteVideoTracks.removeValue(forKey: participant.identity)
        currentParticipants[participant.identity]?["isVideoEnabled"] = false
        sendParticipantsUpdate()
    }

    public func participant(_ participant: RemoteParticipant, didUnpublishVideoTrack videoTrack: RemoteVideoTrackPublication) {
        print("TwilioSdkPlugin: didUnpublishVideoTrack: \(participant.identity)")
        currentParticipants[participant.identity]?["isVideoEnabled"] = false
        sendParticipantsUpdate()
    }

    public func participant(_ participant: RemoteParticipant, didPublishAudioTrack audioTrack: RemoteAudioTrackPublication) {
        print("TwilioSdkPlugin: didPublishAudioTrack: \(participant.identity)")
        currentParticipants[participant.identity]?["isAudioEnabled"] = true
        sendParticipantsUpdate()
    }

    public func participant(_ participant: RemoteParticipant, didUnpublishAudioTrack audioTrack: RemoteAudioTrackPublication) {
        print("TwilioSdkPlugin: didUnpublishAudioTrack: \(participant.identity)")
        currentParticipants[participant.identity]?["isAudioEnabled"] = false
        sendParticipantsUpdate()
    }
}

// MARK: - Separate Stream Handlers

private class ParticipantsStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: TwilioSdkPlugin?
    
    init(plugin: TwilioSdkPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setParticipantsEventSink(events)
        print("TwilioSdkPlugin: Participants stream started")
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setParticipantsEventSink(nil)
        print("TwilioSdkPlugin: Participants stream cancelled")
        return nil
    }
}

private class RoomEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: TwilioSdkPlugin?
    
    init(plugin: TwilioSdkPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setRoomEventSink(events)
        print("TwilioSdkPlugin: Room event stream started")
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setRoomEventSink(nil)
        print("TwilioSdkPlugin: Room event stream cancelled")
        return nil
    }
}

