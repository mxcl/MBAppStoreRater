/*
Copyright (c) 2012, Max Howell
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
*/

#import <Foundation/Foundation.h>
@class MBNonIntrusiveAlertView;


/**
 * MBAppStoreRater shows a non-intrusive invitation to rate your app.
 * MBAppStoreRater must be built with Automatic Reference Counting (ARC)!
 * To customize the appearance of your MBAppStoreRater see below.
 */

@interface MBAppStoreRater : NSObject

/**
 * Instantiate this in application:didFinishLaunchingWithOptions: or you will
 * get unexpected behavior. This method returns nil if the user has already
 * rated the app or decided to never do so.
 *
 * You can find your ID on iTunes Connect. Obviously you must have created
 * iTunes connect database entry for your app first. Note, you _don't_ need to
 * upload the app to get your ASID.
 */
- (id)initWithAppStoreID:(NSUInteger)asid;

/**
 * Will show the non-intrusive prompt to rate the app provided at least three
 * days have passed and the app has been used at least five times. However you
 * should still only show the rater if it's a good time for the user, eg. the
 * user has nothing else to do for some reason or another. The rater will not be
 * shown if the rater has already been clicked. And it will not be shown if the
 * "Not Now" button has been clicked twice.
 *
 * The rater must be presented under a view that has a superview. I have only
 * tested this code with a superview that is the same size as the "underView" so
 * YMMV with other configurations. Feel free to fork and fix!
 *
 * Returns YES if rater was shown.
 */
- (BOOL)showIfAcceptableUnderView:(UIView *)underView;

/**
 * Use this selector to ensure that the rater will show correctly before you
 * submit it to the App Store.
 */
- (void)testUnderView:(UIView *)underView;

/**
 * You should only use this when testing :P
 */
+ (void)resetUserDefaults;

@property (nonatomic, readonly) NSUInteger appStoreID;
@property (nonatomic, strong, readonly) MBNonIntrusiveAlertView *view;
@end



/**
 * MBNonIntrusiveAlertView exists separately so you can show your own
 * non-intrusive messages if you would like.
 */

@interface MBNonIntrusiveAlertView : UIView
- (id)initUnderView:(UIView *)underView;
@property (nonatomic, strong, readonly) UIView *underView;
@property (nonatomic, strong, readonly) UIButton *noButton;
@property (nonatomic, strong, readonly) UIButton *yesButton;
@property (nonatomic, strong, readonly) UILabel *label;
- (void)show;
- (void)hideWithAnimationCompletion:(void(^)(BOOL finished))completionBlock;
@end



/**
 * Customization
 * -------------
 *
 * AFTER calling showIfAcceptableUnderView: the view property will be non-nil
 * you can then customize the appearance of MBAppStoreRater.
 * 
 * If you want the Linen texture, Google how to get it from your Lion install
 * and then set it like so:
 *
 *    UIImage *linen = [UIImage imageNamed:@"nameOfLinenTexture"];
 *    rater.view.backgroundColor = [UIColor colorWithPatternImage:linen];
 *
 * If you want prettier buttons, create some with eg.
 * https://github.com/dermdaly/ButtonMaker.git and then set them:
 *
 *    [rater.noButton setBackgroundImage:img forState:UIControlStateNormal];
 *
 * BIG BUT! You must define this in your precompiled-header:
 *
 *     #define MBAppStoreRaterButtonType UIButtonTypeCustom
 * 
 * Sorry for this ridiculous caveat, but I couldn't otherwise figure out how to
 * do this since [UIButton buttonType] is not a readwrite property.
 */
