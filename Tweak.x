#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Tweak.h"


// How this tweak works

// Originally, the PiP view is snapped to edges using NSLayoutConstraint.
// NSLayoutConstraint is difficult to hook because it is managed as an Ivar.
// Therefore, this tweak uses CGAffineTransform to unsnap it.
// It's not a pretty fix and there must be a better way.
// If you know a beautiful fix, please let me know.

// iOS 13 - Tested on iX, iOS 13.7
// iOS 14 - Tested on Simulator (not on real devices)


// Ref: https://stackoverflow.com/questions/36763415/how-would-you-presentviewcontroller-from-subview (This is kind of a hacky way though...)
#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
    })
// End Ref


static BOOL locked = NO;

static UIView *getContentView(SBPIPContainerViewController *self) {
    if ([self respondsToSelector:@selector(pictureInPictureViewController)])
        return self.pictureInPictureViewController.view;
    return self.contentViewController.view;
}

%hook SBPIPContainerViewController
-(void)loadView {
    %orig;

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [getContentView(self) addGestureRecognizer:longPressGesture];
    [self setupBorder];
}

// iOS13
-(void)_handlePanGesture: (UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        // Change the position of the view using CGAffineTransform
        CGPoint translation = [sender translationInView:self.pictureInPictureViewController.view];
        self.pictureInPictureViewController.view.transform = CGAffineTransformTranslate(self.pictureInPictureViewController.view.transform, translation.x, translation.y);
        [sender setTranslation:CGPointZero inView: self.pictureInPictureViewController.view];
    }
}
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        // Change the scale of the view using CGAffineTransform
        self.pictureInPictureViewController.view.transform = CGAffineTransformScale(self.pictureInPictureViewController.view.transform, sender.scale, sender.scale);
        sender.scale = 1.0;
    }
}
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    // Rotation gesture do nothing (at least as far as I've tried)
    // Prevent updating layout by rotation gesture
    if(locked) %orig;
}
-(void)setContentViewPadding:(UIEdgeInsets)arg1 animationDuration:(double)arg2 animationOptions:(unsigned long long)arg3 {
    // Prevent updating padding when switching apps
    if(locked) %orig;
}

// iOS14
-(void)setContentViewPadding:(UIEdgeInsets)arg1 {
    // Prevent updating padding when switching apps
    if(!locked) arg1 = UIEdgeInsetsZero;
    %orig(arg1);
}

// New methods for this tweak
%new
-(void)handleLongPressGesture: (UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    locked = !locked; // Revert the value

    [self setupBorder];
}

%new
-(void)setupBorder {
    UIView *view = getContentView(self);
    view.layer.borderWidth = 1.5;

    if(!locked) view.layer.borderColor = [UIColor clearColor].CGColor;
    else view.layer.borderColor = [UIColor redColor].CGColor;
}
%end

static UIView *getTargetView(SBPIPInteractionController *self, UIGestureRecognizer *sender) {
    if ([self respondsToSelector:@selector(targetView)])
        return [self targetView];
    return UIViewParentController(sender.view).view;
}

// iOS14+
// Here is using the same logic as in iOS13, but there seems to be a better way.
%hook SBPIPInteractionController
-(void)handlePanGesture: (UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        // Change the position of the view using CGAffineTransform
        UIView *view = getTargetView(self, sender);

        CGPoint translation = [sender translationInView:view];
        view.transform = CGAffineTransformTranslate(view.transform, translation.x, translation.y);
        [sender setTranslation:CGPointZero inView: view];
    }

}
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        // Change the scale of the view using CGAffineTransform
        UIView *view = getTargetView(self, sender);
        view.transform = CGAffineTransformScale(view.transform, sender.scale, sender.scale);
        sender.scale = 1.0;
    }
}
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    // Rotation gesture do nothing (at least as far as I've tried)
    // Prevent updating layout by rotation gesture
    if(locked) %orig;
}
%end


%ctor {
    // Somehow, ifdef does not work here
    #if TARGET_OS_SIMULATOR
    NSLog(@"freepip - target is simulator");
    #else
    NSLog(@"frepip - target is a real device");
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/jp.soh.freepip.list"]) return; // Prevent initializing the tweak if the tweak is malformed (Extremely easy to bypass it, but the pirate repos like HYI cannot bypass it lol)
    #endif

    %init; // initialize the tweak
}