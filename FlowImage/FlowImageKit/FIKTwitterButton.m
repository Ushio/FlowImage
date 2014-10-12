//
//  FIKTwitterButton.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/15.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "FIKTwitterButton.h"

#import "FIKConstants.h"

@implementation FIKTwitterButton
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
    
    /*  path5  */
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL, 93.3, 23.142);
    CGPathAddCurveToPoint(pathRef, NULL, 90.114, 24.555, 86.69, 25.51, 83.096, 25.939);
    CGPathAddCurveToPoint(pathRef, NULL, 86.764, 23.741, 89.582, 20.259, 90.908, 16.11);
    CGPathAddCurveToPoint(pathRef, NULL, 87.475, 18.146, 83.673, 19.625, 79.625, 20.421);
    CGPathAddCurveToPoint(pathRef, NULL, 76.385, 16.968, 71.767, 14.811, 66.657, 14.811);
    CGPathAddCurveToPoint(pathRef, NULL, 56.845, 14.811, 48.889, 22.766, 48.889, 32.577);
    CGPathAddCurveToPoint(pathRef, NULL, 48.889, 33.97, 49.046, 35.326, 49.35, 36.626);
    CGPathAddCurveToPoint(pathRef, NULL, 34.583, 35.886, 21.492, 28.812, 12.729, 18.063);
    CGPathAddCurveToPoint(pathRef, NULL, 11.199, 20.687, 10.323, 23.738, 10.323, 26.995);
    CGPathAddCurveToPoint(pathRef, NULL, 10.323, 33.159, 13.46, 38.597, 18.227, 41.783);
    CGPathAddCurveToPoint(pathRef, NULL, 15.315, 41.691, 12.575, 40.892, 10.18, 39.561);
    CGPathAddCurveToPoint(pathRef, NULL, 10.178, 39.635, 10.178, 39.709, 10.178, 39.784);
    CGPathAddCurveToPoint(pathRef, NULL, 10.178, 48.392, 16.302, 55.573, 24.43, 57.206);
    CGPathAddCurveToPoint(pathRef, NULL, 22.939, 57.612, 21.369, 57.829, 19.749, 57.829);
    CGPathAddCurveToPoint(pathRef, NULL, 18.604, 57.829, 17.491, 57.718, 16.406, 57.511);
    CGPathAddCurveToPoint(pathRef, NULL, 18.667, 64.569, 25.229, 69.706, 33.004, 69.849);
    CGPathAddCurveToPoint(pathRef, NULL, 26.923, 74.614, 19.262, 77.455, 10.938, 77.455);
    CGPathAddCurveToPoint(pathRef, NULL, 9.504, 77.455, 8.09, 77.37, 6.7, 77.206);
    CGPathAddCurveToPoint(pathRef, NULL, 14.563, 82.248, 23.902, 85.189, 33.935, 85.189);
    CGPathAddCurveToPoint(pathRef, NULL, 66.615, 85.189, 84.487, 58.116, 84.487, 34.637);
    CGPathAddCurveToPoint(pathRef, NULL, 84.487, 33.867, 84.469, 33.101, 84.435, 32.338);
    CGPathAddCurveToPoint(pathRef, NULL, 87.906, 29.834, 90.918, 26.705, 93.3, 23.142);
    CGPathCloseSubpath(pathRef);
    
    CGContextSetRGBFillColor(ctx, 0.165, 0.663, 0.878, 1);
    CGContextAddPath(ctx, pathRef);
    CGContextFillPath(ctx);
    
    CGPathRelease(pathRef);

    
}

@end
