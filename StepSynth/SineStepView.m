//
//  SineStepView.m
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SineStepView.h"
#import "SineStepBoxView.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_NUM_STEPS 16.
#define SINE_STEP_PADDING 5.
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface SineStepView() {
    BOOL startedTouches;
    BOOL firstTouchValue;
}
@end

@implementation SineStepView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *colors = [NSArray arrayWithObjects:UIColorFromRGB(0x69D2E7), UIColorFromRGB(0xA7DBD8),
                           UIColorFromRGB(0xE0E4CC), UIColorFromRGB(0xF38630), UIColorFromRGB(0xFA6900), nil];
        if (numSteps == 0) {
            numSteps = DEFAULT_NUM_STEPS;
        }
        if (bpm == 0) {
            bpm = 300;
        }
        uint totalSteps = numSteps * numSteps;
        steps = malloc(totalSteps * sizeof(BOOL));
        memset(steps, NO, sizeof(BOOL) * totalSteps);
        float rectDim = MIN(self.bounds.size.width, self.bounds.size.height) / numSteps;
        for (uint x = 0; x < numSteps; x += 1) {
            for (uint y = 0; y < numSteps; y += 1) {
                SineStepBoxView *ssbView = [[SineStepBoxView alloc] initWithFrame:CGRectInset(CGRectMake(x * rectDim, y * rectDim, rectDim, rectDim), SINE_STEP_PADDING, SINE_STEP_PADDING) x:x y:y];
                [ssbView setColor:[colors objectAtIndex:x % [colors count]]];
                [self addSubview:ssbView];
            }
        }

    }
    return self;
}

- (BOOL) getStep:(uint)x y:(uint)y {
   return steps[x + (y * numSteps)];
}

- (void) animateStep:(uint)x {
    for (uint y = 0; y < numSteps; y += 1) {
        UIView *view = [self.subviews objectAtIndex:(y + x * numSteps)];
        if ([self getStep:x y:y]) {
            CABasicAnimation *animation;
            animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            animation.duration = 30. / bpm;
            animation.fromValue = [NSNumber numberWithFloat:1];
            animation.toValue = [NSNumber numberWithFloat:1.2];
            animation.autoreverses = YES;
            animation.removedOnCompletion = YES;
            [view.layer addAnimation:animation forKey:@"animateSubView"];
        }
    }
}

- (void) registerStep:(uint)x y:(uint)y{
    if (!startedTouches) {
        startedTouches = YES;
        firstTouchValue = ![self getStep:x y:y];
    }
    [self setStep:x y:y withValue:firstTouchValue];
    [[self.subviews objectAtIndex:(y + x * numSteps)] setNeedsDisplay];
}

- (void) registerEnd {
    startedTouches = NO;  
}

- (void) setStep:(uint)x y:(uint)y withValue:(BOOL)value {
    steps[x + (y * numSteps)] = value;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    /*
    [[UIColor whiteColor] set];
    UIRectFill(rect);
    float rectDim = MIN(self.bounds.size.width, self.bounds.size.height) / numSteps;
    for (uint x = 0; x < numSteps; x += 1) {
        for (uint y = 0; y < numSteps; y += 1) {
            UIBezierPath* roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(CGRectMake(x * rectDim, y * rectDim, rectDim, rectDim), SINE_STEP_PADDING, SINE_STEP_PADDING) cornerRadius:5.];
            [[UIColor blackColor] set];
            [roundedRect stroke];
        }
    }
     */
}
 
- (void) handleTouch:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint translate = [[touches anyObject] locationInView: self];
    float rectDim = MIN(self.bounds.size.width, self.bounds.size.height) / numSteps;
    float x = floorf(translate.x / rectDim);
    float y = floorf(translate.y / rectDim);
    [self registerStep:x y:y];
}
#pragma Touch event handlers
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self registerEnd];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self registerEnd];
}

@end
