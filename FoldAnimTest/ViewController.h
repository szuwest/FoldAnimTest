//
//  ViewController.h
//  FoldAnimTest
//
//  Created by West Deng on 12-8-29.
//  Copyright (c) 2012年 Xunlei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FoldAnimManager;

@interface ViewController : UIViewController{
    FoldAnimManager* foldAnimManager;
}

@property (retain, nonatomic) IBOutlet UIView *topBgView;
@property (retain, nonatomic) IBOutlet UIView *bottomView;
@property (retain, nonatomic) IBOutlet UIView *middleBgView;
@property (retain, nonatomic) IBOutlet UITextView *msgTextView;
- (IBAction)start:(id)sender;
@end
