//
//  CircleSelectView.m
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CircleSelectView.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface CircleSelectView()
@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic, retain) UIColor *selectedColor;
@end

@implementation CircleSelectView

@synthesize borderColor, selectedColor, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (totalNumIndexes == 0) {
            totalNumIndexes = 1;
        }
        selectedIndex = 0;
        [self setBorderColor:UIColorFromRGB(0x69D2E7)];
        [self setSelectedColor:UIColorFromRGB(0xE0E4CC)];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] setFill];
    UIRectFill(self.bounds);
    CGPoint center = CGPointMake(self.bounds.size.width / 2., self.bounds.size.height / 2.);
    float startAngle = ((float)selectedIndex) * (2. * M_PI / totalNumIndexes);
    float endAngle = ((float)selectedIndex + 1) * (2. * M_PI / totalNumIndexes);
    float radius = (self.frame.size.width / 2) - 5;
    
    UIBezierPath * outerArc = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle: 2. * M_PI clockwise:YES];

    [self.borderColor setStroke];
    [outerArc setLineWidth:3];
    [outerArc stroke];
    

    UIBezierPath * selectedArc = [UIBezierPath bezierPathWithArcCenter:center radius:radius - 5 startAngle:startAngle  endAngle:endAngle clockwise:YES];
    [self.selectedColor set];
    [selectedArc fill];
    [selectedArc stroke];
    
    UIBezierPath * selectedPath = [UIBezierPath bezierPath];
    [selectedPath moveToPoint:center];
    [selectedPath addLineToPoint:CGPointMake(center.x + cos(startAngle) * (radius - 4), center.y + sin(startAngle)  * (radius - 4))];
    [selectedPath addLineToPoint:CGPointMake(center.x + cos(endAngle) * (radius - 4), center.y + sin(endAngle)  * (radius - 4))];
    [selectedPath closePath];
    [selectedPath fill];
    
    
    UIBezierPath * innerArc = [UIBezierPath bezierPathWithArcCenter:center radius:radius / 3. startAngle:0 endAngle: 2. * M_PI clockwise:YES];    
    [[UIColor blackColor] setFill];
    [innerArc fill];
}

- (void) handleTouch:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint translate = [[touches anyObject] locationInView: self];
    CGPoint center = CGPointMake(self.bounds.size.width / 2., self.bounds.size.height / 2.);
    float yDiff = translate.y - center.y;
    float xDiff = translate.x - center.x;
    float ratio = yDiff / (xDiff != 0 ? xDiff : .1);
    float theta = atan(ratio);
    if (xDiff < 0) {
        theta += M_PI;
    }
    if (theta < 0) {
        theta += M_PI * 2.;
    }
    float i = floorf((theta / (M_PI * 2.)) * ((float)totalNumIndexes));
    if (i != selectedIndex) {
        selectedIndex = i;
        [self setNeedsDisplay];
    }
}

- (void)handleDelegation {
    NSMethodSignature *signature = [delegate methodSignatureForSelector: selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setArgument:&selectedIndex atIndex:2];
    [invocation setSelector:selector];
    [invocation setTarget:delegate];
    [invocation invoke];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleDelegation];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleDelegation];
}
@end
