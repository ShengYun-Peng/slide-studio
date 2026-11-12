// Slide Studio: deterministic, content-driven presentation motion.
// Compile: swiftc runtime/swift/main.swift -o .build/slide-motion
// Run: slide-motion --config scenes/<id>/scene.json --output <directory> --video
import Foundation
import AppKit
import CoreGraphics
import CoreText
import CoreImage
import AVFoundation
import SceneKit
import Metal
import simd

let fm = FileManager.default
let args = CommandLine.arguments
func argument(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}
func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8)); exit(1)
}
guard let configPath = argument("--config"), let outputPath = argument("--output") else {
    fail("Usage: slide-motion --config scene.json --output directory [--preview | --video]")
}
let configURL = URL(fileURLWithPath: configPath).standardizedFileURL
let outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
let data: Data
let raw: [String: Any]
do {
    data = try Data(contentsOf: configURL)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { fail("Config must be a JSON object") }
    raw = object
    try fm.createDirectory(at: outputURL, withIntermediateDirectories: true)
} catch { fail("Configuration: \(error)") }
let kind = raw["kind"] as? String ?? ""
let supportedKinds = ["video-budget"]
guard supportedKinds.contains(kind) else { fail("Unknown scene kind: \(kind)") }
let width = raw["width"] as? Int ?? 1280
let height = raw["height"] as? Int ?? 720
let fps = raw["fps"] as? Int ?? 30
let duration = raw["duration"] as? Double ?? 9
let theme = raw["theme"] as? [String: Any] ?? [:]
let content = raw["content"] as? [String: Any] ?? [:]
let timing = raw["timing"] as? [String: Any] ?? [:]
for key in ["parts","modules","apps"] {
    if let labels=content[key] as? [String], labels.isEmpty {fail("content.\(key) must not be empty")}
}
if let groups=content["papers"] as? [[String]],groups.isEmpty {fail("content.papers must not be empty")}

guard width >= 320, height >= 180, width % 2 == 0, height % 2 == 0,
      abs(Double(width) / Double(height) - 16.0 / 9.0) < 0.001,
      fps >= 1, fps <= 120, duration > 0, duration <= 300 else {
    fail("Expected an even 16:9 size, 1–120 fps, and a duration in (0, 300]")
}
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

let W=width,H=height,space=cs
let bg=theme["background"] as? String ?? "#2B2B2D",white=theme["foreground"] as? String ?? "#F6F6F4",frameBlue="#9BCCFF",tokenGold="#F9BA77",lineGray="#8B949E",lmPurple="#D3B3F0"
func color(_ h:String,_ a:Double=1)->CGColor {c(h,a)}
func label(_ g:CGContext,_ s:String,_ x:Double,_ y:Double,_ size:Double,_ col:String,_ bold:Bool=false,_ center:Bool=true,_ alpha:Double=1) {
 let f=NSFont.systemFont(ofSize:size,weight:bold ? .semibold:.regular)
 let text=CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:f,.foregroundColor:NSColor(cgColor:c(col,alpha))!]))
 let w=CTLineGetTypographicBounds(text,nil,nil,nil);g.saveGState();g.translateBy(x:center ? x-w/2:x,y:y);g.scaleBy(x:1,y:-1);g.textMatrix = .identity;g.textPosition = .zero;CTLineDraw(text,g);g.restoreGState()
}
func value(_ k:String,_ fallback:String)->String {content[k] as? String ?? fallback}
func clamp(_ x:Double)->Double{max(0,min(1,x))}
func smooth(_ x:Double)->Double{let u=clamp(x);return u*u*(3-2*u)}
func mix(_ a:Double,_ b:Double,_ u:Double)->Double{a+(b-a)*u}
func c(_ h:String,_ alpha:Double=1)->CGColor{let n=UInt32(h.dropFirst(),radix:16)!;return CGColor(colorSpace:space,components:[Double((n>>16)&255)/255,Double((n>>8)&255)/255,Double(n&255)/255,alpha])!}
func pt(_ x:Double,_ y:Double)->CGPoint{CGPoint(x:x,y:y)}
func line(_ g:CGContext,_ points:[CGPoint],_ color:String,_ width:Double=3,_ alpha:Double=1){guard points.count>1 && alpha>0 else{return};g.saveGState();g.setStrokeColor(c(color,alpha));g.setLineWidth(width);g.setLineCap(.round);g.setLineJoin(.round);g.beginPath();g.move(to:points[0]);for p in points.dropFirst(){g.addLine(to:p)};g.strokePath();g.restoreGState()}
func box(_ g:CGContext,_ r:CGRect,_ stroke:String,_ fill:String,_ width:Double=3,_ alpha:Double=1,_ fillAlpha:Double=1,_ radius:Double=18){g.saveGState();g.setAlpha(alpha);let path=CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil);g.addPath(path);g.setFillColor(c(fill,fillAlpha));g.fillPath();g.addPath(path);g.setStrokeColor(c(stroke));g.setLineWidth(width);g.strokePath();g.restoreGState()}
func arrow(_ g:CGContext,_ x0:Double,_ x1:Double,_ y:Double,_ a:Double){line(g,[pt(x0,y),pt(x1,y)],lineGray,3.5,a);line(g,[pt(x1-10,y-7),pt(x1,y),pt(x1-10,y+7)],lineGray,3.5,a)}
func dot(_ g:CGContext,_ p:CGPoint,_ radius:Double,_ color:String,_ alpha:Double=1){g.setFillColor(c(color,alpha));g.fillEllipse(in:CGRect(x:p.x-radius,y:p.y-radius,width:radius*2,height:radius*2))}
func packet(_ g:CGContext,_ t:Double,_ start:Double,_ end:Double,_ x0:Double,_ x1:Double,_ y:Double,_ color:String){let u=(t-start)/(end-start);if u<0 || u>1{return};let a=smooth(u/0.12)*(1-smooth((u-0.88)/0.12));let x=mix(x0,x1,smooth(u));box(g,CGRect(x:x-7,y:y-7,width:14,height:14),color,color,1,a,1,3)}
func videoCard(_ g:CGContext,_ index:Int,_ t:Double){
 let x=125.0+Double(index)*40,y=375.0+Double(index)*35,r=CGRect(x:x,y:y,width:245,height:150)
 let a=smooth((t-(0.15+Double(index)*0.7))/0.7)
 guard a>0 else{return}
 box(g,r,frameBlue,"#303B47",3.5,a,1,14)
 g.saveGState();g.setAlpha(a);g.addPath(CGPath(roundedRect:r.insetBy(dx:4,dy:4),cornerWidth:10,cornerHeight:10,transform:nil));g.clip()
 // Abstract sequence: identical scene, changing object position; no empirical evidence.
 line(g,[pt(x+22,y+109),pt(x+78,y+78),pt(x+130,y+98),pt(x+222,y+40)],frameBlue,2.8,0.32)
 line(g,[pt(x+22,y+119),pt(x+222,y+119)],frameBlue,2,0.2)
 let objectX=x+55+Double(index)*64,objectY=y+91-Double(index)*18
 dot(g,pt(objectX,objectY),12,frameBlue,0.94)
 dot(g,pt(objectX,objectY),22,frameBlue,0.10)
 for j in 0..<3{dot(g,pt(x+19+Double(j)*10,y+17),2.4,frameBlue,j==index ? 1:0.28)}
 // Smooth scan passes stay inside each card and then emit a feature packet.
 let s=(t-(3.0+Double(index)*0.38))/1.15
 if s>0 && s<1{let scanX=x+10+225*s;g.setFillColor(c(frameBlue,0.12));g.fill(CGRect(x:scanX-10,y:y+5,width:20,height:140));line(g,[pt(scanX,y+7),pt(scanX,y+143)],frameBlue,3.5,smooth(s/0.1)*(1-smooth((s-0.9)/0.1)))}
 g.restoreGState()
}
func frame(_ g:CGContext,_ t:Double){
 g.saveGState();g.translateBy(x:0,y:Double(H));g.scaleBy(x:Double(W)/1920,y:-Double(H)/1080);g.setFillColor(c(bg));g.fill(CGRect(x:0,y:0,width:1920,height:1080))
 // Low-contrast stable containers support native labels from the first frame.
 let encoderActivation=smooth((t-3)/0.8),languageActivation=smooth((t-11)/1.0)
 box(g,CGRect(x:655,y:370,width:300,height:220),"#78838F","#30363D",3.5,1,1,20)
 box(g,CGRect(x:655,y:370,width:300,height:220),frameBlue,"#344351",3.5,encoderActivation,1,20)
 box(g,CGRect(x:1450,y:370,width:300,height:220),"#78838F","#30363D",3.5,1,1,22)
 box(g,CGRect(x:1450,y:370,width:300,height:220),lmPurple,"#403549",3.5,languageActivation,1,22)
 arrow(g,475,634,480,smooth((t-2.8)/0.6))
 arrow(g,975,1088,480,smooth((t-5.7)/0.6))
 arrow(g,1355,1431,480,smooth((t-10.8)/0.6))
 for i in 0..<3{videoCard(g,i,t)}
 for i in 0..<3{packet(g,t,4.0+Double(i)*0.4,5.4+Double(i)*0.3,480,635,480,frameBlue)}
 // Encoder internals stay clear because editable native words occupy its center.
 let scan=smooth((t-3)/0.8)*(1-smooth((t-5.5)/0.5))
 line(g,[pt(676,565),pt(676+258*clamp((t-3)/3),565)],frameBlue,5,scan)
 for i in 0..<20{
  let col=i%5,row=i/5,x=1110.0+Double(col)*49,y=395.0+Double(row)*49
  let a=smooth((t-(6.0+Double(i)*0.22))/0.55)
  if a>0{box(g,CGRect(x:x,y:y,width:34,height:34),tokenGold,tokenGold,2,a,0.88,5)}
 }
 for i in 0..<3{packet(g,t,5.9+Double(i)*0.5,7.1+Double(i)*0.5,977,1089,480,tokenGold)}
 for i in 0..<5{packet(g,t,11.0+Double(i)*0.65,12.4+Double(i)*0.65,1355,1431,480,tokenGold)}
 // Quiet progress accent, below native language-model words, settles at 15 s.
 let lm=smooth((t-11)/4)
 if lm>0{line(g,[pt(1470,565),pt(1470+260*lm,565)],lmPurple,5,0.8)}
 g.restoreGState()
}

func render(_ elapsed:Double)->CGImage {
 let g=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 let t=elapsed/duration*20;frame(g,t)
 g.translateBy(x:0,y:Double(height));g.scaleBy(x:Double(width)/1920,y:-Double(height)/1080)
 label(g,value("title","Spend compute on the visual evidence that matters."),96,138,64,white,true,false)
 label(g,value("frames_label","Frames"),285,690,50,frameBlue,true)
 label(g,value("frames_detail","Temporal coverage"),285,750,34,"#BAC1CC")
 label(g,"Vision",805,465,44,white,true);label(g,"encoder",805,520,44,white,true)
 label(g,value("tokens_label","Visual tokens"),1225,690,50,tokenGold,true)
 label(g,value("tokens_detail","Detail per frame"),1225,750,34,"#BAC1CC")
 label(g,"Language",1600,465,44,white,true);label(g,"model",1600,520,44,white,true)
 label(g,value("capacity_label","Model capacity"),1600,690,50,lmPurple,true)
 label(g,"Reasoning capacity",1600,750,34,"#BAC1CC")
 let a=smooth((t-13)/1.5)
 box(g,CGRect(x:240,y:855,width:1440,height:120),"#5B616A","#34363B",2,a,1,20)
 label(g,value("cost_label","Inference cost = visual processing + language reasoning"),960,930,43,white,true,true,a)
 return g.makeImage()!
}
func savePNG(_ im:CGImage,_ name:String) {try! NSBitmapImageRep(cgImage:im).representation(using:.png,properties:[:])!.write(to:outputURL.appendingPathComponent(name))}
let times=(raw["preview_times"] as? [Double] ?? [0,duration*0.2,duration*0.4,duration*0.6,duration*0.8,duration])
let posterTime=raw["poster_time"] as? Double ?? duration
savePNG(render(posterTime),"poster.png");savePNG(render(duration),"end.png")
let sheet=CGContext(data:nil,width:1920,height:808,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
sheet.setFillColor(color(bg));sheet.fill(CGRect(x:0,y:0,width:1920,height:808))
for i in 0..<min(6,times.count) {let x=Double(i%3)*640,y=808-Double(i/3)*404-360;sheet.draw(render(times[i]),in:CGRect(x:x,y:y,width:640,height:360))}
savePNG(sheet.makeImage()!,"contact-sheet.png")
var videoMetadata:[String:Any]=[:]
if args.contains("--video") {
    let movie=outputURL.appendingPathComponent("movie.mp4")
    if fm.fileExists(atPath:movie.path){try! fm.removeItem(at:movie)}
    let writer:AVAssetWriter
    do{writer=try AVAssetWriter(outputURL:movie,fileType:.mp4)}catch{fail("Movie writer: \(error)")}
    let transfer:String
    if #available(macOS 15.0,*) {transfer=AVVideoTransferFunction_IEC_sRGB} else {transfer=AVVideoTransferFunction_ITU_R_709_2}
    let settings:[String:Any]=[AVVideoColorPropertiesKey:[AVVideoColorPrimariesKey:AVVideoColorPrimaries_ITU_R_709_2,AVVideoTransferFunctionKey:transfer,AVVideoYCbCrMatrixKey:AVVideoYCbCrMatrix_ITU_R_709_2],AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:width,AVVideoHeightKey:height,AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:width*height*8,AVVideoExpectedSourceFrameRateKey:fps,AVVideoMaxKeyFrameIntervalKey:fps*2,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]]
    let input=AVAssetWriterInput(mediaType:.video,outputSettings:settings);input.expectsMediaDataInRealTime=false
    let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
    guard writer.canAdd(input) else{fail("Unsupported video settings")};writer.add(input)
    guard writer.startWriting() else{fail("Cannot start writing: \(writer.error?.localizedDescription ?? "unknown")")};writer.startSession(atSourceTime:.zero)
    let count=Int(ceil(duration*Double(fps)))
    for i in 0..<count {
        while !input.isReadyForMoreMediaData {if writer.status == .failed{fail("Writer failed: \(writer.error!)")};Thread.sleep(forTimeInterval:0.002)}
        autoreleasepool {
            let image=render(Double(i)/Double(fps))
            var pixel:CVPixelBuffer?;let result=CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,adaptor.pixelBufferPool!,&pixel)
            guard result == kCVReturnSuccess,let pb=pixel else{fail("Pixel buffer allocation failed")}
            CVBufferSetAttachment(pb,kCVImageBufferCGColorSpaceKey,cs,.shouldPropagate)
            CVBufferSetAttachment(pb,kCVImageBufferColorPrimariesKey,kCVImageBufferColorPrimaries_ITU_R_709_2,.shouldPropagate)
            CVBufferSetAttachment(pb,kCVImageBufferTransferFunctionKey,kCVImageBufferTransferFunction_sRGB,.shouldPropagate)
            CVPixelBufferLockBaseAddress(pb,[])
            let c=CGContext(data:CVPixelBufferGetBaseAddress(pb),width:width,height:height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pb),space:cs,bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
            c.draw(image,in:CGRect(x:0,y:0,width:width,height:height));CVPixelBufferUnlockBaseAddress(pb,[])
            if !adaptor.append(pb,withPresentationTime:CMTime(value:Int64(i),timescale:Int32(fps))){fail("Frame append: \(writer.error?.localizedDescription ?? "unknown")")}
        }
        if i%max(1,fps*2)==0{print("\(kind): \(i)/\(count) frames")}
    }
    input.markAsFinished();writer.endSession(atSourceTime:CMTime(seconds:duration,preferredTimescale:600))
    let done=DispatchSemaphore(value:0);writer.finishWriting{done.signal()};done.wait()
    guard writer.status == .completed else{fail("Video incomplete: \(writer.error?.localizedDescription ?? "unknown")")}
    videoMetadata=["filename":"movie.mp4","codec":"H.264","frames":count,"fps":fps,"duration":duration,"silent":true,"color_primaries":"ITU-R BT.709","transfer":"sRGB on macOS 15+; BT.709 fallback"]
}
let manifest:[String:Any]=["schema_version":1,"kind":kind,"renderer":"Slide Studio Swift renderer","config_filename":configURL.lastPathComponent,"width":width,"height":height,"duration":duration,"fps":fps,"preview_times":times,"poster_time":posterTime,"scientific_status":kind.hasPrefix("surface") || kind == "text-and-score" ? "illustrative" : "conceptual","outputs":["poster.png","end.png","contact-sheet.png"],"video":videoMetadata,"notes":"Presentation playback should start automatically within a slide; slide advance remains a separate setting."]
do{let json=try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]);try json.write(to:outputURL.appendingPathComponent("render-manifest.json"))}catch{fail("Manifest: \(error)")}
print("Rendered \(kind) → \(outputURL.path)")
