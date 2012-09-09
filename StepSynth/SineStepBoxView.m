//
//  SineStepBoxView.m
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SineStepBoxView.h"
#import "SineStepView.h"

#import <QuartzCore/QuartzCore.h>

@implementation SineStepBoxView
@synthesize color;

- (id)initWithFrame:(CGRect)frame x:(uint)xval y:(uint)yval {
    self = [self initWithFrame:frame];
    if (self) {
        x = xval;
        y = yval;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setOpaque:NO];
        [self setBackgroundColor:[UIColor clearColor]];
        if (self.color == nil) {
            self.color = [UIColor grayColor];
        }
        self.layer.masksToBounds = NO;
        self.layer.shadowRadius = 2;
        self.layer.cornerRadius = 5;
        self.layer.shadowOpacity = 0.6;
        self.layer.borderWidth = 2;
        self.layer.shadowOffset = CGSizeMake(0,0);
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    self.layer.borderColor = [self.color CGColor];
    if ([self getValue]) {
        self.layer.backgroundColor = [self.color CGColor];
        self.layer.shadowColor = [[UIColor whiteColor] CGColor];
    }
    else {
        self.layer.backgroundColor = [[UIColor clearColor] CGColor];
        self.layer.shadowColor = [[UIColor clearColor] CGColor];
    }
}

- (BOOL) getValue {
    return [((SineStepView *)self.superview) getStep:x y:y];
}

@end
