//
//  DNAlbum.h
//  Wave
//
//  Created by youger on 11/17/15.
//  Copyright © 2015 youger. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;
@interface DNAlbum : NSObject

@property (strong, nonatomic) PHFetchResult * results;
@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSString * identifier;
@property (strong, nonatomic) NSDate   * startDate;
@property (assign, nonatomic) NSInteger  count;

@end
