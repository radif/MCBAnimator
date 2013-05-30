//
//  MCBAnimator.m
//  KJVBible
//
//  Created by Radif Sharafullin on 2/20/13.
//  Copyright (c) 2013 Mocobits. All rights reserved.
//

#import "MCBAnimator.h"
#import <QuartzCore/QuartzCore.h>

#define RAD2DEG(X) ((X)*180.0f/M_PI)
#define DEG2RAD(X) ((X)*M_PI/180.0f)
#define ccp(x,y) CGPointMake(x,y)

const float MCBNotFound = -9283560;
static float _MCBAnimatoriPhoneScaleRatio=480.f/1024.f;

struct MCBAnimatorPositions;

inline void MCBAnimatorPositionsCreate(struct MCBAnimatorPositions * pos, const int numberOfFrames);
inline void MCBAnimatorPositionsFree(const struct MCBAnimatorPositions * pos);

struct MCBAnimatorPositions {
    NSInteger numberOfFrames;
    float * positionsY;
	float * positionsX;
    float * scalesX;
	float * scalesY;
    float * rotations;
	float * opacities;
    unsigned lastPositionsFrame;
    unsigned lastScalesFrame;
    unsigned lastRotationsFrame;
    unsigned lastOpacitiesFrame;
};

void MCBAnimatorPositionsCreate(struct MCBAnimatorPositions * pos, const int numberOfFrames){
    pos->numberOfFrames=numberOfFrames;
    pos->positionsX=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->positionsY=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->scalesX=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->scalesY=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->rotations=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->opacities=(float *)malloc(numberOfFrames * sizeof(float *));
    pos->lastPositionsFrame=0;
    pos->lastScalesFrame=0;
    pos->lastRotationsFrame=0;
    pos->lastOpacitiesFrame=0;
}

void MCBAnimatorPositionsFree(const struct MCBAnimatorPositions * pos){
    free(pos->positionsX);
    free(pos->positionsY);
    free(pos->scalesX);
    free(pos->scalesY);
    free(pos->rotations);
    free(pos->opacities);
}

@implementation MCBAnimator{
    __strong MCBAnimator * _strongSelf;
    __strong UIView * _view;
    __strong MCBAnimatorCompletedBlock _completion;
    double _frameNumber;
    float _fps;
    CFAbsoluteTime _prevFrameDate;
    NSInteger _prevFrameNumber;
    struct MCBAnimatorPositions _positions;
    BOOL _doneCalled, _animationIsPlaying;
    BOOL _viewUserInteractionEnabled;
}

+(void)initialize{
    if ([self class]==[MCBAnimator class])
        [self restoreDeviceSpecificAnimationScale];
}

+(void)setAnimationScale:(float)scale{
    _MCBAnimatoriPhoneScaleRatio=scale;
}
+(void)restoreDeviceSpecificAnimationScale{
    _MCBAnimatoriPhoneScaleRatio=[[UIScreen mainScreen] bounds].size.height/1024.f;
}
#pragma mark initialization
+(__weak MCBAnimator*)animateView:(UIView *)view withAnimationDataPath:(NSString *)animationDataPath completion:(MCBAnimatorCompletedBlock)completion{
    MCBAnimator*a=[[self class] new];
    __weak MCBAnimator*weakA=a;
    [a animateView:view withAnimationDataPath:animationDataPath completion:completion];
    return weakA;
}

-(void)animateView:(UIView *)view withAnimationDataPath:(NSString *)animationDataPath completion:(MCBAnimatorCompletedBlock)completion{
    _strongSelf=self;
    _view=view;
    _viewUserInteractionEnabled=_view.userInteractionEnabled;
    _view.userInteractionEnabled=FALSE;
    _completion=[completion copy];
    dispatch_queue_t q = dispatch_queue_create("com.mocobits.MCBAnimator.parse_and_update", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(q, ^{
        NSDictionary * data=[NSDictionary dictionaryWithContentsOfFile:animationDataPath];
        [_strongSelf parseData:data];
        [_strongSelf tickAnimation:0];
        [_strongSelf scheduleUpdates];
        
    });
}
-(void)parseData:(NSDictionary *)data{
    
    if (data[@"fps"])
        _fps=[data[@"fps"] floatValue];
    
    
    NSInteger totalFrames=0;
    {
        float __x, __y;
        int __val1, __val2;
        NSInteger checkRelativeLayer, checkNumberOfParentLayers;
        NSInteger layerNumber, relativeLayerNumber;
        CGPoint anchorPoint;
        
        
        NSString *fileContentsA = data[@"data"];
        NSAssert(fileContentsA, @"data not found");
        
        NSScanner *scannerA = [[NSScanner alloc] initWithString:fileContentsA];
        while (![scannerA isAtEnd]) {
            if ([scannerA scanFloat:&__x] && [scannerA scanFloat:&__y] && [scannerA scanInt:&__val1] && [scannerA scanInt:&__val2]) {
                anchorPoint=ccp(__x/_view.frame.size.width, __y/_view.frame.size.height);
                layerNumber = __val1;
                totalFrames = __val2;
                if ([scannerA scanInt:&checkRelativeLayer])
                    relativeLayerNumber = checkRelativeLayer;
                if ([scannerA scanInt:&checkNumberOfParentLayers])
                    relativeLayerNumber = checkNumberOfParentLayers;
                
            }
        }
        
    }
    _prevFrameNumber=-1;
    MCBAnimatorPositionsCreate(&_positions, totalFrames);
    
    {
        CGPoint iPadScreenCenter=ccp(1024*.5f, 768*.5f);
        CGRect screenBound=[[UIScreen mainScreen] bounds];
        CGPoint currentScreenCenter=ccp(screenBound.size.height*.5f, screenBound.size.width*.5f);
        
        NSString *fileContents = data[@"dataP"];
        NSAssert(fileContents, @"data not found");
        
        int     val=0;
        float   x=MCBNotFound;
        float   y=MCBNotFound;
        int     __val=0;
        float   __x=MCBNotFound;
        float   __y=MCBNotFound;
        
        
        NSScanner *__scanner = [[NSScanner alloc] initWithString:fileContents];
        while (![__scanner isAtEnd]) {
            if ([__scanner scanInt:&val] && [__scanner scanFloat:&x] && [__scanner scanFloat:&y]) {
                x-=iPadScreenCenter.x;
                y-=iPadScreenCenter.y;
                x*=_MCBAnimatoriPhoneScaleRatio;
                y*=_MCBAnimatoriPhoneScaleRatio;
                x+=currentScreenCenter.x;
                y+=currentScreenCenter.y;
                
                _positions.positionsX[val]=x;
                _positions.positionsY[val]=y;
                
                for (int v=__val; v<val; ++v) {
                    _positions.positionsX[v]=__x;
                    _positions.positionsY[v]=__y;
                    
                }
                
                __x=_positions.positionsX[val];
                __y=_positions.positionsY[val];
                __val=val+1;
                
            }
        }
        _positions.lastPositionsFrame=__val-1;
        
    }
    {
        NSString *fileContents = data[@"dataS"];
        NSAssert(fileContents, @"data not found");
        
        int     val=0;
        float   x=MCBNotFound;
        float   y=MCBNotFound;
        int     __val=0;
        float   __x=MCBNotFound;
        float   __y=MCBNotFound;
        
        NSScanner *__scanner = [[NSScanner alloc] initWithString:fileContents];
        while (![__scanner isAtEnd]) {
            if ([__scanner scanInt:&val] && [__scanner scanFloat:&x] && [__scanner scanFloat:&y]) {
                _positions.scalesX[val]=x/100.f;
                _positions.scalesY[val]=y/100.f;
                
                for (int v=__val; v<val; ++v) {
                    _positions.scalesX[v]=__x;
                    _positions.scalesY[v]=__y;
                    
                }
                
                __x=_positions.scalesX[val];
                __y=_positions.scalesY[val];
                __val=val+1;
                
            }
        }
        _positions.lastScalesFrame=__val-1;
        
    }
    {
        NSString *fileContents = data[@"dataR"];
        NSAssert(fileContents, @"data not found");
        
        int     val=0;
        float   r=MCBNotFound;
        int     __val=0;
        float   __r=MCBNotFound;
        
        NSScanner *__scanner = [[NSScanner alloc] initWithString:fileContents];
        while (![__scanner isAtEnd])
            if ([__scanner scanInt:&val] && [__scanner scanFloat:&r]){
                _positions.rotations[val]=r;
                for (int v=__val; v<val; ++v)
                    _positions.rotations[v]=__r;
                
                __r=_positions.rotations[val];
                __val=val+1;
                
            }
        _positions.lastRotationsFrame=__val-1;
        
    }
    {
        NSString *fileContents = data[@"dataO"];
        NSAssert(fileContents, @"data not found");
        
        int     val=0;
        float   o=MCBNotFound;
        int     __val=0;
        float   __o=MCBNotFound;
        
        NSScanner *__scanner = [[NSScanner alloc] initWithString:fileContents];
        while (![__scanner isAtEnd])
            if ([__scanner scanInt:&val] && [__scanner scanFloat:&o]){
                _positions.opacities[val]=o/100.f;
                
                for (int v=__val; v<val; ++v)
                    _positions.opacities[v]=__o;
                
                __o=_positions.opacities[val];
                __val=val+1;
                
            }
        _positions.lastOpacitiesFrame=__val-1;
        
        
    }
}
#pragma mark updates
-(void)update{
    CFAbsoluteTime now=CFAbsoluteTimeGetCurrent();
    CFTimeInterval deltaTime=_prevFrameDate==0?0:now-_prevFrameDate;
    _frameNumber+=deltaTime*_fps;
    _prevFrameDate=now;
    [self tickAnimation:_frameNumber];
}
-(void)tickAnimation:(const int)frameNumber{
    if (_prevFrameNumber==frameNumber)
        return;
    _prevFrameNumber=frameNumber;
    
    CALayer *l=_view.layer;
    
    
    if (frameNumber < _positions.numberOfFrames) {
        
        const unsigned positionsAnimationFrame=frameNumber>_positions.lastPositionsFrame?_positions.lastPositionsFrame:frameNumber;
        const unsigned scalesAnimationFrame=frameNumber>_positions.lastScalesFrame?_positions.lastScalesFrame:frameNumber;
        const unsigned rotationsAnimationFrame=frameNumber>_positions.lastRotationsFrame?_positions.lastRotationsFrame:frameNumber;
        const unsigned opacitiesAnimationFrame=frameNumber>_positions.lastOpacitiesFrame?_positions.lastOpacitiesFrame:frameNumber;
        
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        if (_positions.positionsX[positionsAnimationFrame] != MCBNotFound && _positions.positionsY[positionsAnimationFrame] != MCBNotFound)
            l.position = ccp(_positions.positionsX[positionsAnimationFrame], _positions.positionsY[positionsAnimationFrame]);
        
        CATransform3D t=CATransform3DIdentity;
        BOOL transformTouched=FALSE;
        if (_positions.scalesX[scalesAnimationFrame] != MCBNotFound && _positions.scalesY[scalesAnimationFrame] != MCBNotFound) {
            t=CATransform3DScale(t, _positions.scalesX[scalesAnimationFrame], _positions.scalesY[scalesAnimationFrame], 1);
            transformTouched=TRUE;
        }
        
        if (_positions.rotations[rotationsAnimationFrame] != MCBNotFound) {
            t=CATransform3DRotate(t,DEG2RAD(_positions.rotations[rotationsAnimationFrame]), 0, 0, 1);
            transformTouched=TRUE;
        }
        if (transformTouched)
            l.transform=t;
        
        if(_positions.opacities[opacitiesAnimationFrame] != MCBNotFound)
            l.opacity = _positions.opacities[opacitiesAnimationFrame];
        
        [CATransaction commit];
        
        
        
        
    }else{
        
        //exit
        if (frameNumber>=_positions.numberOfFrames){
            _animationIsPlaying=FALSE;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_strongSelf done:TRUE];
            });
        }
        
    }
    
}
-(void)stop{
    @synchronized (self){
        if (_animationIsPlaying)
            [self done:FALSE];
    }
    
}
-(void)done:(BOOL)completed{
    if (_doneCalled)
        return;
    _doneCalled=TRUE;
    [self unscheduleUpdates];
    [self unregisterNotifications];
    @synchronized (self){
        [self tickAnimation:_positions.numberOfFrames-1];
    }
    _view.userInteractionEnabled=_viewUserInteractionEnabled;
    if (_completion)
        _completion(completed);
    MCBAnimatorPositionsFree(&_positions);
    _strongSelf=nil;
}
-(void)scheduleUpdates{
    @synchronized (self){
        _animationIsPlaying=TRUE;
    }
    
    while (_animationIsPlaying) {
        [self update];
        [NSThread sleepForTimeInterval:1./60.f];
    }
}
-(void)unscheduleUpdates{
    @synchronized (self){
        _animationIsPlaying=FALSE;
    }
}
#pragma mark app lifecycle

-(void)onEnterBackground{
    @synchronized(self){
        if (_doneCalled)
            return;
        if (_animationIsPlaying) {
            [self unscheduleUpdates];
            [self done:FALSE];
        }
    }
}

-(void)onRestoreFromBackground{
    @synchronized(self){
        _prevFrameDate=0;
        _prevFrameNumber=-1;
    }
}
-(void)registerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(onRestoreFromBackground) name: UIApplicationWillEnterForegroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(onEnterBackground) name: UIApplicationDidEnterBackgroundNotification object: nil];
}
-(void)unregisterNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark lifecycle
-(id)init{
    self=[super init];
    if (self) {
        _fps=24.f;
        _frameNumber=0;
        _prevFrameDate=0;
        _prevFrameNumber=-1;
        [self registerNotifications];
        _doneCalled=FALSE;
        _animationIsPlaying=FALSE;
    }
    return self;
}

-(void)dealloc{
    if (!_doneCalled)
        [self done:FALSE];
#if defined DEBUG && DEBUG==1
    NSLog(@"[%@ %@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
}

@end