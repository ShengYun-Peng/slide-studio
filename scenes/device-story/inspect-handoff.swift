import Foundation
import AppKit
import AVFoundation
import CoreGraphics
import CoreText
let out=URL(fileURLWithPath:CommandLine.arguments[1])
let asset=AVURLAsset(url:out.appendingPathComponent("movie.mp4"))
let gen=AVAssetImageGenerator(asset:asset);gen.appliesPreferredTrackTransform=true;gen.requestedTimeToleranceBefore = .zero;gen.requestedTimeToleranceAfter = .zero
let cs=CGColorSpace(name:CGColorSpace.sRGB)!
for (name,times) in [("hinge-opening-contact-sheet",[1.3,1.45,1.6,1.75,1.9,2.05]),("hinge-closing-contact-sheet",[13.8,14.0,14.2,14.4,14.6,14.8]),("assistant-collapse-contact-sheet",[5.7,5.9,6.1,6.3,6.5,6.7]),("assistant-window-contact-sheet",[6.85,7.0,7.1,7.3,7.55,7.8])] {
 let c=CGContext(data:nil,width:1920,height:808,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.setFillColor(NSColor.black.cgColor);c.fill(CGRect(x:0,y:0,width:1920,height:808))
 for (i,t) in times.enumerated(){let image=try gen.copyCGImage(at:CMTime(seconds:t,preferredTimescale:600),actualTime:nil);let x=Double(i%3)*640,y=Double(1-i/3)*404;c.draw(image,in:CGRect(x:x,y:y+44,width:640,height:360));let text=CTLineCreateWithAttributedString(NSAttributedString(string:String(format:"%.2f s",t),attributes:[.font:NSFont.systemFont(ofSize:24),.foregroundColor:NSColor.white]));c.textPosition=CGPoint(x:x+20,y:y+12);CTLineDraw(text,c)}
 try NSBitmapImageRep(cgImage:c.makeImage()!).representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent(name+".png"))
}
