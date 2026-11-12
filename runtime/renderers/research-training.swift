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
let supportedKinds = ["learn-visual-vocabulary", "masked-token-training"]
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

let space=cs
let bg=theme["background"] as? String ?? "#2B2B2D",white=theme["foreground"] as? String ?? "#F6F6F4",gray="#B4BAC3",dim="#55545D",purple="#C7A0ED",cyan="#77D5DF",panel="#343038"
func assetURL(_ key:String)->URL {let p=content[key] as? String ?? "../../assets/research/toy-table.png";return p.hasPrefix("/") ? URL(fileURLWithPath:p) : configURL.deletingLastPathComponent().appendingPathComponent(p).standardizedFileURL}
// Named stage times are an invertible time mapping to the proven reference sequence.
func referenceTime(_ t:Double)->Double {
 let anchors=raw["timeline"] as? [[String:Double]] ?? [["at":0,"reference":0],["at":duration,"reference":16]]
 if t<=anchors[0]["at"]! {return anchors[0]["reference"]!}
 for i in 1..<anchors.count {let a=anchors[i-1],b=anchors[i];if t<=b["at"]! {let u=(t-a["at"]!)/(b["at"]!-a["at"]!);return a["reference"]!+(b["reference"]!-a["reference"]!)*u}}
 return anchors.last!["reference"]!
}
func color(_ h:String,_ a:Double=1)->CGColor{let n=UInt32(h.dropFirst(),radix:16)!;return CGColor(colorSpace:space,components:[Double((n>>16)&255)/255,Double((n>>8)&255)/255,Double(n&255)/255,a])!}
func clamp(_ t:Double)->Double{max(0,min(1,t))}
func ease(_ t:Double)->Double{let u=clamp(t);return u*u*(3-2*u)}
func on(_ t:Double,_ start:Double,_ d:Double=0.5)->Double{ease((t-start)/d)}
func mix(_ a:Double,_ b:Double,_ u:Double)->Double{a+(b-a)*u}
func pt(_ x:Double,_ y:Double)->CGPoint{CGPoint(x:x,y:y)}
func lerp(_ a:CGPoint,_ b:CGPoint,_ u:Double)->CGPoint{pt(mix(a.x,b.x,u),mix(a.y,b.y,u))}
func mixr(_ a:CGRect,_ b:CGRect,_ u:Double)->CGRect{CGRect(x:mix(a.minX,b.minX,u),y:mix(a.minY,b.minY,u),width:mix(a.width,b.width,u),height:mix(a.height,b.height,u))}
func round(_ c:CGContext,_ r:CGRect,_ fill:String?,_ stroke:String?,_ width:Double=3,_ a:Double=1,_ rad:Double=16){c.saveGState();c.setAlpha(a);let p=CGPath(roundedRect:r,cornerWidth:rad,cornerHeight:rad,transform:nil);c.addPath(p);if let f=fill{c.setFillColor(color(f))};if let s=stroke{c.setStrokeColor(color(s));c.setLineWidth(width)};c.drawPath(using:fill != nil && stroke != nil ? .fillStroke:fill != nil ? .fill:.stroke);c.restoreGState()}
func line(_ c:CGContext,_ ps:[CGPoint],_ col:String,_ w:Double=4,_ a:Double=1){if ps.count<2||a<=0{return};c.saveGState();c.setStrokeColor(color(col,a));c.setLineWidth(w);c.setLineJoin(.round);c.setLineCap(.round);c.move(to:ps[0]);for p in ps.dropFirst(){c.addLine(to:p)};c.strokePath();c.restoreGState()}
func partial(_ ps:[CGPoint],_ v:Double)->[CGPoint]{let u=clamp(v);if u<=0{return [ps[0]]};if u>=1{return ps};let lengths=zip(ps,ps.dropFirst()).map{hypot($0.x-$1.x,$0.y-$1.y)},total=lengths.reduce(0,+);var remain=total*u,out=[ps[0]];for i in 0..<lengths.count{if remain>lengths[i]{out.append(ps[i+1]);remain-=lengths[i]}else{out.append(lerp(ps[i],ps[i+1],remain/max(lengths[i],0.001)));break}};return out}
func arrow(_ c:CGContext,_ ps:[CGPoint],_ u:Double=1,_ col:String=gray,_ w:Double=4,_ a:Double=1){if u<=0{return};let p=partial(ps,u);line(c,p,col,w,a);let e=p.last!,b=p[p.count-2],ang=atan2(e.y-b.y,e.x-b.x),drawn=zip(p,p.dropFirst()).reduce(0.0){$0+hypot($1.1.x-$1.0.x,$1.1.y-$1.0.y)},k=min(18.0,drawn*0.9);line(c,[pt(e.x-k*cos(ang-0.45),e.y-k*sin(ang-0.45)),e,pt(e.x-k*cos(ang+0.45),e.y-k*sin(ang+0.45))],col,w,a)}
func dot(_ c:CGContext,_ p:CGPoint,_ r:Double,_ col:String,_ a:Double=1){c.saveGState();c.setFillColor(color(col,a));c.fillEllipse(in:CGRect(x:p.x-r,y:p.y-r,width:2*r,height:2*r));c.restoreGState()}
func packet(_ c:CGContext,_ ps:[CGPoint],_ t:Double,_ start:Double,_ d:Double,_ col:String=cyan,_ subtle:Bool=false){let u=(t-start)/d;if u<0||u>1{return};let p=partial(ps,ease(u)).last!;dot(c,p,subtle ? 7:11,col,subtle ? 0.10:0.18);dot(c,p,subtle ? 4.5:6,col,subtle ? 0.80:1)}
func text(_ c:CGContext,_ s:String,_ x:Double,_ y:Double,_ size:Double=38,_ col:String=white,_ bold:Bool=false,_ a:Double=1,_ centered:Bool=true){if a<=0{return};let font=NSFont(name:bold ? "SFProDisplay-Bold":"SFProDisplay-Regular",size:size) ?? .systemFont(ofSize:size,weight:bold ? .bold:.regular);let display=(content["labels"] as? [String:String])?[s] ?? s;let l=CTLineCreateWithAttributedString(NSAttributedString(string:display,attributes:[.font:font,.foregroundColor:NSColor(cgColor:color(col))!]));let len=CTLineGetTypographicBounds(l,nil,nil,nil);c.saveGState();c.setAlpha(a);c.translateBy(x:centered ? x-len/2:x,y:y);c.scaleBy(x:1,y:-1);c.textMatrix = .identity;c.textPosition = .zero;CTLineDraw(l,c);c.restoreGState()}
func lines(_ c:CGContext,_ ss:[String],_ x:Double,_ y:Double,_ size:Double=38,_ col:String=white,_ a:Double=1,_ bold:Bool=false){for (i,s) in ss.enumerated(){text(c,s,x,y+Double(i)*(size*1.12),size,col,bold,a)}}
let table:NSImage=NSImage(contentsOf:assetURL("table_image"))!
let tableImage=table.cgImage(forProposedRect:nil,context:nil,hints:nil)!
func drawImage(_ c:CGContext,_ r:CGRect,_ a:Double=1){if a<=0{return};c.saveGState();c.setAlpha(a);c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.interpolationQuality = .high;c.draw(tableImage,in:CGRect(x:0,y:0,width:r.width,height:r.height));c.restoreGState()}
let ids=content["token_ids"] as? [String] ?? ["A","B","C","A","D","B","A","C","B","D","C","A"]
let masked=Set(content["masked_positions"] as? [Int] ?? [1,4,6,9,10])
let guesses=content["predictions"] as? [String] ?? ["A","C","C","A","D","B","B","C","B","A","C","A"]
// Teal marks hidden positions; opaque masks cover shared gray boundaries.
func grid(_ c:CGContext,_ r:CGRect,_ a:Double=1,_ reveal:Double=1,_ maskedOnly:Bool=false,_ focus:Double=0,_ predicted:Bool=false,_ maskSemantics:Bool=false){
 let cw=r.width/4,ch=r.height/3
 if maskSemantics {
  // Neutral full-cell borders first; selected opaque masks cover shared borders.
  for i in 0..<12 {
   let rr=CGRect(x:r.minX+Double(i%4)*cw,y:r.minY+Double(i/4)*ch,width:cw,height:ch),sel=masked.contains(i),alpha=a*(maskedOnly && !sel ? 0.22:1)
   round(c,rr,"#343038","#77717F",3,alpha*(sel ? 1:1-0.55*focus),0)
  }
  for i in 0..<12 where masked.contains(i) {
   let rr=CGRect(x:r.minX+Double(i%4)*cw,y:r.minY+Double(i/4)*ch,width:cw,height:ch).insetBy(dx:-2,dy:-2)
   round(c,rr,"#3C7E86",nil,0,a*focus,0)
  }
  // Letters are always topmost, including the unmasked B between four masks.
  for i in 0..<12 {
   let x=r.minX+Double(i%4)*cw,y=r.minY+Double(i/4)*ch,sel=masked.contains(i),show=on(reveal*12,Double(i)*0.78,1.0),alpha=a*(maskedOnly && !sel ? 0.22:1)
   if maskedOnly && !sel{text(c,"·",x+cw/2,y+ch*0.68,32,dim,false,a)}
   else{let value=predicted ? guesses[i]:ids[i];text(c,value,x+cw/2,y+ch*0.68,min(44,ch*0.68),sel ? white:"#C5C5CD",true,alpha*show)}
  }
  return
 }
 for i in 0..<12{
  let x=r.minX+Double(i%4)*cw,y=r.minY+Double(i/4)*ch,sel=masked.contains(i),show=on(reveal*12,Double(i)*0.78,1.0),alpha=a*(maskedOnly && !sel ? 0.22:1)
  let rr=CGRect(x:x+5,y:y+5,width:cw-10,height:ch-10)
  round(c,rr,"#343038","#77717F",3,alpha*(sel ? 1:1-0.55*focus),7)
  if sel && focus>0{round(c,rr,"#3C7E86","#3C7E86",3,alpha*focus,7)}
  if maskedOnly && !sel{text(c,"·",x+cw/2,y+ch*0.68,32,dim,false,a)}
  else{let value=predicted ? guesses[i]:ids[i];text(c,value,x+cw/2,y+ch*0.68,min(44,ch*0.68),maskSemantics && !sel ? "#C5C5CD":white,true,alpha*show)}
 }
}
func maskImage(_ c:CGContext,_ r:CGRect,_ t:Double,_ a:Double=1){
 drawImage(c,r,a);let cw=r.width/4,ch=r.height/3
 // Draw every grid boundary before any opaque mask so later cells cannot redraw it.
 for i in 0..<12{let box=CGRect(x:r.minX+Double(i%4)*cw,y:r.minY+Double(i/4)*ch,width:cw,height:ch)
  round(c,box.insetBy(dx:0.5,dy:0.5),nil,"#626A73",1,a*0.55,0)
 }
 for i in 0..<12 where masked.contains(i){let box=CGRect(x:r.minX+Double(i%4)*cw,y:r.minY+Double(i/4)*ch,width:cw,height:ch)
  let aa=on(t,Double(i%3)*0.12,0.45)*a;round(c,box.insetBy(dx:-2,dy:-2),"#3C7E86",nil,0,aa,0)
 }
 for i in 0..<12 where masked.contains(i){let box=CGRect(x:r.minX+Double(i%4)*cw,y:r.minY+Double(i/4)*ch,width:cw,height:ch)
  let aa=on(t,Double(i%3)*0.12,0.45)*a;line(c,[pt(box.midX-11,box.midY),pt(box.midX+11,box.midY)],white,4,aa)
 }
}
func network(_ c:CGContext,_ r:CGRect,_ a:Double,_ activity:Double=0,_ decode:Bool=false){round(c,r,panel,purple,3.5,a);if activity>0{round(c,r.insetBy(dx:-6,dy:-6),nil,purple,4,a*activity*0.5,20)};for i in 0..<3{let h=decode ? 70+Double(i)*25:120-Double(i)*25;let x=r.minX+34+Double(i)*55;round(c,CGRect(x:x,y:r.midY-h/2,width:38,height:h),i==1 ? "#77618D":"#51405F",purple,2,a,6)} }
func lock(_ c:CGContext,_ x:Double,_ y:Double,_ a:Double=1){round(c,CGRect(x:x-22,y:y-1,width:44,height:34),nil,cyan,4,a,6);c.saveGState();c.setStrokeColor(color(cyan,a));c.setLineWidth(4);c.addArc(center:pt(x,y-1),radius:15,startAngle:Double.pi,endAngle:0,clockwise:false);c.strokePath();c.restoreGState();dot(c,pt(x,y+14),3,cyan,a)}
func pattern(_ c:CGContext,_ i:Int,_ r:CGRect,_ col:String,_ a:Double){let x=r.minX,y=r.minY,w=r.width,h=r.height;switch i%4{case 0:line(c,[pt(x,y+h/2),pt(x+w,y+h/2)],col,3,a);case 1:line(c,[pt(x+w/2,y),pt(x+w/2,y+h)],col,3,a);line(c,[pt(x,y+h/2),pt(x+w,y+h/2)],col,3,a);case 2:line(c,[pt(x,y),pt(x+w,y),pt(x+w,y+h)],col,3,a);default:line(c,[pt(x,y+h*0.25),pt(x+w*0.65,y+h*0.25)],col,3,a);line(c,[pt(x,y+h*0.7),pt(x+w,y+h*0.7)],col,3,a)}}
func codebook(_ c:CGContext,_ r:CGRect,_ a:Double,_ t:Double,_ pulse:Double){for i in 0..<4{let h=r.height/4,rr=CGRect(x:r.minX,y:r.minY+Double(i)*h+2,width:r.width,height:h-4);let v=t<3 ? 0:max(0,1-abs(sin(min(t,4.8)*2.5+Double(i)*1.2)));round(c,rr,"#343038",purple,2,a,8);round(c,CGRect(x:rr.minX+1,y:rr.minY+1,width:rr.width-2,height:rr.height-2),purple,nil,0,a*min(0.35,v*0.20+pulse*0.15),8);pattern(c,i,CGRect(x:rr.minX+17,y:rr.minY+12,width:35,height:rr.height-24),white,a);text(c,["A","B","C","D"][i],rr.minX+85,rr.midY+13,37,white,true,a);round(c,CGRect(x:rr.minX+120,y:rr.midY-5,width:70*max(0.10,v),height:10),purple,nil,0,a,5)}}

func learnCodebook(_ c:CGContext,_ t:Double){
 let input=CGRect(x:70,y:380,width:245,height:245*288/380),enc=CGRect(x:375,y:380,width:220,height:186),book=CGRect(x:655,y:380,width:220,height:186),tokens=CGRect(x:935,y:380,width:220,height:186),dec=CGRect(x:1215,y:380,width:220,height:186),rec=CGRect(x:1495,y:357,width:305,height:305*288/380)
 let starts=[0.0,1.3,3.0,4.8,6.2,7.6],centers=[input.midX,enc.midX,book.midX,tokens.midX,dec.midX,rec.midX],labels=[["Input table"],["Tokenizer","encoder"],["Visual","vocabulary"],["Visual","tokens"],["Image","decoder"],["Reconstructed","table"]]
 for i in 0..<6{lines(c,labels[i],centers[i],286,44,white,i==0 ? 1:max(0.20,on(t,starts[i],0.35)),true)}
 drawImage(c,input);let update=on(t,11.5,0.6)*(1-on(t,13.8,0.6));network(c,enc,on(t,1.3),on(t,1.7,0.3)*(1-on(t,2.8,0.3))+update,false);codebook(c,book,on(t,3.0),t,update);text(c,"Soft selection",book.midX,367,28,purple,false,on(t,3.0));grid(c,tokens,on(t,4.8),on(t,4.8,1.3));network(c,dec,on(t,6.2),on(t,6.4,0.2)*(1-on(t,7.4,0.3))+update,true);drawImage(c,rec,on(t,7.6,0.7))
 let arrows:[[CGPoint]]=[[pt(326,473),pt(362,473)],[pt(607,473),pt(642,473)],[pt(887,473),pt(922,473)],[pt(1167,473),pt(1202,473)],[pt(1447,473),pt(1482,473)]]
 for (i,ps) in arrows.enumerated(){arrow(c,ps,on(t,starts[i+1]-0.35,0.45),gray,4,0.8);packet(c,ps,t,starts[i+1]-0.35,0.55,"#738F97",true)}
 let compare=on(t,8.5,0.7),a=CGRect(x:70,y:735,width:245,height:245*288/380),b=CGRect(x:365,y:735,width:245,height:245*288/380)
 drawImage(c,mixr(input,a,compare),compare);drawImage(c,mixr(rec,b,compare),compare)
 text(c,"Original",a.midX,710,40,white,false,compare);text(c,"Reconstruction",b.midX,710,40,white,false,compare)
 let lossA=on(t,9.4,0.5);round(c,CGRect(x:730,y:766,width:360,height:126),panel,cyan,3.5,lossA,16);lines(c,["Reconstruction","error"],910,817,44,white,lossA,true)
 arrow(c,[pt(621,828),pt(716,828)],on(t,9.2,0.5),cyan,4)
 arrow(c,[pt(a.midX,932),pt(a.midX,953),pt(680,953),pt(680,828),pt(716,828)],on(t,9.2,0.8),cyan,3.5)
 let feedback=on(t,11.0,0.8);line(c,partial([pt(910,754),pt(910,654)],on(t,10.4,0.6)),purple,4.5);arrow(c,[pt(910,654),pt(485,654),pt(485,579)],feedback,purple,4.5)
 arrow(c,[pt(910,654),pt(765,654),pt(765,579)],feedback,purple,4.5)
 arrow(c,[pt(910,654),pt(1325,654),pt(1325,579)],feedback,purple,4.5)
 lines(c,["Update encoder,","codebook + decoder"],1450,810,44,purple,on(t,10.5,0.7),true)
}

func pretrain(_ c:CGContext,_ t:Double){
 let full=CGRect(x:70,y:320,width:300,height:300*288/380),frozen=CGRect(x:490,y:335,width:380,height:195),target=CGRect(x:1055,y:320,width:300,height:225),maskedInput=CGRect(x:70,y:675,width:300,height:300*288/380),encoder=CGRect(x:490,y:690,width:380,height:195),prediction=CGRect(x:1055,y:675,width:300,height:225)
 text(c,"Full table",full.midX,285,44,white,true);drawImage(c,full)
 let f=on(t,1.0),g=on(t,2.7),m=on(t,4.4),e=on(t,6.1),p=on(t,7.8),focus=on(t,9.6,0.6),upd=on(t,12.2,0.5)*(1-on(t,14,0.6))
 round(c,frozen,"#30343A",gray,3,f,18);lines(c,["Frozen tokenizer"],frozen.midX,390,44,white,f,true);lock(c,frozen.midX,443,f)
 text(c,"Target token IDs",target.midX,285,44,white,true,g);grid(c,target,g,on(t,2.7,1.4),false,focus,false,true)
 arrow(c,[pt(385,433),pt(473,433)],on(t,0.65,0.55),gray,4);packet(c,[pt(385,433),pt(473,433)],t,0.75,0.8)
 arrow(c,[pt(886,433),pt(1038,433)],on(t,2.2,0.55),gray,4);packet(c,[pt(886,433),pt(1038,433)],t,2.25,0.8)
 if m>0{let r=mixr(full,maskedInput,m);maskImage(c,r,t-5.0,m)}
 text(c,"Masked table",maskedInput.midX,640,44,white,true,on(t,4.8))
 round(c,encoder,panel,purple,3.5,e,18);if upd>0{round(c,encoder.insetBy(dx:-7,dy:-7),nil,purple,4,e*upd*0.5,24)}
 lines(c,["Visual encoder"],encoder.midX,759,44,white,e,true);text(c,"Trainable",encoder.midX,824,44,purple,true,e)
 text(c,"Predicted token IDs",prediction.midX,640,44,white,true,p);grid(c,prediction,p,on(t,7.8,1.3),true,focus,true,true)
 arrow(c,[pt(385,788),pt(473,788)],on(t,5.7,0.55),gray,4);packet(c,[pt(385,788),pt(473,788)],t,5.8,0.8)
 arrow(c,[pt(886,788),pt(1038,788)],on(t,7.25,0.55),gray,4);packet(c,[pt(886,788),pt(1038,788)],t,7.35,0.8)
 let comp=on(t,10.0,0.5);round(c,CGRect(x:1480,y:540,width:400,height:150),panel,cyan,3.5,comp,18);lines(c,["Compare only","masked positions"],1680,600,44,white,comp,true)
 arrow(c,[pt(1370,433),pt(1430,433),pt(1430,576),pt(1465,576)],on(t,9.6,0.9),cyan,4)
 arrow(c,[pt(1370,788),pt(1430,788),pt(1430,650),pt(1465,650)],on(t,9.6,0.9),cyan,4)
 packet(c,[pt(1370,433),pt(1430,433),pt(1430,576),pt(1465,576)],t,10.4,0.9,cyan)
 packet(c,[pt(1370,788),pt(1430,788),pt(1430,650),pt(1465,650)],t,10.4,0.9,cyan)
 arrow(c,[pt(1680,706),pt(1680,973),pt(680,973),pt(680,903)],on(t,11.5,1.1),purple,4.5)
 text(c,"Update visual encoder only",1175,950,44,purple,true,on(t,11.8,0.5))
}

func render(_ t:Double)->CGImage {
 let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.translateBy(x:0,y:Double(height));c.scaleBy(x:Double(width)/1920,y:-Double(height)/1080)
 c.setFillColor(color(bg));c.fill(CGRect(x:0,y:0,width:1920,height:1080))
 text(c,content["title"] as? String ?? "Learn structure from unlabeled images.",96,138,64,white,true,1,false)
 let t=referenceTime(t)
 if kind=="learn-visual-vocabulary" {learnCodebook(c,t)} else {pretrain(c,t)}
 return c.makeImage()!
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
