//
//  LBGradientView.m
//  LBGradient
//
//  Created by Laurin Brandner on 12.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LBGradientView.h"
#import "LBGradient.h"

@implementation LBGradientView

-(void)drawRect:(CGRect)rect {
    LBGradient* gradient = [[LBGradient alloc] initWithColorsAndLocations:[UIColor blueColor], 0.0f, [UIColor redColor], 0.5f, [UIColor greenColor], 1.0f, nil];
    [gradient drawInRect:self.bounds angle:289.0f];
}


@end
