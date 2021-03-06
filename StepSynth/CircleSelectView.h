//
//  CircleSelectView.h
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleSelectView : UIView {
@public
    uint selectedIndex;
    uint totalNumIndexes;
    SEL selector;
}
@property (nonatomic, retain) id delegate;
@end
