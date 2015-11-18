//
//  DNPickerHelper.h
//  Wave
//
//  Created by youger on 11/17/15.
//  Copyright © 2015 youger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DNAsset.h"
#import "DNAlbum.h"

@import Photos;

@interface DNPickerHelper : NSObject

+ (void)saveIdentifier : (NSString *)identifier;

+ (NSString *)fetchAlbumIdentifier;

+ (DNAlbum *) fetchAlbum;
+ (NSArray *) fetchAlbumList;

+ (void)fetchImageWithAsset : (id)asset
            needHighQuality : (BOOL) needHighQuality
         imageResultHandler : (void(^)(UIImage * image))handler;

+ (void)fetchImageSizeWithAsset : (id)asset
         imageSizeResultHandler : (void(^)(CGFloat imageSize, NSString * sizeString))handler;

+ (PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset
                             targetSize:(CGSize)targetSize
                     imageResultHandler:(void(^)(UIImage * image))handler;

+ (PHImageRequestID)fetchImageWithAsset: (PHAsset *)asset
                            targetSize : (CGSize)targetSize
                       needHighQuality : (BOOL) needHighQuality
                            synchronous: (BOOL) synchronous
                     imageResultHandler:(void(^)(UIImage * image))handler;

+ (NSArray *)fetchImageAssetsViaCollectionResults : (PHFetchResult *)results;

@end
