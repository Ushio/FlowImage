//
//  CppHelper.cpp
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/23.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#include "CppHelper.hpp"
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>

#include <algorithm>
#include <vector>

namespace cpp_helper {
    cpp_helper::cf_shared_ptr<CGImageRef> cgImageAtPath(NSString *path)
    {
        NSURL *imageURL = [NSURL fileURLWithPath:path];
        cpp_helper::cf_shared_ptr<CGImageSourceRef> imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil), CFRelease);
        if(!imageSource)
        {
            return cpp_helper::cf_shared_ptr<CGImageRef>();
        }
        if(CGImageSourceGetCount(imageSource.get()) == 0)
        {
            return cpp_helper::cf_shared_ptr<CGImageRef>();
        }
        return cpp_helper::cf_shared_ptr<CGImageRef>(CGImageSourceCreateImageAtIndex(imageSource.get(), 0, nil), CGImageRelease);
    }
    namespace
    {
        void bufferFree(void *info, const void *data, size_t size)
        {
            free((void *)data);
        }
    }
    cpp_helper::cf_shared_ptr<CGImageRef> cgImageRasterize(cpp_helper::cf_shared_ptr<CGImageRef> srcImage)
    {
        size_t width = CGImageGetWidth(srcImage.get());
        size_t height = CGImageGetHeight(srcImage.get());
        size_t bitsPerComponent = 8;
        size_t bytesPerRow = align16(4 * width);
        size_t bytesSize = bytesPerRow * height;
        uint8_t *bytes = (uint8_t *)malloc(bytesSize);
        
        cpp_helper::cf_shared_ptr<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB(), CGColorSpaceRelease);
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        cpp_helper::cf_shared_ptr<CGContextRef> context(CGBitmapContextCreate(bytes, width, height, bitsPerComponent, bytesPerRow, colorSpace.get(), bitmapInfo), CGContextRelease);
        CGContextSetBlendMode(context.get(), kCGBlendModeCopy);
        CGContextSetInterpolationQuality(context.get(), kCGInterpolationNone);
        CGContextDrawImage(context.get(), CGRectMake(0, 0, width, height), srcImage.get());
        
        cpp_helper::cf_shared_ptr<CGDataProviderRef> dataProvider(CGDataProviderCreateWithData(NULL, bytes, bytesSize, bufferFree), CGDataProviderRelease);
        size_t bitsPerPixel = 32;
        return cpp_helper::cf_shared_ptr<CGImageRef>(CGImageCreate(width,
                                                                   height,
                                                                   bitsPerComponent,
                                                                   bitsPerPixel,
                                                                   bytesPerRow,
                                                                   colorSpace.get(),
                                                                   bitmapInfo,
                                                                   dataProvider.get(),
                                                                   NULL,
                                                                   NO,
                                                                   kCGRenderingIntentDefault), CGImageRelease);
    }
    CGRect aspect_fit(CGSize source, CGSize destination)
    {
        float srcAspect = source.width / source.height;
        float dstAspect = destination.width / destination.height;
        
        float zoomFactor;
        if(dstAspect < srcAspect)
        {
            //出力先のほうが幅がでかい -> 幅に合わせてリサイズ
            zoomFactor = destination.width / source.width;
        }
        else
        {
            //縦に合わせてリサイズ
            zoomFactor = destination.height / source.height;
        }
        
        CGSize size = { source.width * zoomFactor, source.height * zoomFactor };
        CGPoint point = CGPointMake(-(size.width - destination.width) * 0.5,
                                    -(size.height - destination.height) * 0.5);
        return (CGRect){point, size};
    }
    
    cf_shared_ptr<CGImageRef> cgImageToSquare(cf_shared_ptr<CGImageRef> srcImage)
    {
        size_t width = CGImageGetWidth(srcImage.get());
        size_t height = CGImageGetHeight(srcImage.get());
        if(width == height)
        {
            return srcImage;
        }
        
        CGFloat srcMin = std::min(width, height);
        CGRect cropRect = aspect_fit(CGSizeMake(srcMin, srcMin), CGSizeMake(width, height));
        return cf_shared_ptr<CGImageRef>(CGImageCreateWithImageInRect(srcImage.get(), cropRect), CGImageRelease);
    }
    cf_shared_ptr<CGImageRef> cgImageFit320x320(cf_shared_ptr<CGImageRef> srcImage)
    {
        size_t kFitSize = 320;
        if(CGImageGetWidth(srcImage.get()) == kFitSize && CGImageGetHeight(srcImage.get()) == kFitSize)
        {
            return srcImage;
        }
        
        srcImage = cgImageToSquare(srcImage);
        
        size_t srcWidth = CGImageGetWidth(srcImage.get());
        size_t srcHeight = CGImageGetHeight(srcImage.get());
        size_t srcBitsPerComponent = 8;
        size_t srcBytesPerRow = align16(4 * srcWidth);
        std::vector<uint8_t> srcBytes(srcBytesPerRow * srcHeight);
        
        cf_shared_ptr<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB(), CGColorSpaceRelease);
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        cf_shared_ptr<CGContextRef> context(CGBitmapContextCreate(srcBytes.data(), srcWidth, srcHeight, srcBitsPerComponent, srcBytesPerRow, colorSpace.get(), bitmapInfo), CGContextRelease);
        CGContextSetBlendMode(context.get(), kCGBlendModeCopy);
        CGContextSetInterpolationQuality(context.get(), kCGInterpolationNone);
        CGContextDrawImage(context.get(), CGRectMake(0, 0, srcWidth, srcHeight), srcImage.get());
        
        vImage_Buffer srcImageBuffer = {
            .data = srcBytes.data(),
            .width = srcWidth,
            .height = srcHeight,
            .rowBytes = srcBytesPerRow,
        };
        
        size_t dstBytesPerRow = align16(4 * kFitSize);
        size_t dstByteSize = dstBytesPerRow * kFitSize;
        uint8_t *dstBytes = (uint8_t *)malloc(dstByteSize);
        vImage_Buffer dstImageBuffer = {
            .data = dstBytes,
            .width = static_cast<vImagePixelCount>(kFitSize),
            .height = static_cast<vImagePixelCount>(kFitSize),
            .rowBytes = dstBytesPerRow,
        };
        
        vImageScale_ARGB8888(&srcImageBuffer, &dstImageBuffer, NULL, kvImageHighQualityResampling);
        
        cpp_helper::cf_shared_ptr<CGDataProviderRef> dataProvider(CGDataProviderCreateWithData(NULL, dstBytes, dstByteSize, bufferFree), CGDataProviderRelease);
        size_t bitsPerPixel = 32;
        return cpp_helper::cf_shared_ptr<CGImageRef>(CGImageCreate(kFitSize,
                                                                   kFitSize,
                                                                   8,
                                                                   bitsPerPixel,
                                                                   dstBytesPerRow,
                                                                   colorSpace.get(),
                                                                   bitmapInfo,
                                                                   dataProvider.get(),
                                                                   NULL,
                                                                   NO,
                                                                   kCGRenderingIntentDefault), CGImageRelease);
    }
    cf_shared_ptr<CGImageRef> cgImageToSmartPtr(CGImageRef image)
    {
        return cf_shared_ptr<CGImageRef>(CGImageRetain(image), CGImageRelease);
    }
}
