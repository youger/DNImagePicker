//
//  DNPickerHelper.m
//  Wave
//
//  Created by youger on 11/17/15.
//  Copyright © 2015 youger. All rights reserved.
//

#import "DNPickerHelper.h"
#import <AssetsLibrary/AssetsLibrary.h>

static NSString * kDNPickerManagerDefaultAlbumIdentifier = @"com.dennis.kDNPhotoPickerStoredGroup";

@implementation DNPickerHelper

+ (void)saveIdentifier : (NSString *)identifier {
    
    if (identifier == nil) return;
    
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:identifier forKey:kDNPickerManagerDefaultAlbumIdentifier];
    [ud synchronize];
}

+ (NSString *)fetchAlbumIdentifier
{
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    
    NSString * identifier = [ud objectForKey:kDNPickerManagerDefaultAlbumIdentifier];
    return identifier;
}

+ (DNAlbum *)fetchAlbum
{
    DNAlbum * album = [DNAlbum new];
    NSString * identifier = [self fetchAlbumIdentifier];
    
    if (identifier == nil) return album;

    PHFetchOptions * options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult * result = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
    
    if (result.count <= 0 ){
        
        return album;
    }
    PHAssetCollection * collection = result.firstObject;
    PHFetchResult * requestResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    album.name = collection.localizedTitle;
    album.results = requestResult;
    album.count = requestResult.count;
    album.startDate = collection.startDate;
    album.identifier = collection.localIdentifier;
    
    return album;
}

+ (NSArray *)fetchAlbums
{
    PHFetchOptions * userAlbumsOptions = [PHFetchOptions new];
    
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    userAlbumsOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO]];
    
    NSMutableArray * albums = [NSMutableArray array];
    
    [albums addObject:[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil]];
    
    [albums addObject:[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions]];
    
    return albums;
}

+ (NSArray *)fetchAlbumList
{
    NSArray * results = [self fetchAlbums];
    NSMutableArray * list = [NSMutableArray array];
    
    if (results == nil) return nil;
    
    PHFetchOptions * options = [PHFetchOptions new];
    
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    for (PHFetchResult * result in results) {
        
        [result enumerateObjectsUsingBlock:^(id collection, NSUInteger idx, BOOL * stop) {
            
            PHAssetCollection * assetCollection = collection;
            PHFetchResult * assetResults =[PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            
            NSInteger count = 0;
            switch (assetCollection.assetCollectionType) {
                case PHAssetCollectionTypeAlbum:
                    count = assetResults.count;
                    break;
                case PHAssetCollectionTypeSmartAlbum:
                    count = assetResults.count;
                    break;
                case PHAssetCollectionTypeMoment:
                    count = 0;
                    break;
                default:
                    break;
            }
            
            if (count > 0){
                
                @autoreleasepool {
                    
                    DNAlbum * ablum = [DNAlbum new];
                    ablum.count = count;
                    ablum.results = assetResults;
                    ablum.name = assetCollection.localizedTitle;
                    ablum.startDate = assetCollection.startDate;
                    ablum.identifier = assetCollection.localIdentifier;
                    [list addObject:ablum];
                }
            }
            
        }];
    }
    return list;
}

/**
 Fetch the image with the default mode AspectFill
 'call the method fetchImageWithAsset: targetSize: contentMode: imageResultHandler:
 'the mode is AspectFill
 
 - parameter asset:              the asset you want to be requested
 - parameter targetSize:         the size customed
 - parameter imageResultHandler: image result
 @image the parameter image in block is the requested image
 
 - returns: PHImageRequestID  so that you can cancel the request if needed
 */

+ (PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset
                             targetSize:(CGSize)targetSize
                     imageResultHandler:(void(^)(UIImage * image))handler
{
    if (asset == nil) return 0;
    
    PHImageRequestOptions * options = [PHImageRequestOptions new];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGSize size = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
    
    return [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * result, NSDictionary * info) {
        
        if (handler) {
            handler(result);
        }
    }];
}

+ (void)fetchImageWithAsset: (id)asset
           needHighQuality : (BOOL) needHighQuality
         imageResultHandler:(void(^)(UIImage * image))handler
{
    if ([asset isKindOfClass:[DNAsset class]]) {
        
        DNAsset * dnAsset = (DNAsset *)asset;
        ALAssetsLibrary *lib = [ALAssetsLibrary new];
        [lib assetForURL:dnAsset.url resultBlock:^(ALAsset *imageAsset){
            if (imageAsset) {
             
                UIImage *image;
                if (needHighQuality) {
                    NSNumber *orientationValue = [imageAsset valueForProperty:ALAssetPropertyOrientation];
                    UIImageOrientation orientation = UIImageOrientationUp;
                    if (orientationValue != nil) {
                        orientation = [orientationValue intValue];
                    }
                    image = [UIImage imageWithCGImage:imageAsset.defaultRepresentation.fullResolutionImage];
                    
                } else {
                    
                    image = [UIImage imageWithCGImage:imageAsset.defaultRepresentation.fullScreenImage];
                }
                
                if (handler) {
                    handler(image);
                }
            }
        } failureBlock:^(NSError *error){
            if (handler) {
                handler(nil);
            }
        }];
        
    }else if ([asset isKindOfClass:[PHAsset class]]){
        
        CGSize size = [UIScreen mainScreen].bounds.size;
        [self fetchImageWithAsset:asset targetSize:size needHighQuality:needHighQuality synchronous:YES imageResultHandler:handler];
    }
}

+ (PHImageRequestID)fetchImageWithAsset: (PHAsset *)asset
                            targetSize : (CGSize)targetSize
                       needHighQuality : (BOOL) needHighQuality
                            synchronous: (BOOL) synchronous
                     imageResultHandler:(void(^)(UIImage * image))handler
{
    if (asset == nil) return 0;
 
    PHImageRequestOptions * options = [PHImageRequestOptions new];
    options.synchronous = synchronous;
    options.networkAccessAllowed = YES;
    
    if (needHighQuality) {
        
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
    }else{
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
    
    return [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * result, NSDictionary * info) {
        
        if (handler) {
            handler(result);
        }
    }];
}

+ (NSString *)getSizeStringWithSize:(CGFloat)size
{
    CGFloat mByte = 1024 * 1024;
    NSString * string = nil;
    if (size > mByte) {
        
        string = [NSString stringWithFormat:@"%.1fM",size / mByte];
        
    }else{
        string = [NSString stringWithFormat:@"%.1fK",size / 1024.f];
    }
    return string;
}

+ (void)fetchImageSizeWithAsset : (id)asset
         imageSizeResultHandler : (void(^)(CGFloat imageSize, NSString * sizeString))handler
{
    if (asset == nil) return;
    
    if ([asset isKindOfClass:[ALAsset class]]) {
        
        if ([asset isKindOfClass:[ALAsset class]]) {
            
            NSInteger size = (NSUInteger)([(ALAsset *)asset defaultRepresentation].size);
            CGFloat imageSize = (CGFloat)size;
            NSString *imageSizeString = [self getSizeStringWithSize:imageSize];
            
            if (handler) {
                handler(imageSize, imageSizeString);
            }
        }
        
    }else if ([asset isKindOfClass:[PHAsset class]]){
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * imageData, NSString * dataUTI, UIImageOrientation orientation, NSDictionary * info) {
            
            NSString * imageSizeString = @"0M";
            CGFloat imageSize = 0.f;
            
            if (imageData == nil) {
                handler(imageSize, imageSizeString);
            }
            imageSize = imageData.length;
            imageSizeString = [self getSizeStringWithSize:imageSize];
            
            if (handler) {
                handler(imageSize, imageSizeString);
            }
        }];
    }
}

+ (NSArray *)fetchImageAssetsViaCollectionResults : (PHFetchResult *)results{
    
    NSMutableArray * resultsArray = [NSMutableArray array];
    
    if (results == nil) return resultsArray;
    
    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
       
        [resultsArray addObject:obj];
    }];
    return resultsArray;
}


@end
