//
//  FIKFacebookButton.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/15.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "FIKFacebookButton.h"

#import "FIKConstants.h"
@implementation FIKFacebookButton
- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat w = self.bounds.size.width;
    CGFloat scaleFactor = w / 100.0;
    CGContextScaleCTM(context, scaleFactor, scaleFactor);
    
    [self renderIcon100x100];
    
    if(self.isHighlighted)
    {
        CGContextSetRGBFillColor(context, 0, 0, 0, ICON_GRAY);
        CGContextFillRect(context, CGRectMake(0, 0, 100, 100));
    }
}
- (void)renderIcon100x100
{
#if TARGET_OS_IPHONE
    CGContextRef ctx = UIGraphicsGetCurrentContext();	// iOS
#else
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];	// OS X
#endif
    
    // enable the following lines for flipped coordinate systems
    // CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    // CGContextScaleCTM(ctx, 1, -1);
    
    /*  Blue_1_  */
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL, 86.794, 91.359);
    CGPathAddCurveToPoint(pathRef, NULL, 89.315, 91.359, 91.359, 89.315, 91.359, 86.794);
    CGPathAddLineToPoint(pathRef, NULL, 91.359, 13.206);
    CGPathAddCurveToPoint(pathRef, NULL, 91.359, 10.684, 89.315, 8.641, 86.794, 8.641);
    CGPathAddLineToPoint(pathRef, NULL, 13.206, 8.641);
    CGPathAddCurveToPoint(pathRef, NULL, 10.684, 8.641, 8.641, 10.684, 8.641, 13.206);
    CGPathAddLineToPoint(pathRef, NULL, 8.641, 86.794);
    CGPathAddCurveToPoint(pathRef, NULL, 8.641, 89.315, 10.684, 91.359, 13.206, 91.359);
    CGPathAddLineToPoint(pathRef, NULL, 86.794, 91.359);
    CGPathCloseSubpath(pathRef);
    
    CGContextSetRGBFillColor(ctx, 0.235, 0.353, 0.6, 1);
    CGContextAddPath(ctx, pathRef);
    CGContextFillPath(ctx);
    
    CGPathRelease(pathRef);
    
    /*  f  */
    CGMutablePathRef pathRef2 = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef2, NULL, 61.715, 87.359);
    CGPathAddLineToPoint(pathRef2, NULL, 61.715, 55.326);
    CGPathAddLineToPoint(pathRef2, NULL, 72.467, 55.326);
    CGPathAddLineToPoint(pathRef2, NULL, 74.077, 42.842);
    CGPathAddLineToPoint(pathRef2, NULL, 61.715, 42.842);
    CGPathAddLineToPoint(pathRef2, NULL, 61.715, 34.872);
    CGPathAddCurveToPoint(pathRef2, NULL, 61.715, 31.258, 62.719, 28.794, 67.902, 28.794);
    CGPathAddLineToPoint(pathRef2, NULL, 74.513, 28.792);
    CGPathAddLineToPoint(pathRef2, NULL, 74.513, 17.626);
    CGPathAddCurveToPoint(pathRef2, NULL, 73.369, 17.474, 69.445, 17.134, 64.88, 17.134);
    CGPathAddCurveToPoint(pathRef2, NULL, 55.349, 17.134, 48.823, 22.952, 48.823, 33.636);
    CGPathAddLineToPoint(pathRef2, NULL, 48.823, 42.842);
    CGPathAddLineToPoint(pathRef2, NULL, 38.044, 42.842);
    CGPathAddLineToPoint(pathRef2, NULL, 38.044, 55.326);
    CGPathAddLineToPoint(pathRef2, NULL, 48.823, 55.326);
    CGPathAddLineToPoint(pathRef2, NULL, 48.823, 87.359);
    CGPathAddLineToPoint(pathRef2, NULL, 61.715, 87.359);
    CGPathCloseSubpath(pathRef2);
    
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextAddPath(ctx, pathRef2);
    CGContextFillPath(ctx);
    
    CGPathRelease(pathRef2);
}
@end
