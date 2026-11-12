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
let supportedKinds = ["branch-and-merge"]
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

let base=outputURL, W=width,H=height,srgb=cs
let bg=theme["background"] as? String ?? "#2B2B2D",ink=theme["foreground"] as? String ?? "#F7F7F5",muted="#C8CDD5",brand="#FFAA4A",orange="#FFD25A",blue="#58B6FF",green="#79D692"
func referenceTime(_ t:Double)->Double {
 let anchors=raw["timeline"] as? [[String:Double]] ?? [["at":0,"reference":0],["at":duration,"reference":38]]
 if t<=anchors[0]["at"]! {return anchors[0]["reference"]!}
 for i in 1..<anchors.count {let a=anchors[i-1],b=anchors[i];if t<=b["at"]! {let u=(t-a["at"]!)/(b["at"]!-a["at"]!);return a["reference"]!+(b["reference"]!-a["reference"]!)*u}}
 return anchors.last!["reference"]!
}
func color(_ h:String,_ a:Double=1)->CGColor{let n=UInt32(h.replacingOccurrences(of:"#",with:""),radix:16)!;return CGColor(colorSpace:srgb,components:[Double((n>>16)&255)/255,Double((n>>8)&255)/255,Double(n&255)/255,a])!}
func clamp(_ x:Double)->Double{max(0,min(1,x))}
func smooth(_ x:Double)->Double{let t=clamp(x);return t*t*(3-2*t)}
func ease(_ x:Double)->Double{let t=clamp(x);return t*t*t*(t*(t*6-15)+10)}
func mix(_ a:Double,_ b:Double,_ u:Double)->Double{a+(b-a)*u}
func rectMix(_ a:CGRect,_ b:CGRect,_ u:Double)->CGRect{CGRect(x:mix(a.minX,b.minX,u),y:mix(a.minY,b.minY,u),width:mix(a.width,b.width,u),height:mix(a.height,b.height,u))}
func font(_ s:Double,_ bold:Bool=false,_ mono:Bool=false)->NSFont{if mono{return NSFont.monospacedSystemFont(ofSize:s,weight:bold ? .semibold:.regular)};return NSFont(name:bold ? "SFProDisplay-Semibold":"SFProDisplay-Regular",size:s) ?? NSFont.systemFont(ofSize:s,weight:bold ? .semibold:.regular)}
func text(_ c:CGContext,_ str:String,_ x:Double,_ y:Double,_ s:Double,_ h:String=ink,_ bold:Bool=false,_ center:Bool=false,_ alpha:Double=1,_ mono:Bool=false){if alpha<=0{return};let display=(content["labels"] as? [String:String])?[str] ?? str;let a=NSAttributedString(string:display,attributes:[.font:font(s,bold,mono),.foregroundColor:NSColor(cgColor:color(h))!]);let l=CTLineCreateWithAttributedString(a);let w=CTLineGetTypographicBounds(l,nil,nil,nil);c.saveGState();c.setAlpha(alpha);c.translateBy(x:x-(center ? w/2:0),y:y);c.scaleBy(x:1,y:-1);c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(l,c);c.restoreGState()}
func stroke(_ c:CGContext,_ pts:[CGPoint],_ h:String,_ width:Double=3,_ alpha:Double=1){c.saveGState();c.setStrokeColor(color(h,alpha));c.setLineWidth(width);c.setLineCap(.round);c.setLineJoin(.round);c.beginPath();c.move(to:pts[0]);for p in pts.dropFirst(){c.addLine(to:p)};c.strokePath();c.restoreGState()}
func rounded(_ c:CGContext,_ r:CGRect,_ radius:Double,_ h:String,_ a:Double=1){c.setFillColor(color(h,a));c.addPath(CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil));c.fillPath()}
func outline(_ c:CGContext,_ r:CGRect,_ h:String,_ a:Double=1,_ w:Double=4){c.setStrokeColor(color(h,a));c.setLineWidth(w);c.stroke(r)}
func draw(_ c:CGContext,_ im:CGImage,_ r:CGRect,_ alpha:Double=1){c.saveGState();c.setAlpha(alpha);c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.interpolationQuality = .high;c.draw(im,in:CGRect(x:0,y:0,width:r.width,height:r.height));c.restoreGState()}
struct Cell{let text:String;let area:CGRect;let textBounds:CGRect;let pos:CGPoint}
let cells:[Cell]=[
 Cell(text:"Symptom",area:CGRect(x:2,y:4,width:142,height:141),textBounds:CGRect(x:12,y:60,width:125,height:35),pos:CGPoint(x:13,y:85)),
 Cell(text:"Blood Pressure",area:CGRect(x:144,y:4,width:234,height:70),textBounds:CGRect(x:151,y:26,width:191,height:29),pos:CGPoint(x:154,y:51)),
 Cell(text:"Systolic",area:CGRect(x:144,y:74,width:113,height:71),textBounds:CGRect(x:153,y:98,width:94,height:30),pos:CGPoint(x:154,y:122)),
 Cell(text:"Diastolic",area:CGRect(x:257,y:74,width:121,height:71),textBounds:CGRect(x:265,y:98,width:106,height:30),pos:CGPoint(x:266,y:122)),
 Cell(text:"Fever",area:CGRect(x:2,y:145,width:142,height:70),textBounds:CGRect(x:12,y:168,width:70,height:29),pos:CGPoint(x:13,y:191)),
 Cell(text:"120",area:CGRect(x:144,y:145,width:113,height:70),textBounds:CGRect(x:153,y:168,width:51,height:29),pos:CGPoint(x:154,y:191)),
 Cell(text:"80",area:CGRect(x:257,y:145,width:121,height:70),textBounds:CGRect(x:265,y:168,width:36,height:29),pos:CGPoint(x:266,y:191)),
 Cell(text:"Headache",area:CGRect(x:2,y:215,width:142,height:70),textBounds:CGRect(x:12,y:239,width:125,height:29),pos:CGPoint(x:13,y:261)),
 Cell(text:"132",area:CGRect(x:144,y:215,width:113,height:70),textBounds:CGRect(x:153,y:239,width:51,height:29),pos:CGPoint(x:154,y:261)),
 Cell(text:"90",area:CGRect(x:257,y:215,width:121,height:70),textBounds:CGRect(x:265,y:239,width:36,height:29),pos:CGPoint(x:266,y:261))]
func cellRect(_ r:CGRect,_ b:CGRect)->CGRect{CGRect(x:r.minX+b.minX*r.width/380,y:r.minY+b.minY*r.height/288,width:b.width*r.width/380,height:b.height*r.height/288)}
func table(_ c:CGContext,_ r:CGRect,_ alpha:Double=1,_ texts:[Double]=Array(repeating:1,count:10),_ grid:String=blue){
 c.saveGState();c.setAlpha(alpha);c.translateBy(x:r.minX,y:r.minY);c.scaleBy(x:r.width/380,y:r.height/288)
 c.setFillColor(color("#24262A"));c.fill(CGRect(x:2,y:4,width:376,height:281));c.setFillColor(color("#3C4047"));c.fill(CGRect(x:2,y:145,width:376,height:70))
 let lines:[[CGPoint]]=[[(2,4),(378,4),(378,285),(2,285),(2,4)].map{CGPoint(x:$0.0,y:$0.1)},[(144,4),(144,285)].map{CGPoint(x:$0.0,y:$0.1)},[(257,74),(257,285)].map{CGPoint(x:$0.0,y:$0.1)},[(144,74),(378,74)].map{CGPoint(x:$0.0,y:$0.1)},[(2,145),(378,145)].map{CGPoint(x:$0.0,y:$0.1)},[(2,215),(378,215)].map{CGPoint(x:$0.0,y:$0.1)}]
 for l in lines{stroke(c,l,grid,3.1,1)}
 for (i,z) in cells.enumerated(){text(c,z.text,z.pos.x,z.pos.y,27.5,ink,false,false,texts[i])};c.restoreGState()
}
func image(_ w:Int,_ h:Int,_ block:(CGContext)->Void)->CGImage{let c=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!;block(c);return c.makeImage()!}
func save(_ im:CGImage,_ path:String){let p=base.appendingPathComponent(path);try! FileManager.default.createDirectory(at:p.deletingLastPathComponent(),withIntermediateDirectories:true);try! NSBitmapImageRep(cgImage:im).representation(using:.png,properties:[:])!.write(to:p)}
let inputStart=CGRect(x:510,y:290,width:900,height:682.105263)
let inputFinal=CGRect(x:80,y:420,width:440,height:333.473684)
let structureBox=CGRect(x:620,y:230,width:560,height:420)
let locationBox=CGRect(x:620,y:710,width:560,height:340)
let contentBox=CGRect(x:1240,y:710,width:600,height:340)
let finalBox=CGRect(x:1240,y:230,width:600,height:420)
let structureGrid=CGRect(x:675,y:298,width:450,height:341.052632)
let locationGrid=CGRect(x:645,y:790,width:320,height:242.526316)
let finalGrid=CGRect(x:1315,y:298,width:450,height:341.052632)
let cropTarget=CGRect(x:1265,y:792,width:240,height:62)
let compactContentPositions:[CGPoint]=[(1265,896),(1490,896),(1265,938),(1490,938),(1265,980),(1525,980),(1715,980),(1265,1022),(1525,1022),(1715,1022)].map{CGPoint(x:$0.0,y:$0.1)}
// Once the temporary crop-to-word work row has disappeared, distribute
// recognized content across the full available module body. The same positions
// remain the sources of the word-to-table assembly in the following clip.
let expandedContentPositions:[CGPoint]=[(1265,829),(1490,829),(1265,891),(1490,891),(1265,953),(1525,953),(1715,953),(1265,1015),(1525,1015),(1715,1015)].map{CGPoint(x:$0.0,y:$0.1)}
func contentPosition(_ i:Int,_ t:Double)->CGPoint{
 let u=ease((t-24.2)/0.9),a=compactContentPositions[i],b=expandedContentPositions[i]
 return CGPoint(x:mix(a.x,b.x,u),y:mix(a.y,b.y,u))
}
let cropStarts:[Double]=[15.15,16.45,18.15,18.77,19.39,20.01,20.63,21.25,21.87,22.49]
let assemblyStarts:[Double]=[28.50,29.00,29.50,30.00,30.50,31.00,31.50,32.00,32.50,33.00]
let sourceTable:CGImage={let c=CGContext(data:nil,width:3040,height:2304,bitsPerComponent:8,bytesPerRow:0,space:srgb,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!;c.translateBy(x:0,y:2304);c.scaleBy(x:8,y:-8);table(c,CGRect(x:0,y:0,width:380,height:288));return c.makeImage()!}()
let sourceCrops:[CGImage]=cells.map{z in let r=z.textBounds.insetBy(dx:-4,dy:-4);return sourceTable.cropping(to:CGRect(x:r.minX*8,y:r.minY*8,width:r.width*8,height:r.height*8))!}
func label(_ c:CGContext,_ s:String,_ r:CGRect,_ size:Double,_ h:String=ink,_ a:Double=1){text(c,s,r.midX,r.midY+size*0.35,size,h,false,true,a)}
func module(_ c:CGContext,_ r:CGRect,_ title:String,_ h:String,_ a:Double){if a<=0{return};c.saveGState();c.setAlpha(a);rounded(c,r,14,"#24262A");c.setLineWidth(3.2);c.setStrokeColor(color(h,0.78));c.addPath(CGPath(roundedRect:r,cornerWidth:14,cornerHeight:14,transform:nil));c.strokePath();text(c,title,r.minX+25,r.minY+51,48,h,true);c.restoreGState()}
func trimmed(_ c:CGContext,_ pts:[CGPoint],_ progress:Double,_ h:String,_ alpha:Double=1,_ width:Double=6){
 let u=clamp(progress);if u<=0 || alpha<=0{return};let lengths=zip(pts,pts.dropFirst()).map{hypot($1.x-$0.x,$1.y-$0.y)},total=lengths.reduce(0,+);var remain=total*u,drawPts=[pts[0]]
 for i in 0..<lengths.count{if remain>=lengths[i]{drawPts.append(pts[i+1]);remain-=lengths[i]}else{let f=remain/lengths[i];drawPts.append(CGPoint(x:mix(pts[i].x,pts[i+1].x,f),y:mix(pts[i].y,pts[i+1].y,f)));break}}
 stroke(c,drawPts,h,width,alpha)
 if u>0.93,let last=drawPts.last,drawPts.count>=2{let prev=drawPts[drawPts.count-2],theta=atan2(last.y-prev.y,last.x-prev.x),k=18.0;stroke(c,[CGPoint(x:last.x-k*cos(theta-0.52),y:last.y-k*sin(theta-0.52)),last,CGPoint(x:last.x-k*cos(theta+0.52),y:last.y-k*sin(theta+0.52))],h,width,alpha*smooth((u-0.93)/0.07))}
}
func curvedBranch(_ end:CGPoint)->[CGPoint]{
 let p0=CGPoint(x:526,y:586),p1=CGPoint(x:575,y:586),p2=CGPoint(x:564,y:end.y),p3=end
 return (0...96).map{i in let u=Double(i)/96,v=1-u;return CGPoint(x:v*v*v*p0.x+3*v*v*u*p1.x+3*v*u*u*p2.x+u*u*u*p3.x,y:v*v*v*p0.y+3*v*v*u*p1.y+3*v*u*u*p2.y+u*u*u*p3.y)}
}
func title(_ c:CGContext){
 let f=NSFont(name:"SFProDisplay-Bold",size:76) ?? .systemFont(ofSize:76,weight:.bold)
 let a=NSAttributedString(string:"Three models, one digitized table",attributes:[.font:f,.foregroundColor:NSColor(cgColor:color("#F6F6F4"))!])
 let l=CTLineCreateWithAttributedString(a);c.saveGState();c.translateBy(x:100,y:162);c.scaleBy(x:1,y:-1);c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(l,c);c.restoreGState()
}
func branchCopy(_ c:CGContext,_ t:Double,_ start:Double,_ duration:Double,_ end:CGPoint,_ h:String){
 let dt=t-start;if dt<0 || dt>duration{return};let u=ease(dt/duration)
 let pts=curvedBranch(CGPoint(x:613,y:end.y))+[end],lengths=zip(pts,pts.dropFirst()).map{hypot($1.x-$0.x,$1.y-$0.y)}
 var remain=lengths.reduce(0,+)*u,pos=end
 for i in 0..<lengths.count {if remain<=lengths[i]{let q=remain/lengths[i];pos=CGPoint(x:mix(pts[i].x,pts[i+1].x,q),y:mix(pts[i].y,pts[i+1].y,q));break};remain-=lengths[i]}
 let a=smooth(dt/0.14)*(1-smooth((dt-duration+0.23)/0.23)),r=CGRect(x:pos.x-65,y:pos.y-49.3,width:130,height:98.6)
 draw(c,sourceTable,r,a);outline(c,r,h,a,4)
}
func focus(_ c:CGContext,_ r:CGRect,_ h:String,_ amount:Double){
 if amount<=0{return};c.saveGState();c.setStrokeColor(color(h,amount));c.setLineWidth(4.5);c.addPath(CGPath(roundedRect:r,cornerWidth:14,cornerHeight:14,transform:nil));c.strokePath();c.restoreGState()
}
func sourceWordMark(_ c:CGContext,_ i:Int,_ amount:Double,_ t:Double){
 let a=NSAttributedString(string:cells[i].text,attributes:[.font:font(42)]),line=CTLineCreateWithAttributedString(a)
 let w=CTLineGetTypographicBounds(line,nil,nil,nil),p=contentPosition(i,t)
 rounded(c,CGRect(x:p.x-5,y:p.y-39,width:w+10,height:47),4,green,amount*0.20)
 stroke(c,[CGPoint(x:p.x,y:p.y+7),CGPoint(x:p.x+w,y:p.y+7)],green,3,amount)
}
func badge(_ c:CGContext,_ s:String,_ x:Double,_ y:Double,_ w:Double,_ h:String,_ a:Double){rounded(c,CGRect(x:x,y:y,width:w,height:44),7,h,a*0.10);text(c,s,x+w/2,y+31,27,h,false,true,a,true)}
func placeholder(_ c:CGContext,_ s:String,_ r:CGRect,_ a:Double){
 let lines=s.components(separatedBy:"\n"),size=50.0,leading=58.0
 let firstBaseline=r.midY-Double(lines.count-1)*leading/2+size*0.35
 for (i,line) in lines.enumerated(){text(c,line,r.midX,firstBaseline+Double(i)*leading,size,muted,false,true,a)}
}
func sourceCrop(_ c:CGContext,_ i:Int,_ r:CGRect,_ a:Double=1){
 c.saveGState();c.setAlpha(a);rounded(c,r,5,"#24262A");let im=sourceCrops[i],scale=min((r.width-10)/Double(im.width),(r.height-8)/Double(im.height));let d=CGRect(x:r.midX-Double(im.width)*scale/2,y:r.midY-Double(im.height)*scale/2,width:Double(im.width)*scale,height:Double(im.height)*scale);draw(c,im,d);c.setStrokeColor(color(orange,0.95));c.setLineWidth(3.5);c.stroke(r);c.restoreGState()
}
func structure(_ c:CGContext,_ a:Double,_ t:Double){
 table(c,structureGrid,a,Array(repeating:0,count:10),blue)
 let r0=cellRect(structureGrid,cells[0].area),r1=cellRect(structureGrid,cells[1].area)
 let reveal0=smooth((t-11.15)/0.35),reveal1=smooth((t-11.75)/0.35)
 let p0=reveal0*(1-smooth((t-12.8)/0.35)),p1=reveal1*(1-smooth((t-13.4)/0.35))
 for (r,p) in [(r0,p0),(r1,p1)]{c.setFillColor(color(blue,a*(0.10+0.12*p)));c.fill(r);outline(c,r,blue,a*(0.5+0.5*p),4)}
 // Span attributes belong to the cells they describe; the label never sits
 // beneath the table or appears over an unrelated output cell.
 text(c,"rowspan",r0.midX,r0.midY-6,38,blue,true,true,a*reveal0)
 text(c,"= 2",r0.midX,r0.midY+36,38,blue,true,true,a*reveal0)
 text(c,"colspan = 2",r1.midX,r1.midY+13,38,blue,true,true,a*reveal1)
}
func glyph(_ c:CGContext,_ s:String,_ pos:CGPoint,_ size:Double,_ a:Double=1,_ h:String=ink){text(c,s,pos.x,pos.y,size,h,false,false,a)}
func frame(_ c:CGContext,_ raw:Double){
 let t=min(38,max(0,raw));c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:Double(W)/1920,y:-Double(H)/1080)
 c.setFillColor(color(bg));c.fill(CGRect(x:0,y:0,width:1920,height:1080))
 // Title is supplied by the reusable scene wrapper.
 // The pretraining explanation lives on the earlier training slides.
 // Shift the complete modular diagram together to preserve all connections.
 c.translateBy(x:0,y:-25)
 let move=ease((t-1.3)/1.0),input=rectMix(inputStart,inputFinal,move)
 draw(c,sourceTable,input)
 text(c,"Table image",input.midX,mix(252,382,move),48,muted,true,true)
 let aS=smooth((t-2.9)/0.45),aL=smooth((t-3.65)/0.45),aC=smooth((t-5.0)/0.55),aF=smooth((t-6.8)/0.5)
 trimmed(c,curvedBranch(CGPoint(x:613,y:440)),ease((t-2.3)/0.8),blue)
 trimmed(c,curvedBranch(CGPoint(x:613,y:880)),ease((t-3.0)/0.8),orange)
 trimmed(c,[CGPoint(x:1187,y:880),CGPoint(x:1232,y:880)],ease((t-4.4)/0.75),green)
 // Briefly label the first two real cell crops; never leave a permanent caption.
 let cropLabel=smooth((t-15.15)/0.20)*(1-smooth((t-17.45)/0.25))
 text(c,"crop",1209,850,30,orange,false,true,cropLabel)
 trimmed(c,[CGPoint(x:1187,y:440),CGPoint(x:1232,y:440)],ease((t-6.35)/0.7),blue)
 trimmed(c,[CGPoint(x:1540,y:701),CGPoint(x:1540,y:659)],ease((t-7.1)/0.65),green)
 module(c,structureBox,"Structure model",blue,aS)
 module(c,locationBox,"Location model",orange,aL)
 module(c,contentBox,"Content model",green,aC)
 module(c,finalBox,"Digitized table",ink,aF)
 // The same image is copied into each independently finetuned whole-table model.
 branchCopy(c,t,2.55,1.10,CGPoint(x:670,y:440),blue)
 branchCopy(c,t,3.30,1.10,CGPoint(x:670,y:880),orange)
 let structureFocus=smooth((t-10.45)/0.35)*(1-smooth((t-13.60)/0.55))
 let locationFocus=smooth((t-11.0)/0.35)*(1-smooth((t-15.0)/0.55))
 let contentFocus=smooth((t-15.15)/0.35)*(1-smooth((t-23.6)/0.55))
 let finalFocus=smooth((t-27.0)/0.35)*(1-smooth((t-35.2)/0.55))
 focus(c,structureBox,blue,structureFocus*0.82)
 focus(c,locationBox,orange,locationFocus*0.82)
 focus(c,contentBox,green,contentFocus*0.82)
 focus(c,finalBox,ink,finalFocus*0.82)

 let dataS=smooth((t-10.45)/0.5),dataL=smooth((t-10.8)/0.5)
 placeholder(c,"Rows · columns\nMerged cells",CGRect(x:645,y:335,width:510,height:170),aS*(1-dataS))
 placeholder(c,"Cell boxes",CGRect(x:645,y:815,width:510,height:135),aL*(1-dataL))
 placeholder(c,"Recognize cell crops",CGRect(x:1265,y:840,width:550,height:110),aC*(1-smooth((t-15.0)/0.35)))
 placeholder(c,"Structure + text",CGRect(x:1265,y:350,width:550,height:150),aF*(1-smooth((t-27.0)/0.4)))
 structure(c,dataS,t)
 draw(c,sourceTable,locationGrid,dataL)
 text(c,"Cell",1060,881,44,orange,true,true,dataL)
 text(c,"boxes",1060,927,44,orange,true,true,dataL)
 for (i,z) in cells.enumerated(){let a=smooth((t-11.35-Double(i)*0.15)/0.25);outline(c,cellRect(locationGrid,z.textBounds).insetBy(dx:-3,dy:-3),orange,dataL*a,2.5)}
 // Cell crops are real pixels of the displayed source table, copied along the location -> OCR path.
 var active:Int?=nil
 for i in 0..<10 {if t>=cropStarts[i]{active=i}}
 // Retire the transient crop -> decoded word row once all cells are read.
 // The accumulated content list remains visible for the next assembly stage.
 let activeOCRAlpha=1-smooth((t-23.65)/0.50)
 if let i=active, activeOCRAlpha>0 {
  c.saveGState();c.setAlpha(activeOCRAlpha);c.beginTransparencyLayer(auxiliaryInfo:nil)
  let dt=t-cropStarts[i],travel=i<2 ? 0.70:0.44,u=ease(dt/travel),ready=smooth((dt-(i<2 ? 0.65:0.40))/(i<2 ? 0.20:0.12))
  let from=cellRect(locationGrid,cells[i].textBounds).insetBy(dx:-3,dy:-3)
  let moving=rectMix(from,cropTarget,u)
  sourceCrop(c,i,moving,smooth(dt/0.14))
  trimmed(c,[CGPoint(x:1524,y:824),CGPoint(x:1554,y:824)],1,green,ready,4)
  text(c,cells[i].text,1572,835,cells[i].text.count>11 ? 36:44,ink,false,false,ready)
  let flash=1-smooth((dt-0.7)/0.6)
  outline(c,cellRect(inputFinal,cells[i].textBounds).insetBy(dx:-4,dy:-3),orange,smooth(dt/0.15)*flash,4)
  let selected=cellRect(locationGrid,cells[i].textBounds).insetBy(dx:-3,dy:-3)
  c.setFillColor(color(orange,smooth(dt/0.12)*flash*0.18));c.fill(selected)
  outline(c,selected,orange,smooth(dt/0.12)*flash,4.5)
  c.endTransparencyLayer();c.restoreGState()
 }
 for i in 0..<10 {let a=smooth((t-cropStarts[i]-(i<2 ? 0.72:0.50))/(i<2 ? 0.20:0.10));glyph(c,cells[i].text,contentPosition(i,t),42,a)}
 // The structure is copied; its original output remains visible throughout assembly.
 let structureMove=ease((t-27.0)/1.35)
 if t>=27 {
  let moving=rectMix(structureGrid,finalGrid,structureMove)
  let fa=smooth((t-27.0)/0.25)
  table(c,moving,fa,Array(repeating:0,count:10),blue)

 }
 if t>=28.35 {
  let fills=cells.enumerated().map{i,z in smooth((t-assemblyStarts[i]-0.70)/0.15)}
  table(c,finalGrid,1,fills,blue)
  for i in 0..<10 {
   let dt=t-assemblyStarts[i]
   if dt>=0 && dt<0.85 {
    let u=ease(dt/0.70),a=smooth(dt/0.12)*(1-smooth((dt-0.70)/0.15)),to=CGPoint(x:finalGrid.minX+cells[i].pos.x*finalGrid.width/380,y:finalGrid.minY+cells[i].pos.y*finalGrid.height/288)
    let start=contentPosition(i,t),pos=CGPoint(x:mix(start.x,to.x,u),y:mix(start.y,to.y,u))
    sourceWordMark(c,i,a,t)
    outline(c,cellRect(structureGrid,cells[i].area).insetBy(dx:2,dy:2),blue,a*0.90,4)
    glyph(c,cells[i].text,pos,mix(42,27.5*finalGrid.width/380,u),a,ink)
    outline(c,cellRect(finalGrid,cells[i].area).insetBy(dx:2,dy:2),green,a*0.75,4)
   }
  }
 }
 let finish=smooth((t-34.0)/0.35)
 if finish>0 {
  for i in [0,1]{outline(c,cellRect(finalGrid,cells[i].area).insetBy(dx:2,dy:2),blue,finish*(1-smooth((t-35.1)/0.45))*0.8,5)}
 }
 c.restoreGState()
}

func render(_ t:Double)->CGImage {
 let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 frame(c,referenceTime(t))
 c.saveGState();c.translateBy(x:0,y:Double(height));c.scaleBy(x:Double(width)/1920,y:-Double(height)/1080)
 text(c,content["title"] as? String ?? "Specialized modules assemble a complete result.",96,138,64,ink,true)
 c.restoreGState();return c.makeImage()!
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
