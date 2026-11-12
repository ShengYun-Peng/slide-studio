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
let supportedKinds = ["framework-to-portfolio", "branch-and-merge", "learn-visual-vocabulary", "masked-token-training", "surface-build", "surface-trajectories", "video-budget", "text-and-score", "device-story"]
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
func clamp(_ x: Double) -> Double { max(0, min(1, x)) }
func mix(_ a: Double, _ b: Double, _ u: Double) -> Double { a + (b - a) * u }
func smooth(_ x: Double) -> Double { let u = clamp(x); return u*u*u*(u*(u*6-15)+10) }
func progress(_ t: Double, _ a: Double, _ b: Double) -> Double { smooth((t-a)/max(0.001,b-a)) }
func event(_ name: String, _ fallback: Double) -> Double { timing[name] as? Double ?? fallback * duration }
func phase(_ t: Double, _ start: String, _ end: String, _ a: Double, _ b: Double) -> Double {
    progress(t, event(start,a), event(end,b))
}
func value(_ key: String, _ fallback: String) -> String { content[key] as? String ?? fallback }
func strings(_ key: String, _ fallback: [String]) -> [String] { content[key] as? [String] ?? fallback }
let bg = theme["background"] as? String ?? "#2B2B2D"
let fg = theme["foreground"] as? String ?? "#F6F6F4"
let muted = theme["muted"] as? String ?? "#BAC1CC"
let panel = theme["panel"] as? String ?? "#36383D"
let accents = theme["accents"] as? [String] ?? ["#7ABC73","#66A7FF","#FFB253"]
func accent(_ i: Int) -> String { accents.isEmpty ? "#66A7FF" : accents[i % accents.count] }
let purple = "#C6A1EE"
let cyan = "#81D4EE"
let regular = theme["font_regular"] as? String ?? "HelveticaNeue"
let bold = theme["font_bold"] as? String ?? "HelveticaNeue-Bold"
func color(_ hex: String, _ alpha: Double = 1) -> CGColor {
    let s = hex.replacingOccurrences(of: "#", with: "")
    let n = UInt64(s, radix: 16) ?? 0xF6F6F4
    return CGColor(colorSpace: cs, components: [CGFloat((n>>16)&255)/255,CGFloat((n>>8)&255)/255,CGFloat(n&255)/255,CGFloat(clamp(alpha))])!
}
func nscolor(_ hex: String, _ alpha: Double = 1) -> NSColor { NSColor(cgColor: color(hex,alpha))! }
func font(_ size: Double, _ weight: Bool = false) -> NSFont {
    NSFont(name: weight ? bold : regular, size: size) ?? .systemFont(ofSize: size, weight: weight ? .bold : .regular)
}
func textWidth(_ s: String, _ size: Double, _ weight: Bool = false) -> Double {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:font(size,weight)]))
    return CTLineGetTypographicBounds(line,nil,nil,nil)
}
// y is baseline in a top-left coordinate system. Every label remains a single line.
func text(_ c: CGContext, _ s: String, _ x: Double, _ y: Double, _ size: Double = 42,
          _ col: String? = nil, _ weight: Bool = false, _ alpha: Double = 1,
          _ align: String = "left", _ maxWidth: Double = 1800) {
    var actual = size
    if textWidth(s,actual,weight) > maxWidth { actual *= maxWidth/textWidth(s,actual,weight) }
    let line = CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:font(actual,weight),.foregroundColor:nscolor(col ?? fg,alpha)]))
    let w = CTLineGetTypographicBounds(line,nil,nil,nil)
    let xx = align == "center" ? x-w/2 : (align == "right" ? x-w : x)
    c.saveGState(); c.translateBy(x:xx,y:y); c.scaleBy(x:1,y:-1)
    c.textMatrix = .identity; c.textPosition = .zero; CTLineDraw(line,c); c.restoreGState()
}
func box(_ c: CGContext, _ r: CGRect, _ fill: String? = nil, _ stroke: String? = nil, _ radius: Double = 24, _ alpha: Double = 1, _ lineWidth: Double = 5) {
    c.saveGState(); let p = CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil)
    if let f = fill { c.setFillColor(color(f,alpha)); c.addPath(p); c.fillPath() }
    if let s = stroke { c.setStrokeColor(color(s,alpha)); c.setLineWidth(lineWidth); c.addPath(p); c.strokePath() }
    c.restoreGState()
}
func line(_ c: CGContext, _ points: [CGPoint], _ col: String? = nil, _ thickness: Double = 6, _ alpha: Double = 1, _ dash: [CGFloat] = []) {
    guard points.count > 1 else { return }
    c.saveGState(); c.setStrokeColor(color(col ?? muted,alpha)); c.setLineWidth(thickness)
    c.setLineCap(.round); c.setLineJoin(.round); c.setLineDash(phase:0,lengths:dash)
    c.beginPath(); c.move(to:points[0]); for p in points.dropFirst() { c.addLine(to:p) }; c.strokePath(); c.restoreGState()
}
func dot(_ c: CGContext, _ x: Double, _ y: Double, _ r: Double, _ col: String, _ alpha: Double = 1) {
    c.setFillColor(color(col,alpha)); c.fillEllipse(in:CGRect(x:x-r,y:y-r,width:r*2,height:r*2))
}
func arrow(_ c: CGContext, _ start: CGPoint, _ end: CGPoint, _ col: String? = nil,
           _ bend: Double = 0, _ amount: Double = 1, _ alpha: Double = 1, _ thickness: Double = 6) {
    guard amount > 0 else { return }
    let control1 = CGPoint(x:mix(start.x,end.x,0.48),y:start.y+bend)
    let control2 = CGPoint(x:mix(start.x,end.x,0.52),y:end.y+bend)
    let count = max(2,Int(80*clamp(amount)))
    let points = (0...count).map { i -> CGPoint in
        let u = clamp(amount)*Double(i)/Double(count), v = 1-u
        return CGPoint(x:v*v*v*start.x+3*v*v*u*control1.x+3*v*u*u*control2.x+u*u*u*end.x,
                       y:v*v*v*start.y+3*v*v*u*control1.y+3*v*u*u*control2.y+u*u*u*end.y)
    }
    line(c,points,col,thickness,alpha)
    let a = points[points.count-2], b = points.last!, angle = atan2(b.y-a.y,b.x-a.x), head = max(20,thickness*3.3)
    // Arrowhead and shaft share the exact same endpoint and tangent.
    let p1 = CGPoint(x:b.x-head*cos(angle-0.43),y:b.y-head*sin(angle-0.43))
    let p2 = CGPoint(x:b.x-head*cos(angle+0.43),y:b.y-head*sin(angle+0.43))
    line(c,[p1,b,p2],col,thickness,alpha)
}
func straightArrow(_ c:CGContext,_ a:CGPoint,_ b:CGPoint,_ col:String,_ thickness:Double=4,_ alpha:Double=1) {
    line(c,[a,b],col,thickness,alpha)
    let angle=atan2(b.y-a.y,b.x-a.x),head=19.0
    line(c,[CGPoint(x:b.x-head*cos(angle-0.43),y:b.y-head*sin(angle-0.43)),b,CGPoint(x:b.x-head*cos(angle+0.43),y:b.y-head*sin(angle+0.43))],col,thickness,alpha)
}
func recognitionIcon(_ c:CGContext,_ type:String,_ x:Double,_ y:Double,_ alpha:Double) {
    if type.isEmpty {return}
    let col="#E6CC89"
    if type=="oral" {
        box(c,CGRect(x:x-8,y:y-18,width:16,height:26),col,nil,8,alpha)
        line(c,[CGPoint(x:x-16,y:y-3),CGPoint(x:x-15,y:y+12),CGPoint(x:x,y:y+20),CGPoint(x:x+15,y:y+12),CGPoint(x:x+16,y:y-3)],col,3,alpha)
        line(c,[CGPoint(x:x,y:y+20),CGPoint(x:x,y:y+30)],col,3,alpha)
    } else {
        let p=CGMutablePath()
        for i in 0..<10 {let a = -Double.pi/2+Double(i)*Double.pi/5,r=i%2==0 ? 22.0 : 10.0,pt=CGPoint(x:x+r*cos(a),y:y+r*sin(a));if i==0{p.move(to:pt)}else{p.addLine(to:pt)}}
        p.closeSubpath();c.addPath(p);c.setFillColor(color(col,alpha));c.fillPath()
    }
}
func title(_ c: CGContext, _ fallback: String, _ subtitle: String? = nil) {
    text(c,value("title",fallback),96,140,64,nil,true,1,"left",1728)
    if let s = subtitle { text(c,s,98,201,34,muted,false,1,"left",1700) }
}
func drawImage(_ c: CGContext, _ im: CGImage, _ r: CGRect) {
    c.saveGState(); c.translateBy(x:r.minX,y:r.maxY); c.scaleBy(x:1,y:-1)
    c.draw(im,in:CGRect(x:0,y:0,width:r.width,height:r.height)); c.restoreGState()
}
func badge(_ c: CGContext, _ index: Int, _ x: Double, _ y: Double, _ radius: Double, _ alpha: Double = 1) {
    let col = accent(index)
    c.setStrokeColor(color(col,alpha)); c.setLineWidth(9); c.strokeEllipse(in:CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2))
    if index%3 == 0 {
        let p = CGMutablePath(); p.move(to:CGPoint(x:x-26,y:y-29));p.addLine(to:CGPoint(x:x,y:y-40));p.addLine(to:CGPoint(x:x+26,y:y-29));p.addLine(to:CGPoint(x:x+23,y:y+12));p.addQuadCurve(to:CGPoint(x:x,y:y+37),control:CGPoint(x:x+15,y:y+29));p.addQuadCurve(to:CGPoint(x:x-23,y:y+12),control:CGPoint(x:x-15,y:y+29));p.closeSubpath()
        c.setFillColor(color(col,alpha)); c.addPath(p); c.fillPath();line(c,[CGPoint(x:x-12,y:y),CGPoint(x:x-2,y:y+10),CGPoint(x:x+16,y:y-13)],bg,7,alpha)
    } else if index%3 == 1 {
        line(c,[CGPoint(x:x-26,y:y+25),CGPoint(x:x+26,y:y-26)],col,13,alpha)
        line(c,[CGPoint(x:x-27,y:y-22),CGPoint(x:x+26,y:y+26)],col,13,alpha)
        dot(c,x+26,y-26,13,col,alpha);dot(c,x-27,y-22,13,col,alpha)
    } else {
        c.setStrokeColor(color(col,alpha));c.setLineWidth(6)
        for w in [64.0,29.0] {c.strokeEllipse(in:CGRect(x:x-w/2,y:y-32,width:w,height:64))}
        line(c,[CGPoint(x:x-30,y:y),CGPoint(x:x+30,y:y)],col,5,alpha)
    }
}
func pill(_ c: CGContext, _ s: String, _ x: Double, _ y: Double, _ w: Double, _ col: String, _ alpha: Double = 1) {
    box(c,CGRect(x:x,y:y,width:w,height:68),panel,col,18,alpha,3)
    text(c,s,x+w/2,y+47,34,col,true,alpha,"center",w-24)
}
func card(_ c: CGContext, _ heading: String, _ detail: String, _ r: CGRect, _ col: String, _ alpha: Double = 1) {
    box(c,r,panel,col,22,alpha,5)
    text(c,heading,r.midX,r.midY-4,40,col,true,alpha,"center",r.width-36)
    text(c,detail,r.midX,r.midY+49,31,fg,false,alpha,"center",r.width-36)
}
let tableData = [["Item","Q1","Q2"],["North","42","56"],["South","38","61"],["Total","80","117"]]
func table(_ c: CGContext, _ r: CGRect, _ style: String = "full", _ alpha: Double = 1, _ reveal: Double = 1) {
    let rows = content["table"] as? [[String]] ?? tableData
    let nrow = max(1,rows.count), ncol = max(1,rows.first?.count ?? 3)
    let cw = r.width/Double(ncol), ch = r.height/Double(nrow)
    box(c,r,"#F3F4F2",nil,10,alpha)
    for j in 0..<nrow { for i in 0..<ncol {
        let rr=CGRect(x:r.minX+Double(i)*cw+3,y:r.minY+Double(j)*ch+3,width:cw-6,height:ch-6)
        let highlight = style == "location" && j == 1 && i == 1
        if highlight { box(c,rr,accent(2),nil,2,alpha*0.45) }
        if j == 0 {box(c,rr,"#DDE3EB",nil,2,alpha)}
        box(c,rr,nil,style == "structure" ? accent(1) : "#8796A6",2,alpha,style == "structure" ? 4 : 2)
        if style != "structure" && style != "location", j < rows.count, i < rows[j].count {
            let index = j*ncol+i
            if Double(index) < Double(nrow*ncol)*reveal {
                text(c,rows[j][i],rr.midX,rr.midY+12,min(36,ch*0.42),style == "content" ? "#34743F" : "#303844",j==0,alpha,"center",cw-12)
            }
        }
    }}
}
func cursor(_ c: CGContext, _ x: Double, _ y: Double, _ click: Double = 0) {
    if click>0 { c.setStrokeColor(color(fg,0.65*(1-click)));c.setLineWidth(4);c.strokeEllipse(in:CGRect(x:x-12-28*click,y:y-12-28*click,width:24+56*click,height:24+56*click)) }
    let p=CGMutablePath();p.move(to:CGPoint(x:x,y:y));p.addLine(to:CGPoint(x:x+3,y:y+43));p.addLine(to:CGPoint(x:x+15,y:y+31));p.addLine(to:CGPoint(x:x+27,y:y+48));p.addLine(to:CGPoint(x:x+36,y:y+42));p.addLine(to:CGPoint(x:x+24,y:y+24));p.addLine(to:CGPoint(x:x+41,y:y+22));p.closeSubpath()
    c.addPath(p);c.setFillColor(color(fg));c.fillPath();c.addPath(p);c.setStrokeColor(color(bg));c.setLineWidth(3);c.strokePath()
}

func framework(_ c: CGContext, _ t: Double) {
    title(c,"One framework. Three connected contributions.")
    let spin=phase(t,"spin_start","spin_end",0.08,0.32), spread=phase(t,"spread_start","spread_end",0.30,0.55)
    let center=CGPoint(x:960,y:580), radial=300.0
    let targets=[CGPoint(x:360,y:355),CGPoint(x:960,y:355),CGPoint(x:1560,y:355)]
    let names=strings("parts",["Align for safety","Design for reliability","Scale capability"])
    let groups=content["papers"] as? [[String]] ?? [["Measure the risk","Train with feedback"],["Robust architecture","Structured inputs"],["Learn from more data","Use compute wisely"]]
    let angles=[-Double.pi/2,5*Double.pi/6,Double.pi/6]
    let theta = -2*Double.pi*spin, shrink=1-0.42*spin
    let heroAlpha=1-progress(spread,0.08,0.64)
    // One continuous vector membrane and a single rigid transform. No bitmap halo.
    if heroAlpha>0 {
        c.saveGState();c.setAlpha(heroAlpha);c.translateBy(x:center.x,y:center.y);c.rotate(by:theta);c.scaleBy(x:shrink,y:shrink)
        let membrane=CGMutablePath()
        for i in 0...720 {
            let a=Double(i)/720*2*Double.pi
            let d=angles.map{abs(atan2(sin(a-$0),cos(a-$0)))}.min()!
            let r=156+109*exp(-pow(d/0.16,2))
            let pt=CGPoint(x:r*cos(a),y:r*sin(a));if i==0{membrane.move(to:pt)}else{membrane.addLine(to:pt)}
        }
        membrane.closeSubpath()
        c.saveGState();c.setShadow(offset:CGSize(width:0,height:10),blur:22,color:color("#000000",0.28));c.addPath(membrane);c.setFillColor(color("#D8ECE5"));c.fillPath();c.restoreGState()
        c.saveGState();c.addPath(membrane);c.clip()
        let gradient=CGGradient(colorsSpace:cs,colors:[color("#DDF6E9"),color("#D8E9FA"),color("#FFE7C9")] as CFArray,locations:[0,0.52,1])!
        c.drawLinearGradient(gradient,start:CGPoint(x:-120,y:-180),end:CGPoint(x:165,y:200),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation]);c.restoreGState()
        c.addPath(membrane);c.setStrokeColor(color("#FFFFFF",0.32));c.setLineWidth(2);c.strokePath()
        c.setStrokeColor(color("#FFFFFF",0.58));c.setLineWidth(4);c.setLineCap(.round);c.addArc(center:.zero,radius:142,startAngle:3.65,endAngle:4.45,clockwise:false);c.strokePath()
        text(c,value("center","One mission"),0,13,42,"#25333B",true,1,"center",270)
        for i in 0..<3 {badge(c,i,radial*cos(angles[i]),radial*sin(angles[i]),72)}
        c.restoreGState()
    }
    let componentAlpha=progress(spread,0.18,0.65)
    let labels=phase(t,"labels_start","labels_end",0.48,0.60)
    let awards=content["awards"] as? [[String]] ?? [["oral",""],["award",""],["","open"]]
    let awardsProgress=phase(t,"awards_start","awards_end",0.84,0.94)
    for i in 0..<3 {
        let initial=CGPoint(x:center.x+radial*shrink*cos(angles[i]+theta),y:center.y+radial*shrink*sin(angles[i]+theta))
        let move=progress(spread,0.18,1),pos=CGPoint(x:mix(initial.x,targets[i].x,move),y:mix(initial.y,targets[i].y,move))
        badge(c,i,pos.x,pos.y,62,componentAlpha)
        text(c,names[i%names.count],pos.x,pos.y+130,43,accent(i),true,labels,"center",540)
        let papers=groups[i%groups.count]
        let grow=progress(t,event("papers_start",0.60),event("papers_start",0.60)+0.50)
        line(c,[CGPoint(x:pos.x-224,y:pos.y+174),CGPoint(x:pos.x-224,y:pos.y+174+Double(papers.count)*92*grow)],accent(i),5,labels)
        for (j,paper) in papers.enumerated() {
            let a=progress(t,event("papers_start",0.60)+Double(i)*0.12+Double(j)*0.16,event("papers_start",0.60)+Double(i)*0.12+Double(j)*0.16+0.45)
            text(c,paper,pos.x-195,pos.y+225+Double(j)*92,38,fg,false,a,"left",390)
            if i<awards.count,j<awards[i].count {recognitionIcon(c,awards[i][j],pos.x+230,pos.y+212+Double(j)*92,awardsProgress)}
        }
    }
    text(c,value("recognition","Research → open tools → practical impact"),960,985,36,muted,false,awardsProgress,"center",1700)
}
func branch(_ c: CGContext, _ t: Double) {
    title(c,"Specialized modules become one complete result.")
    let cols=[accent(1),accent(2),accent(0)], labels=strings("modules",["Structure","Cell locations","Cell content"])
    let ys=[360.0,560.0,760.0]
    let input=CGRect(x:100,y:430,width:350,height:270)
    table(c,input);text(c,value("input_label","Table image"),275,770,40,fg,true,1,"center",370)
    let p=phase(t,"branches_start","branches_end",0.12,0.32)
    for i in 0..<3 {
        let y=ys[i], appear=progress(t,event("branches_start",0.12)+Double(i)*0.22,event("branches_end",0.32)+Double(i)*0.15)
        arrow(c,CGPoint(x:475,y:500+Double(i)*65),CGPoint(x:675,y:y),cols[i],0,p,appear)
        card(c,labels[i%labels.count],i==0 ? "Rows & columns" : i==1 ? "Locate each cell" : "Read each crop",CGRect(x:700,y:y-73,width:430,height:146),cols[i],appear)
        let result=phase(t,"merge_start","merge_end",0.53,0.75)
        arrow(c,CGPoint(x:1150,y:y),CGPoint(x:1415,y:500+Double(i)*65),cols[i],0,result,appear)
    }
    let merged=phase(t,"result_start","result_end",0.70,0.90)
    table(c,CGRect(x:1450,y:430,width:350,height:270),"content",merged)
    text(c,value("output_label","Structured output"),1625,770,40,accent(0),true,merged,"center",410)
    text(c,value("takeaway","Keep each task simple. Combine the outputs."),960,965,44,fg,true,merged,"center",1700)
}
func vocabulary(_ c: CGContext, _ t: Double) {
    title(c,"First, learn a visual vocabulary.","Step 1 · Reconstruct the image from discrete visual tokens")
    let input=CGRect(x:95,y:410,width:320,height:270), out=CGRect(x:1505,y:410,width:320,height:270)
    table(c,input);text(c,"Unlabeled image",255,752,37,nil,true,1,"center",330)
    let p=phase(t,"encode_start","encode_end",0.13,0.32)
    arrow(c,CGPoint(x:440,y:545),CGPoint(x:545,y:545),purple,0,p)
    card(c,value("encoder","Image tokenizer"),"Learn patch features",CGRect(x:570,y:435,width:310,height:220),purple,p)
    let v=phase(t,"vocabulary_start","vocabulary_end",0.30,0.53)
    arrow(c,CGPoint(x:905,y:545),CGPoint(x:995,y:545),purple,0,v)
    for j in 0..<3 {for i in 0..<3 {let idx=j*3+i;let a=progress(t,event("vocabulary_start",0.30)+Double(idx)*0.06,event("vocabulary_end",0.53));box(c,CGRect(x:1015+Double(i)*61,y:445+Double(j)*68,width:53,height:58),idx%2==0 ? purple : "#8E7CCB",nil,9,a);text(c,String(UnicodeScalar(65+idx)!),1041+Double(i)*61,485+Double(j)*68,28,bg,true,a,"center",50)}}
    text(c,value("token_label","Visual tokens"),1102,752,37,purple,true,v,"center",240)
    let d=phase(t,"decode_start","decode_end",0.52,0.73)
    arrow(c,CGPoint(x:1210,y:545),CGPoint(x:1288,y:545),purple,0,d)
    box(c,CGRect(x:1312,y:435,width:145,height:220),panel,purple,22,d)
    text(c,"Image",1384,525,32,purple,true,d,"center",130);text(c,"decoder",1384,568,32,purple,true,d,"center",130)
    arrow(c,CGPoint(x:1475,y:545),CGPoint(x:1493,y:545),purple,0,d,1,4)
    let r=phase(t,"reconstruct_start","reconstruct_end",0.67,0.88)
    table(c,out,"full",r,r);text(c,value("output_label","Reconstruction"),1665,752,37,nil,true,r,"center",330)
    let l=phase(t,"learn_start","learn_end",0.81,0.95)
    arrow(c,CGPoint(x:1660,y:820),CGPoint(x:255,y:820),purple,140,l,0.8,5)
    text(c,value("takeaway","Train the tokenizer and decoder together."),960,989,40,purple,true,l,"center",1700)
}
func masked(_ c: CGContext, _ t: Double) {
    title(c,"Then, predict the missing visual tokens.","Step 2 · Learn from the structure in unlabeled images")
    let rows=3, cols=4, xx=105.0,yy=360.0,cw=95.0,ch=85.0
    let masks=[1,6,8]
    let p=phase(t,"mask_start","mask_end",0.10,0.27)
    text(c,value("input_label","Masked image"),295,315,39,fg,true,1,"center",400)
    for j in 0..<rows {for i in 0..<cols {
        let idx=j*cols+i,r=CGRect(x:xx+Double(i)*cw+4,y:yy+Double(j)*ch+4,width:cw-8,height:ch-8)
        let isMask=masks.contains(idx)
        box(c,r,isMask && p>0.5 ? purple : "#D7E0E8",nil,6)
        text(c,isMask && p>0.5 ? "?" : "\(idx+1)",r.midX,r.midY+13,37,isMask && p>0.5 ? bg : "#35404C",true,1,"center",r.width-8)
    }}
    let e=phase(t,"encode_start","encode_end",0.25,0.48)
    arrow(c,CGPoint(x:520,y:488),CGPoint(x:680,y:488),purple,0,e)
    card(c,value("encoder","Visual encoder"),"Learn the context",CGRect(x:710,y:385,width:430,height:210),purple,e)
    let predict=phase(t,"predict_start","predict_end",0.47,0.72)
    arrow(c,CGPoint(x:1165,y:488),CGPoint(x:1330,y:488),purple,0,predict)
    text(c,value("output_label","Predicted tokens"),1575,315,39,purple,true,predict,"center",430)
    for j in 0..<rows {for i in 0..<cols {
        let idx=j*cols+i,r=CGRect(x:1380+Double(i)*95+4,y:360+Double(j)*85+4,width:87,height:77),m=masks.contains(idx)
        box(c,r,m ? purple : panel,m ? nil : "#5A6070",6,predict,2)
        text(c,m ? String(UnicodeScalar(65+idx)!) : "·",r.midX,r.midY+13,36,m ? bg : muted,true,predict,"center",80)
    }}
    let targets=phase(t,"targets_start","targets_end",0.70,0.91)
    box(c,CGRect(x:180,y:760,width:1560,height:130),panel,nil,24,targets)
    text(c,value("target_source","The full image supplies the target tokens."),960,817,40,fg,true,targets,"center",1480)
    text(c,value("takeaway","Keep the tokenizer fixed. Train only the missing positions."),960,868,35,purple,false,targets,"center",1480)
}

// A true three-dimensional mesh. Sample heights are illustrative, not experimental data.
final class SurfaceRenderer {
    let scene=SCNScene(), camera=SCNNode(), surface=SCNNode(), pathNode=SCNNode()
    let renderer:SCNRenderer
    let viewport=CGRect(x:525,y:225,width:1325,height:790)
    let verticalScale:Double
    var lastLevel = -100.0
    struct V { var p:SCNVector3; var n:SCNVector3; var h:Double }
    var vertices=[V](), indices=[Int]()
    init() {
        verticalScale=content["height_scale"] as? Double ?? 2.8
        guard let device=MTLCreateSystemDefaultDevice() else { fail("Surface scenes require a Metal-capable Mac") }
        renderer=SCNRenderer(device:device,options:nil)
        scene.background.contents=NSColor.clear
        camera.camera=SCNCamera();camera.camera!.fieldOfView=62;camera.camera!.zNear=0.01;camera.camera!.zFar=100
        camera.camera!.wantsHDR=false;camera.camera!.wantsExposureAdaptation=false
        camera.position=SCNVector3(2.8,4.5,2.8);camera.look(at:SCNVector3(0,1.20,0))
        scene.rootNode.addChildNode(camera);scene.rootNode.addChildNode(surface);scene.rootNode.addChildNode(pathNode)
        let ambient=SCNNode();ambient.light=SCNLight();ambient.light!.type = .ambient;ambient.light!.intensity=640;scene.rootNode.addChildNode(ambient)
        let key=SCNNode();key.light=SCNLight();key.light!.type = .directional;key.light!.intensity=850;key.position=SCNVector3(-3,7,4);key.look(at:SCNVector3(0,0,0));scene.rootNode.addChildNode(key)
        renderer.scene=scene;renderer.pointOfView=camera;renderer.isJitteringEnabled=false;renderer.autoenablesDefaultLighting=false
        let count=64
        for j in 0...count {for i in 0...count {
            let x = -1.2+2.4*Double(i)/Double(count), z = -1.2+2.4*Double(j)/Double(count), e=0.002
            let dx=(heightAt(x+e,z)-heightAt(x-e,z))/(2*e)*verticalScale,dz=(heightAt(x,z+e)-heightAt(x,z-e))/(2*e)*verticalScale
            let nn=simd_normalize(SIMD3<Float>(Float(-dx),1,Float(-dz)))
            vertices.append(V(p:point(x,z),n:SCNVector3(nn.x,nn.y,nn.z),h:heightAt(x,z)))
        }}
        for j in 0..<count {for i in 0..<count {let a=j*(count+1)+i,b=a+1,c=a+count+1,d=c+1;indices += [a,c,b,b,c,d]}}
    }
    func heightAt(_ x:Double,_ z:Double)->Double {
        let theta=atan2(z,x),r=sqrt(pow(x/1.035,2)+pow(z/0.965,2))
        let boundary=(content["basin_radius"] as? Double ?? 0.78)+0.018*cos(3*theta)+0.012*sin(5*theta)
        let h=1/(1+exp(-(r-boundary)/0.035))
        let floor=0.032+0.014*sin(8*x+0.4)*cos(7*z-0.2)+0.009*sin(13*x+4*z+1.1)
        let plateau=0.982+0.005*sin(5.1*x+0.2)*cos(5.9*z-0.4)+0.003*cos(10*x-3.2*z+1.2)
        return floor+(plateau-floor)*h
    }
    func point(_ x:Double,_ z:Double)->SCNVector3 {SCNVector3(x,heightAt(x,z)*verticalScale,z)}
    func tint(_ h:Double)->SIMD4<Float> {
        let stops:[(Double,SIMD4<Float>)]=[(0,SIMD4(0.61,0.40,0.85,1)),(0.3,SIMD4(0.35,0.57,0.92,1)),(0.6,SIMD4(0.25,0.78,0.76,1)),(1,SIMD4(0.97,0.88,0.42,1))]
        for i in 1..<stops.count {if h<=stops[i].0 {let u=Float(clamp((h-stops[i-1].0)/(stops[i].0-stops[i-1].0)));return stops[i-1].1+(stops[i].1-stops[i-1].1)*u}}
        return stops.last!.1
    }
    func interpolate(_ a:V,_ b:V,_ level:Double)->V {
        let u=(level-a.h)/(b.h-a.h)
        let n=simd_normalize(SIMD3<Float>(Float(mix(Double(a.n.x),Double(b.n.x),u)),Float(mix(Double(a.n.y),Double(b.n.y),u)),Float(mix(Double(a.n.z),Double(b.n.z),u))))
        return V(p:SCNVector3(mix(Double(a.p.x),Double(b.p.x),u),level*verticalScale,mix(Double(a.p.z),Double(b.p.z),u)),n:SCNVector3(n.x,n.y,n.z),h:level)
    }
    func mesh(_ level:Double) {
        guard abs(level-lastLevel)>0.00001 else{return};lastLevel=level
        if level<0 {surface.geometry=nil;return}
        var points=[SCNVector3](),normals=[SCNVector3](),colors=[SIMD4<Float>](),back=[Int32](),front=[Int32]()
        for k in stride(from:0,to:indices.count,by:3) {
            let triangle=[vertices[indices[k]],vertices[indices[k+1]],vertices[indices[k+2]]]
            var clipped=[V]()
            for j in 0..<3 {let a=triangle[j],b=triangle[(j+1)%3],ain=a.h<=level,bin=b.h<=level;if ain {clipped.append(a)};if ain != bin {clipped.append(interpolate(a,b,level))}}
            if clipped.count<3 {continue}
            let base=Int32(points.count)
            for v in clipped {points.append(v.p);normals.append(v.n);colors.append(tint(v.h))}
            let mx=clipped.reduce(0.0){$0+Double($1.p.x)}/Double(clipped.count),mz=clipped.reduce(0.0){$0+Double($1.p.z)}/Double(clipped.count)
            for j in 1..<(clipped.count-1) {let ids=[base,base+Int32(j),base+Int32(j+1)];if mx+mz>0 && hypot(mx,mz)>0.55 {front+=ids}else{back+=ids}}
        }
        let colorData=colors.withUnsafeBufferPointer{Data(buffer:$0)}
        let source=SCNGeometrySource(data:colorData,semantic:.color,vectorCount:colors.count,usesFloatComponents:true,componentsPerVector:4,bytesPerComponent:4,dataOffset:0,dataStride:16)
        let geometry=SCNGeometry(sources:[SCNGeometrySource(vertices:points),SCNGeometrySource(normals:normals),source],elements:[SCNGeometryElement(indices:back,primitiveType:.triangles),SCNGeometryElement(indices:front,primitiveType:.triangles)])
        let material=SCNMaterial();material.lightingModel = .lambert;material.diffuse.contents=NSColor.white;material.isDoubleSided=true
        let frontMat=material.copy() as! SCNMaterial;frontMat.transparency=0.35;frontMat.transparencyMode = .singleLayer;frontMat.writesToDepthBuffer=false
        geometry.materials=[material,frontMat];surface.geometry=geometry
    }
    func project(_ p:SCNVector3)->CGPoint {
        let q=renderer.projectPoint(p),scale=1920/Double(width)
        return CGPoint(x:viewport.minX+Double(q.x)*scale,y:viewport.maxY-Double(q.y)*scale)
    }
    func render(_ c:CGContext,_ t:Double,_ trajectories:Bool) {
        let build=phase(t,"build_start","build_end",0.40,0.84)
        mesh(trajectories ? 1.03 : (build>0 ? mix(0.001,1.03,build) : -1))
        let snap=renderer.snapshot(atTime:t,with:CGSize(width:viewport.width*Double(width)/1920,height:viewport.height*Double(height)/1080),antialiasingMode:.multisampling4X)
        let im=snap.cgImage(forProposedRect:nil,context:nil,hints:nil)!
        drawImage(c,im,viewport)
        for (a,b) in [(SCNVector3(-1.42,0,0),SCNVector3(1.52,0,0)),(SCNVector3(0,0,-1.42),SCNVector3(0,0,1.52)),(SCNVector3(0,0,0),SCNVector3(0,3.25,0))] {
            straightArrow(c,project(a),project(b),muted,3,0.62)
        }
        let dx=project(SCNVector3(1.52,0,0)),dz=project(SCNVector3(0,0,1.52)),dy=project(SCNVector3(0,3.25,0))
        text(c,"Direction 1",dx.x,dx.y+44,30,muted,false,1,"center",230);text(c,"Direction 2",dz.x,dz.y+44,30,muted,false,1,"center",230)
        text(c,value("height_label","Risk"),dy.x-22,dy.y-18,34,fg,true,1,"right",200)
        if !trajectories {
            let measured=phase(t,"measure_start","measure_end",0.07,0.18),curve=phase(t,"curve_start","curve_end",0.18,0.39)
            let origin=project(SCNVector3(0,0,0));dot(c,origin.x,origin.y,8,purple)
            let p=project(point(0,-0.7*measured));dot(c,p.x,p.y,8,cyan,1-build)
            if curve>0 {
                let pts=(0...90).map{project(point(0,-1.15*curve*Double($0)/90))};line(c,pts,cyan,6,1-build*0.65)
            }
            if build>0 && build<1 {
                let y=mix(0.001,1.03,build)*verticalScale,a=1.23
                line(c,[project(SCNVector3(-a,y,-a)),project(SCNVector3(a,y,-a)),project(SCNVector3(a,y,a)),project(SCNVector3(-a,y,a)),project(SCNVector3(-a,y,-a))],cyan,3,0.4)
            }
            let stage=build>0.01 ? 2 : curve>0.01 ? 1 : 0
            let stages=strings("steps",["Measure one point","Trace one direction","Reveal the full surface"])
            for i in 0..<min(3,stages.count) {text(c,"0\(i+1)",100,360+Double(i)*140,34,i==stage ? cyan : muted,true);text(c,stages[i],100,413+Double(i)*140,37,i==stage ? fg : muted,i==stage,1,"left",500)}
        } else {
            let u=phase(t,"path_start","path_end",0.12,0.83)
            let paths:[(Double,Double,String,String)]=[(1.06,0.12,accent(2),value("path_a","Unconstrained updates")),(0.43,-0.28,accent(0),value("path_b","Constrained updates"))]
            for (i,v) in paths.enumerated() {
                let pts=(0...90).map{j -> CGPoint in let z=Double(j)/90*u;return project(point(v.0*z,v.1*z))};line(c,pts,v.2,7)
                for checkpoint in 0...4 {let z=Double(checkpoint)/4;if z<=u {let p=project(point(v.0*z,v.1*z));dot(c,p.x,p.y,7,v.2);if checkpoint==4 || (checkpoint==2 && i==0) {text(c,"e\(checkpoint)",p.x+(i==0 ? 18 : -34),p.y+(i==0 ? -17 : 40),29,v.2,true,1,"left",90)}}}
                text(c,v.3,100,430+Double(i)*150,38,v.2,true,1,"left",500)
            }
            text(c,value("takeaway","The path matters."),100,820,42,fg,true,1,"left",500)
        }
    }
}
var surfaceRenderer:SurfaceRenderer? = nil
func surface(_ c:CGContext,_ t:Double,_ trajectories:Bool) {
    title(c,trajectories ? "Track the path, not just the final checkpoint." : "Measure a point. Trace a curve. Reveal the surface.")
    if surfaceRenderer == nil {surfaceRenderer=SurfaceRenderer()}
    surfaceRenderer!.render(c,t,trajectories)
    text(c,value("footnote","Illustrative geometry · Replace with measured data for empirical claims"),96,1040,27,muted,false,1,"left",1750)
}
func budget(_ c:CGContext,_ t:Double) {
    title(c,"Spend inference compute on the right visual evidence.")
    let frames=content["frame_count"] as? Int ?? 4, tokens=content["token_count"] as? Int ?? 24
    let p=phase(t,"frames_start","frames_end",0.08,0.27)
    for i in (0..<min(6,max(1,frames))).reversed() {let x=130+Double(i)*22,y=385-Double(i)*20;box(c,CGRect(x:x,y:y,width:300,height:210),panel,accent(2),15,p,4);dot(c,x+200,y+64,24,accent(2),p);line(c,[CGPoint(x:x+15,y:y+185),CGPoint(x:x+110,y:y+100),CGPoint(x:x+190,y:y+160),CGPoint(x:x+250,y:y+130),CGPoint(x:x+285,y:y+185)],accent(2),8,p)}
    text(c,value("frames_label","Frames"),300,733,45,accent(2),true,p,"center",340)
    text(c,value("frames_detail","Temporal coverage"),300,792,32,muted,false,p,"center",380)
    let e=phase(t,"encoder_start","encoder_end",0.24,0.42)
    arrow(c,CGPoint(x:505,y:505),CGPoint(x:620,y:505),accent(2),0,e)
    card(c,"Vision encoder","Extract visual evidence",CGRect(x:650,y:392,width:350,height:225),accent(2),e)
    let tok=phase(t,"tokens_start","tokens_end",0.40,0.60)
    arrow(c,CGPoint(x:1025,y:505),CGPoint(x:1090,y:505),accent(1),0,tok)
    for i in 0..<min(40,max(1,tokens)) {let col=i%6,row=i/6;box(c,CGRect(x:1120+Double(col)*37,y:410+Double(row)*49,width:29,height:38),accent(1),nil,6,tok)}
    text(c,value("tokens_label","Tokens"),1228,733,45,accent(1),true,tok,"center",300)
    text(c,value("tokens_detail","Visual detail"),1228,792,32,muted,false,tok,"center",310)
    let lm=phase(t,"lm_start","lm_end",0.58,0.77)
    arrow(c,CGPoint(x:1370,y:505),CGPoint(x:1450,y:505),accent(0),0,lm)
    card(c,value("model_label","Language model"),value("model_detail","Reason over evidence"),CGRect(x:1480,y:392,width:350,height:225),accent(0),lm)
    text(c,value("capacity_label","Model capacity"),1655,733,43,accent(0),true,lm,"center",380)
    let total=phase(t,"cost_start","cost_end",0.76,0.91)
    box(c,CGRect(x:300,y:892,width:1320,height:106),panel,nil,22,total)
    text(c,value("cost_label","Total inference cost = visual processing + language reasoning"),960,960,40,fg,true,total,"center",1250)
}
func score(_ c:CGContext,_ t:Double) {
    title(c,"A response can change direction as it unfolds.")
    let sentence=value("response","Here is some useful background . Next , the answer starts offering unsafe operational details . Let us stop there and focus on a safer alternative .")
    let words=sentence.split(separator:" ").map(String.init)
    let values=content["scores"] as? [Double] ?? [0.85,0.87,0.86,0.84,0.87,0.82,0.78,0.71,0.60,0.45,0.31,0.25,0.22,0.21,0.23,0.27,0.36,0.52,0.66,0.76,0.84,0.88,0.9,0.92,0.93,0.93,0.94]
    let u=phase(t,"response_start","response_end",0.13,0.88),position=u*Double(max(1,words.count-1)),visible=min(words.count,Int(position)+1)
    box(c,CGRect(x:96,y:238,width:1728,height:720),"#F3F5F3",nil,28)
    text(c,"RESPONSE SO FAR",144,293,26,"#68747C",true)
    var x=145.0,y=365.0
    for i in 0..<visible {
        let nextIsPunctuation=i+1<words.count && [".",",",";",":"].contains(words[i+1]);let word=words[i]+(nextIsPunctuation ? "":" "),w=textWidth(word,42)
        if x+w>1760{x=145;y+=62}
        let col=i>=8 && i<=15 ? "#8544B4" : i>=18 ? "#347C50" : "#25333B"
        if (i>=8 && i<=15 || i>=18) && ![".",",",";",":"].contains(words[i]) {box(c,CGRect(x:x-1,y:y-39,width:w+2,height:50),col,nil,4,0.10)}
        text(c,word,x,y,42,col,false);x+=w
    }
    let chart=CGRect(x:210,y:635,width:1490,height:235)
    text(c,value("score_label","Safety score"),145,579,34,"#26363E",true)
    text(c,"Safer prefix",1330,579,30,"#347C50",true);text(c,"Riskier prefix",1520,579,30,"#8544B4",true)
    for j in 0...4 {
        let yy=chart.maxY-Double(j)*chart.height/4
        line(c,[CGPoint(x:chart.minX,y:yy),CGPoint(x:chart.maxX,y:yy)],"#C9D1D2",1.5,0.65)
        text(c,String(format:"%.2g",Double(j)/4),180,yy+9,26,"#647078",false,1,"right",80)
    }
    let mapped=(0..<words.count).map{i -> CGPoint in
        let ix=Double(i)*Double(max(0,values.count-1))/Double(max(1,words.count-1)),a=min(values.count-1,Int(ix)),b=min(values.count-1,a+1)
        return CGPoint(x:chart.minX+Double(i)/Double(max(1,words.count-1))*chart.width,y:chart.maxY-clamp(mix(values[a],values[b],ix-Double(a)))*chart.height)
    }
    var shown=Array(mapped.prefix(visible))
    if visible<words.count,let last=shown.last {let next=mapped[visible],f=position-floor(position);shown.append(CGPoint(x:mix(last.x,next.x,f),y:mix(last.y,next.y,f)))}
    for i in 1..<shown.count {
        let fraction=clamp((chart.maxY-shown[i].y)/chart.height),green=NSColor(cgColor:color("#4C9663"))!,violet=NSColor(cgColor:color("#9B5BCE"))!
        let shade=violet.blended(withFraction:fraction,of:green)!
        c.setStrokeColor(shade.cgColor);c.setLineWidth(6);c.setLineCap(.round);c.beginPath();c.move(to:shown[i-1]);c.addLine(to:shown[i]);c.strokePath()
    }
    if let point=shown.last {dot(c,point.x,point.y,9,"#3A6373");line(c,[CGPoint(x:point.x,y:chart.minY),CGPoint(x:point.x,y:chart.maxY)],"#3A6373",2,0.2,[5,7])}
    text(c,"The response unfolds →",chart.midX,925,30,"#647078",false,1,"center",800)
    text(c,value("footnote","Illustrative score sequence · Text and curve share one timeline"),100,1025,28,muted)
}
let ciContext=CIContext(options:[.useSoftwareRenderer:false])
var screenAsset:CGImage? = nil
if let imagePath=content["screen_image"] as? String {
    let url=configURL.deletingLastPathComponent().appendingPathComponent(imagePath)
    if let image=NSImage(contentsOf:url) {screenAsset=image.cgImage(forProposedRect:nil,context:nil,hints:nil)}
}
func screenContent(_ t:Double)->CGImage {
    let c=CGContext(data:nil,width:1280,height:800,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:800);c.scaleBy(x:1280.0/1920,y:-800.0/1200)
    box(c,CGRect(x:0,y:0,width:1920,height:1200),"#23272F",nil,0)
    if let asset=screenAsset {drawImage(c,asset,CGRect(x:0,y:0,width:1920,height:1200));return c.makeImage()!}
    let app=phase(t,"app_start","app_end",0.30,0.47)
    text(c,value("screen_heading","Your ideas. In motion."),960,270,86,fg,true,1-app,"center",1700)
    let names=strings("apps",["Write","Explore","Create"])
    let cursorProgress=phase(t,"cursor_start","cursor_end",0.18,0.32),cx=mix(550,1260,cursorProgress),cy=715.0
    for i in 0..<3 {let x=540+Double(i)*420,dist=abs(cx-Double(x)),scale=1+0.19*exp(-pow(dist/165,2));let s=150*scale
        box(c,CGRect(x:Double(x)-s/2,y:570-s/2,width:s,height:s),accent(i),nil,35,1-app)
        text(c,String(names[i%names.count].prefix(1)),Double(x),592,79,bg,true,1-app,"center",130)
        text(c,names[i%names.count],Double(x),750,46,fg,false,1-app,"center",370)
    }
    if app<1 {c.saveGState();c.setAlpha(1-app);cursor(c,cx,cy);c.restoreGState()}
    box(c,CGRect(x:180,y:120,width:1560,height:940),panel,"#5F6773",34,app,3)
    text(c,value("app_title","AI assistant"),960,235,66,fg,true,app,"center",1300)
    let sentence=value("prompt","Build a clear story from these notes.")
    let typing=phase(t,"typing_start","typing_end",0.48,0.71),count=Int(Double(sentence.count)*typing),typed=String(sentence.prefix(count))
    box(c,CGRect(x:310,y:470,width:1300,height:230),"#454A54",nil,25,app)
    text(c,typed,355,560,64,fg,false,app,"left",1180)
    let tick=phase(t,"send_start","send_end",0.72,0.81)
    dot(c,1530,634,39,accent(1),app)
    arrow(c,CGPoint(x:1530,y:655),CGPoint(x:1530,y:616),bg,0,1,app,5)
    if t>event("typing_end",0.71) {c.saveGState();c.setAlpha(app);cursor(c,mix(1680,1530,tick),mix(850,640,tick),tick>0.6 ? (tick-0.6)/0.4 : 0);c.restoreGState()}
    text(c,value("status","Building your first draft…"),960,880,45,accent(1),false,tick,"center",1350)
    return c.makeImage()!
}
func device(_ c:CGContext,_ t:Double) {
    title(c,"Start with a familiar moment.")
    let open=phase(t,"open_start","open_end",0,0.19),close=phase(t,"close_start","close_end",0.91,1)
    let openness=open*(1-close)
    let hingeY=830.0, topY=mix(820,270,openness),halfTop=mix(530,560,openness),halfBottom=550.0
    let quad=[CGPoint(x:960-halfTop,y:topY),CGPoint(x:960+halfTop,y:topY),CGPoint(x:960+halfBottom,y:hingeY),CGPoint(x:960-halfBottom,y:hingeY)]
    let frame=CGMutablePath();frame.move(to:quad[0]);for p in quad.dropFirst(){frame.addLine(to:p)};frame.closeSubpath()
    c.saveGState();c.setShadow(offset:CGSize(width:0,height:22),blur:45,color:color("#000000",0.4));c.addPath(frame);c.setFillColor(color("#17191D"));c.fillPath();c.restoreGState()
    c.addPath(frame);c.setStrokeColor(color("#9BA0A8"));c.setLineWidth(8);c.strokePath()
    if openness>0.025 {
        let inset=18.0, inner=[CGPoint(x:quad[0].x+inset,y:quad[0].y+inset*openness),CGPoint(x:quad[1].x-inset,y:quad[1].y+inset*openness),CGPoint(x:quad[2].x-inset,y:quad[2].y-inset*openness),CGPoint(x:quad[3].x+inset,y:quad[3].y-inset*openness)]
        let input=CIImage(cgImage:screenContent(t)),filter=CIFilter(name:"CIPerspectiveTransform")!
        filter.setValue(input,forKey:kCIInputImageKey)
        filter.setValue(CIVector(x:inner[0].x,y:1080-inner[0].y),forKey:"inputTopLeft")
        filter.setValue(CIVector(x:inner[1].x,y:1080-inner[1].y),forKey:"inputTopRight")
        filter.setValue(CIVector(x:inner[2].x,y:1080-inner[2].y),forKey:"inputBottomRight")
        filter.setValue(CIVector(x:inner[3].x,y:1080-inner[3].y),forKey:"inputBottomLeft")
        if let image=filter.outputImage,let cg=ciContext.createCGImage(image,from:CGRect(x:0,y:0,width:1920,height:1080)) {drawImage(c,cg,CGRect(x:0,y:0,width:1920,height:1080))}
    }
    let base=CGMutablePath();base.move(to:CGPoint(x:405,y:830));base.addLine(to:CGPoint(x:1515,y:830));base.addLine(to:CGPoint(x:1650,y:925));base.addQuadCurve(to:CGPoint(x:1610,y:943),control:CGPoint(x:1640,y:943));base.addLine(to:CGPoint(x:310,y:943));base.addQuadCurve(to:CGPoint(x:270,y:925),control:CGPoint(x:280,y:943));base.closeSubpath()
    c.addPath(base);c.setFillColor(color("#7A8089"));c.fillPath();line(c,[CGPoint(x:285,y:925),CGPoint(x:1635,y:925)],"#BFC3CA",4)
    for j in 0..<3 {for i in 0..<15 {box(c,CGRect(x:470+Double(i)*65-Double(j)*8,y:843+Double(j)*17,width:49,height:10),"#363B43",nil,3,openness)}}
    box(c,CGRect(x:845,y:898,width:230,height:24),"#9399A2",nil,6)
}

func render(_ t:Double)->CGImage {
    let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:Double(height));c.scaleBy(x:Double(width)/1920,y:-Double(height)/1080)
    c.setFillColor(color(bg));c.fill(CGRect(x:0,y:0,width:1920,height:1080))
    switch kind {
    case "framework-to-portfolio":framework(c,t)
    case "branch-and-merge":branch(c,t)
    case "learn-visual-vocabulary":vocabulary(c,t)
    case "masked-token-training":masked(c,t)
    case "surface-build":surface(c,t,false)
    case "surface-trajectories":surface(c,t,true)
    case "video-budget":budget(c,t)
    case "text-and-score":score(c,t)
    case "device-story":device(c,t)
    default:break
    }
    return c.makeImage()!
}
func savePNG(_ im:CGImage,_ name:String) {
    do {try NSBitmapImageRep(cgImage:im).representation(using:.png,properties:[:])!.write(to:outputURL.appendingPathComponent(name))}catch{fail("PNG: \(error)")}
}
let times=(raw["preview_times"] as? [Double] ?? [0,duration*0.25,duration*0.5,duration*0.75,duration*0.90,duration]).map{max(0,min(duration,$0))}
let posterTime=raw["poster_time"] as? Double ?? duration*0.87
savePNG(render(posterTime),"poster.png");savePNG(render(duration),"end.png")
let tileW=640,tileH=360, sheet=CGContext(data:nil,width:tileW*3,height:(tileH+44)*2,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
sheet.translateBy(x:0,y:Double((tileH+44)*2));sheet.scaleBy(x:1,y:-1);sheet.setFillColor(color(bg));sheet.fill(CGRect(x:0,y:0,width:tileW*3,height:(tileH+44)*2))
for i in 0..<min(6,times.count) {let x=Double(i%3*tileW),y=Double(i/3*(tileH+44));drawImage(sheet,render(times[i]),CGRect(x:x,y:y,width:Double(tileW),height:Double(tileH)));text(sheet,String(format:"%.2f s",times[i]),x+20,y+391,22,muted)}
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
