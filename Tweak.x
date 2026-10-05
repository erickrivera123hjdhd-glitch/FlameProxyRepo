// FlameProxy - adds a floating "Proxy" button to TikTok to route traffic via an HTTP proxy.
// Untested best-effort source. Build with Theos.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString *const kEnabled = @"FP_Enabled";
static NSString *const kHost    = @"FP_Host";
static NSString *const kPort    = @"FP_Port";
static NSString *const kUser    = @"FP_User";
static NSString *const kPass    = @"FP_Pass";

static NSUserDefaults *Prefs(void) { return [NSUserDefaults standardUserDefaults]; }

static NSDictionary *ProxyDict(void) {
    NSUserDefaults *d = Prefs();
    if (![d boolForKey:kEnabled]) return nil;
    NSString *host = [d stringForKey:kHost];
    NSInteger port = [d integerForKey:kPort];
    if (host.length == 0 || port <= 0) return nil;
    return @{
        @"HTTPEnable": @1, @"HTTPProxy": host, @"HTTPPort": @(port),
        @"HTTPSEnable": @1, @"HTTPSProxy": host, @"HTTPSPort": @(port)
    };
}

// Store proxy credentials so NSURLSession can answer the proxy auth challenge.
static void ApplyCredentials(void) {
    NSUserDefaults *d = Prefs();
    NSString *host = [d stringForKey:kHost];
    NSInteger port = [d integerForKey:kPort];
    NSString *user = [d stringForKey:kUser];
    NSString *pass = [d stringForKey:kPass];
    if (host.length == 0 || port <= 0 || user.length == 0) return;

    NSURLCredential *cred = [NSURLCredential credentialWithUser:user password:pass ?: @""
                                                     persistence:NSURLCredentialPersistenceForSession];
    NSArray *types = @[NSURLProtectionSpaceHTTPProxy, NSURLProtectionSpaceHTTPSProxy];
    for (NSString *t in types) {
        NSURLProtectionSpace *ps = [[NSURLProtectionSpace alloc] initWithProxyHost:host
                                                                              port:port
                                                                              type:t
                                                                             realm:nil
                                                              authenticationMethod:NSURLAuthenticationMethodDefault];
        [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:cred forProtectionSpace:ps];
    }
}

%hook NSURLSessionConfiguration
- (NSDictionary *)connectionProxyDictionary {
    NSDictionary *p = ProxyDict();
    return p ?: %orig;
}
%end

static UIViewController *TopVC(void) {
    UIWindow *win = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class]) {
            for (UIWindow *w in ((UIWindowScene *)s).windows) { if (w.isKeyWindow) { win = w; break; } }
        }
        if (win) break;
    }
    UIViewController *vc = win.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

@interface FPButtonHandler : NSObject
+ (void)show;
@end

@implementation FPButtonHandler
+ (void)show {
    NSUserDefaults *d = Prefs();
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"HTTP Proxy"
        message:@"Restart the app after changing settings."
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Host"; t.text = [d stringForKey:kHost]; t.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Port"; t.keyboardType = UIKeyboardTypeNumberPad; NSInteger p = [d integerForKey:kPort]; t.text = p ? @(p).stringValue : nil; }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Username"; t.text = [d stringForKey:kUser]; t.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Password"; t.secureTextEntry = YES; t.text = [d stringForKey:kPass]; }];

    void (^save)(BOOL) = ^(BOOL on) {
        NSArray *f = a.textFields;
        [d setObject:[f[0] text] forKey:kHost];
        [d setInteger:[[f[1] text] integerValue] forKey:kPort];
        [d setObject:[f[2] text] forKey:kUser];
        [d setObject:[f[3] text] forKey:kPass];
        [d setBool:on forKey:kEnabled];
        [d synchronize];
        ApplyCredentials();
    };
    [a addAction:[UIAlertAction actionWithTitle:@"Save & Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { save(YES); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Save & Disable" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { save(NO); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [TopVC() presentViewController:a animated:YES completion:nil];
}
@end

static UIButton *gButton;

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    if (gButton || ![self isKindOfClass:UIWindow.class]) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gButton) return;
        gButton = [UIButton buttonWithType:UIButtonTypeSystem];
        gButton.frame = CGRectMake(8, 90, 64, 30);
        gButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
        gButton.layer.cornerRadius = 8;
        gButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [gButton setTitle:@"Proxy" forState:UIControlStateNormal];
        [gButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [gButton addTarget:[FPButtonHandler class] action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:gButton];
    });
}
%end

%ctor { ApplyCredentials(); }
