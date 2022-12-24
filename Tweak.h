@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
-(UIView *)targetView; // iOS 15+
@end

@interface SBPIPContainerViewController : UIViewController
-(PGPictureInPictureViewController *)contentViewController; // iOS 15+
-(PGPictureInPictureViewController *)pictureInPictureViewController; // iOS <= 14
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)setupBorder;
-(void)loadView;
@end