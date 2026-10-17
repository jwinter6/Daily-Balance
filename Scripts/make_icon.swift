import CoreGraphics
import ImageIO
import Foundation

let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let colors = [CGColor(red: 0.08, green: 0.30, blue: 0.34, alpha: 1),
              CGColor(red: 0.16, green: 0.51, blue: 0.48, alpha: 1)] as CFArray
let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 1024, y: 0), end: CGPoint(x: 0, y: 1024), options: [])
context.setStrokeColor(CGColor(gray: 1, alpha: 0.12)); context.setLineWidth(3)
context.strokeEllipse(in: CGRect(x: 160, y: 160, width: 704, height: 704))
context.move(to: CGPoint(x: 232, y: 455))
context.addCurve(to: CGPoint(x: 505, y: 505), control1: CGPoint(x: 350, y: 455), control2: CGPoint(x: 370, y: 660))
context.addCurve(to: CGPoint(x: 786, y: 620), control1: CGPoint(x: 620, y: 355), control2: CGPoint(x: 655, y: 620))
context.setLineCap(.round); context.setLineWidth(34); context.setStrokeColor(CGColor(gray: 1, alpha: 1)); context.strokePath()
context.setFillColor(CGColor(red: 0.76, green: 0.90, blue: 0.81, alpha: 1))
context.fillEllipse(in: CGRect(x: 747, y: 581, width: 78, height: 78))
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not save icon") }
