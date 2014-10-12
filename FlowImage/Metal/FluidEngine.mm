//
//  FluidEngine.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/23.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "FluidEngine.hpp"

// Objective-C
#import <Metal/Metal.h>
#import "MetalView.h"

// C++
#include <vector>
#include <array>
#include "MyShaderTypes.hpp"
#include <simd/simd.h>

#include <half.hpp>
#include "CppHelper.hpp"

const float kFluidSize = FLUID_SIZE;

typedef glm::detail::tvec4<half_float::half, glm::highp> hvec4;

namespace
{
    void bufferFree(void *info, const void *data, size_t size)
    {
        free((void *)data);
    }
}

@implementation FluidEngine
{
    MetalView *_metalView;
    
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLLibrary> _library;
    id<MTLRenderPipelineState> _renderPipelineState;
    
    // geometry buffers
    id<MTLBuffer> _vertexBuffer;
    id<MTLTexture> _fuild_rgb_texture0;
    id<MTLTexture> _fuild_rgb_texture1;
    
    // compute
    id <MTLComputePipelineState> _step_fuild_kernel;
    
    id<MTLTexture> _fuild_simulation_texture0;
    id<MTLTexture> _fuild_simulation_texture1;
    
    id<MTLBuffer> _fuildConstantBuffer;
    bool _isRequiedUpdateConstant;
    
    // control
    dispatch_semaphore_t _semaphore;
}
- (instancetype)initWithMetalView:(MetalView *)metalView
{
    if(self = [super init])
    {
        _metalView = metalView;
        
        // Metal 初期化
        _device = MTLCreateSystemDefaultDevice();
        
        _metalView.metalLayer.device = _device;
        _metalView.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        _metalView.metalLayer.framebufferOnly = YES;
        
        _commandQueue = [_device newCommandQueue];
        _library = [_device newDefaultLibrary];
        
        MyShaderTypes::QuardVertex quad[] = {
            {simd::float2{-1.0f, 1.0f}, simd::float2{0.0f, 1.0f}},
            {simd::float2{ 1.0f, 1.0f}, simd::float2{1.0f, 1.0f}},
            {simd::float2{-1.0f,-1.0f}, simd::float2{0.0f, 0.0f}},
            {simd::float2{ 1.0f,-1.0f}, simd::float2{1.0f, 0.0f}},
        };
        _vertexBuffer = [_device newBufferWithBytes:quad
                                             length:sizeof(quad)
                                            options:0];
        
        auto create_rgba16float_texture = ^{
            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                                                                                            width:FLUID_SIZE
                                                                                           height:FLUID_SIZE
                                                                                        mipmapped:NO];
            return [_device newTextureWithDescriptor:desc];
        };
        _fuild_rgb_texture0 = create_rgba16float_texture();
        _fuild_rgb_texture1 = create_rgba16float_texture();
        
        // debug
//        [self didSelectedChecker:nil];
        
        _step_fuild_kernel = ^{
            NSError *error;
            return [_device newComputePipelineStateWithFunction:[_library newFunctionWithName:@"step_fuild"]
                                                          error:&error];
            
        }();
        
        _fuild_simulation_texture0 = create_rgba16float_texture();
        _fuild_simulation_texture1 = create_rgba16float_texture();
        
        [self clearFluid];
        
        MyShaderTypes::FuildConstant fuildConstant = {0};
        _fuildConstantBuffer = [_device newBufferWithBytes:&fuildConstant
                                                    length:sizeof(fuildConstant)
                                                   options:0];
        
        _renderPipelineState = ^{
            NSError *error;
            MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
            desc.vertexFunction = [_library newFunctionWithName:@"myVertexShader"];
            desc.fragmentFunction = [_library newFunctionWithName:@"myFragmentShader"];
            desc.colorAttachments[0].pixelFormat = metalView.metalLayer.pixelFormat;
            desc.sampleCount = 1;
            return [_device newRenderPipelineStateWithDescriptor:desc error:&error];
        }();
        
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

// debug
//inline float checker_fast(simd::float2 uv)
//{
//    return fmod(floor(uv.x) + floor(uv.y), 2.0f);
//}
//- (void)didSelectedChecker:(UIButton *)sender
//{
//    std::vector<hvec4> texture_data(FLUID_SIZE * FLUID_SIZE);
//    for(int y = 0 ; y < FLUID_SIZE ; ++y)
//    {
//        for(int x = 0 ; x < FLUID_SIZE ; ++x)
//        {
//            float c = checker_fast(simd::float2{float(x), float(y)} * 0.05f);
//            
//            float h = cpp_helper::remap(y, 0, FLUID_SIZE - 1, 0, 270);
//            glm::vec3 hsv = glm::vec3(h, 1.0, 1.0);
//            glm::vec3 rgb = glm::rgbColor(hsv);
//            
//            glm::vec3 color = rgb * c;
//            texture_data[y * FLUID_SIZE + x] = hvec4(color, 1.0f);
//        }
//    }
//    
//    [_fuild_rgb_texture0 replaceRegion:MTLRegionMake2D(0, 0, _fuild_rgb_texture0.width, _fuild_rgb_texture0.height)
//                           mipmapLevel:0
//                             withBytes:texture_data.data()
//                           bytesPerRow:sizeof(decltype(texture_data)::value_type) * FLUID_SIZE];
//}
- (void)clearFluid
{
    // 流体クリア
    std::vector<hvec4> fuild_initial_data(FLUID_SIZE * FLUID_SIZE, hvec4(0.0f, 0.0f, 1.0f, 1.0f));
    MTLRegion region = MTLRegionMake2D(0, 0, _fuild_simulation_texture0.width, _fuild_simulation_texture0.height);
    [_fuild_simulation_texture0 replaceRegion:region
                                  mipmapLevel:0
                                    withBytes:fuild_initial_data.data()
                                  bytesPerRow:sizeof(decltype(fuild_initial_data)::value_type) * FLUID_SIZE];
}
- (void)storeImage320x320:(cpp_helper::cf_shared_ptr<CGImageRef>)image
{
    if (CGImageGetWidth(image.get()) != FLUID_SIZE || CGImageGetHeight(image.get()) != FLUID_SIZE) {
        NSAssert(0, @"");
        return;
    }
    
    // ピクセルデータへ
    size_t srcWidth = FLUID_SIZE;
    size_t srcHeight = FLUID_SIZE;
    size_t srcBitsPerComponent = 8;
    size_t srcBytesPerRow = cpp_helper::align16(4 * srcWidth);
    std::vector<uint8_t> srcBytes(srcBytesPerRow * srcHeight);
    
    cpp_helper::cf_shared_ptr<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB(), CGColorSpaceRelease);
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    cpp_helper::cf_shared_ptr<CGContextRef> context(CGBitmapContextCreate(srcBytes.data(), srcWidth, srcHeight, srcBitsPerComponent, srcBytesPerRow, colorSpace.get(), bitmapInfo), CGContextRelease);
    CGContextSetBlendMode(context.get(), kCGBlendModeCopy);
    CGContextSetInterpolationQuality(context.get(), kCGInterpolationNone);
    CGContextDrawImage(context.get(), CGRectMake(0, 0, srcWidth, srcHeight), image.get());
    
    std::vector<hvec4> texture_data(FLUID_SIZE * FLUID_SIZE);
    
    float div255 = 1.0f / 255.0f;
    for(int y = 0 ; y < FLUID_SIZE ; ++y)
    {
        uint8_t *lineHead = srcBytes.data() + srcBytesPerRow * ((int)FLUID_SIZE - y - 1);
        for(int x = 0 ; x < FLUID_SIZE ; ++x)
        {
            uint8_t *pixelHead = lineHead + x * 4;
            float r = (float)pixelHead[0] * div255;
            float g = (float)pixelHead[1] * div255;
            float b = (float)pixelHead[2] * div255;
            
            texture_data[y * FLUID_SIZE + x] = hvec4(r, g, b, 1.0f);
        }
    }
    [_fuild_rgb_texture0 replaceRegion:MTLRegionMake2D(0, 0, _fuild_rgb_texture0.width, _fuild_rgb_texture0.height)
                           mipmapLevel:0
                             withBytes:texture_data.data()
                           bytesPerRow:sizeof(decltype(texture_data)::value_type) * FLUID_SIZE];
    [self clearFluid];
}

- (cpp_helper::cf_shared_ptr<CGImageRef>)loadImage320x320
{
    std::vector<hvec4> texture_data(FLUID_SIZE * FLUID_SIZE);
    [_fuild_rgb_texture0 getBytes:texture_data.data()
                      bytesPerRow:sizeof(decltype(texture_data)::value_type) * FLUID_SIZE
                       fromRegion:MTLRegionMake2D(0, 0, _fuild_rgb_texture0.width, _fuild_rgb_texture0.height)
                      mipmapLevel:0];
    
    size_t width = FLUID_SIZE;
    size_t height = FLUID_SIZE;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = cpp_helper::align16(4 * width);
    size_t bytesSize = bytesPerRow * height;
    uint8_t *bytes = (uint8_t *)malloc(bytesSize);
    
    for(int y = 0 ; y < height ; ++y)
    {
        uint8_t *dsthead = bytes + bytesPerRow * (height - y - 1);
        for(int x = 0 ; x < width ; ++x)
        {
            hvec4 color_h = texture_data[y * width + x];
            std::array<float, 3> rgb = {
                static_cast<float>(color_h.x),
                static_cast<float>(color_h.y),
                static_cast<float>(color_h.z)
            };
            uint8_t *dstcolor = dsthead + 4 * x;
            for(int i = 0 ; i < 3 ; ++i)
            {
                int colori = glm::round(cpp_helper::remap(rgb[i], 0.0f, 1.0f, 0.0f, 255.0f));
                dstcolor[i] = std::max(std::min(colori, 255), 0);
            }
            dstcolor[3] = 255;
        }
    }
    
    cpp_helper::cf_shared_ptr<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB(), CGColorSpaceRelease);
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big; // RGBA
    
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
- (void)update60fps
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    id<CAMetalDrawable> drawable = [_metalView.metalLayer nextDrawable];
    if(drawable == nil)
    {
        return;
    }
    
    if(_isRequiedUpdateConstant)
    {
        [self updateFluidConstant];
        _isRequiedUpdateConstant = false;
    }
    
    // 流体シミュレーション
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    if(commandBuffer == nil)
    {
        return;
    }
    
    MTLSize threadsPerGroup = {16, 16, 1};
    MTLSize numThreadgroups = {(int)FLUID_SIZE / threadsPerGroup.width, (int)FLUID_SIZE / threadsPerGroup.height, 1};
    
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_step_fuild_kernel];
    
    [computeEncoder setTexture:_fuild_simulation_texture0
                       atIndex:0];
    [computeEncoder setTexture:_fuild_simulation_texture1
                       atIndex:1];
    [computeEncoder setBuffer:_fuildConstantBuffer offset:0 atIndex:0];
    
    [computeEncoder setTexture:_fuild_rgb_texture0
                       atIndex:2];
    [computeEncoder setTexture:_fuild_rgb_texture1
                       atIndex:3];
    
    [computeEncoder dispatchThreadgroups:numThreadgroups
                   threadsPerThreadgroup:threadsPerGroup];
    
    [computeEncoder endEncoding];
    
    std::swap(_fuild_simulation_texture0, _fuild_simulation_texture1);
    
    // 描画
    id <MTLRenderCommandEncoder> commandEncoder = ^{
        MTLRenderPassDescriptor *desc = [MTLRenderPassDescriptor renderPassDescriptor];
        
        desc.colorAttachments[0].texture = [drawable texture];
        desc.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        return [commandBuffer renderCommandEncoderWithDescriptor:desc];
    }();
    
    [commandEncoder setRenderPipelineState:_renderPipelineState];
    
    [commandEncoder setTriangleFillMode:MTLTriangleFillModeFill];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentTexture:_fuild_rgb_texture0 atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [commandEncoder endEncoding];
    
    std::swap(_fuild_rgb_texture0, _fuild_rgb_texture1);
    
    __block dispatch_semaphore_t semaphore = _semaphore;
    [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
        dispatch_semaphore_signal(semaphore);
    }];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}
- (void)setPen:(float)pen
{
    _pen = pen;
    _isRequiedUpdateConstant = true;
}
- (void)setForce:(glm::vec2)force
{
    _force = force;
    _isRequiedUpdateConstant = true;
}
- (void)setForceSegmentPointA:(glm::vec2)forceSegmentPointA
{
    _forceSegmentPointA = forceSegmentPointA;
    _isRequiedUpdateConstant = true;
}
- (void)setForceSegmentPointB:(glm::vec2)forceSegmentPointB
{
    _forceSegmentPointB = forceSegmentPointB;
    _isRequiedUpdateConstant = true;
}
- (void)updateFluidConstant
{
    MyShaderTypes::FuildConstant *fuildConstant = (MyShaderTypes::FuildConstant *)[_fuildConstantBuffer contents];
    fuildConstant->pen = _pen;
    fuildConstant->a = simd::float2{self.forceSegmentPointA.x, self.forceSegmentPointA.y};
    fuildConstant->b = simd::float2{self.forceSegmentPointB.x, self.forceSegmentPointB.y};
    fuildConstant->force = simd::float2{self.force.x, self.force.y};
}
@end
