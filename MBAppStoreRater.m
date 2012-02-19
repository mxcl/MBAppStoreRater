#import "MBAppStoreRater.h"
#import <QuartzCore/QuartzCore.h>

#define MBNumberOfTimesAppOpened @"MBNumberOfTimesAppOpened"
#define MBAppStoreRaterDone @"MBAppStoreRaterDone"
#define MBFirstUseDate @"MBFirstUseDate"
#define MBNotNowDate @"MBNotNowDate"

#ifdef MBAppStoreRaterButtonType
#define MBAppStoreRaterMargin1 8
#define MBAppStoreRaterMargin2 5
#else
#define MBAppStoreRaterMargin1 12
#define MBAppStoreRaterMargin2 12
#endif

#ifndef MBAppStoreRaterButtonType
#define MBAppStoreRaterButtonType UIButtonTypeRoundedRect
#endif

@interface UIView (MBLayoutHelper)
- (void)centerSubview:(UIView *)subview leftOfSubview:(UIView *)leftOfSubview margin:(NSUInteger)margin;
@end



@implementation MBAppStoreRater
@synthesize appStoreID;
@synthesize view;

- (id)initWithAppStoreID:(NSUInteger)asid {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:MBAppStoreRaterDone])
        return nil;

    appStoreID = asid;
    
    id defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:MBFirstUseDate])
        [defaults setObject:[NSDate date] forKey:MBFirstUseDate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)testUnderView:(UIView *)underView {
    view = [[MBNonIntrusiveAlertView alloc] initUnderView:underView];
    [view.yesButton addTarget:self action:@selector(onRateAppTapped) forControlEvents:UIControlEventTouchUpInside];
    [view.noButton addTarget:self action:@selector(onNotNowTapped) forControlEvents:UIControlEventTouchUpInside];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:MBNotNowDate])
        [view.noButton setTitle:@"Stop Asking!" forState:UIControlStateNormal];
    [view show];
}

- (BOOL)showIfAcceptableUnderView:(UIView *)underView {
    if (view) {
        NSLog(@"MBAppStoreRater already visible!");
        return NO;
    }
    
    id defaults = [NSUserDefaults standardUserDefaults];
    id now = [NSDate date];
    int opens = [defaults integerForKey:MBNumberOfTimesAppOpened];
    id firstuse = [defaults objectForKey:MBFirstUseDate] ?: now;
    id notNowDate = [defaults objectForKey:MBNotNowDate];
    
    if ([now timeIntervalSinceDate:firstuse] < 3 * 24 * 60 * 60 || opens < 5)
        return NO;
    if (notNowDate && [now timeIntervalSinceDate:notNowDate] < 5 * 24 * 60 * 60)
        return NO;
    
    [self testUnderView:underView];
    
    return YES;
}

- (void)andWereDone {
    [[self class] resetUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MBAppStoreRaterDone];
}

#define MBAppStoreRaterTidyUp \
    [view removeFromSuperview]; \
    view = nil

- (void)onNotNowTapped {
    [view hideWithAnimationCompletion:^(BOOL finished){
        MBAppStoreRaterTidyUp;
    }];
    
    id defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:MBNotNowDate]) {
        [self andWereDone];
    } else {
        [defaults setObject:[NSDate date] forKey:MBNotNowDate];
    }
}

- (void)onRateAppTapped {
    id format = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%u";
    id string = [NSString stringWithFormat:format, appStoreID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];

    // if we do it this way the rating bar dissappears before the user returns
    // but not before the app animates away in the carousel, looks great.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self andWereDone];
}

- (void)onEnteredBackground {
    view.underView.frame = CGRectOffset(view.underView.frame, 0, view.bounds.size.height);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    MBAppStoreRaterTidyUp;
}

- (void)onApplicationDidBecomeActive {
    id defaults = [NSUserDefaults standardUserDefaults];
    int x = [defaults integerForKey:MBNumberOfTimesAppOpened];
    [defaults setInteger:x + 1 forKey:MBNumberOfTimesAppOpened];
}

+ (void)resetUserDefaults {
    id defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:MBNumberOfTimesAppOpened];
    [defaults removeObjectForKey:MBFirstUseDate];
    [defaults removeObjectForKey:MBNotNowDate];
    [defaults removeObjectForKey:MBAppStoreRaterDone];
}

@end



@implementation MBNonIntrusiveAlertView
@synthesize underView;
@synthesize noButton;
@synthesize yesButton;
@synthesize label;

- (id)initUnderView:(UIView *)uv {
    CGRect frame = uv.frame;
    frame.origin.y = CGRectGetMaxY(frame);
    frame.size.height = 64;
    
    self = [super initWithFrame:frame];
    if (self) {
        underView = uv;
        
        self.backgroundColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        
        UIView *box = [[UIView alloc] initWithFrame:self.bounds];
        box.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        CAGradientLayer *cg = [CAGradientLayer layer];
        cg.colors = [NSArray arrayWithObjects:(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
        cg.frame = (CGRect){0, 0, 1024, 10};
        [self.layer addSublayer:cg];
        
        yesButton = [UIButton buttonWithType:MBAppStoreRaterButtonType];
        [yesButton setTitle:@"Rate App" forState:UIControlStateNormal];
        [box addSubview:yesButton];
        
        noButton = [UIButton buttonWithType:MBAppStoreRaterButtonType];
        [noButton setTitle:@"Not Now" forState:UIControlStateNormal];
        [box addSubview:noButton];
        
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.text = [NSString stringWithFormat:@"If you are enjoying %@, would you mind rating it?", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];;
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.opaque = NO;
        label.backgroundColor = nil;
        label.font = [UIFont boldSystemFontOfSize:16];
        [box insertSubview:label atIndex:0];
        
        [self addSubview:box];
        [underView.superview addSubview:self];
    }
    return self;
}

- (void)layoutSubviews {
    [self centerSubview:yesButton leftOfSubview:nil margin:MBAppStoreRaterMargin1];
    [self centerSubview:noButton leftOfSubview:yesButton margin:MBAppStoreRaterMargin2];
    
    CGRect frame = CGRectInset(self.bounds, 15, 2.5);
    frame = CGRectOffset(frame, 0, 2.5);
    frame.size.width = noButton.frame.origin.x - 25;
    label.frame = frame;
}

- (void)show {
    [UIView animateWithDuration:0.5 animations:^{
        underView.frame = CGRectOffset(underView.frame, 0, -self.bounds.size.height);
        self.frame = CGRectOffset(self.frame, 0, -self.bounds.size.height);
    }];
}

- (void)hideWithAnimationCompletion:(void(^)(BOOL finished))completionBlock {
    [UIView animateWithDuration:0.3 animations:^{
        underView.frame = CGRectOffset(underView.frame, 0, self.bounds.size.height);
        self.frame = CGRectOffset(self.frame, 0, self.bounds.size.height);
    } completion:^(BOOL finished) {
        completionBlock(finished);
    }];
}

@end



@implementation UIView (MBLayoutHelper)

- (void)centerSubview:(UIView *)subview leftOfSubview:(UIView *)leftOfSubview margin:(NSUInteger)margin {
    if (CGRectIsEmpty(subview.bounds))
        [subview sizeToFit];
    
    CGRect const f1 = self.bounds;
    CGRect const f2 = subview.bounds;
    float const y = (f1.size.height - f2.size.height) / 2 + 5;
    float const x = leftOfSubview == nil
        ? f1.size.width - f2.size.width - margin
        : leftOfSubview.frame.origin.x - margin - f2.size.width;
    
    subview.frame = (CGRect){x, y, f2.size};
}

@end
