//
//  FluidEngine.h
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/23.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import <memory>
#include "CppHelper.hpp"

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/ext.hpp>

extern const float kFluidSize;

@class MetalView;
@interface FluidEngine : NSObject
- (instancetype)initWithMetalView:(MetalView *)metalView;

- (void)storeImage320x320:(cpp_helper::cf_shared_ptr<CGImageRef>)image;
- (cpp_helper::cf_shared_ptr<CGImageRef>)loadImage320x320;

- (void)update60fps;

@property (nonatomic, assign) float pen;
@property (nonatomic, assign) glm::vec2 forceSegmentPointA;
@property (nonatomic, assign) glm::vec2 forceSegmentPointB;
@property (nonatomic, assign) glm::vec2 force;
@end
