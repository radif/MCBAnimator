MCBAnimator
===========

UIKit animation with block interface that draws the animation data from the file

	[MCBAnimator animateView: self.view
	        withAnimationDataPath: [[NSBundle mainBundle] pathForResource:@"appear_transition" ofType:@"data"]
	                   completion: ^(BOOL finished) {
	                       NSlog(@"completed");
	                   }];