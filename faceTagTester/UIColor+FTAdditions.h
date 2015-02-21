//
//  UIColor+FTAdditions.h
//  Link
//
//  Created by David He on 8/28/14.
//  Copyright (c) 2014 Path. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (FTAdditions)

+ (UIColor *)randomColor;
+ (UIColor *)colorWithHex:(NSUInteger)rgb;
+ (UIColor *)colorWithHex:(NSUInteger)rgb alpha:(CGFloat)alpha;

+ (instancetype)colorForText:(NSString*)text;

- (instancetype)initWithHex:(NSUInteger)rgb;
- (instancetype)initWithHex:(NSUInteger)rgb alpha:(CGFloat)alpha;
- (instancetype)blendWithColor:(UIColor*)color mode:(CGBlendMode)blendMode;
- (instancetype)colorByAdjustingSaturation:(CGFloat)saturation brightness:(CGFloat)brightness;
- (instancetype)colorWithClampedSaturation:(CGPoint)saturationClamp brightness:(CGPoint)brightnessClamp;

+ (instancetype)pathTextColor:(NSString*)text;
+ (instancetype)pathNameColor:(NSString*)text;

- (instancetype)pathVibrantColor;
- (instancetype)pathDarkColor;
- (instancetype)pathDarkestColor;

@end
