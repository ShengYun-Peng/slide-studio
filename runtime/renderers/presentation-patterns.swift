// Slide Studio: deterministic, content-driven presentation motion.
// Compile: swiftc runtime/swift/main.swift -o .build/slide-motion
// Run: slide-motion --config scenes/<id>/scene.json --output <directory> --video
import Foundation
import AppKit
import CoreGraphics
import CoreText
import CoreImage
import AVFoundation

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
let supportedKinds = ["context-zoom","before-after","metric-focus","research-timeline","evidence-to-insight"]
guard supportedKinds.contains(kind) else { fail("Unknown scene kind: \(kind)") }
let width = raw["width"] as? Int ?? 1920
let height = raw["height"] as? Int ?? 1080
let fps = raw["fps"] as? Int ?? 60
let duration = raw["duration"] as? Double ?? 9
let theme = raw["theme"] as? [String: Any] ?? [:]
let content = raw["content"] as? [String: Any] ?? [:]
let timing = raw["timing"] as? [String: Any] ?? [:]
for key in ["parts","modules","apps"] {
    if let labels=content[key] as? [String], labels.isEmpty {fail("content.\(key) must not be empty")}
}
for key in ["headers","milestones","years"] {
    if let labels=content[key] as? [String], labels.count != 4 {fail("content.\(key) needs four entries for this layout")}
}
for key in ["document_metrics","document_metric_labels"] {
    if let labels=content[key] as? [String], labels.count != 3 {fail("content.\(key) needs three entries")}
}
if let rows=content["rows"] as? [[String]], rows.count != 4 || rows.contains(where: {$0.count != 4}) {fail("content.rows needs four rows of four columns")}
if let rows=content["table"] as? [[String]], rows.isEmpty || rows.contains(where: {$0.count != 4}) {fail("content.table needs nonempty four-column rows")}
let yMinimum=content["y_min"] as? Double ?? 40
let yMaximum=content["y_max"] as? Double ?? 100
guard yMaximum>yMinimum else {fail("y_max must exceed y_min")}
for key in ["baseline","proposed"] {
    if let values=content[key] as? [Double], values.count<2 || values.contains(where: {$0<yMinimum || $0>yMaximum}) {fail("content.\(key) requires at least two values within y_min...y_max")}
}
if let a=content["baseline"] as? [Double],let b=content["proposed"] as? [Double],a.count != b.count {fail("baseline and proposed must have matching sample positions")}

for (key,value) in timing {
    if let seconds=value as? Double,seconds<0 || seconds>duration {fail("timing.\(key) is outside this scene duration")}
}
if let poster=raw["poster_time"] as? Double,poster<0 || poster>duration {fail("poster_time is outside this scene duration")}


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

// Five common explanatory patterns. All geometry is on a 1920 x 1080 canvas.
// Media, text, and event times can be replaced in the scene JSON.
func drawImage(_ c: CGContext,_ im:CGImage,_ r:CGRect,_ alpha:Double=1) {
    c.saveGState(); c.setAlpha(alpha); c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1)
    c.draw(im,in:CGRect(x:0,y:0,width:r.width,height:r.height));c.restoreGState()
}
func gradient(_ c:CGContext,_ rect:CGRect,_ colors:[String],_ alpha:Double=1,_ horizontal:Bool=false) {
    let list=colors.map{color($0,alpha)} as CFArray
    let grad=CGGradient(colorsSpace:cs,colors:list,locations:nil)!
    c.saveGState();c.clip(to:rect)
    c.drawLinearGradient(grad,start:CGPoint(x:rect.minX,y:rect.minY),end:horizontal ? CGPoint(x:rect.maxX,y:rect.minY) : CGPoint(x:rect.minX,y:rect.maxY),options:[]);c.restoreGState()
}
func backdrop(_ c:CGContext) {
    c.setFillColor(color(bg));c.fill(CGRect(x:0,y:0,width:1920,height:1080))
    let g=CGGradient(colorsSpace:cs,colors:[color("#FFFFFF",0.025),color(bg,0)] as CFArray,locations:[0,1])!
    c.drawRadialGradient(g,startCenter:CGPoint(x:960,y:400),startRadius:0,endCenter:CGPoint(x:960,y:400),endRadius:1100,options:[.drawsAfterEndLocation])
}
func heading(_ c:CGContext,_ fallback:String) {
    text(c,value("eyebrow",""),96,77,28,muted,true,1,"left",1720)
    text(c,value("title",fallback),96,157,64,fg,true,1,"left",1728)
}
func shadowPanel(_ c:CGContext,_ r:CGRect,_ alpha:Double=1,_ radius:Double=24) {
    c.saveGState();c.setShadow(offset:CGSize(width:0,height:18),blur:30,color:color("#000000",0.22*alpha));box(c,r,panel,nil,radius,alpha);c.restoreGState()
    box(c,r,nil,"#FFFFFF",radius,alpha*0.08,2)
}
func roundClip(_ c:CGContext,_ r:CGRect,_ radius:Double=24) {c.addPath(CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil));c.clip()}
func rectMix(_ a:CGRect,_ b:CGRect,_ u:Double)->CGRect {CGRect(x:mix(a.minX,b.minX,u),y:mix(a.minY,b.minY,u),width:mix(a.width,b.width,u),height:mix(a.height,b.height,u))}
func underline(_ c:CGContext,_ r:CGRect,_ col:String,_ p:Double) {
    line(c,[CGPoint(x:r.minX,y:r.maxY),CGPoint(x:r.minX+r.width*p,y:r.maxY)],col,5)
}
func raster(_ w:Int,_ h:Int,_ draw:(CGContext)->Void)->CGImage {
    let c=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:Double(h));c.scaleBy(x:1,y:-1);draw(c);return c.makeImage()!
}
func loaded(_ key:String)->CGImage? {
    guard let p=content[key] as? String else{return nil}
    let url=p.hasPrefix("/") ? URL(fileURLWithPath:p) : configURL.deletingLastPathComponent().appendingPathComponent(p)
    guard let im=NSImage(contentsOf:url) else {fail("Cannot read content.\(key): \(url.path)")}
    var r=CGRect(origin:.zero,size:im.size);return im.cgImage(forProposedRect:&r,context:nil,hints:nil)
}
func footer(_ c:CGContext,_ p:Double=1) {
    text(c,value("footnote","Illustrative example · Replace with your evidence"),96,1031,27,muted,false,p,"left",1728)
}

// The report is a procedural vector illustration rendered once at double size.
// Focus geometry is declared in its own coordinate system, so corners always agree.
let reportW=900.0,reportH=1120.0
let reportFocus=CGRect(x:70,y:390,width:760,height:280)
func paintReport(_ c:CGContext) {
    c.setFillColor(color("#F6F7F5"));c.fill(CGRect(x:0,y:0,width:reportW,height:reportH))
    text(c,value("document_title","Operations overview"),70,104,46,"#1E2933",true)
    text(c,value("document_subtitle","A complete report, with the relevant detail intact"),70,155,23,"#677280",false,1,"left",760)
    let vals=strings("document_metrics",["1,248","94%","2.4 h"]),labs=strings("document_metric_labels",["Requests","Resolved","Median time"])
    for i in 0..<3 {let x=70.0+Double(i)*262;box(c,CGRect(x:x,y:204,width:236,height:108),"#E8EDF1",nil,12);text(c,vals[i%vals.count],x+22,257,38,"#2E4358",true);text(c,labs[i%labs.count],x+22,290,21,"#697785")}
    text(c,value("table_title","Service requests by region"),70,363,30,"#273A4B",true)
    let rows=content["table"] as? [[String]] ?? [["Region","Requests","Resolved","Median time"],["North","248","97%","2.1 h"],["South","316","93%","2.8 h"],["East","402","96%","2.3 h"],["West","282","91%","2.6 h"]]
    let tableR=CGRect(x:70,y:390,width:760,height:470),cw=190.0,ch=94.0
    box(c,tableR,"#FFFFFF","#D4DCE3",10,1,2)
    c.saveGState();roundClip(c,tableR,10)
    c.setFillColor(color("#DCE6EF"));c.fill(CGRect(x:70,y:390,width:760,height:94))
    for i in 0..<rows.count {
        if i>0 && i%2==0 {c.setFillColor(color("#F2F5F7"));c.fill(CGRect(x:70,y:390+Double(i)*ch,width:760,height:ch))}
        for j in 0..<min(4,rows[i].count) {text(c,rows[i][j],70+Double(j)*cw+22,390+Double(i)*ch+57,i==0 ? 24 : 29,i==0 ? "#34495D" : "#263847",i==0)}
        if i>0 {line(c,[CGPoint(x:70,y:390+Double(i)*ch),CGPoint(x:830,y:390+Double(i)*ch)],"#D8E0E7",1.5)}
    }
    c.restoreGState()
    text(c,"Quarterly context",70,930,27,"#34495D",true)
    for i in 0..<3 {box(c,CGRect(x:70,y:966+Double(i)*29,width:[718.0,760,635][i],height:10),"#D9E0E5",nil,5)}
    text(c,"Illustrative source document",70,1090,19,"#7A8792")
}
let reportImage:CGImage = loaded("source_image") ?? raster(1800,2240){c in c.scaleBy(x:2,y:2);paintReport(c)}
func focusConfig()->CGRect {
    guard let a=content["focus_rect"] as? [Double],a.count==4 else{return reportFocus}
    return CGRect(x:a[0],y:a[1],width:a[2],height:a[3])
}
func documentCrop(_ image:CGImage,_ source:CGRect,_ r:CGRect,_ c:CGContext,_ alpha:Double) {
    c.saveGState();c.setAlpha(alpha);roundClip(c,r,16)
    let sx=r.width/source.width,sy=r.height/source.height
    let full=CGRect(x:r.minX-source.minX*sx,y:r.minY-source.minY*sy,width:reportW*sx,height:reportH*sy)
    drawImage(c,image,full);c.restoreGState()
}
func contextZoom(_ c:CGContext,_ t:Double) {
    heading(c,"Show the detail without losing its context.")
    let source=CGRect(x:175,y:252,width:500,height:622.222)
    let focus=focusConfig(),scale=source.width/reportW
    let selected=CGRect(x:source.minX+focus.minX*scale,y:source.minY+focus.minY*scale,width:focus.width*scale,height:focus.height*scale)
    let target=CGRect(x:920,y:396,width:840,height:309.474)
    let focusP=phase(t,"focus_start","focus_end",0.12,0.25)
    let zoom=phase(t,"zoom_start","zoom_end",0.29,0.56)
    let caption=phase(t,"caption_start","caption_end",0.63,0.76)
    c.saveGState();c.setShadow(offset:CGSize(width:0,height:18),blur:35,color:color("#000000",0.32));box(c,source,"#F6F7F5",nil,14);c.restoreGState()
    c.saveGState();roundClip(c,source,14);drawImage(c,reportImage,source);c.restoreGState()
    text(c,value("source_label","Full document"),source.midX,936,36,muted,false,1,"center",620)
    // Dim everything except the region of interest; never crop away the source.
    c.saveGState();roundClip(c,source,14)
    c.setFillColor(color(bg,0.30*focusP));let outer=CGMutablePath();outer.addRect(source);outer.addRect(selected);c.addPath(outer);c.fillPath(using:.evenOdd);c.restoreGState()
    box(c,selected,nil,accent(1),4,focusP,4)
    if zoom>0 {
        let expanded=rectMix(selected,target,zoom)
        for pair in [(CGPoint(x:selected.maxX,y:selected.minY),CGPoint(x:expanded.minX,y:expanded.minY)),(CGPoint(x:selected.maxX,y:selected.maxY),CGPoint(x:expanded.minX,y:expanded.maxY))] {
            line(c,[pair.0,pair.1],accent(1),2.5,0.48*zoom)
        }
        c.saveGState();c.setShadow(offset:CGSize(width:0,height:18),blur:36,color:color("#000000",0.3*zoom));box(c,expanded,"#F6F7F5",nil,16);c.restoreGState()
        documentCrop(reportImage,focus,expanded,c,1)
        box(c,expanded,nil,accent(1),16,0.95,3)
    }
    text(c,value("detail_label","Linked detail"),target.minX,350,36,accent(1),true,zoom,"left",800)
    text(c,value("takeaway_line1","Keep the row, column,"),target.minX,813,48,fg,true,caption,"left",850)
    text(c,value("takeaway_line2","and source connected."),target.minX,872,48,fg,true,caption,"left",850)
    footer(c)
}

// Two drawings share exactly the same coordinates. A clip reveals the output.
func comparisonPaper(_ r:CGRect)->CGRect {CGRect(x:r.minX+80,y:r.minY+63,width:r.width-160,height:r.height-126)}
func paintComparison(_ c:CGContext,_ r:CGRect,_ structured:Bool) {
    let paper=comparisonPaper(r)
    box(c,paper,structured ? "#F3F7F6" : "#EDEFEF",nil,8)
    let cols=[0.0,0.30,0.52,0.76,1.0],rows=6
    let cw=paper.width,ch=paper.height/Double(rows)
    let data=content["table"] as? [[String]] ?? [["Region","Q1","Q2","Change"],["North","142","168","+18%"],["South","128","151","+18%"],["East","186","204","+10%"],["West","167","182","+9%"],["Total","623","705","+13%"]]
    for row in 0..<rows {
        if row==0 {box(c,CGRect(x:paper.minX,y:paper.minY,width:paper.width,height:ch),structured ? "#DCEBE6" : "#D6DDE0",nil,0)}
        for col in 0..<4 {
            let cell=CGRect(x:paper.minX+cols[col]*cw,y:paper.minY+Double(row)*ch,width:(cols[col+1]-cols[col])*cw,height:ch)
            if structured {box(c,cell.insetBy(dx:4,dy:4),nil,accent(col==0 ? 1 : 0),3,0.75,2.5)}
            let offset=structured ? 0.0 : [0.0,-3.0,1.0,2.0,0.0,2.0][row]
            text(c,data[row%data.count][col],cell.minX+22,cell.midY+12+offset,row==0 ? 31 : 36,structured && row>0 ? "#356D45" : "#39464E",row==0,structured ? 1 : 0.78,"left",cell.width-40)
        }
        if !structured && row>0 {line(c,[CGPoint(x:paper.minX,y:paper.minY+Double(row)*ch),CGPoint(x:paper.maxX,y:paper.minY+Double(row)*ch)],"#A8B4BB",2,0.72)}
    }
}
let beforeImage=loaded("before_image"),afterImage=loaded("after_image")
func beforeAfter(_ c:CGContext,_ t:Double) {
    heading(c,"Keep the view fixed. Reveal what changed.")
    let r=CGRect(x:150,y:286,width:1620,height:600)
    shadowPanel(c,r,1,28)
    let enter=phase(t,"reveal_start","reveal_end",0.15,0.56),settle=phase(t,"settle_start","settle_end",0.66,0.80)
    let paper=comparisonPaper(r)
    let defaultSplit=(beforeImage == nil && afterImage == nil) ? paper.minX+paper.width*0.52 : r.midX
    let restingSplit=(content["split_fraction"] as? Double).map{r.minX+r.width*clamp($0)} ?? defaultSplit
    let boundary=mix(mix(r.maxX-22,r.minX+22,enter),restingSplit,settle)
    c.saveGState();roundClip(c,r,28)
    if let before=beforeImage {drawImage(c,before,r)}else{paintComparison(c,r,false)}
    c.saveGState();c.clip(to:CGRect(x:boundary,y:r.minY,width:r.maxX-boundary,height:r.height))
    if let after=afterImage {drawImage(c,after,r)}else{paintComparison(c,r,true)}
    c.restoreGState();c.restoreGState()
    // The handle, its shaft and clipping boundary use one state variable.
    c.saveGState();c.setShadow(offset:.zero,blur:12,color:color("#000000",0.35));line(c,[CGPoint(x:boundary,y:r.minY+1),CGPoint(x:boundary,y:r.maxY-1)],fg,5);dot(c,boundary,r.midY,27,fg);c.restoreGState()
    line(c,[CGPoint(x:boundary-7,y:r.midY-8),CGPoint(x:boundary-15,y:r.midY),CGPoint(x:boundary-7,y:r.midY+8)],bg,3)
    line(c,[CGPoint(x:boundary+7,y:r.midY-8),CGPoint(x:boundary+15,y:r.midY),CGPoint(x:boundary+7,y:r.midY+8)],bg,3)
    text(c,value("before_label","Image input"),r.minX+12,246,39,muted,true,1,"left",650)
    text(c,value("after_label","Structured output"),r.maxX-12,246,39,accent(0),true,1,"right",650)
    text(c,value("takeaway","One shared camera makes the difference easier to see."),960,964,43,fg,true,phase(t,"caption_start","caption_end",0.78,0.90),"center",1700)
    footer(c)
}

func metricFocus(_ c:CGContext,_ t:Double) {
    heading(c,"More safety, with capability intact.")
    let labels=strings("headers",["Method","Safety ↑","Capability ↑","Cost ↓"])
    let rows=content["rows"] as? [[String]] ?? [["Baseline A","62.5","91.0","1.0×"],["Baseline B","80.2","90.7","1.0×"],["Baseline C","83.4","85.2","1.2×"],["Proposed","94.6","90.9","0.68×"]]
    let baseline=content["baseline_row"] as? Int ?? 1,ours=content["focus_row"] as? Int ?? 3
    let focus=phase(t,"focus_start","focus_end",0.30,0.46),read=phase(t,"insight_start","insight_end",0.58,0.76)
    let x=118.0,y=300.0,w=1160.0,rowH=116.0
    let xs=[x+34,x+540,x+812,x+1045]
    shadowPanel(c,CGRect(x:x,y:y-76,width:w,height:615),1,24)
    for i in 0..<min(4,labels.count) {text(c,labels[i],xs[i],y-20,33,muted,true,1,i==0 ? "left":"center",i==0 ? 420:240)}
    line(c,[CGPoint(x:x+26,y:y+12),CGPoint(x:x+w-26,y:y+12)],"#FFFFFF",2,0.12)
    for i in 0..<min(4,rows.count) {
        let yy=y+34+Double(i)*rowH
        let selected=i==baseline || i==ours
        let alpha=selected ? 1.0 : mix(1,0.30,focus)
        if i==ours {box(c,CGRect(x:x+16,y:yy-4,width:w-32,height:101),accent(0),nil,16,0.11*focus);box(c,CGRect(x:x+16,y:yy-4,width:5,height:101),accent(0),nil,2,focus)}
        for j in 0..<min(4,rows[i].count) {
            text(c,rows[i][j],xs[j],yy+61,j==0 ? 42:44,(i == ours && j != 2) ? accent(0) : fg,selected,alpha,j==0 ? "left":"center",j==0 ? 430:235)
        }
        if i<3 {line(c,[CGPoint(x:x+30,y:yy+109),CGPoint(x:x+w-30,y:yy+109)],"#FFFFFF",1.5,0.07)}
    }
    let rx=1364.0
    text(c,value("metric","+14.4"),rx,470,108,accent(0),true,read,"left",450)
    text(c,value("metric_label","safety points"),rx+3,531,39,fg,true,read,"left",445)
    line(c,[CGPoint(x:rx,y:574),CGPoint(x:rx+365*read,y:574)],accent(0),4,read)
    text(c,value("comparison_line1","Comparable"),rx+3,655,43,fg,false,read,"left",440)
    text(c,value("comparison_line2","capability"),rx+3,711,43,fg,false,read,"left",440)
    text(c,value("takeaway","Keep the baseline visible. Highlight the result that matters."),960,952,43,fg,true,phase(t,"takeaway_start","takeaway_end",0.77,0.9),"center",1730)
    footer(c)
}

func milestoneArtifact(_ c:CGContext,_ index:Int,_ x:Double,_ y:Double,_ col:String,_ opacity:Double) {
    c.saveGState();c.setAlpha(opacity)
    let r=CGRect(x:x-92,y:y,width:184,height:122)
    if index==0 {
        // A source document with one observation selected.
        box(c,CGRect(x:r.minX+28,y:r.minY,width:128,height:122),"#3A3E44","#6D7784",10,1,2)
        for i in 0..<3 {box(c,CGRect(x:r.minX+44,y:r.minY+20+Double(i)*16,width:[84.0,70.0,79.0][i],height:4),"#AAB4C0",nil,2,0.65)}
        box(c,CGRect(x:r.minX+40,y:r.minY+73,width:104,height:30),col,nil,5,0.12)
        box(c,CGRect(x:r.minX+40,y:r.minY+73,width:104,height:30),nil,col,5,1,2.5)
        for i in 0..<3 {line(c,[CGPoint(x:r.minX+49+Double(i)*31,y:r.minY+82),CGPoint(x:r.minX+49+Double(i)*31,y:r.minY+94)],col,3)}
    } else if index==1 {
        // A causal structure with one connected path emphasized.
        let pts=[CGPoint(x:x-66,y:y+60),CGPoint(x:x,y:y+24),CGPoint(x:x,y:y+98),CGPoint(x:x+66,y:y+60)]
        for pair in [(0,1),(0,2),(1,3),(2,3)] {line(c,[pts[pair.0],pts[pair.1]],pair.0==0 && pair.1==2 || pair.0==2 ? col:muted,3,0.7)}
        for (i,p) in pts.enumerated() {dot(c,p.x,p.y,16,bg);c.setStrokeColor(color(i==1 ? muted:col));c.setLineWidth(3);c.strokeEllipse(in:CGRect(x:p.x-16,y:p.y-16,width:32,height:32));dot(c,p.x,p.y,5,i==1 ? muted:col)}
    } else if index==2 {
        // A method becomes an inspectable small application.
        box(c,r,"#353A40","#64707E",12,1,2)
        line(c,[CGPoint(x:r.minX+1,y:r.minY+27),CGPoint(x:r.maxX-1,y:r.minY+27)],muted,1.5,0.35)
        for i in 0..<3 {dot(c,r.minX+15+Double(i)*12,r.minY+14,3.1,muted,0.7)}
        box(c,CGRect(x:r.minX+15,y:r.minY+44,width:65,height:59),nil,col,7,0.7,2)
        for i in 0..<3 {box(c,CGRect(x:r.minX+94,y:r.minY+45+Double(i)*22,width:[69.0,51,61][i],height:7),i==2 ? col:muted,nil,3,0.85)}
        line(c,[CGPoint(x:r.minX+28,y:r.minY+83),CGPoint(x:r.minX+40,y:r.minY+92),CGPoint(x:r.minX+67,y:r.minY+62)],col,4)
    } else {
        // Evaluation compares curves, ending in a visible validation mark.
        line(c,[CGPoint(x:r.minX+9,y:r.minY+14),CGPoint(x:r.minX+9,y:r.maxY-9),CGPoint(x:r.maxX-5,y:r.maxY-9)],muted,2.5,0.6)
        line(c,[CGPoint(x:r.minX+10,y:r.maxY-26),CGPoint(x:r.minX+55,y:r.maxY-42),CGPoint(x:r.minX+106,y:r.maxY-50),CGPoint(x:r.maxX-9,y:r.maxY-58)],muted,3,0.6)
        line(c,[CGPoint(x:r.minX+10,y:r.maxY-33),CGPoint(x:r.minX+55,y:r.maxY-66),CGPoint(x:r.minX+106,y:r.maxY-82),CGPoint(x:r.maxX-9,y:r.maxY-94)],col,4)
        dot(c,r.maxX-9,r.maxY-94,5,col)
    }
    c.restoreGState()
}
func inverseSmooth(_ value:Double)->Double {
    var lo=0.0,hi=1.0
    for _ in 0..<28 {let mid=(lo+hi)/2;if smooth(mid)<value {lo=mid}else{hi=mid}}
    return (lo+hi)/2
}
func researchTimeline(_ c:CGContext,_ t:Double) {
    heading(c,"One question becomes a research program.")
    let labels=strings("milestones",["Observe","Explain","Build","Validate"])
    let details=content["details"] as? [[String]] ?? [["Find a failure","worth studying"],["Identify the","underlying cause"],["Turn the insight","into a method"],["Test the value","in practice"]]
    let years=strings("years",["Stage 1","Stage 2","Stage 3","Stage 4"])
    let xs=[225.0,715.0,1205.0,1695.0],y=575.0
    line(c,[CGPoint(x:xs[0],y:y),CGPoint(x:xs.last!,y:y)],muted,5,0.18)
    let overall=phase(t,"journey_start","journey_end",0.12,0.69)
    let end=mix(xs[0],xs.last!,overall)
    let path=CGRect(x:xs[0],y:y-3,width:max(0,end-xs[0]),height:6)
    gradient(c,path,[accent(1),accent(0)],1,true)
    for i in 0..<4 {
        let start=event("journey_start",0.12),finish=event("journey_end",0.69)
        let arrival=start+(finish-start)*inverseSmooth(Double(i)/3)
        let reveal=progress(t,arrival,arrival+duration*0.07)
        let col=i==3 ? accent(0):accent(1)
        let node=CGRect(x:xs[i]-23,y:y-23,width:46,height:46)
        dot(c,xs[i],y,24,bg)
        c.setStrokeColor(color(col,mix(0.25,1,reveal)));c.setLineWidth(5);c.strokeEllipse(in:node)
        dot(c,xs[i],y,10,col,reveal)
        // A single restrained pulse, no spring or repeated bounce.
        let pulse=sin(Double.pi*reveal)
        c.setStrokeColor(color(col,0.17*pulse));c.setLineWidth(2);c.strokeEllipse(in:CGRect(x:xs[i]-26-12*pulse,y:y-26-12*pulse,width:52+24*pulse,height:52+24*pulse))
        milestoneArtifact(c,i,xs[i],235,col,reveal)
        text(c,labels[i%labels.count],xs[i],445,57,col,true,reveal,"center",420)
        if i<details.count {for j in 0..<min(2,details[i].count) {text(c,details[i][j],xs[i],688+Double(j)*54,41,fg,false,reveal,"center",430)}}
        text(c,years[i%years.count],xs[i],813,30,muted,false,reveal,"center",420)
    }
    text(c,value("takeaway","Each contribution gives the next one a stronger starting point."),960,951,43,fg,true,phase(t,"takeaway_start","takeaway_end",0.77,0.90),"center",1730)
    footer(c)
}

func seriesPoints(_ vals:[Double],_ rect:CGRect)->[CGPoint] {
    vals.enumerated().map{i,v in CGPoint(x:rect.minX+Double(i)/Double(max(1,vals.count-1))*rect.width,y:rect.maxY-(v-yMinimum)/(yMaximum-yMinimum)*rect.height)}
}
func trace(_ c:CGContext,_ points:[CGPoint],_ p:Double,_ col:String,_ width:Double=7) {
    guard p > 0.0001 else {return}
    let n=Double(points.count-1)*clamp(p),index=Int(n)
    guard points.count>1 else{return}
    var out=Array(points.prefix(index+1))
    if index+1<points.count {let a=points[index],b=points[index+1],f=n-Double(index);out.append(CGPoint(x:mix(a.x,b.x,f),y:mix(a.y,b.y,f)))}
    line(c,out,col,width)
    if let last=out.last {dot(c,last.x,last.y,8,col)}
}
func evidenceInsight(_ c:CGContext,_ t:Double) {
    heading(c,"The biggest gains appear when data is scarce.")
    let r=CGRect(x:180,y:304,width:1050,height:528)
    let axes=phase(t,"axes_start","axes_end",0.03,0.13),draw=phase(t,"curves_start","curves_end",0.18,0.53),focus=phase(t,"focus_start","focus_end",0.59,0.75)
    let baseline=content["baseline"] as? [Double] ?? [50,57,63,68,73,77,80,82,84]
    let proposed=content["proposed"] as? [Double] ?? [62,72,78,82,85,87,89,90,91]
    c.saveGState();c.setAlpha(axes)
    let ticks=content["y_ticks"] as? [Double] ?? [40,60,80,100]
    for value in ticks {let y=r.maxY-(value-yMinimum)/(yMaximum-yMinimum)*r.height;line(c,[CGPoint(x:r.minX,y:y),CGPoint(x:r.maxX,y:y)],muted,1.5,0.17);text(c,String(format:"%g",value),r.minX-28,y+12,32,muted,false,1,"right",90)}
    line(c,[CGPoint(x:r.minX,y:r.minY),CGPoint(x:r.minX,y:r.maxY),CGPoint(x:r.maxX,y:r.maxY)],muted,3,0.6)
    let xt=strings("x_ticks",["1k","4k","16k","64k"])
    for i in 0..<4 {let x=r.minX+Double(i)/3*r.width;text(c,xt[i%xt.count],x,r.maxY+52,32,muted,false,1,"center",160)}
    text(c,value("y_label","Accuracy (%)"),r.minX,r.minY-45,34,muted,true)
    text(c,value("x_label","Training examples (log scale)"),r.midX,r.maxY+116,34,muted,false,1,"center",980)
    c.restoreGState()
    // The focus band sits behind the curves; labels stay in a clear callout column.
    gradient(c,CGRect(x:r.minX,y:r.minY,width:r.width*0.39,height:r.height),[accent(0),bg],0.09*focus,true)
    let a=seriesPoints(baseline,r),b=seriesPoints(proposed,r)
    trace(c,a,draw,accent(1));trace(c,b,draw,accent(0))
    if draw>0.98 {
        for i in [0,2,4,6,8] where i<a.count && i<b.count {dot(c,a[i].x,a[i].y,6,accent(1));dot(c,b[i].x,b[i].y,6,accent(0))}
    }
    line(c,[CGPoint(x:765,y:236),CGPoint(x:815,y:236)],accent(1),6,axes);text(c,value("baseline_label","Baseline"),835,248,32,fg,false,axes,"left",300)
    line(c,[CGPoint(x:1100,y:236),CGPoint(x:1150,y:236)],accent(0),6,axes);text(c,value("proposed_label","Proposed"),1170,248,32,fg,false,axes,"left",300)
    let ix=max(0,min(content["delta_index"] as? Int ?? 2,min(a.count,b.count)-1))
    let x=a[ix].x+16
    line(c,[CGPoint(x:x,y:b[ix].y),CGPoint(x:x,y:a[ix].y)],fg,3,focus)
    line(c,[CGPoint(x:b[ix].x,y:b[ix].y),CGPoint(x:x+7,y:b[ix].y)],fg,3,focus)
    line(c,[CGPoint(x:a[ix].x,y:a[ix].y),CGPoint(x:x+7,y:a[ix].y)],fg,3,focus)
    text(c,value("delta_label",String(format:"%+.0f",proposed[ix]-baseline[ix])),x+22,(a[ix].y+b[ix].y)/2+14,41,fg,true,focus,"left",180)
    text(c,value("insight_heading","Early gains"),1340,444,52,accent(0),true,focus,"left",480)
    text(c,value("insight_line1","More signal"),1340,542,50,fg,true,focus,"left",480)
    text(c,value("insight_line2","from less data."),1340,604,50,fg,true,focus,"left",480)
    line(c,[CGPoint(x:1340,y:654),CGPoint(x:1340+400*focus,y:654)],accent(0),4,focus)
    text(c,value("insight_detail","Highlight the regime,"),1340,725,34,muted,false,focus,"left",480)
    text(c,value("insight_detail2","not every data point."),1340,771,34,muted,false,focus,"left",480)
    footer(c)
}

func render(_ t:Double)->CGImage {
    let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:Double(height));c.scaleBy(x:Double(width)/1920,y:-Double(height)/1080)
    backdrop(c)
    switch kind {
    case "context-zoom":contextZoom(c,t)
    case "before-after":beforeAfter(c,t)
    case "metric-focus":metricFocus(c,t)
    case "research-timeline":researchTimeline(c,t)
    case "evidence-to-insight":evidenceInsight(c,t)
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
let manifest:[String:Any]=["schema_version":1,"kind":kind,"renderer":"Slide Studio presentation patterns","config_filename":configURL.lastPathComponent,"width":width,"height":height,"duration":duration,"fps":fps,"preview_times":times,"poster_time":posterTime,"scientific_status":"illustrative","outputs":["poster.png","end.png","contact-sheet.png"],"video":videoMetadata,"notes":"Presentation playback should start automatically within a slide; slide advance remains a separate setting."]
do{let json=try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]);try json.write(to:outputURL.appendingPathComponent("render-manifest.json"))}catch{fail("Manifest: \(error)")}
print("Rendered \(kind) → \(outputURL.path)")
