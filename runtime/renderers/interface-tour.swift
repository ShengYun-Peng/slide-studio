// A lossless UI-state tour with one continuous camera. Coordinates inside each
// captured state are CSS/source coordinates; labels and viewport use 1920×1080.
import Foundation
import AppKit
import AVFoundation
import CoreGraphics
import CoreText
import ImageIO

let args=CommandLine.arguments
func option(_ name:String)->String? {
    guard let i=args.firstIndex(of:name),i+1<args.count else{return nil}
    return args[i+1]
}
guard let configPath=option("--config"),let outputPath=option("--output") else {
    fatalError("--config scene.json --output directory [--video] [--sample-times 4.0,4.017]")
}
let out=URL(fileURLWithPath:outputPath)
let cfg=try JSONSerialization.jsonObject(with:Data(contentsOf:URL(fileURLWithPath:configPath))) as! [String:Any]
let content=cfg["content"] as! [String:Any]
let theme=cfg["theme"] as? [String:Any] ?? [:]
func number(_ object:[String:Any],_ key:String,_ fallback:Double=0)->Double {
    (object[key] as? NSNumber)?.doubleValue ?? fallback
}
let width=Int(number(cfg,"width",3840)),height=Int(number(cfg,"height",2160)),fps=Int(number(cfg,"fps",60))
let duration=number(cfg,"duration"),scale=Double(width)/1920
precondition(width>0 && height>0 && abs(Double(width)/Double(height)-16.0/9)<0.001,"Use a 16:9 output; geometry uses 1920×1080 logical units")
let colorSpace=CGColorSpace(name:CGColorSpace.sRGB)!
let background=theme["background"] as? String ?? "#2B2B2D"
let foreground=theme["foreground"] as? String ?? "#F6F6F4"
let regular=theme["font_regular"] as? String ?? "HelveticaNeue"
let bold=theme["font_bold"] as? String ?? "HelveticaNeue-Bold"
let assets=content["assets"] as! [String:[String:Any]]
let shots=content["shots"] as! [[String:Any]]
let cameras=content["camera"] as! [[String:Any]]
let pointers=content["pointer"] as? [[String:Any]] ?? []
let captions=content["captions"] as? [[String:Any]] ?? []
let bounds=content["viewport"] as? [Double] ?? [96,238,1728,720]
let viewport=CGRect(x:bounds[0],y:bounds[1],width:bounds[2],height:bounds[3])
let aspect=viewport.width/viewport.height
try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)

func ease(_ t:Double)->Double {let x=max(0,min(1,t));return x*x*x*(10+x*(-15+6*x))}
func color(_ hex:String,_ alpha:Double=1)->CGColor {
    let n=UInt64(hex.dropFirst(),radix:16)!
    return CGColor(colorSpace:colorSpace,components:[Double(n>>16&255)/255,Double(n>>8&255)/255,Double(n&255)/255,alpha])!
}
func text(_ c:CGContext,_ value:String,_ x:Double,_ y:Double,_ size:Double,_ hex:String,_ weight:Bool=true) {
    let font=NSFont(name:weight ? bold:regular,size:size) ?? NSFont.systemFont(ofSize:size,weight:weight ? .bold:.regular)
    let line=CTLineCreateWithAttributedString(NSAttributedString(string:value,attributes:[.font:font,.foregroundColor:NSColor(cgColor:color(hex))!]))
    c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:1,y:-1)
    c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(line,c);c.restoreGState()
}
func drawImage(_ c:CGContext,_ image:CGImage,_ rect:CGRect) {
    c.saveGState();c.translateBy(x:rect.minX,y:rect.maxY);c.scaleBy(x:1,y:-1)
    c.interpolationQuality = .high;c.draw(image,in:CGRect(x:0,y:0,width:rect.width,height:rect.height));c.restoreGState()
}
var cache:[String:CGImage]=[:],recent:[String]=[]
func image(_ file:String)->CGImage {
    if let cached=cache[file]{recent.removeAll{$0==file};recent.append(file);return cached}
    guard let source=CGImageSourceCreateWithURL(URL(fileURLWithPath:file) as CFURL,nil),let loaded=CGImageSourceCreateImageAtIndex(source,0,nil) else{fatalError("Cannot decode \(file)")}
    cache[file]=loaded;recent.append(file)
    while recent.count>6{cache.removeValue(forKey:recent.removeFirst())}
    return loaded
}
func segment(_ t:Double,_ keys:[[String:Any]])->(Int,Double) {
    if t<=number(keys[0],"time"){return(0,0)}
    for i in 0..<max(0,keys.count-1){let a=number(keys[i],"time"),b=number(keys[i+1],"time");if t<b{return(i,(t-a)/(b-a))}}
    return(keys.count-1,0)
}
func camera(_ t:Double)->CGRect {
    let(i,u)=segment(t,cameras),a=cameras[i],b=cameras[min(i+1,cameras.count-1)],e=ease(u)
    let aw=number(a,"w"),bw=number(b,"w"),w=exp(log(aw)+(log(bw)-log(aw))*e)
    let ax=number(a,"x")+aw/2,bx=number(b,"x")+bw/2
    let ay=number(a,"y")+aw/aspect/2,by=number(b,"y")+bw/aspect/2
    return CGRect(x:ax+(bx-ax)*e-w/2,y:ay+(by-ay)*e-w/aspect/2,width:w,height:w/aspect)
}
func drawAsset(_ c:CGContext,_ asset:[String:Any],_ cam:CGRect) {
    let r=asset["rect"] as! [Double],sx=viewport.width/cam.width,sy=viewport.height/cam.height
    drawImage(c,image(asset["file"] as! String),CGRect(x:viewport.minX+(r[0]-cam.minX)*sx,y:viewport.minY+(r[1]-cam.minY)*sy,width:r[2]*sx,height:r[3]*sy))
    for layer in asset["layers"] as? [[String:Any]] ?? []{drawAsset(c,layer,cam)}
}
func pointer(_ c:CGContext,_ x:Double,_ y:Double,_ down:Bool) {
    c.saveGState();c.translateBy(x:x,y:y);let s=down ? 0.85:1.0;c.scaleBy(x:s,y:s)
    let p=CGMutablePath();p.move(to:.zero)
    for v in [(1.0,43.0),(12.0,33.0),(20.0,50.0),(30.0,45.0),(22.0,28.0),(37.0,27.0)]{p.addLine(to:CGPoint(x:v.0,y:v.1))}
    p.closeSubpath();c.setFillColor(color("#FFFFFF"));c.setStrokeColor(color("#161616"));c.setLineWidth(2.5);c.addPath(p);c.drawPath(using:.fillStroke);c.restoreGState()
}
func frame(_ t:Double)->CGImage {
    let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:colorSpace,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:Double(height));c.scaleBy(x:scale,y:-scale)
    c.setFillColor(color(background));c.fill(CGRect(x:0,y:0,width:1920,height:1080))
    if let title=content["title"] as? String{text(c,title,96,144,number(content,"title_size",72),foreground)}
    let cam=camera(t),index=shots.lastIndex(where:{number($0,"time")<=t}) ?? 0,shot=shots[index]
    let fade=number(shot,"fade",0.5),progress=fade>0 ? ease((t-number(shot,"time"))/fade):1
    c.saveGState();c.addPath(CGPath(roundedRect:viewport,cornerWidth:22,cornerHeight:22,transform:nil));c.clip()
    c.setFillColor(color(content["viewport_background"] as? String ?? "#FFFFFF"));c.fill(viewport)
    if index>0 && progress<1{drawAsset(c,assets[shots[index-1]["asset"] as! String]!,cam)}
    c.saveGState();c.setAlpha(index==0 ? 1:progress);drawAsset(c,assets[shot["asset"] as! String]!,cam);c.restoreGState()
    if !pointers.isEmpty {
        let(i,u)=segment(t,pointers),a=pointers[i],b=pointers[min(i+1,pointers.count-1)],e=ease(u)
        if a["visible"] as? Bool ?? true {
            let x=number(a,"x")+(number(b,"x")-number(a,"x"))*e,y=number(a,"y")+(number(b,"y")-number(a,"y"))*e
            let px=viewport.minX+(x-cam.minX)*viewport.width/cam.width,py=viewport.minY+(y-cam.minY)*viewport.height/cam.height
            if viewport.contains(CGPoint(x:px,y:py)){pointer(c,px,py,a["down"] as? Bool ?? false)}
        }
    }
    c.restoreGState()
    if let caption=captions.last(where:{number($0,"time")<=t}) {
        c.saveGState();c.setAlpha(ease((t-number(caption,"time"))/max(0.001,number(caption,"fade",0.3))))
        text(c,caption["text"] as! String,96,1032,number(content,"caption_size",56),caption["color"] as? String ?? foreground);c.restoreGState()
    }
    return c.makeImage()!
}
func png(_ im:CGImage,_ file:String){try! NSBitmapImageRep(cgImage:im).representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent(file))}
png(frame(min(duration-0.001,number(cfg,"poster_time",0))),"poster.png")
png(frame(duration-0.001),"end.png")
let samples=option("--sample-times")?.split(separator:",").map{Double($0)!} ?? (cfg["preview_times"] as? [Double] ?? [0,duration*0.2,duration*0.4,duration*0.6,duration*0.8,duration-0.001])
precondition(samples.allSatisfy{$0>=0 && $0<=duration},"Sample times must stay inside the scene")
let sheet=CGContext(data:nil,width:1920,height:1080,bitsPerComponent:8,bytesPerRow:0,space:colorSpace,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
sheet.translateBy(x:0,y:1080);sheet.scaleBy(x:1,y:-1);sheet.setFillColor(color(background));sheet.fill(CGRect(x:0,y:0,width:1920,height:1080))
for(i,t)in samples.enumerated(){let im=frame(min(t,duration-0.001));png(im,String(format:"frame-%02d.png",i));if i<6{let x=Double(i%3)*640,y=Double(i/3)*540;drawImage(sheet,im,CGRect(x:x,y:y,width:640,height:360));text(sheet,String(format:"%.3f s",t),x+20,y+405,42,foreground)}}
png(sheet.makeImage()!,"contact-sheet.png")

// Measure the available source pixels at each camera anchor. A detail layer only
// qualifies when it covers the entire camera view; otherwise the base is needed.
func density(_ asset:[String:Any],_ cam:CGRect)->(Double,String)? {
    let r=asset["rect"] as! [Double],rect=CGRect(x:r[0],y:r[1],width:r[2],height:r[3]);let im=image(asset["file"] as! String)
    var best:(Double,String)?=rect.insetBy(dx:-0.001,dy:-0.001).contains(cam) ? (min(Double(im.width)/r[2],Double(im.height)/r[3]),asset["file"] as! String):nil
    for layer in asset["layers"] as? [[String:Any]] ?? []{if let d=density(layer,cam),d.0>(best?.0 ?? 0){best=d}}
    return best
}
var densityChecks:[[String:Any]]=[]
for key in cameras {
    let t=number(key,"time"),cam=camera(t),shot=shots.last(where:{number($0,"time")<=t})!,asset=assets[shot["asset"] as! String]!
    let d=density(asset,cam),required=viewport.width*scale/cam.width
    densityChecks.append(["time":t,"asset":shot["asset"]!,"required_source_dpr":required,"available_source_dpr":d?.0 ?? 0,"upsampling_ratio":d.map{required/$0.0} ?? -1,"full_camera_covered":d != nil,"source_file":d?.1 ?? ""])
}
try JSONSerialization.data(withJSONObject:["camera_anchors":densityChecks,"interpretation":"Upsampling ratio >1 enlarges source pixels. Values concern geometry, not proof that a capture contains every SVG layer. Inspect encoded frames and detail-crop boundaries."],options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("source-density.json"))

if args.contains("--video") {
    let url=out.appendingPathComponent("movie.mp4");try? FileManager.default.removeItem(at:url)
    let writer=try AVAssetWriter(outputURL:url,fileType:.mp4)
    let bitrate=Int(number(cfg,"bitrate",Double(width*height*fps)*0.12))
    let input=AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:width,AVVideoHeightKey:height,AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:bitrate,AVVideoExpectedSourceFrameRateKey:fps,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]])
    let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
    input.expectsMediaDataInRealTime=false;writer.add(input)
    guard writer.startWriting() else{fatalError("\(String(describing:writer.error))")};writer.startSession(atSourceTime:.zero)
    for n in 0..<Int(ceil(duration*Double(fps))) {
        while !input.isReadyForMoreMediaData{if writer.status != .writing{fatalError("\(String(describing:writer.error))")};Thread.sleep(forTimeInterval:0.002)}
        autoreleasepool {
            let im=frame(Double(n)/Double(fps));var px:CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil,adaptor.pixelBufferPool!,&px)==kCVReturnSuccess else{fatalError("Pixel buffer allocation failed")}
            let buffer=px!;CVBufferSetAttachment(buffer,kCVImageBufferCGColorSpaceKey,colorSpace,.shouldPropagate);CVPixelBufferLockBaseAddress(buffer,[])
            let c=CGContext(data:CVPixelBufferGetBaseAddress(buffer),width:width,height:height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:colorSpace,bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
            c.draw(im,in:CGRect(x:0,y:0,width:width,height:height));CVPixelBufferUnlockBaseAddress(buffer,[])
            guard adaptor.append(buffer,withPresentationTime:CMTime(value:Int64(n),timescale:Int32(fps))) else{fatalError("\(String(describing:writer.error))")}
        }
    }
    input.markAsFinished();writer.endSession(atSourceTime:CMTime(seconds:duration,preferredTimescale:600))
    let finished=DispatchSemaphore(value:0);writer.finishWriting{finished.signal()};finished.wait()
    guard writer.status == .completed else{fatalError("\(String(describing:writer.error))")}
}
let report:[String:Any]=["width":width,"height":height,"fps":fps,"duration":duration,"config":configPath,"source":"Lossless states composed with one deterministic camera; not uninterrupted native screen capture."]
try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("render-manifest.json"))
