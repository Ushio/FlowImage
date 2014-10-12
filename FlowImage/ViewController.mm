//
//  ViewController.m
//  FlowImage
//
//  Created by ushiostarfish on 2014/09/07.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "ViewController.h"

// Objective-C
#import <Social/Social.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FIKBrashView.h"

#import "UFIImageCollectionViewCell.h"
#import "MetalView.h"
#import "FluidEngine.hpp"

// C++
#include <memory>
#include <vector>

#include "CppHelper.hpp"

namespace {
    NSString *const kImageCellIdentifier = @"ImageCell";
    
    const int kImageCount = 12;
    
    inline NSString *imagePathAtIndex(int imageIndex)
    {
        NSString *name = [NSString stringWithFormat:@"%02d.png", imageIndex];
        return [[NSBundle mainBundle] pathForResource:name ofType:nil];
    }
    

}


@implementation ViewController
{
    IBOutlet UIView *_metalPlaceholderView;
    
    IBOutlet UISlider *_brashSlider;
    IBOutlet FIKBrashView *_brashView;
    IBOutlet UICollectionView *_imageCollectionView;
    IBOutlet UICollectionViewFlowLayout *_imageCollectionViewFlowLayout;
    
    std::vector<cpp_helper::cf_shared_ptr<CGImageRef>> _sampleImages;
    
    MetalView *_metalView;
    FluidEngine *_fluidEngine;
    NSTimer *_timer;
    
    CGPoint _previousTouch;
    
    // image picker
    UIPopoverController *_popoverController;
    
    // document interaction
    UIDocumentInteractionController *_documentInteractionController;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.bounds = CGRectMake(0, 0, 320.0, 480.0);
    
    [self fetchBrashSizeRatio];
    
    _sampleImages.reserve(kImageCount);
    for(int i = 0 ; i < kImageCount ; ++i)
    {
        auto image = cpp_helper::cgImageRasterize(cpp_helper::cgImageAtPath(imagePathAtIndex(i)));
        _sampleImages.push_back(image);
    }
    
    UINib *nib = [UINib nibWithNibName:@"UFIImageCollectionViewCell" bundle:nil];
    [_imageCollectionView registerNib:nib forCellWithReuseIdentifier:kImageCellIdentifier];
    
    _imageCollectionView.delegate = self;
    _imageCollectionView.dataSource = self;
    [_imageCollectionView reloadData];
    
    
    // create metal view dynamic
    _metalView = [[MetalView alloc] init];
    _metalView.translatesAutoresizingMaskIntoConstraints = NO;
    [_metalPlaceholderView addSubview:_metalView];
    
    // タッチ
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [_metalView addGestureRecognizer:pan];
    
    
    MetalView *metalView = _metalView;
    NSDictionary *views = NSDictionaryOfVariableBindings(metalView);
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[metalView]-0-|"
                                                                    options:NSLayoutFormatAlignAllCenterX
                                                                    metrics:nil
                                                                      views:views];
    
    [self.view addConstraints:vConstraints];
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[metalView]-0-|"
                                                                    options:NSLayoutFormatAlignAllCenterX
                                                                    metrics:nil
                                                                      views:views];
    [self.view addConstraints:hConstraints];
    
    _timer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(update:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)update:(CADisplayLink *)sender
{
    [_fluidEngine update60fps];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    double size = std::max((int)_imageCollectionView.bounds.size.height - 10, 0);
    _imageCollectionViewFlowLayout.itemSize = CGSizeMake(size, size);
    
    CGSize metalViewSize = _metalView.bounds.size;
    if(metalViewSize.width >= 1 && metalViewSize.height >= 1)
    {
        if(_fluidEngine == nil)
        {
            _fluidEngine = [[FluidEngine alloc] initWithMetalView:_metalView];
            [_fluidEngine storeImage320x320:_sampleImages[0]];
            [self fetchBrashSizeRatio];
        }
    }
}
- (void)didPan:(UIPanGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:_metalView];
    CGPoint velocity = [sender velocityInView:_metalView];
    
    glm::vec2 force = glm::vec2((float)velocity.x, (float)-velocity.y) * 0.003f;
    glm::vec2 forceSegmentPointA;
    glm::vec2 forceSegmentPointB;
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        forceSegmentPointA = forceSegmentPointB = glm::vec2{
            cpp_helper::remap(location.x, 0, _metalView.bounds.size.width, 0, kFluidSize),
            cpp_helper::remap(location.y, _metalView.bounds.size.height, 0, 0, kFluidSize)
        };
    }
    else if(sender.state == UIGestureRecognizerStateChanged)
    {
        forceSegmentPointA = glm::vec2{
            cpp_helper::remap(_previousTouch.x, 0, _metalView.bounds.size.width, 0, kFluidSize),
            cpp_helper::remap(_previousTouch.y, _metalView.bounds.size.height, 0, 0, kFluidSize)
        };
        forceSegmentPointB = glm::vec2{
            cpp_helper::remap(location.x, 0, _metalView.bounds.size.width, 0, kFluidSize),
            cpp_helper::remap(location.y, _metalView.bounds.size.height, 0, 0, kFluidSize)
        };
    }
    else if(sender.state == UIGestureRecognizerStateEnded)
    {
        force = glm::vec2(0, 0);
    }
    _previousTouch = location;
    
    _fluidEngine.forceSegmentPointA = forceSegmentPointA;
    _fluidEngine.forceSegmentPointB = forceSegmentPointB;
    _fluidEngine.force = force;
}

- (IBAction)didChangeBrashSlider:(UISlider *)sender
{
    [self fetchBrashSizeRatio];
}
- (void)fetchBrashSizeRatio
{
    _brashView.brashSizeRatio = _brashSlider.value;
    _fluidEngine.pen = _brashSlider.value;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_fluidEngine storeImage320x320:_sampleImages[indexPath.row]];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _sampleImages.size();
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UFIImageCollectionViewCell *cell = [_imageCollectionView dequeueReusableCellWithReuseIdentifier:kImageCellIdentifier
                                                                                       forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithCGImage:_sampleImages[indexPath.row].get()];
    return cell;
}
- (IBAction)didSelectedImport:(UIButton *)sender
{
    CGRect srcRect = [sender convertRect:sender.bounds toView:self.view];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"text_5", @"入力")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    auto showImagePicker = ^(UIImagePickerControllerSourceType type)
    {
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.sourceType = type;
        ipc.mediaTypes = @[(__bridge id)kUTTypeImage];
        ipc.allowsEditing = YES;
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _popoverController = [[UIPopoverController alloc] initWithContentViewController:ipc];
            [_popoverController presentPopoverFromRect:srcRect
                                                inView:self.view
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        }
        else
        {
            [self presentViewController:ipc animated:YES completion:^{}];
        }
    };
    showImagePicker = [showImagePicker copy];
    
    // addActionした順に左から右にボタンが配置されます
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text_6", @"写真から選ぶ") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        showImagePicker(UIImagePickerControllerSourceTypePhotoLibrary);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text7", @"カメラで撮る") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        showImagePicker(UIImagePickerControllerSourceTypeCamera);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text_4", @"キャンセル") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    alertController.popoverPresentationController.sourceView = sender;
    alertController.popoverPresentationController.sourceRect = sender.bounds;
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if(image == nil)
    {
        return;
    }
    
    [_fluidEngine storeImage320x320:cpp_helper::cgImageFit320x320(cpp_helper::cgImageToSmartPtr(image.CGImage))];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (IBAction)didSelectedTwitter:(id)sender
{
    auto image = [_fluidEngine loadImage320x320];
    
    SLComposeViewController *slViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [slViewController addImage:[UIImage imageWithCGImage:image.get()]];
    slViewController.completionHandler = ^(SLComposeViewControllerResult result)
    {
        
    };
    [self presentViewController:slViewController animated:YES completion:^{}];
}
- (IBAction)didSelectedFacebook:(id)sender
{
    auto image = [_fluidEngine loadImage320x320];
    
    SLComposeViewController *slViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [slViewController addImage:[UIImage imageWithCGImage:image.get()]];
    slViewController.completionHandler = ^(SLComposeViewControllerResult result)
    {
        
    };
    [self presentViewController:slViewController animated:YES completion:^{}];
}
- (IBAction)didSelectedExport:(UIButton *)sender
{
    CGRect srcRect = [sender convertRect:sender.bounds toView:self.view];
    
    auto image = [_fluidEngine loadImage320x320];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"text_1", @"出力")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text_2", @"写真として保存") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithCGImage:image.get()], nil, nil, nil);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text3", @"他のアプリに送る") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSData *png = UIImagePNGRepresentation([UIImage imageWithCGImage:image.get()]);
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.png"];
        [png writeToFile:tmpPath atomically:YES];
        _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tmpPath]];
        _documentInteractionController.UTI = @"public.png";
        _documentInteractionController.delegate = self;
        [_documentInteractionController presentOpenInMenuFromRect:srcRect inView:self.view animated:YES];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"text_4", @"キャンセル") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    alertController.popoverPresentationController.sourceView = sender;
    alertController.popoverPresentationController.sourceRect = sender.bounds;
    
    [self presentViewController:alertController animated:YES completion:nil];
}
- (BOOL)shouldAutorotate
{
    if([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)
    {
        return NO;
    }
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
@end
