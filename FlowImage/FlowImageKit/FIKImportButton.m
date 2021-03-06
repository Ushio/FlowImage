//
//  FIKPhotoButton.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/20.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "FIKImportButton.h"

#import "FIKConstants.h"

@implementation FIKImportButton

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
    
    /*  Shape   */
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL, 41.889, 32.129);
    CGPathAddLineToPoint(pathRef, NULL, 41.889, 34.833);
    CGPathAddLineToPoint(pathRef, NULL, 27.018, 34.833);
    CGPathAddLineToPoint(pathRef, NULL, 27.018, 80.796);
    CGPathAddLineToPoint(pathRef, NULL, 72.981, 80.796);
    CGPathAddLineToPoint(pathRef, NULL, 72.981, 34.833);
    CGPathAddLineToPoint(pathRef, NULL, 58.111, 34.833);
    CGPathAddLineToPoint(pathRef, NULL, 58.111, 32.129);
    CGPathAddLineToPoint(pathRef, NULL, 75.685, 32.129);
    CGPathAddLineToPoint(pathRef, NULL, 75.685, 83.5);
    CGPathAddLineToPoint(pathRef, NULL, 24.315, 83.5);
    CGPathAddLineToPoint(pathRef, NULL, 24.315, 32.129);
    CGPathAddLineToPoint(pathRef, NULL, 41.889, 32.129);
    CGPathCloseSubpath(pathRef);
    
    CGContextSetRGBFillColor(ctx, 0, 0.482, 0.969, 1);
    CGContextAddPath(ctx, pathRef);
    CGContextFillPath(ctx);
    
    CGPathRelease(pathRef);
    
    /*  Shape 2  */
    CGMutablePathRef pathRef2 = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef2, NULL, 49.193, 56.169);
    CGPathAddLineToPoint(pathRef2, NULL, 37.833, 44.692);
    CGPathAddLineToPoint(pathRef2, NULL, 39.745, 42.78);
    CGPathAddLineToPoint(pathRef2, NULL, 47.857, 51.055);
    CGPathAddLineToPoint(pathRef2, NULL, 47.857, 10.5);
    CGPathAddLineToPoint(pathRef2, NULL, 50.56, 10.5);
    CGPathAddLineToPoint(pathRef2, NULL, 50.56, 51.055);
    CGPathAddLineToPoint(pathRef2, NULL, 59.463, 42.78);
    CGPathAddLineToPoint(pathRef2, NULL, 61.375, 44.692);
    CGPathAddLineToPoint(pathRef2, NULL, 49.193, 56.169);
    CGPathCloseSubpath(pathRef2);
    
    CGContextSetRGBFillColor(ctx, 0, 0.482, 0.969, 1);
    CGContextAddPath(ctx, pathRef2);
    CGContextFillPath(ctx);
    
    CGPathRelease(pathRef2);
}

@end
