import Flutter
import UIKit
import TwilioVideo

/// Platform View Factory for Twilio Video Views on iOS
@objc public class TwilioVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    private var plugin: TwilioSdkPlugin?
    
    public init(plugin: TwilioSdkPlugin) {
        self.plugin = plugin
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        let isLocal = params["isLocal"] as? Bool ?? false
        let participantId = params["participantId"] as? String
        
        print("TwilioVideoViewFactory: Creating view - viewId: \(viewId), isLocal: \(isLocal), participantId: \(participantId ?? "nil")")
        
        return TwilioVideoPlatformView(
            frame: frame,
            viewId: viewId,
            plugin: plugin,
            isLocal: isLocal,
            participantId: participantId
        )
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Platform View that renders Twilio Video Track on iOS
@objc public class TwilioVideoPlatformView: NSObject, FlutterPlatformView {
    private var videoView: VideoView?
    private var plugin: TwilioSdkPlugin?
    private var isLocal: Bool
    private var participantId: String?
    
    public init(frame: CGRect, viewId: Int64, plugin: TwilioSdkPlugin?, isLocal: Bool, participantId: String?) {
        self.plugin = plugin
        self.isLocal = isLocal
        self.participantId = participantId
        super.init()
        
        print("TwilioVideoPlatformView: Initializing - isLocal: \(isLocal), participantId: \(participantId ?? "nil")")
        
        // Create video view
        let view = VideoView(frame: frame, delegate: nil)
        self.videoView = view
        
        // Set up video rendering
        if isLocal {
            if let localTrack = plugin?.getLocalVideoTrack() {
                localTrack.addRenderer(view)
                print("TwilioVideoPlatformView: Added local video track to view")
            } else {
                print("TwilioVideoPlatformView: Local video track not available")
            }
        } else if let participantId = participantId {
            if let remoteTrack = plugin?.getRemoteVideoTrack(participantId: participantId) {
                remoteTrack.addRenderer(view)
                print("TwilioVideoPlatformView: Added remote video track for participant: \(participantId)")
            } else {
                print("TwilioVideoPlatformView: Remote video track not available for participant: \(participantId)")
            }
        }
    }
    
    public func view() -> UIView {
        return videoView ?? UIView()
    }
    
    deinit {
        print("TwilioVideoPlatformView: Deinitializing")
        if let view = videoView {
            if isLocal {
                plugin?.getLocalVideoTrack()?.removeRenderer(view)
            } else if let participantId = participantId {
                plugin?.getRemoteVideoTrack(participantId: participantId)?.removeRenderer(view)
            }
        }
    }
}

