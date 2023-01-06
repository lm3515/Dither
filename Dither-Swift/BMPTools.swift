//
//  BMPTools.swift
//  InkZone
//
//  Created by 刘敏 on 2022/10/25.
//

import UIKit

enum PaletteType{
    case BW     // 黑白屏
    case BWR    // 黑白红屏
    case BWY    // 黑白黄屏
}

// 初始化
func dim<T>(_ count: Int, _ value: T) -> [T] {
    return [T](repeating: value, count: count)
}
 
struct Pixel: Equatable {
    private var rgba: UInt32
    static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue|CGBitmapInfo.byteOrder32Little.rawValue

    var red: UInt8 {
        return UInt8((rgba >> 24) & 255)
    }

    var green: UInt8 {
        return UInt8((rgba >> 16) & 255)
    }

    var blue: UInt8 {
        return UInt8((rgba >> 8) & 255)
    }

    var alpha: UInt8 {
        return UInt8((rgba >> 0) & 255)
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        rgba = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }

    static func ==(lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.rgba == rhs.rgba
    }
}


class BMPTools: NSObject {
    // 根据屏幕类型获取基础颜色
    fileprivate static func getPalette(_ dType: PaletteType) -> [Pixel] {
        if dType == .BWR {
            // 黑白红
            let triple = [Pixel(red: 0, green: 0, blue: 0, alpha: 255),
                          Pixel(red: 255, green: 255, blue: 255, alpha: 255),
                          Pixel(red: 255, green: 0, blue: 0, alpha: 255)]
            return triple
        }
        else if dType == .BWY {
            // 黑白黄
            let triple = [Pixel(red: 0, green: 0, blue: 0, alpha: 255),
                          Pixel(red: 255, green: 255, blue: 255, alpha: 255),
                          Pixel(red: 255, green: 255, blue: 0, alpha: 255)]
            return triple
        }
        else {
            // 黑白
            let triple = [Pixel(red: 0, green: 0, blue: 0, alpha: 255),
                          Pixel(red: 255, green: 255, blue: 255, alpha: 255)]
            return triple
        }
    }
    
    // MARK: - 图像二值化
    public static func blackAndWhite(_ image: UIImage, completion: @escaping (UIImage?) -> Void) {
        let width: Int = Int(image.size.width)
        let height: Int = Int(image.size.height)
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = Pixel.bitmapInfo
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        // 创建context
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.draw(image.cgImage!, in: rect)
        
        guard let buffer = context.data else {
            print("无法获取图片上下文数据")
            return
        }
        
        // 得到Pixel数组指针
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: width * height)
        for row in 0 ..< height { 
            for col in 0 ..< width {
                let offset = Int(row * width + col)

                let red = Float(pixels[offset].red)
                let green = Float(pixels[offset].green)
                let blue = Float(pixels[offset].blue)
                let alpha = pixels[offset].alpha
                let luminance = UInt8(0.2126 * red + 0.7152 * green + 0.0722 * blue)
                pixels[offset] = Pixel(red: luminance, green: luminance, blue: luminance, alpha: alpha)
            }
        }
        
        let outputImage = context.makeImage()!
        completion(UIImage(cgImage: outputImage, scale: image.scale, orientation: image.imageOrientation))
    }
    
    // MARK: - 图像抖动算法
    public static func floydSteinberg(_ image: UIImage, type: PaletteType, completion: @escaping (UIImage?) -> Void) {
        let width: Int = Int(image.size.width)
        let height: Int = Int(image.size.height)
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = Pixel.bitmapInfo
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        // 创建context
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.draw(image.cgImage!, in: rect)
        
        guard let buffer = context.data else {
            print("无法获取图片上下文数据")
            return
        }

        // 得到Pixel数组指针
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: width * height)
        let convert: [[UInt8]] = convertPixels(pixels: pixels, width: width, height: height, type: type)
        
        for row in 0 ..< height { 
            for col in 0 ..< width {
                let offset = row * width + col
                if convert[row][col] == 0 {
                    // 处理黑色
                    pixels[offset] = Pixel(red: 0, green: 0, blue: 0, alpha: 255)
                }
                else if convert[row][col] == 1 {
                    // 处理白色
                    pixels[offset] = Pixel(red: 255, green: 255, blue: 255, alpha: 255)
                }
                else if convert[row][col] == 2 && type == .BWR {
                    // 处理红色
                    pixels[offset] = Pixel(red: 255, green: 0, blue: 0, alpha: 255)
                }
                else if convert[row][col] == 2 && type == .BWY {
                    // 处理黄色
                    pixels[offset] = Pixel(red: 255, green: 255, blue: 0, alpha: 255)
                }
            }
        }

        let outputImage = context.makeImage()!
        completion(UIImage(cgImage: outputImage, scale: image.scale, orientation: image.imageOrientation))
    }
    
    // 像素处理
    fileprivate static func convertPixels(pixels: UnsafeMutablePointer<Pixel>,
                                          width: Int,
                                          height: Int,
                                          type: PaletteType) -> [[UInt8]] {
        let palette = getPalette(type)
        // 创建一个二维数组，记录颜色值
        var result = dim(height, dim(width, UInt8(0)))
        
        for row in 0 ..< height { 
            for col in 0 ..< width{
                let offset = row * width + col
                let index = findNearestColor(color: pixels[offset], palette: palette)
                result[row][col] = index
                
                let e_R = Int(pixels[offset].red & 255) - Int(palette[Int(index)].red & 255)
                let e_G = Int(pixels[offset].green & 255) - Int(palette[Int(index)].green & 255)
                let e_B = Int(pixels[offset].blue & 255) - Int(palette[Int(index)].blue & 255)
        
                // 残差(设置像素点)
                if col + 1 < width {
                    let m_index = offset + 1
                    let r = plus_truncate_uchar(a: pixels[m_index].red, b: ((e_R * 7) >> 4))
                    let g = plus_truncate_uchar(a: pixels[m_index].green, b: ((e_G * 7) >> 4))
                    let b = plus_truncate_uchar(a: pixels[m_index].blue, b: ((e_B * 7) >> 4))
                    
                    pixels[m_index] = Pixel(red: r, green: g, blue: b, alpha: 255)
                }
                
                if row + 1 < height {
                    if row + 1 < width {
                        let m_index = (row + 1) * width + col + 1
                        let r = plus_truncate_uchar(a: pixels[m_index].red, b: (e_R >> 4))
                        let g = plus_truncate_uchar(a: pixels[m_index].green, b: (e_G >> 4))
                        let b = plus_truncate_uchar(a: pixels[m_index].blue, b: (e_B >> 4))
                        
                        pixels[m_index] = Pixel(red: r, green: g, blue: b, alpha: 255)
                    }
                    
                    let m_index = (row + 1) * width + col
                    let r = plus_truncate_uchar(a: pixels[m_index].red, b: ((e_R * 5) >> 4))
                    let g = plus_truncate_uchar(a: pixels[m_index].green, b: ((e_G * 5) >> 4))
                    let b = plus_truncate_uchar(a: pixels[m_index].blue, b: ((e_B * 5) >> 4))
                    
                    pixels[m_index] = Pixel(red: r, green: g, blue: b, alpha: 255)
                    
                    // 一定要放在最下面
                    if col - 1 > 0 {
                        let m_index = (row + 1) * width + col - 1
                        let r = plus_truncate_uchar(a: pixels[m_index].red, b: ((e_R * 3) >> 4))
                        let g = plus_truncate_uchar(a: pixels[m_index].green, b: ((e_G * 3) >> 4))
                        let b = plus_truncate_uchar(a: pixels[m_index].blue, b: ((e_B * 3) >> 4))
                        
                        pixels[m_index] = Pixel(red: r, green: g, blue: b, alpha: 255)
                    }
                }
            }
        }
        return result
    }
    
    fileprivate static func findNearestColor(color: Pixel, palette: [Pixel]) -> UInt8 {
        var minDistanceSquared = pow(255, 2) + pow(255, 2) + pow(255, 2) + 1
        var index = 0
        for i in 0 ..< palette.count {
            let R: Int = Int(color.red & 255) - Int(palette[i].red & 255)
            let G: Int = Int(color.green & 255) - Int(palette[i].green & 255)
            let B: Int = Int(color.blue & 255) - Int(palette[i].blue & 255)
            let distanceSquared = pow(Decimal(R), 2) + pow(Decimal(G), 2) + pow(Decimal(B), 2)
            if distanceSquared < minDistanceSquared {
                minDistanceSquared = distanceSquared
                index = i
            }
        }
        return UInt8(index)
    }
    
    // MARK: - 私有方法
    fileprivate static func plus_truncate_uchar(a: UInt8, b: Int) -> UInt8 {
        if Int(a & 255) + b < 0 {
            return 0
        }
        else if Int(a & 255) + b > 255 {
            return 255
        }
        else {
            return UInt8(Int(a) + b)
        }
    }
}
