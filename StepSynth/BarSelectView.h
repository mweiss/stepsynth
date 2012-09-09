//
//  BarSelectView.h
//  StepSynth
//
//  Created by Michael Weiss on 9/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BarSelectView : UIView {
@public
    float ratio;
    SEL selector;
}
@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic, retain) UIColor *selectedColor;
@property (nonatomic, retain) id delegate;
@end
