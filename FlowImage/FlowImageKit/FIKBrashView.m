//
//  FIKBrashView.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/14.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "FIKBrashView.h"


static double lerp(double a, double b, double amp)
{
    return a + (b - a) * amp;
}

@implementation FIKBrashView
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect maxRect = CGRectInset(self.bounds, 10, 10);
    double brashSize = lerp(2, maxRect.size.width, _brashSizeRatio);
    CGRect ellipseRect = CGRectMake(maxRect.origin.x + (maxRect.size.width - brashSize) * 0.5,
                                    maxRect.origin.y + (maxRect.size.height - brashSize) * 0.5,
                                    brashSize,
                                    brashSize);

    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillEllipseInRect(context, ellipseRect);
}
- (void)setBrashSizeRatio:(double)brashSizeRatio
{
    _brashSizeRatio = MAX(MIN(brashSizeRatio, 1.0), 0.0);
    [self setNeedsDisplay];
}
@end
