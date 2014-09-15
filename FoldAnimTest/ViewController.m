//
//  ViewController.m
//  FoldAnimTest
//
//  Created by West Deng on 12-8-29.
//  Copyright (c) 2012年 Xunlei. All rights reserved.
//

#import "ViewController.h"
#import "FoldAnimManager.h"

@implementation ViewController
@synthesize topBgView;
@synthesize bottomView;
@synthesize middleBgView;
@synthesize msgTextView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    foldAnimManager = [[FoldAnimManager alloc] init];
//    foldAnimManager.topBgView = topBgView;
//    foldAnimManager.bottomBgView = bottomView;
//    foldAnimManager.middleBgView = middleBgView;
    topBgView.hidden = YES;
    bottomView.hidden = YES;
    middleBgView.hidden = YES;
    msgTextView.editable = NO;
}

- (void)viewDidUnload
{
    [self setMsgTextView:nil];
    [self setTopBgView:nil];
    [self setBottomView:nil];
    [self setMiddleBgView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)start:(id)sender {
    [foldAnimManager setFoldView:msgTextView];
    [foldAnimManager startFoldAnim];
}

- (void)dealloc {
    [msgTextView release];
    [middleBgView release];
    [bottomView release];
    [middleBgView release];
    [super dealloc];
}
@end
