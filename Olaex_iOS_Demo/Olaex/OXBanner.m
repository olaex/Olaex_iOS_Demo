//
//  OXBanner.m
//  Olaex_iOS_Demo
//
//  Created by fannheyward on 2019/6/12.
//  Copyright © 2019 Olaex. All rights reserved.
//

#import "OXBanner.h"

#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <CommonCrypto/CommonDigest.h>

NSString * const OXAD_APIURL = @"https://api.olaexbiz.com/v1/ads";
NSString * const OXAD_TEMPLATE = @"<html><head><meta name=\"viewport\" content=\"width=device-width\"/><style>body{margin:0;padding:0;}</style></head><body><div align=\"center\">%@</div></body></html>";

@interface OXBannerItem ()

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *content;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;

@end

@implementation OXBannerItem

- (instancetype)initWithDict:(NSDictionary *)adData {
    if (self = [super init]) {
        self.type = adData[@"adType"];
        self.width = [adData[@"width"] integerValue];
        self.height = [adData[@"height"] integerValue];
        self.content = [NSString stringWithFormat:OXAD_TEMPLATE, adData[@"bannerAd"][@"content"]];
    }
    
    return self;
}

@end

const struct {
    __weak NSString *appKey;
    __weak NSString *requestType;
    __weak NSString *auid;
    __weak NSString *timestamp;
    __weak NSString *floorPrice;
    __weak NSString *sign;
    __weak NSString *test;
    
    // App
    __weak NSString *appName;
    __weak NSString *appVersion;
    __weak NSString *appBundle;
    
    // device
    __weak NSString *os;
    __weak NSString *osVersion;
    __weak NSString *ifa;
    __weak NSString *userAgent;
    __weak NSString *model;
    __weak NSString *lang;
} RequestKey = {
    .appKey = @"app_key",
    .requestType = @"rt",
    .auid = @"auid",
    .timestamp = @"ts",
    .floorPrice = @"fp",
    .sign = @"sign",
    .test = @"test",
    .appName = @"app_name",
    .appVersion = @"app_ver",
    .appBundle = @"app_bundle",
    .os = @"os",
    .osVersion = @"osv",
    .ifa = @"ifa",
    .userAgent = @"ua",
    .model = @"model",
    .lang = @"lang",
};

@interface OXBanner ()

@property (nonatomic, copy) NSString *requestType;
@property (nonatomic, copy) NSString *timestramp;
@property (nonatomic, copy) NSString *sign;
@property (nonatomic, copy) NSString *test;

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *appBundle;

@property (nonatomic, copy) NSString *os;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *lang;

@end

@implementation OXBanner

- (instancetype)init {
    if (self = [super init]) {
        self.requestType = @"api";
        self.timestramp = [self getTimestamp];
        
        self.appName = [self getAppName];
        self.appVersion = [self getAppVersion];
        self.appBundle = [self getAppBundle];
        
        self.os = @"iOS";
        self.osVersion = [self getOSVersion];
        self.ifa = [self getIFA];
        self.userAgent = [self getUserAgent];
        self.model = [self getModel];
        self.lang = [self getLang];
    }
    
    return self;
}

- (void)loadSuccess:(success)successHandler fail:(fail)failHandler {
    if (successHandler == nil) {
        return;
    }
    
    NSError *err;
    NSURL *url = [NSURL URLWithString:OXAD_APIURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:60.0];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:[self getJSONBody]
                                                   options:0
                                                     error:&err];
    if (err != nil) {
        if (failHandler) {
            failHandler(err.code, err.localizedDescription);
        }
        return;
    }
    
    [request setHTTPBody:body];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            if (failHandler) {
                failHandler(error.code, error.localizedDescription);
            }
            return;
        }
        
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&error];
        if (error != nil) {
            if (failHandler) {
                failHandler(error.code, error.localizedDescription);
            }
            return;
        }
        
        NSInteger code = -1;
        NSString *msg = @"No AD";
        if ([jsonData.allKeys containsObject:@"code"]) {
            code = [jsonData[@"code"] integerValue];
            msg = jsonData[@"msg"];
            
            if (code == 0) {
                NSDictionary *adData = jsonData[@"data"];
                
                OXBannerItem *ad = [[OXBannerItem alloc] initWithDict:adData];
                return successHandler(ad);
            }
        }
        
        if (failHandler) {
            failHandler(code, msg);
        }
    }];
    [task resume];
}

#pragma mark - private

- (NSString *)getMD5:(NSString *)str{
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), result );
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

- (NSString *)genSign:(NSDictionary *)params {
    if (params == nil) {
        return @"";
    }
    
    NSArray *keyArr = [params allKeys];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    NSArray *sortedArr = [keyArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSMutableString *paramStr = [[NSMutableString alloc] init];
    for (NSString *key in sortedArr) {
        [paramStr appendString:key];
        [paramStr appendString:params[key]];
    }
    [paramStr appendString:_appSecret];
    
    return [self getMD5:paramStr];
}

- (NSDictionary *)getJSONBody {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:_appKey forKey:RequestKey.appKey];
    [dict setObject:_requestType forKey:RequestKey.requestType];
    [dict setObject:_timestramp forKey:RequestKey.timestamp];
    [dict setObject:_auid forKey:RequestKey.auid];
    [dict setObject:_appName forKey:RequestKey.appName];
    [dict setObject:_appVersion forKey:RequestKey.appVersion];
    [dict setObject:_appBundle forKey:RequestKey.appBundle];
    [dict setObject:_os forKey:RequestKey.os];
    [dict setObject:_osVersion forKey:RequestKey.osVersion];
    [dict setObject:_ifa forKey:RequestKey.ifa];
    [dict setObject:_userAgent forKey:RequestKey.userAgent];
    [dict setObject:_model forKey:RequestKey.model];
    [dict setObject:_lang forKey:RequestKey.lang];
    
    if (_debug) {
        [dict setObject:@"1" forKey:RequestKey.test];
    } else {
        NSString *sign = [self genSign:dict];
        [dict setObject:sign forKey:RequestKey.sign];
    }
    
    return dict;
}

- (NSString *)getAppName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    return name == nil ? @"" : name;
}

- (NSString *)getAppVersion {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return version == nil ? @"" : version;
}

- (NSString *)getAppBundle {
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    return bundle == nil ? @"" : bundle;
}

- (NSString *)getOSVersion {
    NSString *osv = [[UIDevice currentDevice] systemVersion];
    return osv == nil ? @"" : osv;
}

- (NSString *)getIFA {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

- (NSString *)getTimestamp {
    return [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)getUserAgent {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    return userAgent;
}

- (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine
                                         encoding:NSUTF8StringEncoding];
    return model == nil ? @"" : model;
}

- (NSString *)getLang {
    NSString * language = [[NSLocale preferredLanguages] firstObject];
    return language == nil ? @"en_US" : language;
}

@end
