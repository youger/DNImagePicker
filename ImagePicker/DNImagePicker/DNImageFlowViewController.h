//
//  DNImageFlowViewController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DNPickerHelper.h"

@interface DNImageFlowViewController : UIViewController

- (instancetype)initWithIdentifier:(NSString *)identifier;
- (instancetype)initWithAlbum:(DNAlbum *)album;
- (instancetype)initWithGroupURL:(NSURL *)assetsGroupURL;

@end
