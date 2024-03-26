//
//  TwilioSettings.swift
//  BMXCall
//
//  Created by Yingtao on 9/9/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation
import TwilioVideo

class TwilioSettings: NSObject {

    // ISDK-2644: Resolving a conflict with AudioToolbox in iOS 13
    let supportedAudioCodecs: [TwilioVideo.AudioCodec] = [OpusCodec(),
                                                          PcmaCodec(),
                                                          PcmuCodec(),
                                                          G722Codec()]
    
    let supportedVideoCodecs: [VideoCodec] = [Vp8Codec(),
                                              Vp8Codec(simulcast: true),
                                              H264Codec(),
                                              Vp9Codec()]

    // Valid signaling Regions are listed here:
    // https://www.twilio.com/docs/video/ip-address-whitelisting#signaling-communication
    let supportedSignalingRegions: [String] = ["gll",
                                               "au1",
                                               "br1",
                                               "de1",
                                               "ie1",
                                               "in1",
                                               "jp1",
                                               "sg1",
                                               "us1",
                                               "us2"]


    let supportedSignalingRegionDisplayString: [String : String] = ["gll": "Global Low Latency",
                                                                    "au1": "Australia",
                                                                    "br1": "Brazil",
                                                                    "de1": "Germany",
                                                                    "ie1": "Ireland",
                                                                    "in1": "India",
                                                                    "jp1": "Japan",
                                                                    "sg1": "Singapore",
                                                                    "us1": "US East Coast (Virginia)",
                                                                    "us2": "US West Coast (Oregon)"]
    
    var audioCodec: TwilioVideo.AudioCodec?
    var videoCodec: VideoCodec?

    var maxAudioBitrate = UInt()
    var maxVideoBitrate = UInt()

    var signalingRegion: String?

    func getEncodingParameters() -> EncodingParameters?  {
        if maxAudioBitrate == 0 && maxVideoBitrate == 0 {
            return nil;
        } else {
            return EncodingParameters(audioBitrate: maxAudioBitrate,
                                      videoBitrate: maxVideoBitrate)
        }
    }
    
    private override init() {
        // Can't initialize a singleton
    }
    
    // MARK:- Shared Instance
    static let shared = TwilioSettings()
}

class ConnectOptionsFactory {
    
    private let settings = TwilioSettings.shared
    
    func makeConnectOptions(accessToken: String,
                            roomName: String,
                            audioTracks: [LocalAudioTrack],
                            videoTracks: [TwilioVideo.LocalVideoTrack]) -> ConnectOptions {
        ConnectOptions(token: accessToken) { [self] builder in
            builder.audioTracks = audioTracks
            builder.videoTracks = videoTracks
            
            // Use the preferred audio codec
            if let preferredAudioCodec = settings.audioCodec {
                builder.preferredAudioCodecs = [preferredAudioCodec]
            }
            
            // Use the preferred video codec
            if let preferredVideoCodec = settings.videoCodec {
                builder.preferredVideoCodecs = [preferredVideoCodec]
            }
            
            // Use the preferred encoding parameters
            if let encodingParameters = settings.getEncodingParameters() {
                builder.encodingParameters = encodingParameters
            }

            // Use the preferred signaling region
            if let signalingRegion = settings.signalingRegion {
                builder.region = signalingRegion
            }
            
            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = roomName
        }
    }
    
}

