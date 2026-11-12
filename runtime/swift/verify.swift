// Decode every frame, verify timing/geometry, and save a decoded contact sheet.
import Foundation
import AppKit
import AVFoundation
import CoreGraphics
import CoreText
let args=CommandLine.arguments
guard args.count>=2 else {fatalError("Usage: verify <demo-directory>")}
let dir=URL(fileURLWithPath:args[1]),movie=dir.appendingPathComponent("movie.mp4")
let manifest=try JSONSerialization.jsonObject(with:Data(contentsOf:dir.appendingPathComponent("render-manifest.json"))) as! [String:Any]
let width=manifest["width"] as! Int,height=manifest["height"] as! Int,fps=manifest["fps"] as! Int,duration=manifest["duration"] as! Double
let asset=AVURLAsset(url:movie),track=asset.tracks(withMediaType:.video).first!
let reader=try AVAssetReader(asset:asset)
let output=AVAssetReaderTrackOutput(track:track,outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]);reader.add(output);reader.startReading()
var frames=0,lastTime = -1.0,monotonic=true
while let sample=output.copyNextSampleBuffer(){let t=CMSampleBufferGetPresentationTimeStamp(sample).seconds;if t<=lastTime {monotonic=false};lastTime=t;frames+=1}
let generator=AVAssetImageGenerator(asset:asset);generator.appliesPreferredTrackTransform=true;generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
let cs=CGColorSpace(name:CGColorSpace.sRGB)!,c=CGContext(data:nil,width:1280,height:720,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
var decodeSamples=0
for (i,fraction) in [0.0,0.3,0.6,0.97].enumerated(){let image=try generator.copyCGImage(at:CMTime(seconds:duration*fraction,preferredTimescale:600),actualTime:nil);let x=(i%2)*640,y=(1-i/2)*360;c.draw(image,in:CGRect(x:x,y:y,width:640,height:360));decodeSamples+=1}
try NSBitmapImageRep(cgImage:c.makeImage()!).representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent("decoded-contact-sheet.png"))
let pass=reader.status == .completed && frames==Int(ceil(duration*Double(fps))) && monotonic && Int(track.naturalSize.width)==width && Int(track.naturalSize.height)==height && abs(asset.duration.seconds-duration)<0.05 && abs(Double(track.nominalFrameRate)-Double(fps))<0.05
let result:[String:Any]=["pass":pass,"frames_decoded":frames,"timestamps_strictly_increasing":monotonic,"actual_duration":asset.duration.seconds,"actual_fps":track.nominalFrameRate,"actual_width":track.naturalSize.width,"actual_height":track.naturalSize.height,"sample_images_decoded":decodeSamples,"reader_completed":reader.status == .completed]
try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]).write(to:dir.appendingPathComponent("verification.json"))
print("\(pass ? "PASS":"FAIL") \(dir.path) — \(frames) decoded frames")
exit(pass ? 0:1)
