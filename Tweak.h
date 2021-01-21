@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPContainerViewController : UIViewController
-(PGPictureInPictureViewController *)pictureInPictureViewController;
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)setupBorder;
-(void)loadView;
@end