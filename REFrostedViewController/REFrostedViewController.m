//
// REFrostedViewController.m
// REFrostedViewController
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "REFrostedViewController.h"
#import "REFrostedContainerViewController.h"
#import "UIImage+REFrostedViewController.h"
#import "UIView+REFrostedViewController.h"
#import "UIViewController+REFrostedViewController.h"
#import "RECommonFunctions.h"

@interface REFrostedViewController ()

@property (assign, readwrite, nonatomic) CGFloat imageViewWidth;
@property (strong, readwrite, nonatomic) UIImage *image;
@property (strong, readwrite, nonatomic) UIImageView *imageView;
@property (assign, readwrite, nonatomic) BOOL visible;
@property (strong, readwrite, nonatomic) REFrostedContainerViewController *containerViewController;
@property (strong, readwrite, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation REFrostedViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.wantsFullScreenLayout = YES;
#pragma clang diagnostic pop
    _panGestureEnabled = YES;
    _animationDuration = 0.35f;
    _blurTintColor = REUIKitIsFlatMode() ? nil : [UIColor colorWithWhite:1 alpha:0.75f];
    _blurSaturationDeltaFactor = 1.8f;
    _blurRadius = 10.0f;
    _containerViewController = [[REFrostedContainerViewController alloc] init];
    _containerViewController.frostedViewController = self;
    _minimumMenuViewSize = CGSizeZero;
    _liveBlur = REUIKitIsFlatMode();
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:_containerViewController action:@selector(panGestureRecognized:)];
}

- (id)initWithContentViewController:(UIViewController *)contentViewController menuViewController:(UIViewController *)menuViewController
{
    self = [self init];
    if (self) {
        _contentViewController = contentViewController;
        _menuViewController = menuViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self re_displayController:self.contentViewController frame:self.view.frame];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.contentViewController beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.contentViewController endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.contentViewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.contentViewController endAppearanceTransition];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.contentViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.contentViewController;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    _contentViewController = contentViewController;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    if (!_menuViewController) {
        _menuViewController = menuViewController;
        return;
    }
    CGRect frame = _menuViewController.view.frame;
    [_menuViewController willMoveToParentViewController:nil];
    [_menuViewController removeFromParentViewController];
     [_menuViewController.view removeFromSuperview];
    _menuViewController = menuViewController;
    if (!_menuViewController)
        return;
    
    [self.containerViewController addChildViewController:menuViewController];
    menuViewController.view.frame = frame;
    [self.containerViewController.containerView addSubview:menuViewController.view];
    [menuViewController didMoveToParentViewController:self];
}

#pragma mark -

- (void)presentMenuViewController
{
    [self presentMenuViewControllerWithAnimatedApperance:YES];
}

- (void)presentMenuViewControllerWithAnimatedApperance:(BOOL)animateApperance
{
    if ([self.delegate conformsToProtocol:@protocol(REFrostedViewControllerDelegate)] && [self.delegate respondsToSelector:@selector(frostedViewController:willShowMenuViewController:)]) {
        [self.delegate frostedViewController:self willShowMenuViewController:self.menuViewController];
    }
    
    self.containerViewController.animateApperance = animateApperance;
    if (CGSizeEqualToSize(self.minimumMenuViewSize, CGSizeZero)) {
        if (self.direction == REFrostedViewControllerDirectionLeft || self.direction == REFrostedViewControllerDirectionRight)
            self.minimumMenuViewSize = CGSizeMake(self.contentViewController.view.frame.size.width - 50.0f, self.contentViewController.view.frame.size.height);
        
        if (self.direction == REFrostedViewControllerDirectionTop || self.direction == REFrostedViewControllerDirectionBottom)
            self.minimumMenuViewSize = CGSizeMake(self.contentViewController.view.frame.size.width, self.contentViewController.view.frame.size.height - 50.0f);
    }
    
    if (!self.liveBlur) {
        if (REUIKitIsFlatMode() && !self.blurTintColor) {
            self.blurTintColor = [UIColor colorWithWhite:1 alpha:0.75f];
        }
        self.containerViewController.screenshotImage = [[self.contentViewController.view re_screenshot] re_applyBlurWithRadius:self.blurRadius tintColor:self.blurTintColor saturationDeltaFactor:self.blurSaturationDeltaFactor maskImage:nil];
    }
        
    [self re_displayController:self.containerViewController frame:self.contentViewController.view.frame];
    self.visible = YES;
}

- (void)hideMenuViewController
{
    if (!self.liveBlur) {
        self.containerViewController.screenshotImage = [[self.contentViewController.view re_screenshot] re_applyBlurWithRadius:self.blurRadius tintColor:self.blurTintColor saturationDeltaFactor:self.blurSaturationDeltaFactor maskImage:nil];
        [self.containerViewController refreshBackgroundImage];
    }
    [self.containerViewController hide];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    if ([self.delegate conformsToProtocol:@protocol(REFrostedViewControllerDelegate)] && [self.delegate respondsToSelector:@selector(frostedViewController:didRecognizePanGesture:)])
        [self.delegate frostedViewController:self didRecognizePanGesture:recognizer];
    
    if (!self.panGestureEnabled)
        return;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self presentMenuViewControllerWithAnimatedApperance:NO];
    }
    
    [self.containerViewController panGestureRecognized:recognizer];
}

#pragma mark -
#pragma mark Rotation handler

- (BOOL)shouldAutorotate
{
    return self.contentViewController.shouldAutorotate;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (self.visible) {
        if (self.direction == REFrostedViewControllerDirectionLeft || self.direction == REFrostedViewControllerDirectionRight)
            self.minimumMenuViewSize = CGSizeMake(self.view.bounds.size.width - 50.0f, self.view.bounds.size.height);
        
        if (self.direction == REFrostedViewControllerDirectionTop || self.direction == REFrostedViewControllerDirectionBottom)
            self.minimumMenuViewSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height - 50.0f);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (!self.visible) {
        self.minimumMenuViewSize = CGSizeZero;
    }
}

@end
