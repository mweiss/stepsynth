//
//  SineStepBoxView.h
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SineStepBoxView : UIView{
@public
    uint x;
    uint y;
}
@property (nonatomic, retain) UIColor *color;
- (id)initWithFrame:(CGRect)frame x:(uint)xval y:(uint)yval;
@end
