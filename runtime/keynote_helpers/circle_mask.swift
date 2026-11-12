// Produce a non-destructive, face-aware circle crop for the Keynote adapter.
// Focal coordinates are normalized from the source image's top-left.
import AppKit
import Foundation

let args=CommandLine.arguments
if args.count != 7 { fputs("usage: circle_mask INPUT OUTPUT PIXELS FOCAL_X FOCAL_Y ZOOM\n",stderr); exit(2) }
guard let image=NSImage(contentsOfFile:args[1]), let pixels=Int(args[3]), pixels>0,
      let fx=Double(args[4]), let fy=Double(args[5]), let zoom=Double(args[6]), zoom>=1 else {
    fputs("Invalid image or circle crop arguments\n",stderr); exit(2)
}
let side=CGFloat(pixels), iw=image.size.width, ih=image.size.height
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
rep.size=NSSize(width:side,height:side)
let context=NSGraphicsContext(bitmapImageRep:rep)!
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=context
context.imageInterpolation = .high
NSColor.clear.setFill(); NSRect(x:0,y:0,width:side,height:side).fill()
NSBezierPath(ovalIn:NSRect(x:0,y:0,width:side,height:side)).addClip()
let scale=max(side/iw,side/ih)*CGFloat(zoom), sw=iw*scale, sh=ih*scale
let x=max(side-sw,min(0,side/2-CGFloat(fx)*sw))
let y=max(side-sh,min(0,side/2-CGFloat(1-fy)*sh))
image.draw(in:NSRect(x:x,y:y,width:sw,height:sh),from:.zero,operation:.sourceOver,fraction:1)
NSGraphicsContext.restoreGraphicsState()
guard let png=rep.representation(using:.png,properties:[:]) else { exit(3) }
try png.write(to:URL(fileURLWithPath:args[2]))
