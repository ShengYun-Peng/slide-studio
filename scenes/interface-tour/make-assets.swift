// Original synthetic interface. No captured product UI or measured results.
// Run: swift scenes/interface-tour/make-assets.swift scenes/interface-tour
import Foundation
import AppKit
import CoreGraphics
import CoreText
let out=URL(fileURLWithPath:CommandLine.arguments.count>1 ? CommandLine.arguments[1]:".")
let cs=CGColorSpace(name:CGColorSpace.sRGB)!
func color(_ h:String)->CGColor{let n=UInt64(h.dropFirst(),radix:16)!;return CGColor(colorSpace:cs,components:[Double(n>>16&255)/255,Double(n>>8&255)/255,Double(n&255)/255,1])!}
func draw(_ c:CGContext,_ selected:Bool){
 func box(_ x:Double,_ y:Double,_ w:Double,_ h:Double,_ fill:String,_ radius:Double=0){c.setFillColor(color(fill));c.addPath(CGPath(roundedRect:CGRect(x:x,y:y,width:w,height:h),cornerWidth:radius,cornerHeight:radius,transform:nil));c.fillPath()}
 func label(_ s:String,_ x:Double,_ y:Double,_ size:Double,_ hex:String="#24282F",_ bold:Bool=false){let f=NSFont(name:bold ? "HelveticaNeue-Bold":"HelveticaNeue",size:size)!;let line=CTLineCreateWithAttributedString(NSAttributedString(string:s,attributes:[.font:f,.foregroundColor:NSColor(cgColor:color(hex))!]));c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:1,y:-1);c.textPosition = .zero;CTLineDraw(line,c);c.restoreGState()}
 box(0,0,1200,500,"#F5F7FA");box(0,0,1200,58,"#FFFFFF");label("Signal Explorer",24,39,27,"#24282F",true);label("Illustrative interface",980,36,17,"#626B78")
 box(0,60,170,440,"#E9EDF3");label("Runs",22,103,22,"#24282F",true)
 for i in 0..<4{box(12,126+Double(i)*60,146,44,i==1 ? "#D6E5FC":"#E9EDF3",8);label("Experiment \(i+1)",23,154+Double(i)*60,17)}
 box(190,80,450,380,"#FFFFFF",16);label("Validation accuracy",216,120,23,"#24282F",true)
 c.setStrokeColor(color("#CDD4DF"));c.setLineWidth(1.5);for yy in [190.0,250,310,370]{c.move(to:CGPoint(x:222,y:yy));c.addLine(to:CGPoint(x:612,y:yy));c.strokePath()}
 let values=[0.42,0.53,0.62,0.68,0.76,0.82]
 for(i,v)in values.enumerated(){let x=235+Double(i)*62,h=v*260;box(x,399-h,36,h,selected && i==5 ? "#FFB253":"#66A7FF",4);label("\((i+1)*20)",x-2,427,17,"#626B78")}
 label("Training step",351,451,17,"#626B78")
 box(668,80,512,380,"#FFFFFF",16);label(selected ? "Selected checkpoint":"Choose a checkpoint",696,122,25,"#24282F",true)
 label(selected ? "Step 120":"Click a bar to inspect it",696,167,24,"#626B78")
 label(selected ? "0.82":"—",696,258,68,selected ? "#1874CB":"#BAC1CC",true)
 label("Validation accuracy",696,302,23,"#24282F")
 box(694,331,458,2,"#E7EBF0");label("One step. One result.",696,382,23,"#626B78")
 label("Synthetic values for this reusable demo",696,426,17,"#626B78")
}
func capture(_ file:String,_ rect:CGRect,_ dpr:Double,_ selected:Bool){let w=Int(rect.width*dpr),h=Int(rect.height*dpr);let c=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:0,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!;c.translateBy(x:0,y:Double(h));c.scaleBy(x:dpr,y:-dpr);c.translateBy(x:-rect.minX,y:-rect.minY);draw(c,selected);let png=NSBitmapImageRep(cgImage:c.makeImage()!).representation(using:.png,properties:[:])!;try! png.write(to:out.appendingPathComponent(file));print("\(file): \(w)×\(h)")}
try! FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
capture("overview.png",CGRect(x:0,y:0,width:1200,height:500),6,false)
capture("selected.png",CGRect(x:0,y:0,width:1200,height:500),6,true)
capture("selected-detail.png",CGRect(x:650,y:60,width:540,height:270),12,true)
