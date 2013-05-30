//
//  MCBAnimator.h
//  KJVBible
//
//  Created by Radif Sharafullin on 2/20/13.
//  Copyright (c) 2013 Mocobits. All rights reserved.
//

#import <Foundation/Foundation.h>
// Runs animations sourced from data files.
// ------------------------------------------------------------------------------------------------
typedef void (^MCBAnimatorCompletedBlock)(BOOL finished);

//this version doesn't support embedded sound
@interface MCBAnimator : NSObject
//Initiating the animation (multiple simultaneous instances are ok). Each call will return a weak pointer to the animator instance. You can force stop it by calling -(void)stop; The MCBAnimator's object lifetime ends as soon as the animation ends.
+(__weak MCBAnimator*)animateView:(UIView *)view withAnimationDataPath:(NSString *)animationDataPath completion:(MCBAnimatorCompletedBlock)completion;
//stop the animations at a current frame. You need to reset the position values manually if you call it during the animation. A good place to do this is a completion block, which will be called from stop only once the animation already started and not finished yet.
-(void)stop;
//by default is screen.height/1024 For iPad it is 1. If you have iphone specific animations, set it to 1;
+(void)setAnimationScale:(float)scale;
+(void)restoreDeviceSpecificAnimationScale;
@end