//
//  DNImagePickerController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "DNImagePickerController.h"
#import "DNAlbumTableViewController.h"
#import "DNImageFlowViewController.h"
#import "DNPickerHelper.h"

ALAssetsFilter * ALAssetsFilterFromDNImagePickerControllerFilterType(DNImagePickerFilterType type)
{
    switch (type) {
        default:
        case DNImagePickerFilterTypeNone:
            return [ALAssetsFilter allAssets];
            break;
        case DNImagePickerFilterTypePhotos:
            return [ALAssetsFilter allPhotos];
            break;
        case DNImagePickerFilterTypeVideos:
            return [ALAssetsFilter allVideos];
            break;
    }
}

@interface DNImagePickerController ()<UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<UINavigationControllerDelegate> navDelegate;
@property (nonatomic, assign) BOOL isDuringPushAnimation;

@property (strong, nonatomic) NSArray * assetsCollection;

@end

@implementation DNImagePickerController

- (void)chargeAuthorizationStatus : (PHAuthorizationStatus)status{
    
    DNAlbumTableViewController * viewController = self.viewControllers.firstObject;
    
    if (viewController == nil){
        
        return;
    }else{
        
        [self showAlbumList];
    }
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            
            [viewController reloadTableView];
            break;
            
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            
            [viewController showUnAuthorizedTipsView];
            break;
            
        case PHAuthorizationStatusNotDetermined:
            
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                if (status == PHAuthorizationStatusNotDetermined) {
                    return ;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self chargeAuthorizationStatus:status];
                });
            }];
    }
}

- (void)authorizationPhotoLibrary
{
    NSString * albumIdentifier = [DNPickerHelper fetchAlbumIdentifier];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    
    if (albumIdentifier == nil) {
        
        [self showAlbumList];
        [self chargeAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
        
    }else{
        
        if (albumIdentifier.length == 0) {
            
            [self showAlbumList];
            [self chargeAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
        }else{
            [self showImageFlow:nil];
        }
    }
    
#else
    
    if (albumIdentifier.length <= 0) {
        
        [self showAlbumList];
        
    } else {
        
        ALAssetsLibrary *assetsLibiary = [[ALAssetsLibrary alloc] init];
        [assetsLibiary enumerateGroupsWithTypes:ALAssetsGroupAll
                                     usingBlock:^(ALAssetsGroup *assetsGroup, BOOL *stop){
                                         
                                         if (assetsGroup == nil && *stop ==  NO) {
                                             [self showAlbumList];
                                         }
                                         
                                         NSString *assetsGroupID= [assetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
                                         if ([assetsGroupID isEqualToString:albumIdentifier]) {
                                             *stop = YES;
                                             NSURL *assetsGroupURL = [assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
                                             
                                             [self showImageFlow:assetsGroupURL];
                                         }
                                         
                                     }
                                   failureBlock:^(NSError *error){
                                       
                                       [self showAlbumList];
                                       
                                   }];
    }
#endif
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.delegate) {
        self.delegate = self;
    }
    
    self.interactivePopGestureRecognizer.delegate = self;
    [self authorizationPhotoLibrary];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - priviate methods

- (void)showAlbumList
{
    DNAlbumTableViewController *albumTableViewController = [[DNAlbumTableViewController alloc] init];
    [self setViewControllers:@[albumTableViewController]];
}

- (void)showImageFlow : (NSURL *)assetsGroupURL
{
    DNAlbumTableViewController *albumTableViewController = [[DNAlbumTableViewController alloc] init];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    
    DNImageFlowViewController *imageFlowController = [[DNImageFlowViewController alloc] initWithIdentifier:[DNPickerHelper fetchAlbumIdentifier]];
    [self setViewControllers:@[albumTableViewController,imageFlowController]];
    
#else
    
    DNImageFlowViewController *imageFlowController = [[DNImageFlowViewController alloc] initWithGroupURL:assetsGroupURL];
    [self setViewControllers:@[albumTableViewController,imageFlowController]];
    
#endif
}

#pragma mark - UINavigationController

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    [super setDelegate:delegate ? self : nil];
    self.navDelegate = delegate != self ? delegate : nil;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated __attribute__((objc_requires_super))
{
    self.isDuringPushAnimation = YES;
    [super pushViewController:viewController animated:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    self.isDuringPushAnimation = NO;
    if ([self.navDelegate respondsToSelector:_cmd]) {
        [self.navDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        return [self.viewControllers count] > 1 && !self.isDuringPushAnimation;
    } else {
        return YES;
    }
}

#pragma mark - Delegate Forwarder

- (BOOL)respondsToSelector:(SEL)s
{
    return [super respondsToSelector:s] || [self.navDelegate respondsToSelector:s];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)s
{
    return [super methodSignatureForSelector:s] ?: [(id)self.navDelegate methodSignatureForSelector:s];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id delegate = self.navDelegate;
    if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];
    }
}


@end
