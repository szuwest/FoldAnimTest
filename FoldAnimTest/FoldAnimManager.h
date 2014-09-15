//
//  FoldAnimation.h
//  EnvelopeAnim
//
//  Created by West Deng on 12-8-29.
//  Copyright (c) 2012年 Xunlei. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef enum {
    kAnimationFlipVertical,  //从上下往中间折叠
    kAnimationFlipHorizontal, //从左右向中间折叠
} AnimationType;

@protocol FoldAnimationDelegate ;

/**
 该动画主要包含两部分动画:view折叠动画 和 发送折叠后的view的动画
 
 当设备处于竖向放置时,view折叠动画是 先从顶部往中间折叠,然后从底部向中间折叠,
 当设备处于横向时,先从右部向中间折叠,然后从左部向中间折叠
 
 发送动画是用了苹果系统的一个私有API(该动画效果已经被网上很多人使用,应该没有太大问题)
 该动画默认是在整个折叠动画结束后开始.动画效果是 将折叠后的视图往它的父视图的左上角发送出去
 **/

@interface FoldAnimManager : NSObject

//从上往下折叠还是从左往右折叠,默认是从上往下
@property (nonatomic)AnimationType animationType;

//当视图被折叠起来后是否接着自动发送,默认为真
@property (nonatomic)BOOL autoSend;


//当没有设置下面的背部视图或者图像时,默认时白色
@property (retain, nonatomic)UIView* middleBgView;
@property (retain, nonatomic)UIView* topBgView;
@property (retain, nonatomic)UIView* bottomBgView;


//动画结束时的delegate
@property (nonatomic, assign)id<FoldAnimationDelegate> delegate;
//折叠动画时间,默认0.4
@property (nonatomic) NSTimeInterval foldDuation;
//折叠后翻转动画时间,默认是0.5
@property (nonatomic) NSTimeInterval rotaeDuation;
//翻转后缩小动画,默认时间世是1.0
@property (nonatomic) NSTimeInterval scaleDuation;
//缩小后发送动画时间,默认世0.5
@property (nonatomic) NSTimeInterval sendDuation;

//contentView 必须要有父view,否则无法实现动画
//contentView的父view的frame最好是占满整个屏幕,这样发送动画的效果才会好
- (BOOL)setFoldView:(UIView *)contentView;
//该方法的调用须在setFoldView:之后调用
- (BOOL)startFoldAnim;

//将折叠后的纸发送出去的动画,该动画默认会在视图被折叠起来后调用
//autoSend为假时,该方法不会被调用,用户在需要的时候自己手动调用
- (void)sendPaperAnim;


//重设动画,还原到未设动画的初始状态.该方法会在所有动画结束之后自动被调用.
//一般来说用户不需要自己调用
- (void)reset;

@end

@protocol FoldAnimationDelegate <NSObject>

@optional
//当视图折叠动画完后该方法被调用
- (void)foldViewAnimDidStop:(FoldAnimManager *)foldAnimManager;
//当视图发送动画完成后该方法被调用
- (void)sendViewAnimDidStop:(FoldAnimManager *)foldAnimManager;

@end