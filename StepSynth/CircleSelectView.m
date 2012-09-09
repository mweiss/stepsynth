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

@synthesize borderColor, selectedColor;

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
    // Draw a smaller circle
    
    
    UIBezierPath * innerArc = [UIBezierPath bezierPathWithArcCenter:center radius:radius / 3. startAngle:0 endAngle: 2. * M_PI clockwise:YES];
    
    [[UIColor blackColor] setFill];
    [innerArc fill];
    // Drawing the filled in arc for the selected value
}


@end
