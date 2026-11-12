// Slide Studio — vector cinematic title reveal. No third-party dependencies.
// The default scene is entirely procedural. Optional PDF/video media is read-only.
import Foundation
import AppKit
import CoreGraphics
import CoreText
import CoreImage
import AVFoundation

let fm=FileManager.default,args=CommandLine.arguments
func argument(_ s:String)->String? {guard let i=args.firstIndex(of:s),i+1<args.count else{return nil};return args[i+1]}
func fail(_ s:String)->Never {FileHandle.standardError.write(Data((s+"\n").utf8));exit(1)}
guard let cp=argument("--config"),let op=argument("--output") else{fail("--config scene.json --output directory [--preview|--video]")}
let configURL=URL(fileURLWithPath:cp).standardizedFileURL,out=URL(fileURLWithPath:op).standardizedFileURL
let raw=try JSONSerialization.jsonObject(with:Data(contentsOf:configURL)) as! [String:Any]
try fm.createDirectory(at:out,withIntermediateDirectories:true)
let content=raw["content"] as? [String:Any] ?? [:],timing=raw["timing"] as? [String:Double] ?? [:]
let width=raw["width"] as? Int ?? 1920,height=raw["height"] as? Int ?? 1080,fps=raw["fps"] as? Int ?? 60,duration=raw["duration"] as? Double ?? 8
guard width>0,height>0,width%2==0,height%2==0,fps>0,duration>0,abs(Double(width)/Double(height)-16/9)<0.001 else{fail("Expected even 16:9 dimensions, positive fps/duration")}
let cs=CGColorSpace(name:CGColorSpace.sRGB)!,ci=CIContext(options:[.cacheIntermediates:false])
let W=1920.0,H=1080.0
func str(_ k:String,_ d:String)->String{content[k] as? String ?? d}
func val(_ k:String,_ d:Double)->Double{(content[k] as? NSNumber)?.doubleValue ?? d}
func clamp(_ x:Double)->Double{max(0,min(1,x))}
func smooth(_ x:Double)->Double{let q=clamp(x);return q*q*q*(q*(q*6-15)+10)}
func ease(_ t:Double,_ a:Double,_ b:Double)->Double{smooth((t-a)/max(0.001,b-a))}
func event(_ k:String,_ f:Double)->Double{timing[k] ?? f*duration}
func phase(_ t:Double,_ k:String,_ l:String,_ a:Double,_ b:Double)->Double{ease(t,event(k,a),event(l,b))}
func col(_ hex:String,_ a:Double=1)->CGColor {let n=UInt64(hex.replacingOccurrences(of:"#",with:""),radix:16) ?? 0xFFFFFF;return CGColor(colorSpace:cs,components:[Double((n>>16)&255)/255,Double((n>>8)&255)/255,Double(n&255)/255,clamp(a)])!}
func rgba(_ r:Double,_ g:Double,_ b:Double,_ a:Double=1)->CGColor{CGColor(colorSpace:cs,components:[r,g,b,clamp(a)])!}
func drawImage(_ c:CGContext,_ im:CGImage,_ r:CGRect){c.saveGState();c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.draw(im,in:CGRect(x:0,y:0,width:r.width,height:r.height));c.restoreGState()}
func gradient(_ c:CGContext,_ colors:[CGColor],_ locations:[CGFloat],_ a:CGPoint,_ b:CGPoint){let g=CGGradient(colorsSpace:cs,colors:colors as CFArray,locations:locations)!;c.drawLinearGradient(g,start:a,end:b,options:[.drawsBeforeStartLocation,.drawsAfterEndLocation])}
func glow(_ c:CGContext,_ x:Double,_ y:Double,_ rx:Double,_ ry:Double,_ color:CGColor,_ alpha:Double){
    c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:rx,y:ry);let rgb=color.components!;let g=CGGradient(colorsSpace:cs,colors:[rgba(rgb[0],rgb[1],rgb[2],alpha),rgba(rgb[0],rgb[1],rgb[2],alpha*0.22),rgba(rgb[0],rgb[1],rgb[2],0)] as CFArray,locations:[0,0.4,1])!;c.drawRadialGradient(g,startCenter:.zero,startRadius:0,endCenter:.zero,endRadius:1,options:[]);c.restoreGState()
}
func text(_ c:CGContext,_ s:String,_ y:Double,_ size:Double,_ color:CGColor,_ tracking:Double=0,_ weight:String="HelveticaNeue"){
    let f=CTFontCreateWithName(weight as CFString,size,nil)
    let line=CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:f,.foregroundColor:color,.kern:tracking]))
    let w=CTLineGetTypographicBounds(line,nil,nil,nil);c.saveGState();c.translateBy(x:(W-w)/2,y:y);c.scaleBy(x:1,y:-1);c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(line,c);c.restoreGState()
}
func glyphPath(_ s:String,_ fontName:String,_ size:Double,_ tracking:Double)->CGPath{
    let f=CTFontCreateWithName(fontName as CFString,size,nil),line=CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:f,.kern:tracking]))
    let total=CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun]{let n=CTRunGetGlyphCount(run);var glyphs=[CGGlyph](repeating:0,count:n),points=[CGPoint](repeating:.zero,count:n);CTRunGetGlyphs(run,CFRange(location:0,length:0),&glyphs);CTRunGetPositions(run,CFRange(location:0,length:0),&points);for i in 0..<n{if let p=CTFontCreatePathForGlyph(f,glyphs[i],nil){total.addPath(p,transform:CGAffineTransform(translationX:points[i].x,y:points[i].y))}}}
    let b=total.boundingBoxOfPath,scale=min(1,val("max_title_width",1510)/b.width)
    // Flip font coordinates once; path has top-left geometry for all subsequent passes.
    var transform=CGAffineTransform(a:scale,b:0,c:0,d:-scale,tx:W/2-(b.minX+b.width/2)*scale,ty:val("title_center_y",575)+(b.minY+b.height/2)*scale)
    return total.copy(using:&transform) ?? total
}
let title=str("title","NEXT CHAPTER"),subtitle=str("subtitle","A new direction. A clear promise.")
let titlePath=glyphPath(title,str("font","HelveticaNeue-Bold"),val("font_size",174),val("tracking",8))
let titleBounds=titlePath.boundingBoxOfPath,light=col(str("light_color","#D9E7FF")),logoColor=col(str("logo_color","#B7C8E5"))
func assetURL(_ key:String)->URL?{guard let p=content[key] as? String,!p.isEmpty else{return nil};return p.hasPrefix("/") ? URL(fileURLWithPath:p):configURL.deletingLastPathComponent().appendingPathComponent(p).standardizedFileURL}
let logoPDF=assetURL("logo_pdf").flatMap{CGPDFDocument($0 as CFURL)}
if assetURL("logo_pdf") != nil && logoPDF == nil {fail("Cannot open content.logo_pdf")}
let logoRect=CGRect(x:W/2-56,y:val("logo_y",286),width:112,height:112)
let logoMask:CGImage? = {
    guard let page=logoPDF?.page(at:1) else{return nil}
    let b=page.getBoxRect(.mediaBox),s=4.0
    let c=CGContext(data:nil,width:448,height:448,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    let scale=min(448/b.width,448/b.height);c.translateBy(x:(448-b.width*scale)/2,y:(448-b.height*scale)/2);c.scaleBy(x:scale,y:scale);c.translateBy(x:-b.minX,y:-b.minY);c.drawPDFPage(page)
    _=s;return c.makeImage()
}()
let logoEdges:CGImage? = {
    guard let m=logoMask else{return nil}
    let im=CIImage(cgImage:m)
    let alpha=im.applyingFilter("CIColorMatrix",parameters:["inputRVector":CIVector(x:0,y:0,z:0,w:1),"inputGVector":CIVector(x:0,y:0,z:0,w:1),"inputBVector":CIVector(x:0,y:0,z:0,w:1),"inputAVector":CIVector(x:0,y:0,z:0,w:1)])
    let inner=alpha.applyingFilter("CIMorphologyMinimum",parameters:[kCIInputRadiusKey:3])
    let edge=alpha.applyingFilter("CISubtractBlendMode",parameters:[kCIInputBackgroundImageKey:inner])
    return ci.createCGImage(edge,from:im.extent)
}()
let backgroundURL=assetURL("background_video")
if let u=backgroundURL,!fm.fileExists(atPath:u.path){fail("Cannot open content.background_video")}
let backgroundAsset=backgroundURL.map{AVURLAsset(url:$0)}
let backgroundGenerator=backgroundAsset.map{a->AVAssetImageGenerator in let g=AVAssetImageGenerator(asset:a);g.appliesPreferredTrackTransform=true;g.requestedTimeToleranceBefore = .zero;g.requestedTimeToleranceAfter = .zero;return g}
let backgroundDuration=backgroundAsset?.duration.seconds ?? 1

func logo(_ c:CGContext,_ t:Double,_ face:Double,_ sweep:Double,_ env:Double){
    if str("logo_kind","monogram")=="none"{return}
    if let mask=logoMask {
        c.saveGState();c.setAlpha(face);drawImage(c,mask,logoRect);c.restoreGState()
        if let edge=logoEdges,env>0 {
            c.saveGState();c.setBlendMode(.screen);c.setAlpha(env*0.8)
            // A sharp vector-derived edge, not a permanently blurred low-res halo.
            drawImage(c,edge,logoRect);c.restoreGState()
        }
    } else {
        // Original abstract aperture mark: two offset open arcs plus a central seam.
        let center=CGPoint(x:960,y:342),radius=48.0
        let p=CGMutablePath();p.addArc(center:center,radius:radius,startAngle:.pi*0.18,endAngle:.pi*1.7,clockwise:false)
        p.addArc(center:center,radius:radius-16,startAngle:.pi*1.18,endAngle:.pi*2.7,clockwise:false)
        c.addPath(p);c.setStrokeColor(logoColor.copy(alpha:face*0.85)!);c.setLineWidth(6);c.setLineCap(.round);c.strokePath()
        if env>0 {
            let a=sweep*2.4*Double.pi - Double.pi*0.4
            let q=CGMutablePath();q.addArc(center:center,radius:radius,startAngle:a-0.38,endAngle:a+0.03,clockwise:false)
            c.addPath(q);c.setStrokeColor(col("#FFFFFF",env));c.setLineWidth(6);c.strokePath()
            glow(c,960+radius*cos(a),342+radius*sin(a),23,23,light,env*0.14)
        }
    }
}

func rim(_ c:CGContext,_ path:CGPath,_ x:Double,_ y:Double,_ spread:Double,_ alpha:Double,_ stroke:Double){
    guard alpha>0 else{return};c.saveGState();c.addPath(path);c.setLineWidth(stroke);c.setLineJoin(.round);c.replacePathWithStrokedPath();c.clip()
    let comps=light.components!;gradient(c,[rgba(comps[0],comps[1],comps[2],0),rgba(comps[0],comps[1],comps[2],alpha*0.25),rgba(1,1,1,alpha),rgba(comps[0],comps[1],comps[2],alpha*0.12),rgba(comps[0],comps[1],comps[2],0)],[0,0.32,0.52,0.7,1],CGPoint(x:x-spread,y:y-90),CGPoint(x:x+spread,y:y+90));c.restoreGState()
}

func render(_ t:Double)->CGImage {
    let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:Double(height));c.scaleBy(x:Double(width)/W,y:-Double(height)/H)
    gradient(c,[col("#030508"),col("#11151D"),col("#06080D")],[0,0.66,1],CGPoint(x:0,y:0),CGPoint(x:W*0.3,y:H))
    let atmosphere=phase(t,"atmosphere_start","atmosphere_end",0,0.3)
    let sweep=phase(t,"sweep_start","sweep_end",0.07,0.43)
    let reveal=phase(t,"face_start","face_end",0.17,0.55)
    let endRim=1-phase(t,"rim_fade_start","rim_fade_end",0.43,0.63)
    let env=phase(t,"rim_start","rim_full",0.025,0.09)*endRim
    let sweepX=titleBounds.minX-140+(titleBounds.width+280)*sweep
    let push=1+0.012*(1-ease(t,0,duration*0.7))
    // Broad moving studio illumination remains secondary to glyph edges.
    glow(c,630+380*sweep,520,800,520,light,0.055*atmosphere*(1-reveal*0.65))
    glow(c,1280-160*sweep,720,620,320,col("#CCA985"),0.025*atmosphere)
    if let g=backgroundGenerator {
        let amount=phase(t,"background_start","background_end",0.36,0.61)
        if amount>0 {
            let bt=max(0,min(backgroundDuration-1/Double(fps),t-event("background_start",0.36)))
            if let image=try? g.copyCGImage(at:CMTime(seconds:bt,preferredTimescale:600),actualTime:nil) {
                c.saveGState();c.setAlpha(amount*val("background_opacity",0.60));drawImage(c,image,CGRect(x:0,y:0,width:W,height:H));c.restoreGState()
                gradient(c,[col("#030508",0.55*amount),col("#030508",0.12*amount),col("#030508",0.38*amount)],[0,0.50,1],CGPoint(x:0,y:0),CGPoint(x:0,y:H))
            }
        }
    }
    c.saveGState();c.translateBy(x:960,y:540);c.scaleBy(x:push,y:push);c.translateBy(x:-960,y:-540)
    // The front face has a soft platinum material: no hard bevel or black outline.
    c.saveGState();c.setAlpha(phase(t,"face_alpha_start","face_alpha_end",0.08,0.28));c.addPath(titlePath);c.clip()
    let e=0.018+0.982*reveal
    gradient(c,[rgba(0.94*e,0.965*e,0.995*e),rgba(0.76*e,0.80*e,0.86*e),rgba(0.91*e,0.925*e,0.94*e)],[0,0.73,1],CGPoint(x:0,y:titleBounds.minY),CGPoint(x:0,y:titleBounds.maxY))
    let sheen=phase(t,"sheen_start","sheen_end",0.33,0.67)
    let sx=titleBounds.minX-160+(titleBounds.width+320)*sheen
    let sa=sin(Double.pi*sheen)*0.19*reveal
    gradient(c,[col("#FFFFFF",0),col("#FFFFFF",sa),col("#FFFFFF",0)],[0,0.5,1],CGPoint(x:sx-110,y:titleBounds.minY),CGPoint(x:sx+110,y:titleBounds.maxY))
    c.restoreGState()
    // Three precise stroked passes: thin core, restrained surrounding light,
    // and a reflected return sweep. They all use the original glyph paths.
    rim(c,titlePath,sweepX,titleBounds.midY,170,env*0.20,8)
    rim(c,titlePath,sweepX,titleBounds.midY,140,env,1.7)
    rim(c,titlePath,titleBounds.maxX+100-(titleBounds.width+200)*sweep,titleBounds.midY,105,env*0.45,1)
    glow(c,sweepX,titleBounds.midY,165,185,light,env*0.022)
    logo(c,t,reveal,sweep,env*0.75)
    c.restoreGState()
    let caption=phase(t,"subtitle_start","subtitle_end",0.55,0.73)
    if !subtitle.isEmpty {text(c,subtitle,val("subtitle_y",764),val("subtitle_size",34),col("#BAC4D2",caption*0.86),1.7)}
    let eyebrow=str("eyebrow","")
    if !eyebrow.isEmpty {text(c,eyebrow,211,25,col("#B6C7DF",caption*0.66),5.5)}
    return c.makeImage()!
}
func save(_ image:CGImage,_ file:String){try! NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent(file))}
let preview=(raw["preview_times"] as? [Double] ?? [0,duration*0.14,duration*0.27,duration*0.42,duration*0.6,duration-0.02]).map{max(0,min(duration,$0))}
let posterTime=min(duration,raw["poster_time"] as? Double ?? duration*0.83)
save(render(posterTime),"poster.png");save(render(duration-1/Double(fps)),"end.png")
let sheet=CGContext(data:nil,width:1920,height:804,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
sheet.translateBy(x:0,y:804);sheet.scaleBy(x:1,y:-1);sheet.setFillColor(col("#080A10"));sheet.fill(CGRect(x:0,y:0,width:1920,height:804))
for (i,t) in preview.prefix(6).enumerated(){let x=Double(i%3)*640,y=Double(i/3)*402;drawImage(sheet,render(t),CGRect(x:x,y:y,width:640,height:360));sheet.saveGState();sheet.translateBy(x:x-640,y:y-680);text(sheet,String(format:"%0.2f s",t),1070,22,col("#9DA9B9"));sheet.restoreGState()}
save(sheet.makeImage()!,"contact-sheet.png")
var video:[String:Any]=[:]
if args.contains("--video") {
    let movie=out.appendingPathComponent("movie.mp4");if fm.fileExists(atPath:movie.path){try fm.removeItem(at:movie)}
    let writer=try AVAssetWriter(outputURL:movie,fileType:.mp4)
    let transfer:String
    if #available(macOS 15.0,*){transfer=AVVideoTransferFunction_IEC_sRGB}else{transfer=AVVideoTransferFunction_ITU_R_709_2}
    let settings:[String:Any]=[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:width,AVVideoHeightKey:height,AVVideoColorPropertiesKey:[AVVideoColorPrimariesKey:AVVideoColorPrimaries_ITU_R_709_2,AVVideoTransferFunctionKey:transfer,AVVideoYCbCrMatrixKey:AVVideoYCbCrMatrix_ITU_R_709_2],AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:width*height*10,AVVideoExpectedSourceFrameRateKey:fps,AVVideoMaxKeyFrameIntervalKey:fps*2,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]]
    let input=AVAssetWriterInput(mediaType:.video,outputSettings:settings);input.expectsMediaDataInRealTime=false
    let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
    guard writer.canAdd(input) else{fail("Cannot add video input")};writer.add(input);guard writer.startWriting() else{fail("Cannot start writer")};writer.startSession(atSourceTime:.zero)
    let count=Int(ceil(duration*Double(fps)))
    for i in 0..<count {
        while !input.isReadyForMoreMediaData{if writer.status == .failed{fail("Writer failed")};Thread.sleep(forTimeInterval:0.002)}
        autoreleasepool {
            let im=render(Double(i)/Double(fps));var buffer:CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,adaptor.pixelBufferPool!,&buffer)==kCVReturnSuccess,let pb=buffer else{fail("Pixel buffer failed")}
            CVBufferSetAttachment(pb,kCVImageBufferCGColorSpaceKey,cs,.shouldPropagate);CVBufferSetAttachment(pb,kCVImageBufferTransferFunctionKey,kCVImageBufferTransferFunction_sRGB,.shouldPropagate)
            CVPixelBufferLockBaseAddress(pb,[]);let c=CGContext(data:CVPixelBufferGetBaseAddress(pb),width:width,height:height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pb),space:cs,bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!;c.draw(im,in:CGRect(x:0,y:0,width:width,height:height));CVPixelBufferUnlockBaseAddress(pb,[])
            if !adaptor.append(pb,withPresentationTime:CMTime(value:Int64(i),timescale:Int32(fps))){fail("Append failed")}
        }
        if i%120==0{print("cinematic-title: \(i)/\(count)")}
    }
    input.markAsFinished();writer.endSession(atSourceTime:CMTime(seconds:duration,preferredTimescale:600));let done=DispatchSemaphore(value:0);writer.finishWriting{done.signal()};done.wait();guard writer.status == .completed else{fail("Video incomplete")}
    video=["filename":"movie.mp4","codec":"H.264","frames":count,"fps":fps,"duration":duration,"silent":true]
}
let manifest:[String:Any]=["schema_version":1,"kind":"cinematic-title-reveal","renderer":"Vector glyph cinematic reveal","width":width,"height":height,"fps":fps,"duration":duration,"poster_time":posterTime,"preview_times":preview,"video":video,"outputs":["poster.png","end.png","contact-sheet.png","movie.mp4"],"scientific_status":"editorial","asset_status":backgroundURL == nil ? "original procedural demo":"contains third-party local reference footage; redistribution unreviewed"]
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("render-manifest.json"))
print("Rendered cinematic title → \(out.path)")
