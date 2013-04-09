//
//  LBGradient.m
//  LBGradient
//
//  Created by Laurin Brandner on 12.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LBGradient.h"

static NSString* const kLBGradientColorsKey = @"colors";
static NSString* const kLBGradientLocationsKey = @"locations";

static inline CGFloat* LBGradientConsistentColorLocations(NSUInteger count) {
    CGFloat* newLocations = (CGFloat*)malloc(count*sizeof(CGFloat));
    for (NSUInteger i = 0; i < count; i++) {
        newLocations[i] = (i) ? (CGFloat)i/(CGFloat)(count-1) : 0.0f;
    }
    
    return newLocations;
}

static inline NSArray* LBGradientArrayFromLocations(CGFloat* locations, NSUInteger count) {
    NSMutableArray* locationArray = [NSMutableArray array];
    for (int i = count; i >= 0; i--) {
        [locationArray addObject:[NSNumber numberWithFloat:locations[i]]];
    }
    return locationArray;
}

static inline CGFloat* LBGradientLocationsFromArray(NSArray* locations) {
    CGFloat* newLocations = malloc(locations.count*sizeof(CGFloat));
    for (NSUInteger i = 0; i < locations.count; i++) {
        newLocations[i] = [[locations objectAtIndex:i] floatValue];
    }
    return newLocations;
}

static inline CGFloat LBGradientDegreesToRadians (CGFloat i) {
    return (M_PI * (i) / 180.0f);
}

@interface LBGradient () {
    CGFloat* locations;
}

@property (nonatomic, copy) NSArray* colors;
@property (nonatomic, assign) CGColorSpaceRef colorSpace;

@end
@implementation LBGradient

@synthesize colors, colorSpace;

#pragma mark Accessors

-(NSUInteger)numberOfColorStops {
    return self.colors.count;
}

#pragma mark -
#pragma mark Initialization 

-(id)initWithStartingColor:(UIColor *)startingColor endingColor:(UIColor *)endingColor {
    self = [super init];
    if (self) {
        self.colors = [NSArray arrayWithObjects:(id)startingColor.CGColor, (id)endingColor.CGColor, nil];
        self.colorSpace = CGColorSpaceCreateDeviceRGB();
        locations = LBGradientConsistentColorLocations(2);
    }
    return self;
}

-(id)initWithColors:(NSArray *)colorArray {
    self = [super init];
    if (self) {
        NSMutableArray* newColors = [NSMutableArray new];
        for (UIColor* color in colorArray) {
            [newColors addObject:(id)color.CGColor];
        }
        self.colors = newColors;
        self.colorSpace = CGColorSpaceCreateDeviceRGB();
        locations = LBGradientConsistentColorLocations(colorArray.count);
    }
    return self;
}

-(id)initWithColors:(NSArray *)colorArray atLocations:(CGFloat *)locationValues colorSpace:(CGColorSpaceRef)colorSpaceValue {
    self = [super init];
    if (self) {
        NSMutableArray* newColors = [NSMutableArray new];
        for (UIColor* color in colorArray) {
            [newColors addObject:(id)color.CGColor];
        }
        self.colors = newColors;
        locations = locationValues;
        self.colorSpace = colorSpaceValue;
    }
    return self;
}

-(id)initWithColorsAndLocations:(UIColor *)firstColor, ... {
    self = [super init];
    if (self) {
        NSMutableArray* newColors = [NSMutableArray array];
        va_list arguments;
        va_start(arguments, firstColor);
        for (UIColor* color = firstColor; color; color=va_arg(arguments, UIColor*)) {
            [newColors addObject:(id)color.CGColor];
            locations = realloc(locations, newColors.count*sizeof(CGFloat));
            locations[newColors.count-1] = va_arg(arguments, double);
        }
        va_end(arguments);
        
        self.colors = newColors;
        self.colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    return self;
}

#pragma mark -
#pragma mark NSCopying

-(id)copyWithZone:(NSZone *)zone {
    LBGradient* copy = [[self.class allocWithZone:zone] init];
    copy->locations = self->locations;
    copy.colors = self.colors;
    copy.colorSpace = self.colorSpace;
    
    return copy;
}

#pragma mark -
#pragma mark NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        NSArray* encodedColors = [aDecoder decodeObjectForKey:kLBGradientColorsKey];
        NSMutableArray* newColors = [NSMutableArray new];
        for (UIColor* color in encodedColors) {
            [newColors addObject:(id)color.CGColor];
        }
        self.colors = newColors;
        locations = LBGradientLocationsFromArray([aDecoder decodeObjectForKey:kLBGradientLocationsKey]);
        self.colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    NSMutableArray* encodableColors = [NSMutableArray new];
    for (id color in self.colors) {
        [encodableColors addObject:[UIColor colorWithCGColor:(CGColorRef)color]];
    }
    [aCoder encodeObject:encodableColors forKey:kLBGradientColorsKey];
    [aCoder encodeObject:LBGradientArrayFromLocations(locations, colors.count) forKey:kLBGradientLocationsKey];
}

#pragma mark -
#pragma mark Memory

-(void)dealloc {
    free(locations);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark -
#pragma mark Drawing

-(void)drawFromPoint:(CGPoint)startingPoint toPoint:(CGPoint)endingPoint options:(LBGradientDrawingOptions)options {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawLinearGradient(context, gradient, startingPoint, endingPoint, options);
    CGGradientRelease(gradient);
}

-(void)drawFromCenter:(CGPoint)startCenter radius:(CGFloat)startRadius toCenter:(CGPoint)endCenter radius:(CGFloat)endRadius options:(LBGradientDrawingOptions)options {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawRadialGradient(context, gradient, startCenter, startRadius, endCenter, endRadius, options);
    CGGradientRelease(gradient);
}

-(void)drawInRect:(CGRect)rect angle:(CGFloat)angle {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextClipToRect(context, rect);
    
    CGFloat midX =  CGRectGetMidX(rect);
    CGFloat midY =  CGRectGetMidY(rect);
    
    CGContextTranslateCTM(context, midX, midY);
    CGContextRotateCTM(context, -LBGradientDegreesToRadians(angle));
    CGContextTranslateCTM(context, -midX, -midY);
    
    CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), midY);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), midY);
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation|kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

-(void)drawInBezierPath:(UIBezierPath *)path angle:(CGFloat)angle {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [path addClip];
    CGContextClip(context);
    
    CGRect bounds = path.bounds;
    CGFloat midX =  CGRectGetMidX(bounds);
    CGFloat midY =  CGRectGetMidY(bounds);
    
    CGContextTranslateCTM(context, midX, midY);
    CGContextRotateCTM(context, -LBGradientDegreesToRadians(angle));
    CGContextTranslateCTM(context, -midX, -midY);
    
    CGPoint startPoint = CGPointMake(CGRectGetMinX(bounds), midY);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(bounds), midY);
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation|kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

-(void)drawInRect:(CGRect)rect relativeCenterPosition:(CGPoint)relativeCenterPosition {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextClipToRect(context, rect);
    
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    CGFloat radius = sqrtf(powf(width/2.0f, 2)+powf(height/2.0f, 2));
    
    CGPoint startCenter = CGPointMake(width/2.0f+(width*relativeCenterPosition.x)/2.0f, height/2.0f+(height*relativeCenterPosition.y)/2.0f);
    CGPoint endCenter = CGPointMake(width/2.0f, height/2.0f);
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawRadialGradient(context, gradient, startCenter, 0, endCenter, radius, 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

-(void)drawInBezierPath:(UIBezierPath *)path relativeCenterPosition:(CGPoint)relativeCenterPosition {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [path addClip];
    CGContextClip(context);
    
    CGRect bounds = path.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat radius = sqrtf(powf(width/2.0f, 2)+powf(height/2.0f, 2));
    
    CGPoint startCenter = CGPointMake(width/2.0f+(width*relativeCenterPosition.x)/2.0f, height/2.0f+(height*relativeCenterPosition.y)/2.0f);
    CGPoint endCenter = CGPointMake(width/2.0f, height/2.0f);
    
    CGGradientRef gradient = CGGradientCreateWithColors(self.colorSpace, (__bridge CFArrayRef)self.colors, locations);
    CGContextDrawRadialGradient(context, gradient, startCenter, 0.0f, endCenter, radius, 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

#pragma mark -
#pragma mark Other Methods

-(void)getColor:(UIColor **)color location:(CGFloat *)location atIndex:(NSUInteger)index {
    if (index < self.colors.count) {
        *color = [UIColor colorWithCGColor:(CGColorRef)[self.colors objectAtIndex:index]];
        *location = locations[index];
    }
}

#pragma mark -

@end
