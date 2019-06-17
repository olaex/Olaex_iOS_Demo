//
//  ViewController.m
//  Olaex_iOS_Demo
//
//  Created by fannheyward on 2019/6/12.
//  Copyright © 2019 Olaex. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

#import "OXBanner.h"

@interface ViewController () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGRect rect = CGRectMake((width-320)/2, 50, 320, 50);
    rect = CGRectMake((width-300)/2, 50, 300, 250); // 300x250
    
    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:rect configuration:wkWebConfig];
    _webView.scrollView.scrollEnabled = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    [self.view addSubview:_webView];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"Load AD" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor grayColor]];
    btn.frame = CGRectMake((width-100)/2, height-100, 100, 60);
    [btn addTarget:self action:@selector(loadAd) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [self loadAd];
}

- (void)loadAd {
    OXBanner *request = [[OXBanner alloc] init];
    request.appKey = @"3dfc2129ac25440dae5301737e8a18f2";
    request.appSecret = @"adaa8ca89bc54e91a63b6e596a9b0168";
    request.auid = @"10000";
    request.auid = @"10001"; // 300x250
    
    //    request.debug = YES;
    
    __weak typeof(self) weakSelf = self;
    [request loadSuccess:^(OXBannerItem * _Nonnull ad) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.webView loadHTMLString:ad.content baseURL:nil];
        });
    } fail:^(NSInteger errorCode, NSString * _Nonnull errorMsg) {
        NSLog(@"error: %@", errorMsg);
    }];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURL *url = navigationAction.request.URL;
    if (![url.absoluteString hasPrefix:@"about:blank"]) {
        if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
            [[UIApplication sharedApplication] openURL:url
                                               options:@{}
                                     completionHandler:nil];
            
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate
- (WKWebView*)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL
                                           options:@{}
                                 completionHandler:nil];
    }
    
    return nil;
}

@end
