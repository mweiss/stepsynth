//
//  ViewController.m
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SineStepViewController.h"
#import "SineStepView.h"
#import "CircleSelectView.h"

#import <AudioToolbox/AudioToolbox.h>

#define CIRCLE_SELECT_VIEW_PADDING 20
OSStatus RenderTone(
                    void *inRefCon, 
                    AudioUnitRenderActionFlags 	*ioActionFlags, 
                    const AudioTimeStamp 		*inTimeStamp, 
                    UInt32 						inBusNumber, 
                    UInt32 						inNumberFrames, 
                    AudioBufferList 			*ioData)

{
	// Fixed amplitude is good enough for our purposes
	// Get the tone parameters out of the view controller
	SineStepViewController *viewController = (SineStepViewController *)inRefCon;
	double theta = viewController->theta;
    double* frequencies = viewController->frequencies;
    // TODO: replace
	double theta_increment = 2.0 * M_PI / viewController->sampleRate;
    
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
    UInt32 frameToSwitch = floor( (60. *  viewController->sampleRate) / (viewController->bpm));
    UInt32 totalNumFrames = inNumberFrames + viewController->totalFrames;
    UInt32 totalFrames = viewController->totalFrames;
    UInt32 numSteps = viewController->numSteps;
    BOOL* steps = viewController->steps;
    UInt32 lastX = (totalFrames / frameToSwitch) % numSteps;
    viewController.sineStepView->bpm = viewController->bpm;
	// Generate the samples
	for (UInt32 frame = viewController->totalFrames; frame < totalNumFrames; frame++) 
	{
        UInt32 x = (frame / frameToSwitch) % numSteps;
        if (lastX != x) {
            dispatch_async(dispatch_get_main_queue(), 
                           ^{
                               [viewController.sineStepView animateStep:x];
                           });
        }
        Float32 bufferValue = 0;
        for (uint y = 0; y < numSteps; y += 1) {
            BOOL step = steps[x + (y * numSteps)];
            // NSLog(@"%i", step);
            bufferValue += ((Float32)step) * (sin(theta * frequencies[y])) * (1. / 16.);
        }
		buffer[frame - totalFrames] = bufferValue;
		theta += theta_increment;
        lastX = x;
	}
	
	// Store the theta back in the view controller
	viewController->theta = theta;
    viewController->totalFrames = totalNumFrames;
	return noErr;
}

@interface SineStepViewController () {
}
@end

@implementation SineStepViewController

@synthesize sineStepView;
- (void)viewDidLoad
{
    theta = 0;
    totalFrames = 0;
    sampleRate = 44100;
    bpm = 200;
    
    [super viewDidLoad];
    
    float m = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    SineStepView *view = [[SineStepView alloc] initWithFrame:CGRectMake(0, 0, m, m)];
    [self setSineStepView:view];
    numSteps = view->numSteps;
    frequencies = malloc(sizeof(double) * numSteps);
    const float pentatonic[5] = {0, 2, 4, 7, 9};
    float a = pow(2, 1. / 12.);
    for (uint i = 0; i < numSteps; i += 1) {
        frequencies[i] = 440. * pow(a, floor((i / 5) * 12 + pentatonic[i % 5] - 12));
    }
    steps = view->steps;
    [self.view setBackgroundColor:[UIColor blackColor]];
    float otherMin = MIN(self.view.bounds.size.height - m,  m);
    CircleSelectView *csView = [[CircleSelectView alloc] initWithFrame:CGRectMake(CIRCLE_SELECT_VIEW_PADDING, m + CIRCLE_SELECT_VIEW_PADDING, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2))];
    csView->totalNumIndexes = 5;
    [self.view addSubview:view];
    [self.view addSubview:csView];
    [self.view setNeedsDisplay];
    [self createToneUnit];
    // Stop changing parameters on the unit
    OSErr err = AudioUnitInitialize(toneUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
    
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %ld", err);

    // 
}

- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %ld", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = self;
	err = AudioUnitSetProperty(toneUnit, 
                               kAudioUnitProperty_SetRenderCallback, 
                               kAudioUnitScope_Input,
                               0, 
                               &input, 
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %ld", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;	
	streamFormat.mBytesPerFrame = four_bytes_per_float;		
	streamFormat.mChannelsPerFrame = 1;	
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
