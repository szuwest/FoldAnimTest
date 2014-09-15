//
//  FoldAnimation.m
//  EnvelopeAnim
//
//  Created by West Deng on 12-8-29.
//  Copyright (c) 2012年 Xunlei. All rights reserved.
//

#import "FoldAnimManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Screenshot)

- (UIImage*)screenshot
{
    // take screenshot of the view
    //    CGFloat scale = [[UIScreen mainScreen] scale];
    if ([self isKindOfClass:NSClassFromString(@"MKMapView")])
    {
        // if the view is a mapview, screenshot has to take the screen scale into consideration
        // else, the screen shot in retina display devices will be of a less detail map (note, it is not the size of the screenshot, but it is the level of detail of the screenshot 
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    }
    else 
    {
        // for performance consideration, everything else other than mapview will use a lower quality screenshot
        UIGraphicsBeginImageContext(self.bounds.size);
    }
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenshot;
}

@end

#define PERSPECTIVEDEPTH    2000.0f //透视参数,一般在200-2000之间,可正负值
//#define ANIM_DURATION       0.5
#define MAX_OPACITY         0.7

@interface FoldAnimManager(){
    
    //存储contentView三段截图的临时变量
    CGImageRef topOrLeftImgRef;
    CGImageRef middleImgRef;
    CGImageRef bottomOrRightImgRef;
    
    BOOL isAnimating;
    
    int animCount;
}
//外部传入的要做折叠动画的视图
@property (retain, nonatomic)UIView* contentView;
//foldViewParentView是contentView替代品,frame跟contentView一样
//contentView三段截图的视图加在它里面, 发送动画是针对它来做的
@property (retain, nonatomic)UIView* foldViewParentView;
//存储contentView三段截图的视图,所有动画都时针对
//
@property (retain, nonatomic)CALayer* foldFrontLayer;
@property (retain, nonatomic)CALayer* foldBackLayer;
@property (retain, nonatomic)CALayer* topLayer;
@property (retain, nonatomic)CALayer* middleLayer;
@property (retain, nonatomic)CALayer* bottomLayer;
@property (retain, nonatomic)UIImage* topBgImg;
@property (retain, nonatomic)UIImage* bottomBgImg;

@property (retain, nonatomic)CALayer* middleBgLayer;

- (void)setTransformProgress:(float)startTransformValue
                            :(float)endTransformValue
                            :(float)duration
                            :(int)aX 
                            :(int)aY 
                            :(int)aZ
                            :(BOOL)setDelegate
                            :(BOOL)removedOnCompletion
                            :(NSString *)fillMode
                            :(CALayer *)targetLayer;

- (void)setOpacityProgress:(float)startOpacityValue
                          :(float)endOpacityValue
                          :(float)beginTime
                          :(float)duration
                          :(NSString *)fillMode
                          :(CALayer *)targetLayer;

@end

@implementation FoldAnimManager

@synthesize animationType;
@synthesize autoSend;

@synthesize contentView;
@synthesize foldViewParentView;

@synthesize delegate;

@synthesize foldFrontLayer;
@synthesize foldBackLayer;
@synthesize topLayer;
@synthesize middleLayer;
@synthesize bottomLayer;
@synthesize middleBgLayer;

@synthesize middleBgView;
@synthesize topBgView;
@synthesize bottomBgView;
@synthesize topBgImg;
@synthesize bottomBgImg;

@synthesize foldDuation;
@synthesize rotaeDuation;
@synthesize sendDuation;
@synthesize scaleDuation;

- (id)init{
    if(self = [super init]){
        autoSend = YES;
        animationType = kAnimationFlipVertical;
        
        foldDuation = 0.4;
        rotaeDuation = 0.5;
        scaleDuation = 1.0;
        sendDuation = 0.5;
    }
    return  self;
}

- (void)dealloc{
    [self reset];
    self.topBgView = nil;
    self.bottomBgView = nil;
    self.middleBgView = nil;

    self.topBgImg = nil;
    self.bottomBgImg = nil;
    
    [super dealloc];
}

- (void)setLayer:(CALayer *)layer withContent:(CGImageRef)imageRef{
    CALayer* imageLayer = [CALayer layer];
    imageLayer.frame = layer.bounds;
    if(imageRef){
        //__bridge关键字用于项目启用了ARC的时候
        //        [imageLayer setContents:(__bridge id)imageRef]; 
        [imageLayer setContents:(id)imageRef];
        
    }else{
        imageLayer.backgroundColor = [[UIColor whiteColor] CGColor];
        imageLayer.doubleSided = YES;
    }
    [layer addSublayer:imageLayer];
    
    //shadow, index=1; above img
    CALayer *shadowLayer = [CALayer layer];
    shadowLayer.frame = layer.bounds;
    shadowLayer.backgroundColor = [[UIColor grayColor] CGColor];
    shadowLayer.opacity = 0.0f;
    shadowLayer.doubleSided = YES;
    [layer addSublayer:shadowLayer];
}


- (void)setViewShot{
    
    UIImage* image = [contentView screenshot];
    CGPoint frontAnchorPoint, backAnchorPoint;
    CGRect frame;
    
    if( animationType == kAnimationFlipVertical) {
        
        backAnchorPoint = CGPointMake(0.5, 0.0);
        frontAnchorPoint = CGPointMake(0.5, 1.0);
        
        if(topBgView)
            frame = CGRectMake(0, 0, topBgView.frame.size.width, topBgView.frame.size.height);
        else
            frame = CGRectMake(0, 0, contentView.frame.size.width, contentView.frame.size.height/3);
        topLayer.frame = frame;
        frame.origin.y = topLayer.frame.origin.y + topLayer.frame.size.height;
        if(topBgView && middleBgView)
            frame.size = middleBgView.frame.size;
        middleLayer.frame = frame;
        frame.origin.y = middleLayer.frame.origin.y + middleLayer.frame.size.height;
        if(bottomBgView)
            frame.size = bottomBgView.frame.size;
        bottomLayer.frame = frame;
        
        if(topBgView)
            topOrLeftImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, topBgView.frame.size.width, topBgView.frame.size.height));
        else
            topOrLeftImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width*image.scale, image.size.height*image.scale/3));
        
        if(topBgView && middleBgView)
            middleImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, topBgView.frame.size.height, middleBgView.frame.size.width, middleBgView.frame.size.height));
        else
            middleImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, image.size.height*image.scale/3, image.size.width*image.scale, image.size.height*image.scale/3));
        
        if(bottomBgView)
            bottomOrRightImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, topBgView.frame.size.height+middleBgView.frame.size.height, bottomBgView.frame.size.width, bottomBgView.frame.size.height));
        else
            bottomOrRightImgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, image.size.height*image.scale*2/3, image.size.width*image.scale, image.size.height*image.scale/3));
    }
    //================topOrLeft layer start=====================
    //content transform layer
    CALayer *flipFrontLayer = [CATransformLayer layer];
    flipFrontLayer.anchorPoint = frontAnchorPoint;
    flipFrontLayer.frame = topLayer.bounds;
    [self setLayer:flipFrontLayer withContent:topOrLeftImgRef];
    
    CALayer *flipBackLayer = [CATransformLayer layer];
    flipBackLayer.anchorPoint = frontAnchorPoint;
    flipBackLayer.frame = topLayer.bounds;
    if( animationType == kAnimationFlipVertical){
        if(topBgView){
            topBgView.hidden = NO;
            self.topBgImg = [topBgView screenshot];
            topBgView.hidden = YES;
        }
        if(topBgImg)
            [self setLayer:flipBackLayer withContent:(topBgImg.CGImage)];
        else
            [self setLayer:flipBackLayer withContent:nil];
    }
        
    
    [topLayer addSublayer:flipBackLayer];
    [topLayer addSublayer:flipFrontLayer];
    //============end=================
    
    [self.middleLayer setContents:(id)middleImgRef];
    middleBgLayer.frame = self.middleLayer.frame;
    if(middleBgView){
        middleBgView.hidden = NO;
        UIImage* infoImg = [middleBgView screenshot];
        middleBgView.hidden = YES;
        [middleBgLayer setContents:(id)infoImg.CGImage];
        CATransform3D endTransform = CATransform3DIdentity;
        endTransform = CATransform3DRotate(endTransform, M_PI, 0, 1, 0);	
        middleBgLayer.transform = endTransform;
        
    }
    else    
        middleBgLayer.backgroundColor = [[UIColor whiteColor] CGColor];
    
    //===========bottomOrRight layer start======================
    CALayer *flipFrontLayer2 = [CATransformLayer layer];
    flipFrontLayer2.anchorPoint = backAnchorPoint;
    flipFrontLayer2.frame = bottomLayer.bounds;
    [self setLayer:flipFrontLayer2 withContent:bottomOrRightImgRef];
    
    
    CALayer *flipBackLayer2 = [CATransformLayer layer];
    flipBackLayer2.anchorPoint = backAnchorPoint;
    flipBackLayer2.frame = bottomLayer.bounds;
    if( animationType == kAnimationFlipVertical){
        if(bottomBgView){
            bottomBgView.hidden = NO;
            self.bottomBgImg = [bottomBgView screenshot];
            bottomBgView.hidden = YES;
        }
        if(bottomBgImg)
            [self setLayer:flipBackLayer2 withContent:bottomBgImg.CGImage];
        else
            [self setLayer:flipBackLayer2 withContent:nil];
    }
        
    
    [bottomLayer addSublayer:flipBackLayer2];
    [bottomLayer addSublayer:flipFrontLayer2];
    //=============end===============
    
    CFRelease(topOrLeftImgRef);
    CFRelease(middleImgRef);
    CFRelease(bottomOrRightImgRef);
}

- (BOOL)setFoldView:(UIView *)_contentView{
    if(!_contentView.superview)
        return NO;
    [self reset];
    self.contentView = _contentView;
    
    foldViewParentView = [[UIView alloc] initWithFrame:contentView.frame];
    foldViewParentView.backgroundColor = [UIColor clearColor];
    [_contentView.superview addSubview:foldViewParentView];
    
    self.foldFrontLayer = [CATransformLayer layer];
    foldFrontLayer.frame = foldViewParentView.bounds;
    
    self.foldBackLayer = [CATransformLayer layer];
    foldBackLayer.frame = foldViewParentView.bounds;
    
    [foldViewParentView.layer addSublayer:foldBackLayer];
    [foldViewParentView.layer addSublayer:foldFrontLayer];
    
    self.topLayer = [CALayer layer];
    self.middleLayer = [CALayer layer];
    self.bottomLayer = [CALayer layer];
    
    [foldFrontLayer addSublayer:middleLayer];
    [foldFrontLayer addSublayer:bottomLayer];

    [foldFrontLayer addSublayer:topLayer];
    
    self.middleBgLayer = [CALayer layer];
    [foldBackLayer addSublayer:middleBgLayer];
    
    [self setViewShot];
    
    contentView.hidden = YES;
    isAnimating = NO;
    return YES;
}

- (void)fromTop2Bottom{
    CALayer* flipLayer = [topLayer.sublayers objectAtIndex:1];
    CALayer* flipBackLayer = [topLayer.sublayers objectAtIndex:0];
    
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = foldDuation;
    anim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, 0, -1, 0, 0)];
    anim.toValue =[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, -M_PI, 1, 0, 0)];
    anim.delegate = self;
    anim.removedOnCompletion = NO;
    
    CATransform3D aTransform2 = CATransform3DIdentity;
    aTransform2.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim2.duration = foldDuation*0.5;
    anim2.fromValue= [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform2, 0, -1, 0, 0)];
    anim2.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform2, M_PI*0.5, -0.5, 0, 0)];
    anim2.delegate = self;
    anim2.removedOnCompletion = NO;
    
    
    [flipLayer addAnimation:anim2 forKey:@"transform2LeftFront"];
    [flipBackLayer addAnimation:anim forKey:@"transform2LeftBack"];
    
//    [self setTransformProgress:0 :-M_PI*0.5 :foldDuation :-1 :0 :0 :YES :NO :kCAFillModeForwards :flipLayer];
//    [self setTransformProgress:0 :-M_PI     :foldDuation :-1 :0 :0 :YES :NO :kCAFillModeForwards :flipBackLayer];
    
    [self setOpacityProgress:0.0 :MAX_OPACITY :0.0 :foldDuation*0.5 :kCAFillModeRemoved :[flipLayer.sublayers objectAtIndex:1]];
    [self setOpacityProgress:MAX_OPACITY :0.0 :foldDuation*0.5 :foldDuation*0.5 :kCAFillModeRemoved :[flipBackLayer.sublayers objectAtIndex:1]];
}

- (void)fromBottom2Top{
    CALayer* flipLayer = [bottomLayer.sublayers objectAtIndex:1];
    CALayer* flipBackLayer = [bottomLayer.sublayers objectAtIndex:0];
    
	[CATransaction begin];
    [CATransaction setAnimationDuration:0.0];
    [CATransaction setDisableActions:YES];
    CATransform3D endTransform = CATransform3DIdentity;
	endTransform = CATransform3DRotate(endTransform, -M_PI, -1.0, 0, 0.0);	
    endTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    
    flipBackLayer.transform = endTransform;
    flipLayer.transform = endTransform;
	[bottomLayer removeAllAnimations];
	bottomLayer.transform = endTransform;
    bottomLayer.sublayerTransform = endTransform;
	[CATransaction commit];
    
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = foldDuation;
    anim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, 0,     1, 0, 0)];
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(  aTransform, M_PI, -1, 0, 0)];
    anim.delegate = self;
    anim.removedOnCompletion = NO;
    
    CATransform3D aTransform2 = CATransform3DIdentity;
    aTransform2.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim2.duration = foldDuation*0.5;
    anim2.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform2, 0,        1.0, 0, 0)];
    anim2.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(  aTransform2, -M_PI*0.5, 0.5, 0, 0)];
    anim2.delegate = self;
    anim2.removedOnCompletion = NO;
    
    [flipLayer addAnimation:anim2 forKey:@"transform2RightFront"];
    [flipBackLayer addAnimation:anim forKey:@"transform2RightBack"];
    
//    [self setTransformProgress:0 :-M_PI*0.5 :foldDuation :1 :0 :0 :YES :NO :kCAFillModeForwards :flipLayer];
//    [self setTransformProgress:0 :-M_PI     :foldDuation :1 :0 :0 :YES :NO :kCAFillModeForwards :flipBackLayer];
    
    [self setOpacityProgress:0.0 :MAX_OPACITY :0.0 :foldDuation*0.5 :kCAFillModeRemoved :[flipLayer.sublayers objectAtIndex:1]];
    [self setOpacityProgress:MAX_OPACITY :0.0 :foldDuation*0.5 :foldDuation*0.5 :kCAFillModeRemoved :[flipBackLayer.sublayers objectAtIndex:1]];
}

- (void)rotateCenter{
    
    //    CATransform3D aTransform = CATransform3DIdentity;
    CATransform3D aTransform = foldFrontLayer.transform;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = rotaeDuation;
    anim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, 0, 0, 1, 0)];
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, M_PI, 0, -1, 0)];
    anim.delegate = self;
    anim.removedOnCompletion = NO;
    
    
    CABasicAnimation* anim2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim2.duration = rotaeDuation*0.5;
    anim2.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, 0, 0, 1, 0)];
    anim2.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, M_PI*0.5, 0, -0.5, 0)];
    anim2.delegate = self;
    anim2.removedOnCompletion = NO;
    
    [foldFrontLayer addAnimation:anim2 forKey:@"centerRotate"];
    [foldBackLayer addAnimation:anim forKey:@"centerRotate"];
    
//    [self setTransformProgress:0 :-M_PI*0.5 :foldDuation :1 :0 :0 :YES :NO :kCAFillModeForwards :foldFrontLayer];
//    [self setTransformProgress:0 :-M_PI     :foldDuation :1 :0 :0 :YES :NO :kCAFillModeForwards :foldBackLayer];
}

- (void)shrink{
    
    CATransform3D aTransform = foldViewParentView.layer.transform;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = scaleDuation;
    //    anim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, 0, 0, 1, 0)];
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DScale(aTransform, 0.9, 0.9, 1)];
    anim.delegate = self;
    anim.removedOnCompletion = NO;
    [foldViewParentView.layer addAnimation:anim forKey:@"shrink"];
    
}

- (BOOL)startFoldAnim{
    if(!foldViewParentView || isAnimating )
        return NO;
    isAnimating = YES;
    if( animationType == kAnimationFlipVertical) {
        [self fromBottom2Top];
    }
    return YES;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag{
    animCount++;
    if(animCount == 1){
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0.0];
        [[bottomLayer.sublayers objectAtIndex:1] setHidden:YES];
        [CATransaction commit];
    }
    else if(animCount == 2){
        if( animationType == kAnimationFlipVertical) {
            [self fromTop2Bottom];
        }
    }
    else if(animCount == 3){
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0];
        [CATransaction setDisableActions:YES];
        [[topLayer.sublayers objectAtIndex:1] setHidden:YES];
        
        [CATransaction commit];
        
    }else if(animCount == 4){
        if (delegate && [delegate respondsToSelector:@selector(foldViewAnimDidStop:)]) {
            [delegate foldViewAnimDidStop:self];
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0];
        [CATransaction setDisableActions:YES];
        CATransform3D endTransform = CATransform3DIdentity;
        endTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
        CALayer* flipLayer;
        CALayer* flipBackLayer;
        endTransform = CATransform3DRotate(endTransform, -M_PI, 1.0, 0.0, 0.0);

        flipLayer = [topLayer.sublayers objectAtIndex:1];
        flipBackLayer = [topLayer.sublayers objectAtIndex:0];
        flipBackLayer.transform = endTransform;
        flipLayer.transform = endTransform;
        [topLayer removeAllAnimations];
        topLayer.transform = endTransform;
        topLayer.sublayerTransform = endTransform;

        foldBackLayer.hidden = YES;
        
        [CATransaction commit];
        
        [self rotateCenter];
        
    }else if(animCount == 5){
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0];
        [CATransaction setDisableActions:YES];
        [foldFrontLayer setHidden:YES];
        foldBackLayer.hidden = NO;
        [CATransaction commit];
        
    }else if(animCount == 6){
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0.0];
        CATransform3D endTransform = foldViewParentView.layer.transform;
        endTransform = CATransform3DRotate(endTransform, -M_PI, 0, 1, 0);	
        endTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
        
        foldFrontLayer.transform = endTransform;
        foldBackLayer.transform = endTransform;
        
        [foldViewParentView.layer removeAllAnimations];
        foldViewParentView.layer.transform = endTransform;
        foldViewParentView.layer.sublayerTransform = endTransform;
        
        [CATransaction commit];
        
        [self shrink];
        
    }else if(animCount == 7){
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0.0];
        CATransform3D endTransform = foldViewParentView.layer.transform;
        endTransform = CATransform3DScale(endTransform, 0.9, 0.9, 1);	
        
        foldViewParentView.layer.transform = endTransform;
        
        [CATransaction commit];
        
        if(autoSend)
            [self sendPaperAnim];
        
    }else if(animCount == 8){
        foldViewParentView.hidden = YES;
        isAnimating = NO;
        [self reset];
        
        if (delegate && [delegate respondsToSelector:@selector(sendViewAnimDidStop:)]) {
            [delegate sendViewAnimDidStop:self];
        }
    }
}

- (void)reset{
    
    contentView.hidden = NO;
    isAnimating = NO;
    [self.foldViewParentView removeFromSuperview];
    self.foldViewParentView = nil;
    self.contentView = nil;
    animCount = 0;
}

- (void)fly2TopRight{
    //    CATransform3D aTransform = CATransform3DIdentity
    CATransform3D aTransform = foldViewParentView.layer.transform;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    
    float tx = -foldViewParentView.frame.size.width*0.6;
    float  ty =  -foldViewParentView.frame.size.height;
    
    CATransform3D ca3d = CATransform3DConcat(CATransform3DRotate(aTransform, M_PI*0.15, 0.01, 0, -1), CATransform3DScale(aTransform, 0.5, 0.5, 1));
    CATransform3D all3d = CATransform3DConcat(ca3d, CATransform3DTranslate(aTransform, tx, ty, 0));
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = sendDuation;
    anim.toValue = [NSValue valueWithCATransform3D:all3d];
    anim.delegate = self;
    anim.timingFunction = UIViewAnimationOptionCurveEaseInOut;
    anim.removedOnCompletion = YES;
    [foldViewParentView.layer addAnimation:anim forKey:@"animationSend"];
}


- (void)sendPaperAnim{
    
    if(foldViewParentView.hidden) return;
    [self fly2TopRight];
}

- (void)setTransformProgress:(float)startTransformValue
                            :(float)endTransformValue
                            :(float)duration
                            :(int)aX 
                            :(int)aY 
                            :(int)aZ
                            :(BOOL)setDelegate
                            :(BOOL)removedOnCompletion
                            :(NSString *)fillMode
                            :(CALayer *)targetLayer
{
    //NSLog(@"transform value %f, %f", startTransformValue, endTransformValue);
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / PERSPECTIVEDEPTH;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = duration;
    anim.fromValue= [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, startTransformValue, aX, aY, aZ)];
    anim.toValue=[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, endTransformValue, aX, aY, aZ)];
    if (setDelegate) {
        anim.delegate = self;
    }
    anim.removedOnCompletion = removedOnCompletion;
    [anim setFillMode:fillMode];
    
    [targetLayer addAnimation:anim forKey:@"transformAnimation"];
}

- (void)setOpacityProgress:(float)startOpacityValue
                          :(float)endOpacityValue
                          :(float)beginTime
                          :(float)duration
                          :(NSString *)fillMode
                          :(CALayer *)targetLayer
{
    //NSLog(@"opacity value %f, %f, %@", startOpacityValue, endOpacityValue, targetLayer);
    //return;
    CFTimeInterval localMediaTime = [targetLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.duration = duration;
    anim.fromValue= [NSNumber numberWithFloat:startOpacityValue];
    anim.toValue= [NSNumber numberWithFloat:endOpacityValue];
    anim.beginTime = localMediaTime+beginTime;
    anim.removedOnCompletion = NO;
    [anim setFillMode:fillMode];
    
    [targetLayer addAnimation:anim forKey:@"opacityAnimation"];
}


@end

