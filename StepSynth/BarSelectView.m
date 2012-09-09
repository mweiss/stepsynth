//
//  BarSelectView.m
//  StepSynth
//
//  Created by Michael Weiss on 9/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BarSelectView.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define BAR_SELECT_VIEW_PADDING 5

@implementation BarSelectView
@synthesize selectedColor, borderColor, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        ratio = 0;
    }
    [self setOpaque:NO];
    [self setBorderColor:UIColorFromRGB(0x69D2E7)];
    [self setSelectedColor:UIColorFromRGB(0xE0E4CC)];
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] set];
    UIRectFill(self.bounds);
    float startY = (self.bounds.size.height - (2 * BAR_SELECT_VIEW_PADDING)) - ratio * (self.bounds.size.height - (2 * BAR_SELECT_VIEW_PADDING));
    
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRect:CGRectMake(BAR_SELECT_VIEW_PADDING, BAR_SELECT_VIEW_PADDING + startY, self.bounds.size.width - (2 * BAR_SELECT_VIEW_PADDING), (self.bounds.size.height - 2 * BAR_SELECT_VIEW_PADDING) - startY)];
    
    [self.selectedColor setFill];
    [fillPath fill];
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRect:self.bounds];
    [borderPath setLineWidth:4];
    [self.borderColor setStroke];
    [borderPath stroke];
    
}

- (void) handleTouch:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint translate = [[touches anyObject] locationInView: self];
    ratio = 1 - MIN(1, MAX(0, translate.y / self.bounds.size.height));


    [self setNeedsDisplay];
}

- (void) handleDelegation {
    NSMethodSignature *signature = [delegate methodSignatureForSelector: selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setArgument:&ratio atIndex:2];
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
