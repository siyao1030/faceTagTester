//
//  UIColor+FTAdditions.m
//  Link
//
//  Created by David He on 8/28/14.
//  Copyright (c) 2014 Path. All rights reserved.
//

#import "UIColor+FTAdditions.h"

@implementation UIColor (FTAdditions)

+ (instancetype)colorForText:(NSString*)text {
    // Build hash from characters
    // in specified text. Using
    // Fowler-Noll-Vo hash.
    // http://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function
    unsigned long fnv_prime = 0x811C9DC5;
    unsigned int hash = 0;
    
    for(NSUInteger i = 0; i < text.length; i++) {
        hash *= fnv_prime;
        hash ^= [text characterAtIndex:i];
    }
    
    // Mess it up a bit to increase distribution.
    hash += hash << 13;
    hash ^= hash >> 7;
    hash += hash << 3;
    hash ^= hash >> 17;
    hash += hash << 5;
    
    // Generate random number between 0.0 and 1.0
    // based on George Marsaglia's MWC (multiply
    // with carry) RNG. Use hash generated above
    // as seed for generator so the same result is
    // produced for identical strings.
    unsigned int m_w = hash >> 16;
    unsigned int m_z = hash % 4294967296;
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    unsigned int u = (m_z << 16) + m_w;
    double result = (u + 1.0) * 2.328306435454494e-10;
    
    // Use the value as an index into our color
    // palette and return the color found.
    return [UIColor pathIndexedColor:result];
}

+ (instancetype)colorWithHex:(NSUInteger)rgb {
    return [[UIColor alloc] initWithHex:rgb];
}

+ (instancetype)colorWithHex:(NSUInteger)rgb alpha:(CGFloat)alpha {
    return [[UIColor alloc] initWithHex:rgb alpha:alpha];
}

- (instancetype)initWithHex:(NSUInteger)rgb {
    return [self initWithHex:rgb alpha:1.0f];
}

- (instancetype)initWithHex:(NSUInteger)rgb alpha:(CGFloat)alpha {
    return [self initWithRed:((float)((rgb & 0xFF0000) >> 16))/255.0 green:((float)((rgb & 0xFF00) >> 8))/255.0 blue:((float)(rgb & 0xFF))/255.0 alpha:alpha];
}

- (UIColor*)blendWithColor:(UIColor*)color mode:(CGBlendMode)blendMode {
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGContextSetFillColorWithColor(context, self.CGColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 1.0, 1.0));
    CGContextSetBlendMode(context, blendMode);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 1.0, 1.0));
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
}

- (instancetype)colorByAdjustingSaturation:(CGFloat)saturationAmount brightness:(CGFloat)brightnessAmount {
    CGFloat hue, saturation, brightness, alpha;
    UIColor* color = self;
    
    if([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        color = [UIColor colorWithHue:hue saturation:MAX(MIN(saturation + saturationAmount, 1.0), 0.0) brightness:MAX(MIN(brightness + brightnessAmount, 1.0), 0.0) alpha:alpha];
    }
    
    return color;
}

- (instancetype)colorWithClampedSaturation:(CGPoint)saturationClamp brightness:(CGPoint)brightnessClamp {
    CGFloat hue, saturation, brightness, alpha;
    UIColor* color = self;
    
    if([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        color = [UIColor colorWithHue:hue saturation:MAX(MIN(saturation, saturationClamp.y), saturationClamp.x) brightness:MAX(MIN(brightness, brightnessClamp.y), brightnessClamp.x) alpha:alpha];
    }
    
    return color;
}

+ (UIColor *)randomColor {
	CGFloat randomPercentageRed = ((CGFloat)arc4random_uniform(UINT32_MAX) / UINT32_MAX);
	CGFloat randomPercentageGreen = ((CGFloat)arc4random_uniform(UINT32_MAX) / UINT32_MAX);
	CGFloat randomPercentageBlue = ((CGFloat)arc4random_uniform(UINT32_MAX) / UINT32_MAX);
	
	return [UIColor colorWithRed:randomPercentageRed green:randomPercentageGreen blue:randomPercentageBlue alpha:1.0f];
}


+ (instancetype)pathTextColor:(NSString*)text {
    return [self colorForText:text];
}

+ (instancetype)pathNameColor:(NSString*)text {
    return [self colorForText:[text lowercaseString]];
}

- (instancetype)pathDarkestColor {
    UIColor* color = [self blendWithColor:[UIColor colorWithWhite:0.0 alpha:0.4] mode:kCGBlendModeNormal];
    return [color blendWithColor:[UIColor colorWithWhite:0.0 alpha:1.0] mode:kCGBlendModeSoftLight];
}

- (instancetype)pathDarkColor {
    UIColor* color = [self blendWithColor:[UIColor colorWithWhite:0.0 alpha:0.1] mode:kCGBlendModeNormal];
    return [color blendWithColor:[UIColor colorWithWhite:0.0 alpha:0.3] mode:kCGBlendModeSoftLight];
}

- (instancetype)pathVibrantColor {
    UIColor* color = [self blendWithColor:[UIColor colorWithWhite:1.0 alpha:0.05] mode:kCGBlendModeNormal];
    return [color blendWithColor:[UIColor colorWithWhite:0.45 alpha:1.0] mode:kCGBlendModeColorDodge];
}

+ (instancetype)pathIndexedColor:(CGFloat)value {
    static dispatch_once_t onceToken;
    static UInt8* sPalettePixels = NULL;
    static CGFloat sPaletteWidth = 0.0f;
    dispatch_once(&onceToken, ^{
        CGImageRef paletteImageRef = [UIImage imageNamed:@"Color Palette"].CGImage;
        CGSize paletteSize = CGSizeMake(CGImageGetWidth(paletteImageRef), CGImageGetHeight(paletteImageRef));
        
        sPaletteWidth = paletteSize.width;
        sPalettePixels = malloc((NSUInteger)paletteSize.width * 4);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(sPalettePixels, paletteSize.width, 1, 8, 4 * paletteSize.width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, paletteSize.width, paletteSize.height), paletteImageRef);
        CGContextRelease(context);
    });
    
    NSUInteger pixel = roundf((sPaletteWidth-1.0f) * value) * 4;
    CGFloat red = (CGFloat)sPalettePixels[pixel];
    CGFloat green = (CGFloat)sPalettePixels[pixel+1];
    CGFloat blue = (CGFloat)sPalettePixels[pixel+2];
    
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1.0f];
}


@end
