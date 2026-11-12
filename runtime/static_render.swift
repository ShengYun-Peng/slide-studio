import Foundation
import AppKit
import CoreGraphics

func color(_ value: String) -> NSColor {
    let h=value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let v=UInt64(h,radix:16) ?? 0xFFFFFF
    return NSColor(srgbRed:CGFloat((v>>16)&255)/255,green:CGFloat((v>>8)&255)/255,blue:CGFloat(v&255)/255,alpha:1)
}
func number(_ d:[String:Any],_ key:String,_ fallback:Double=0)->CGFloat { CGFloat((d[key] as? NSNumber)?.doubleValue ?? fallback) }
let args=CommandLine.arguments
guard args.count>=3 else {fputs("usage: static-render MANIFEST.json OUTPUT.png [WIDTH]\n",stderr);exit(2)}
let data=try Data(contentsOf:URL(fileURLWithPath:args[1]))
let d=try JSONSerialization.jsonObject(with:data) as! [String:Any]
let W=number(d,"width",1920),H=number(d,"height",1080)
let outW=args.count>3 ? Int(args[3]) ?? 1280 : 1280
let scale=CGFloat(outW)/W,outH=Int(H*scale)
let cs=CGColorSpace(name:CGColorSpace.sRGB)!
let ctx=CGContext(data:nil,width:outW,height:outH,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x:0,y:CGFloat(outH));ctx.scaleBy(x:scale,y:-scale)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true)
color(d["background"] as? String ?? "#2B2B2D").setFill()
NSBezierPath(rect:NSRect(x:0,y:0,width:W,height:H)).fill()
for item in d["items"] as? [[String:Any]] ?? [] {
    let r=NSRect(x:number(item,"x"),y:number(item,"y"),width:number(item,"w"),height:number(item,"h"))
    let kind=item["type"] as? String ?? ""
    if kind=="text" {
        let size=number(item,"size",44)
        let name=item["font"] as? String ?? "HelveticaNeue"
        let font=NSFont(name:name,size:size) ?? NSFont.systemFont(ofSize:size,weight:(item["bold"] as? Bool ?? false) ? .bold : .regular)
        let p=NSMutableParagraphStyle()
        p.alignment=item["align"] as? String == "center" ? .center : item["align"] as? String == "right" ? .right : .left
        p.minimumLineHeight=size*1.22;p.maximumLineHeight=size*1.22
        p.lineBreakMode = .byWordWrapping
        let attr:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:color(item["color"] as? String ?? "#F6F6F4"),.paragraphStyle:p]
        NSAttributedString(string:item["text"] as? String ?? "",attributes:attr).draw(in:r)
    } else if kind=="rect" || kind=="ellipse" {
        let path=kind=="ellipse" ? NSBezierPath(ovalIn:r) : NSBezierPath(roundedRect:r,xRadius:number(item,"corner_radius"),yRadius:number(item,"corner_radius"))
        if let fill=item["fill"] as? String,fill != "none" {color(fill).setFill();path.fill()}
        if let stroke=item["stroke"] as? String,stroke != "none" {color(stroke).setStroke();path.lineWidth=number(item,"stroke_width",6);path.stroke()}
    } else if kind=="line" {
        let path=NSBezierPath();path.move(to:r.origin);path.line(to:NSPoint(x:r.maxX,y:r.maxY));path.lineWidth=number(item,"stroke_width",6);path.lineCapStyle = .round
        color(item["stroke"] as? String ?? "#F6F6F4").setStroke();path.stroke()
        if item["arrow_end"] as? Bool ?? false {
            let angle=atan2(r.height,r.width),length:CGFloat=22
            let arrow=NSBezierPath();arrow.move(to:NSPoint(x:r.maxX-length*cos(angle-0.5),y:r.maxY-length*sin(angle-0.5)));arrow.line(to:NSPoint(x:r.maxX,y:r.maxY));arrow.line(to:NSPoint(x:r.maxX-length*cos(angle+0.5),y:r.maxY-length*sin(angle+0.5)));arrow.lineWidth=path.lineWidth;arrow.lineCapStyle = .round;arrow.stroke()
        }
    } else if kind=="image",let path=item["path"] as? String,let image=NSImage(contentsOfFile:path) {
        let circular=item["mask"] as? String == "circle"
        let fit=circular ? max(r.width/image.size.width,r.height/image.size.height) : min(r.width/image.size.width,r.height/image.size.height)
        let size=NSSize(width:image.size.width*fit,height:image.size.height*fit)
        let fx=number(item,"focal_x",0.5),fy=number(item,"focal_y",0.5)
        let dx=circular ? max(r.maxX-size.width,min(r.minX,r.midX-size.width*fx)) : r.midX-size.width/2
        let dy=circular ? max(r.maxY-size.height,min(r.minY,r.midY-size.height*fy)) : r.midY-size.height/2
        let dest=NSRect(x:dx,y:dy,width:size.width,height:size.height)
        NSGraphicsContext.saveGraphicsState()
        if circular {NSBezierPath(ovalIn:r).addClip()}
        image.draw(in:dest,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
        NSGraphicsContext.restoreGraphicsState()
    }
}
NSGraphicsContext.restoreGraphicsState()
let png=NSBitmapImageRep(cgImage:ctx.makeImage()!).representation(using:.png,properties:[:])!
try png.write(to:URL(fileURLWithPath:args[2]))
