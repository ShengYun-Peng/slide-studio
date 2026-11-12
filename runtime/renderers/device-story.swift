// Slide Studio photographic device story. Native frame registration + original UI.
// Hardware provenance: assets/device/provenance.json. No defense path is a runtime dependency.
import Foundation
import AppKit
import CoreText
import CoreImage
import CoreGraphics
import AVFoundation
import VideoToolbox
let args=CommandLine.arguments
func arg(_ k:String)->String?{guard let i=args.firstIndex(of:k),i+1<args.count else{return nil};return args[i+1]}
func fail(_ s:String)->Never{fputs(s+"\n",stderr);exit(1)}
guard let cf=arg("--config"),let of=arg("--output") else{fail("--config FILE --output DIR --preview|--video")}
let configURL=URL(fileURLWithPath:cf),outputURL=URL(fileURLWithPath:of),outputRoot=outputURL
let raw=try JSONSerialization.jsonObject(with:Data(contentsOf:configURL)) as! [String:Any]
let W=raw["width"] as? Int ?? 1920,H=raw["height"] as? Int ?? 1080,fps=raw["fps"] as? Int ?? 60
let duration=raw["duration"] as? Double ?? 16.5,scale=Double(W)/1920
let timing=raw["timing"] as? [String:Double] ?? [:],content=raw["content"] as? [String:Any] ?? [:]
let theme=raw["theme"] as? [String:Any] ?? [:]
let fm=FileManager.default;try fm.createDirectory(at:outputURL,withIntermediateDirectories:true)
let projectRoot=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let hardware=projectRoot.appendingPathComponent("assets/device")
let srgb=CGColorSpace(name:CGColorSpace.sRGB)!,cs=CGColorSpace(name:CGColorSpace.sRGB)!
let ci=CIContext(options:[.workingColorSpace:srgb,.outputColorSpace:srgb])
func loadImage(_ u:URL)->CGImage {let src=CGImageSourceCreateWithURL(u as CFURL,nil)!;return CGImageSourceCreateImageAtIndex(src,0,nil)!}
func assetURL(_ key:String,_ fallback:String)->URL { if let path=content[key] as? String {return path.hasPrefix("/") ? URL(fileURLWithPath:path):configURL.deletingLastPathComponent().appendingPathComponent(path).standardizedFileURL};return hardware.appendingPathComponent(fallback) }
let clip=AVURLAsset(url:assetURL("hardware_video","apple-pv-open-large-2x.mp4"))
let generator=AVAssetImageGenerator(asset:clip);generator.appliesPreferredTrackTransform=true;generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
let clipDuration=CMTimeGetSeconds(clip.duration)
let photo=try generator.copyCGImage(at:CMTime(seconds:clipDuration-1/30,preferredTimescale:600),actualTime:nil)
let photoCI=CIImage(cgImage:photo)
var desktopCI=CIImage(color:CIColor(red:0.02,green:0.025,blue:0.04)).cropped(to:CGRect(x:0,y:0,width:1920,height:1080))
func clamp(_ t:Double)->Double{max(0,min(1,t))}
func smooth(_ t:Double)->Double{let x=clamp(t);return x*x*(3-2*x)}
func ease(_ t:Double)->Double{let x=clamp(t);return x*x*x*(x*(x*6-15)+10)}
func mix(_ a:Double,_ b:Double,_ t:Double)->Double{a+(b-a)*t}
func point(_ a:CGPoint,_ b:CGPoint,_ t:Double)->CGPoint{CGPoint(x:mix(a.x,b.x,t),y:mix(a.y,b.y,t))}
func save(_ im:CGImage,_ file:String){let b=NSBitmapImageRep(cgImage:im);try! b.representation(using:.png,properties:[:])!.write(to:outputRoot.appendingPathComponent(file))}
let fallbackQuad=[[1151.0,580.0],[2906,580],[2750,1031],[1307,1031]]
var tracking:[[String:Any]]=[]
if let data=try? Data(contentsOf:assetURL("screen_tracking","screen-tracking.json")),let json=try? JSONSerialization.jsonObject(with:data) as? [String:Any],let f=json["frames"] as? [[String:Any]] {tracking=f}
func quadAt(_ t:Double)->[CGPoint]{
 if tracking.isEmpty{return fallbackQuad.map{CGPoint(x:$0[0],y:$0[1])}}
 let f=tracking.min{abs(($0["time"] as! Double)-t)<abs(($1["time"] as! Double)-t)}!
 return (f["quad"] as! [[Double]]).map{CGPoint(x:$0[0],y:$0[1])}
}
let sourceQuad=[CGPoint(x:1151,y:580),CGPoint(x:2906,y:580),CGPoint(x:2750,y:1031),CGPoint(x:1307,y:1031)]
let plateScale=0.78,plateOffset=CGPoint(x:960-2028*0.78,y:590-940*0.78)
let initialQuad=sourceQuad.map{CGPoint(x:$0.x*plateScale+plateOffset.x,y:$0.y*plateScale+plateOffset.y)}
let fullQuad=[CGPoint(x:0,y:0),CGPoint(x:1920,y:0),CGPoint(x:1920,y:1080),CGPoint(x:0,y:1080)]
func homography(_ from:[CGPoint],_ to:[CGPoint])->[Double] {
 var a=Array(repeating:Array(repeating:0.0,count:9),count:8)
 for i in 0..<4 {let x=from[i].x,y=from[i].y,u=to[i].x,v=to[i].y;a[2*i]=[x,y,1,0,0,0,-u*x,-u*y,u];a[2*i+1]=[0,0,0,x,y,1,-v*x,-v*y,v]}
 for k in 0..<8 {var p=k;for i in k..<8{if abs(a[i][k])>abs(a[p][k]){p=i}};if p != k {a.swapAt(p,k)};let d=a[k][k];for j in k..<9{a[k][j]/=d};for i in 0..<8 where i != k {let f=a[i][k];for j in k..<9{a[i][j]-=f*a[k][j]}}}
 return (0..<8).map{a[$0][8]}+[1]
}
func project(_ a:CGPoint,_ m:[Double])->CGPoint{let d=m[6]*a.x+m[7]*a.y+1;return CGPoint(x:(m[0]*a.x+m[1]*a.y+m[2])/d,y:(m[3]*a.x+m[4]*a.y+m[5])/d)}
func draw(_ c:CGContext,_ im:CGImage,_ r:CGRect,alpha:Double=1){c.saveGState();c.setAlpha(alpha);c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.interpolationQuality = .high;c.draw(im,in:CGRect(x:0,y:0,width:r.width,height:r.height));c.restoreGState()}
func warp(_ c:CGContext,_ im:CIImage,_ pts:[CGPoint],_ alpha:Double=1){
 if alpha<=0{return};let f=CIFilter(name:"CIPerspectiveTransform")!;f.setValue(im,forKey:kCIInputImageKey)
 for (k,p) in zip(["inputTopLeft","inputTopRight","inputBottomRight","inputBottomLeft"],pts){f.setValue(CIVector(x:p.x*scale,y:Double(H)-p.y*scale),forKey:k)}
 guard let output=f.outputImage,let image=ci.createCGImage(output,from:CGRect(x:0,y:0,width:W,height:H))else{return};draw(c,image,CGRect(x:0,y:0,width:1920,height:1080),alpha:alpha)
}
func polygon(_ c:CGContext,_ q:[CGPoint],_ gray:Double=0,_ alpha:Double=1){c.setFillColor(CGColor(colorSpace:srgb,components:[gray,gray,gray,alpha])!);c.beginPath();c.move(to:q[0]);for p in q.dropFirst(){c.addLine(to:p)};c.closePath();c.fillPath()}
// Screen and bezel are registered once in the same photographic plane.
// The mask is intentionally broader than the true display quad; only black
// fills the few safety-margin pixels, never the original Apple wallpaper.
let canonicalPhoto:CGImage = {
 let ctx=CGContext(data:nil,width:photo.width,height:photo.height,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:0,y:Double(photo.height));ctx.scaleBy(x:1,y:-1)
 draw(ctx,photo,CGRect(x:0,y:0,width:photo.width,height:photo.height))
 polygon(ctx,quadAt(77.0/30),0)
 return ctx.makeImage()!
}()
let canonicalLid=CIImage(cgImage:canonicalPhoto.cropping(to:CGRect(x:0,y:0,width:3456,height:1065))!)
let canonicalTopRim=CIImage(cgImage:canonicalPhoto.cropping(to:CGRect(x:0,y:0,width:3456,height:580))!)
let canonicalLowerLid=CIImage(cgImage:canonicalPhoto.cropping(to:CGRect(x:0,y:580,width:3456,height:485))!)
func monotone(_ x:[Double],_ y:[Double],_ value:Double)->Double {
 let t=max(x.first!,min(x.last!,value)),n=x.count
 var d=[Double](),m=Array(repeating:0.0,count:n)
 for i in 0..<(n-1){d.append((y[i+1]-y[i])/(x[i+1]-x[i]))}
 m[0]=d[0];m[n-1]=d[n-2]
 for i in 1..<(n-1){if d[i-1]*d[i]<=0{m[i]=0}else{let h0=x[i]-x[i-1],h1=x[i+1]-x[i],w1=2*h1+h0,w2=h1+2*h0;m[i]=(w1+w2)/(w1/d[i-1]+w2/d[i])}}
 var i=0;while i<n-2 && t>x[i+1]{i+=1}
 let h=x[i+1]-x[i],u=(t-x[i])/h,u2=u*u,u3=u2*u
 return (2*u3-3*u2+1)*y[i]+(u3-2*u2+u)*h*m[i]+(-2*u3+3*u2)*y[i+1]+(u3-u2)*h*m[i+1]
}
func fittedScreenQuad(_ t:Double)->[CGPoint]{
 let y=monotone([0.98,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,77.0/30],[969.623,949.769,843.226,744.674,675.198,630.532,604.94,592.529,585.166,581.363,580,580],t)
 let dy=y-580,cx=2028.5,topWidth=1755+0.23*dy,bottomWidth=1443-0.072*dy,bottomY=1031+0.06*dy
 return [CGPoint(x:cx-topWidth/2,y:y),CGPoint(x:cx+topWidth/2,y:y),CGPoint(x:cx+bottomWidth/2,y:bottomY),CGPoint(x:cx-bottomWidth/2,y:bottomY)]
}
func cameraPlate(_ c:CGContext,_ progress:Double,_ screenAlpha:Double=1){
 let dest=zip(initialQuad,fullQuad).map{point($0.0,$0.1,progress)}
 let matrix=homography(sourceQuad,dest)
 let photoCorners=[CGPoint(x:0,y:0),CGPoint(x:photo.width,y:0),CGPoint(x:photo.width,y:photo.height),CGPoint(x:0,y:photo.height)].map{project($0,matrix)}
 warp(c,CIImage(cgImage:canonicalPhoto),photoCorners)
 // An opaque dark screen first covers the original product wallpaper entirely.
 polygon(c,dest,0)
 warp(c,desktopCI,dest,screenAlpha)
}
var maskedFrameCache:[Int:CGImage]=[:]
func maskedHardwareFrame(_ index:Int)->CGImage {
 let i=max(0,min(77,index))
 if let cached=maskedFrameCache[i]{return cached}
 let frameURL=hardware.appendingPathComponent(String(format:"pv-frames/frame-%03d.png",i))
 let im=FileManager.default.fileExists(atPath:frameURL.path) ? loadImage(frameURL):try! generator.copyCGImage(at:CMTime(value:Int64(i),timescale:30),actualTime:nil)
 let c=CGContext(data:nil,width:im.width,height:im.height,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.translateBy(x:0,y:Double(im.height));c.scaleBy(x:1,y:-1)
 draw(c,im,CGRect(x:0,y:0,width:im.width,height:im.height))
 if i>=27{polygon(c,quadAt(Double(i)/30),0)}
 let masked=c.makeImage()!
 if maskedFrameCache.count>5 {for key in maskedFrameCache.keys where abs(key-i)>2{maskedFrameCache.removeValue(forKey:key)}}
 maskedFrameCache[i]=masked
 return masked
}
func drawActualClosure(_ c:CGContext,_ time:Double){
 let f=clamp(time/(77.0/30))*77,lo=Int(floor(f)),fraction=f-Double(lo)
 let rect=CGRect(x:plateOffset.x,y:plateOffset.y,width:Double(photo.width)*plateScale,height:Double(photo.height)*plateScale)
 draw(c,maskedHardwareFrame(lo),rect)
 if fraction>0.0001 {draw(c,maskedHardwareFrame(lo+1),rect,alpha:fraction)}
}
// Compress the almost-static tails of Apple's clip, preserving time for the
// visible hinge movement. Monotone cubic interpolation avoids speed changes.
func closureSourceTime(_ seconds:Double)->Double {
 let x=[0.0,0.07,0.20,0.40,0.60,0.80,1.0,1.20,1.35]
 let y=[77.0/30,1.8,1.5,1.28,1.10,0.92,0.72,0.47,0.0]
 let t=max(x.first!,min(x.last!,seconds)),n=x.count
 var d=[Double](),m=Array(repeating:0.0,count:n)
 for i in 0..<(n-1){d.append((y[i+1]-y[i])/(x[i+1]-x[i]))}
 m[0]=d[0];m[n-1]=d[n-2]
 for i in 1..<(n-1){let h0=x[i]-x[i-1],h1=x[i+1]-x[i],w1=2*h1+h0,w2=h1+2*h0;m[i]=(w1+w2)/(w1/d[i-1]+w2/d[i])}
 var i=0;while i<n-2 && t>x[i+1]{i+=1}
 let h=x[i+1]-x[i],u=(t-x[i])/h,u2=u*u,u3=u2*u
 return (2*u3-3*u2+1)*y[i]+(u3-2*u2+u)*h*m[i]+(-2*u3+3*u2)*y[i+1]+(u3-u2)*h*m[i+1]
}

func registeredSourceFront(_ c:CGContext,_ time:Double){
 // Before the canonical plane takes over, register the two adjacent source
 // lid poses to one interpolated outer edge before blending their textures.
 // This avoids the 30fps source's two-outline blend at the handoff boundary.
 let f=time*30,lo=Int(floor(f)),fraction=f-Double(lo)
 let edge=[27:1022.0,28:993.0,29:961.0,30:927.0]
 let target=monotone([0.9,28.0/30,29.0/30,1.0],[1022,993,961,927],time)
 let cut=1065*plateScale+plateOffset.y
 c.setFillColor(CGColor(gray:0,alpha:1));c.fill(CGRect(x:0,y:0,width:1920,height:cut))
 for (i,a) in [(lo,1.0),(lo+1,fraction)] {
  if a<=0{continue}
  let scale=(1065-target)/(1065-edge[i]!)
  let top=1065-1065*scale
  let q=[CGPoint(x:0,y:top),CGPoint(x:3456,y:top),CGPoint(x:3456,y:1065),CGPoint(x:0,y:1065)].map{CGPoint(x:$0.x*plateScale+plateOffset.x,y:$0.y*plateScale+plateOffset.y)}
  let im=maskedHardwareFrame(i).cropping(to:CGRect(x:0,y:0,width:3456,height:1065))!
  warp(c,CIImage(cgImage:im),q,a)
 }
}
func drawActualOpening(_ c:CGContext,_ time:Double,_ unusedAlpha:Double){
 // Single opaque front-lid takeover while the screen is still black.
 // The measured physical rim keeps its thickness at grazing angles, unlike
 // a flat plane projection. This matches the source silhouette without
 // showing two independently positioned edges during an alpha dissolve.
 drawActualClosure(c,time)
 if time<0.98{if time>=0.9{registeredSourceFront(c,time)};return}
 let q=fittedScreenQuad(time),m=homography(sourceQuad,q)
 let cut=project(CGPoint(x:2028.5,y:1065),m).y*plateScale+plateOffset.y
 func stage(_ p:CGPoint)->CGPoint{CGPoint(x:p.x*plateScale+plateOffset.x,y:p.y*plateScale+plateOffset.y)}
 let target=q.map{stage($0)}
 c.saveGState()
 c.setFillColor(CGColor(gray:0,alpha:1));c.fill(CGRect(x:0,y:0,width:1920,height:cut))
 let lower=[CGPoint(x:0,y:580),CGPoint(x:3456,y:580),CGPoint(x:3456,y:1065),CGPoint(x:0,y:1065)].map{stage(project($0,m))}
 warp(c,canonicalLowerLid,lower)
 let physicalRim=monotone([0.98,1.0,1.1,1.2,1.3,1.4,1.5,1.7,1.9],[22.2,22.769,27.226,27.674,30.198,31.532,31.0,31.2,32.0],time)
 let projectedRim=q[0].y-project(CGPoint(x:2028.5,y:548),m).y
 let factor=physicalRim/projectedRim
 let upper=[CGPoint(x:0,y:0),CGPoint(x:3456,y:0),CGPoint(x:3456,y:580),CGPoint(x:0,y:580)].map{p -> CGPoint in
  let r=project(p,m)
  return stage(CGPoint(x:r.x,y:q[0].y+(r.y-q[0].y)*factor))
 }
 warp(c,canonicalTopRim,upper)
 warp(c,desktopCI,target,smooth((time-1.13)/0.28))
 c.restoreGState()
}

let ink="#F4F5F7",muted="#A8B3C5",bg="#080A0F"
func value(_ key:String,_ fallback:String)->String{content[key] as? String ?? fallback}
func event(_ key:String,_ fallback:Double)->Double{timing[key] ?? fallback*duration/16.5}
func phase(_ t:Double,_ a:String,_ b:String,_ aa:Double,_ bb:Double)->Double{ease((t-event(a,aa))/max(0.001,event(b,bb)-event(a,aa)))}
func color(_ hex:String,_ alpha:Double=1)->CGColor{let n=UInt32(hex.replacingOccurrences(of:"#",with:""),radix:16) ?? 0xffffff;return CGColor(colorSpace:srgb,components:[Double((n>>16)&255)/255,Double((n>>8)&255)/255,Double(n&255)/255,alpha])!}
func font(_ size:Double,_ bold:Bool=false)->NSFont{NSFont(name:bold ? "SFProDisplay-Semibold":"SFProDisplay-Regular",size:size) ?? .systemFont(ofSize:size,weight:bold ? .semibold:.regular)}
func text(_ c:CGContext,_ s:String,_ x:Double,_ y:Double,_ size:Double=40,_ col:String=ink,_ bold:Bool=false,_ align:Int=0,_ alpha:Double=1){if alpha<=0{return};let l=CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:font(size,bold),.foregroundColor:NSColor(cgColor:color(col,alpha))!]));let w=CTLineGetTypographicBounds(l,nil,nil,nil);c.saveGState();c.translateBy(x:x-(align==1 ? w/2:align==2 ? w:0),y:y);c.scaleBy(x:1,y:-1);c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(l,c);c.restoreGState()}
func rect(_ c:CGContext,_ r:CGRect,_ radius:Double,_ fill:String,_ alpha:Double=1,_ stroke:String?=nil,_ sa:Double=1,_ sw:Double=1){let p=CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil);c.addPath(p);c.setFillColor(color(fill,alpha));c.fillPath();if let s=stroke{c.addPath(p);c.setStrokeColor(color(s,sa));c.setLineWidth(sw);c.strokePath()}}
func gradient(_ c:CGContext,_ r:CGRect,_ radius:Double,_ top:String,_ bottom:String,_ alpha:Double=1,_ stroke:String?=nil,_ sa:Double=0.2){c.saveGState();let p=CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil);c.addPath(p);c.clip();let g=CGGradient(colorsSpace:srgb,colors:[color(top,alpha),color(bottom,alpha)] as CFArray,locations:[0,1])!;c.drawLinearGradient(g,start:CGPoint(x:r.minX,y:r.minY),end:CGPoint(x:r.maxX,y:r.maxY),options:[]);c.restoreGState();if let s=stroke{c.addPath(p);c.setStrokeColor(color(s,sa));c.setLineWidth(1.4);c.strokePath()}}
func stroke(_ c:CGContext,_ p:[CGPoint],_ col:String,_ width:Double,_ a:Double=1){c.saveGState();c.setLineWidth(width);c.setStrokeColor(color(col,a));c.setLineCap(.round);c.setLineJoin(.round);c.move(to:p[0]);for v in p.dropFirst(){c.addLine(to:v)};c.strokePath();c.restoreGState()}
func dot(_ c:CGContext,_ x:Double,_ y:Double,_ r:Double,_ col:String,_ a:Double=1){c.setFillColor(color(col,a));c.fillEllipse(in:CGRect(x:x-r,y:y-r,width:r*2,height:r*2))}
func glow(_ c:CGContext,_ p:CGPoint,_ radius:Double,_ col:String,_ a:Double){let g=CGGradient(colorsSpace:srgb,colors:[color(col,a),color(col,0)] as CFArray,locations:[0,1])!;c.drawRadialGradient(g,startCenter:p,startRadius:0,endCenter:p,endRadius:radius,options:[])}
func cursor(_ c:CGContext,_ x:Double,_ y:Double,_ press:Double=0,_ a:Double=1){c.saveGState();c.translateBy(x:x,y:y);let s=1-0.08*press;c.scaleBy(x:s,y:s);c.setAlpha(a);c.setShadow(offset:CGSize(width:0,height:3),blur:7,color:color("#000000",0.55));let ps=[CGPoint(x:0,y:0),CGPoint(x:2,y:42),CGPoint(x:13,y:31),CGPoint(x:22,y:50),CGPoint(x:31,y:45),CGPoint(x:22,y:27),CGPoint(x:38,y:25)];c.move(to:ps[0]);for p in ps.dropFirst(){c.addLine(to:p)};c.closePath();c.setFillColor(color("#FFFFFF"));c.setStrokeColor(color("#151A25"));c.setLineWidth(2);c.drawPath(using:.fillStroke);c.restoreGState()}
func pressure(_ t:Double,_ start:Double)->Double{let u=(t-start)/0.22;return u<0 || u>1 ? 0:sin(u*Double.pi)}
func glyph(_ c:CGContext,_ kind:Int,_ center:CGPoint,_ size:Double){
 c.saveGState();c.translateBy(x:center.x,y:center.y);c.scaleBy(x:size/100,y:size/100)
 if kind==0{for (i,w) in [48.0,57.0,36.0].enumerated(){stroke(c,[CGPoint(x:-26,y:-20+Double(i)*20),CGPoint(x:-26+w,y:-20+Double(i)*20)],ink,7)}}
 else if kind==1{c.setStrokeColor(color(ink));c.setLineWidth(6);c.strokeEllipse(in:CGRect(x:-32,y:-32,width:64,height:64));let p=CGMutablePath();p.move(to:CGPoint(x:-10,y:-8));p.addLine(to:CGPoint(x:24,y:-25));p.addLine(to:CGPoint(x:8,y:10));p.addLine(to:CGPoint(x:-24,y:25));p.closeSubpath();c.addPath(p);c.setFillColor(color(ink));c.fillPath()}
 else {let p=CGMutablePath();p.move(to:CGPoint(x:0,y:-39));p.addCurve(to:CGPoint(x:39,y:0),control1:CGPoint(x:7,y:-11),control2:CGPoint(x:11,y:-7));p.addCurve(to:CGPoint(x:0,y:39),control1:CGPoint(x:11,y:7),control2:CGPoint(x:7,y:11));p.addCurve(to:CGPoint(x:-39,y:0),control1:CGPoint(x:-7,y:11),control2:CGPoint(x:-11,y:7));p.addCurve(to:CGPoint(x:0,y:-39),control1:CGPoint(x:-11,y:-7),control2:CGPoint(x:-7,y:-11));c.addPath(p);c.setFillColor(color(ink));c.fillPath()}
 c.restoreGState()
}
func appIcon(_ c:CGContext,_ kind:Int,_ x:Double,_ y:Double,_ s:Double,_ alpha:Double=1){c.saveGState();c.setAlpha(alpha);c.setShadow(offset:CGSize(width:0,height:13),blur:30,color:color("#000000",0.35));let colors=[("#548BBE","#223A64"),("#7E8FC6","#343F66"),("#779D92","#2A4E50")];gradient(c,CGRect(x:x-s/2,y:y-s/2,width:s,height:s),s*0.23,colors[kind%3].0,colors[kind%3].1,1,"#E4EEFF",0.35);c.setShadow(offset:.zero,blur:0,color:nil);rect(c,CGRect(x:x-s*0.35,y:y-s*0.44,width:s*0.7,height:1.5),1,"#FFFFFF",0.20);glyph(c,kind,CGPoint(x:x,y:y),s*0.67);c.restoreGState()}
func menu(_ c:CGContext){rect(c,CGRect(x:0,y:0,width:1920,height:58),0,"#0B101A",0.64);text(c,"Studio",48,38,26,ink,true);text(c,"File   Edit   View",153,38,25,"#D6DEEA");rect(c,CGRect(x:1724,y:20,width:43,height:19),4,"#000000",0,"#DCE5F0",1,2);rect(c,CGRect(x:1728,y:24,width:30,height:11),2,"#DCE5F0");rect(c,CGRect(x:1770,y:26,width:3,height:7),1,"#DCE5F0");text(c,"9:41",1880,39,25,ink,false,2)}
func desktop(_ c:CGContext,_ t:Double){
 gradient(c,CGRect(x:0,y:0,width:1920,height:1080),0,"#101722","#1E2232")
 glow(c,CGPoint(x:400,y:1100),850,"#416789",0.32);glow(c,CGPoint(x:1490,y:240),820,"#646290",0.23)
 // Quiet curved light bands create a dimensional wallpaper, without decorative noise.
 for j in 0..<5 {let p=CGMutablePath();p.move(to:CGPoint(x:-100,y:790+Double(j)*37));p.addCurve(to:CGPoint(x:2050,y:900+Double(j)*45),control1:CGPoint(x:510,y:410+Double(j)*32),control2:CGPoint(x:1250,y:1280+Double(j)*15));c.addPath(p);c.setLineWidth(1.0);c.setStrokeColor(color("#BBC9EB",0.05));c.strokePath()}
 menu(c)
 let app=phase(t,"app_start","app_end",7.10,7.80)
 let captionsOut=phase(t,"app_labels_out_start","app_labels_out_end",5.82,5.95)
 let assistantLabel=phase(t,"assistant_label_start","assistant_label_end",6.55,6.72)
 let desktopOut=phase(t,"desktop_out_start","desktop_out_end",6.94,7.10)
 let collapse=phase(t,"collapse_start","collapse_end",5.95,6.55)
 let sweep=phase(t,"cursor_start","cursor_end",3.35,5.85),cx=mix(420,1370,sweep)
 let hover=phase(t,"cursor_start","cursor_visible",3.35,3.62)
 let labels=content["apps"] as? [String] ?? ["Write","Explore","Create"]
 let names=labels.count>=3 ? labels:["Write","Explore","Create"]
 let topAlpha=1-desktopOut
 text(c,value("screen_heading","Your ideas. In motion."),960,328,83,ink,true,1,topAlpha)
 text(c,value("screen_subtitle","One place to think, create, and get things done."),960,394,34,"#BDC6D7",false,1,topAlpha)
 c.saveGState();c.setAlpha(1-desktopOut);c.beginTransparencyLayer(auxiliaryInfo:nil)
 let oldTileAlpha=1-smooth((collapse-0.08)/0.52),newTileAlpha=smooth((collapse-0.60)/0.40)
 let centers=[550.0,960.0,1370.0]
 for i in 0..<3 {
  let distance=(centers[i]-cx)/175,influence=exp(-0.5*distance*distance)*hover
  let s=(156+33*influence)*(1-0.08*collapse)
  let x=mix(centers[i],960,collapse),y=620.0
  appIcon(c,i,x,y,s,oldTileAlpha)
  text(c,names[i],x,772,31,ink,false,1,1-captionsOut)
 }
 if collapse>0{appIcon(c,2,960,620,172,newTileAlpha);text(c,value("app_title","AI assistant"),960,772,32,ink,true,1,assistantLabel)}
 let click=pressure(t,event("app_click_start",6.78))
 let ccx=mix(cx,973,collapse),ccy=mix(701,645,collapse)
 cursor(c,ccx,ccy,click,hover)
 c.endTransparencyLayer();c.restoreGState()
 if app>0{
  c.saveGState();c.setAlpha(app);c.beginTransparencyLayer(auxiliaryInfo:nil);let s=mix(0.14,1,app),cy=mix(620,545,app);c.translateBy(x:960,y:cy);c.scaleBy(x:s,y:s);c.translateBy(x:-960,y:-545)
  c.setShadow(offset:CGSize(width:0,height:30),blur:70,color:color("#000000",0.58));gradient(c,CGRect(x:275,y:148,width:1370,height:790),30,"#252D3B","#171F2D",1,"#D4E0F5",0.24);c.setShadow(offset:.zero,blur:0,color:nil)
  for (x,col) in [(309.0,"#F07171"),(336.0,"#E8BB66"),(363.0,"#73B68B")]{dot(c,x,180,7,col)}
  text(c,value("app_title","AI assistant"),960,188,27,"#BDCADB",true,1)
  stroke(c,[CGPoint(x:276,y:214),CGPoint(x:1644,y:214)],"#DCE7F6",1,0.12)
  appIcon(c,2,960,331,94)
  let sent=phase(t,"send_start","send_end",11.15,11.6)
  text(c,value("chat_heading","What would you like to make?"),960,450,61,ink,true,1,1-sent)
  text(c,value("chat_subtitle","Start with an idea. We’ll take it from there."),960,512,32,muted,false,1,1-sent)
  let input=CGRect(x:382,y:572,width:1156,height:210)
  gradient(c,input,24,"#323D4F","#293344",1,"#D3E4FF",0.3)
  let prompt=value("prompt","Turn these notes into a clear 10-minute research talk.")
  let typing=phase(t,"typing_start","typing_end",7.95,10.75),characters=Array(prompt),count=min(characters.count,Int(Double(characters.count)*typing))
  let typed=String(characters.prefix(count))
  text(c,typed,421,638,37,"#EAF0F9")
  if typing<1 && t>event("typing_start",7.95){let line=CTLineCreateWithAttributedString(NSAttributedString(string:typed,attributes:[.font:font(37)]));let w=CTLineGetTypographicBounds(line,nil,nil,nil);rect(c,CGRect(x:425+w,y:608,width:2,height:37),1,"#DBE8FC",0.4+0.5*sin(t*6)*sin(t*6))}
  let sendP=pressure(t,event("send_start",11.15)),buttonScale=1-0.1*sendP
  c.saveGState();c.translateBy(x:1478,y:731);c.scaleBy(x:buttonScale,y:buttonScale);dot(c,0,0,30,"#DDEAFF");stroke(c,[CGPoint(x:0,y:13),CGPoint(x:0,y:-13)],"#27354B",4.5);stroke(c,[CGPoint(x:-11,y:-2),CGPoint(x:0,y:-13),CGPoint(x:11,y:-2)],"#27354B",4.5);c.restoreGState()
  text(c,"+",421,741,37,"#BDCADB")
  let mouse=phase(t,"send_cursor_start","send_start",10.75,11.15)
  if t>=event("send_cursor_start",10.75) && t<=event("send_end",11.6)+0.35{cursor(c,mix(1285,1478,mouse),mix(846,731,mouse),sendP,1-phase(t,"send_end","cursor_hide",11.6,11.95))}
  if sent>0 {
   text(c,value("status","Building your first draft"),960,460,55,ink,true,1,sent)
   for i in 0..<3 {let a=0.35+0.6*pow(sin(t*3-Double(i)*0.65),2);dot(c,923+Double(i)*37,510,5,"#AACBFC",sent*a)}
   text(c,value("status_detail","Finding the story. Connecting the ideas."),960,855,30,"#AABAD0",false,1,sent)
  }
  c.endTransparencyLayer();c.restoreGState()
 }
}
var suppliedScreen:CGImage?=nil
if let image=content["screen_image"] as? String {let u=image.hasPrefix("/") ? URL(fileURLWithPath:image):configURL.deletingLastPathComponent().appendingPathComponent(image);suppliedScreen=loadImage(u)}
func screen(_ t:Double)->CGImage{if let im=suppliedScreen{return im};let c=CGContext(data:nil,width:1920,height:1080,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!;c.translateBy(x:0,y:1080);c.scaleBy(x:1,y:-1);desktop(c,t);return c.makeImage()!}
// Apply one camera transform to the whole registered live device frame.
// This lets hinge motion continue while the camera enters/leaves the display.
func liveDevice(_ c:CGContext,_ sourceTime:Double,_ zoom:Double){
 if zoom<=0.00001{drawActualOpening(c,sourceTime,1);return}
 let stage=CGContext(data:nil,width:1920,height:1080,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 stage.setFillColor(color("#000000"));stage.fill(CGRect(x:0,y:0,width:1920,height:1080));stage.translateBy(x:0,y:1080);stage.scaleBy(x:1,y:-1)
 drawActualOpening(stage,sourceTime,1)
 let screen=fittedScreenQuad(sourceTime).map{CGPoint(x:$0.x*plateScale+plateOffset.x,y:$0.y*plateScale+plateOffset.y)}
 let dest=zip(screen,fullQuad).map{point($0.0,$0.1,zoom)},matrix=homography(screen,dest)
 let corners=[CGPoint(x:0,y:0),CGPoint(x:1920,y:0),CGPoint(x:1920,y:1080),CGPoint(x:0,y:1080)].map{project($0,matrix)}
 warp(c,CIImage(cgImage:stage.makeImage()!),corners)
}
func render(_ t:Double)->CGImage {
 let c=CGContext(data:nil,width:W,height:H,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.setFillColor(color("#000000"));c.fill(CGRect(x:0,y:0,width:W,height:H));c.translateBy(x:0,y:Double(H));c.scaleBy(x:scale,y:-scale)
 let ui=screen(t);desktopCI=CIImage(cgImage:ui)
 let open=phase(t,"open_start","open_end",0.20,1.95)
 let zoom=phase(t,"zoom_start","zoom_end",1.45,3.15)
 let out=phase(t,"zoom_out_start","zoom_out_end",13.0,14.3)
 let close=phase(t,"close_start","close_end",13.95,15.95)
 if t<event("open_start",0.20){drawActualClosure(c,0)}
 else if open<1{liveDevice(c,closureSourceTime((1-open)*1.35),zoom)}
 else if zoom<1{cameraPlate(c,zoom)}
 else if out<=0{draw(c,ui,CGRect(x:0,y:0,width:1920,height:1080))}
 else if close<=0{cameraPlate(c,1-out)}
 else if close<1 {liveDevice(c,closureSourceTime(close*1.35),max(0,1-out))}
 else {drawActualClosure(c,0)}
 return c.makeImage()!
}
func savePNG(_ im:CGImage,_ name:String){try! NSBitmapImageRep(cgImage:im).representation(using:.png,properties:[:])!.write(to:outputURL.appendingPathComponent(name))}
let times=raw["preview_times"] as? [Double] ?? [0.8,2.2,4.8,8.8,12.4,15.3]
let posterTime=raw["poster_time"] as? Double ?? 2.2
savePNG(render(posterTime),"poster.png");savePNG(render(duration),"end.png")
let sheet=CGContext(data:nil,width:1920,height:808,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
sheet.translateBy(x:0,y:808);sheet.scaleBy(x:1,y:-1);sheet.setFillColor(color("#101217"));sheet.fill(CGRect(x:0,y:0,width:1920,height:808))
for i in 0..<min(6,times.count){let x=Double(i%3)*640,y=Double(i/3)*404;draw(sheet,render(times[i]),CGRect(x:x,y:y,width:640,height:360));text(sheet,String(format:"%.2f s",times[i]),x+22,y+391,23,muted)}
savePNG(sheet.makeImage()!,"contact-sheet.png")
var videoMetadata:[String:Any]=[:]
if args.contains("--video") {
 let target=outputURL.appendingPathComponent("movie.mp4");try? fm.removeItem(at:target)
 let writer=try AVAssetWriter(outputURL:target,fileType:.mp4)
 let input=AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:W,AVVideoHeightKey:H,AVVideoColorPropertiesKey:[AVVideoColorPrimariesKey:AVVideoColorPrimaries_ITU_R_709_2,AVVideoTransferFunctionKey:AVVideoTransferFunction_IEC_sRGB,AVVideoYCbCrMatrixKey:AVVideoYCbCrMatrix_ITU_R_709_2],AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:W*H*10,AVVideoExpectedSourceFrameRateKey:fps,AVVideoMaxKeyFrameIntervalKey:fps,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]])
 input.expectsMediaDataInRealTime=false
 let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:W,kCVPixelBufferHeightKey as String:H,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
 writer.add(input);guard writer.startWriting() else{fail("writer failed")};writer.startSession(atSourceTime:.zero)
 let count=Int(ceil(duration*Double(fps)))
 for i in 0..<count{while !input.isReadyForMoreMediaData{Thread.sleep(forTimeInterval:0.002)};autoreleasepool{let im=render(Double(i)/Double(fps));var p:CVPixelBuffer?;CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,adaptor.pixelBufferPool!,&p);let pb=p!;CVBufferSetAttachment(pb,kCVImageBufferCGColorSpaceKey,srgb,.shouldPropagate);CVPixelBufferLockBaseAddress(pb,[]);let g=CGContext(data:CVPixelBufferGetBaseAddress(pb),width:W,height:H,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pb),space:srgb,bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!;g.draw(im,in:CGRect(x:0,y:0,width:W,height:H));CVPixelBufferUnlockBaseAddress(pb,[]);if !adaptor.append(pb,withPresentationTime:CMTime(value:Int64(i),timescale:Int32(fps))){fail("Frame append failed")}};if i%(fps*2)==0{print("device-story: \(i)/\(count)")}}
 input.markAsFinished();writer.endSession(atSourceTime:CMTime(seconds:duration,preferredTimescale:600));let sem=DispatchSemaphore(value:0);writer.finishWriting{sem.signal()};sem.wait();guard writer.status == .completed else{fail("Video failed")}
 videoMetadata=["filename":"movie.mp4","codec":"H.264","frames":count,"fps":fps,"duration":duration,"silent":true]
}
let manifest:[String:Any]=["schema_version":1,"kind":"device-story","renderer":"Photographic registered-lid composite + configurable original UI","width":W,"height":H,"duration":duration,"fps":fps,"preview_times":times,"poster_time":posterTime,"scientific_status":"conceptual","asset_rights":"Apple hardware footage: review before redistribution","outputs":["poster.png","end.png","contact-sheet.png"],"video":videoMetadata]
try! JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:outputURL.appendingPathComponent("render-manifest.json"))
print("Rendered device-story → \(outputURL.path)")
