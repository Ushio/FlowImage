//
//  CppHelper.h
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/23.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <memory>

namespace cpp_helper {
    template <typename T>
    using cf_shared_ptr = std::shared_ptr<typename std::remove_pointer<T>::type>;
    
    static inline size_t align16(size_t size)
    {
        if(size == 0)
            return 0;
        
        return (((size - 1) >> 4) << 4) + 16;
    }
    static inline float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
    {
        return (value - inputMin) * ((outputMax - outputMin) / (inputMax - inputMin)) + outputMin;
    }
    
    cf_shared_ptr<CGImageRef> cgImageAtPath(NSString *path);
    cf_shared_ptr<CGImageRef> cgImageRasterize(cf_shared_ptr<CGImageRef> srcImage);
    CGRect aspect_fit(CGSize source, CGSize destination);
    cf_shared_ptr<CGImageRef> cgImageFit320x320(cf_shared_ptr<CGImageRef> srcImage);
    cf_shared_ptr<CGImageRef> cgImageToSmartPtr(CGImageRef image);
}