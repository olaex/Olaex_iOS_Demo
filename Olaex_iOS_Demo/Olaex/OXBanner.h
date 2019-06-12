//
//  OXBanner.h
//  Olaex_iOS_Demo
//
//  Created by fannheyward on 2019/6/12.
//  Copyright © 2019 Olaex. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OXBannerItem : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;

- (instancetype)initWithDict:(NSDictionary *)adData;

@end

typedef void(^success)(OXBannerItem *ad);
typedef void(^fail)(NSInteger errorCode, NSString *errorMsg);

@interface OXBanner : NSObject

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *auid;
@property (nonatomic, assign) Boolean debug;

- (void)loadSuccess:(success)successHandler fail:(fail)failHandler;

@end

NS_ASSUME_NONNULL_END
