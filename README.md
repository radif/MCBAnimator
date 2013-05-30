MCBAnimator
===========

UIKit animation with block interface that pulls the animation path/data from the file
This allows you to create sophisticated animations on UIViews

	[MCBAnimator animateView: self.view
	        withAnimationDataPath: [[NSBundle mainBundle] pathForResource:@"appear_transition" ofType:@"data"]
	                   completion: ^(BOOL finished) {
	                       NSlog(@"completed");
	                   }];