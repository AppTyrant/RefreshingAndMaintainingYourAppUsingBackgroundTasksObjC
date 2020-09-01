//
//  Color.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import "Color.h"

@implementation Color

-(instancetype)initWithRed:(double)red green:(double)green blue:(double)blue
{
    self = [super init];
    if (self)
    {
        _red = red;
        _green = green;
        _blue = blue;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    if (self)
    {
        _red = [coder decodeDoubleForKey:@"red"];
        _green = [coder decodeDoubleForKey:@"green"];
        _blue = [coder decodeDoubleForKey:@"blue"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeDouble:self.red forKey:@"red"];
    [coder encodeDouble:self.green forKey:@"green"];
    [coder encodeDouble:self.blue forKey:@"blue"];
}
    
+(BOOL)supportsSecureCoding
{
    return YES;
}

+(Color*)makeRandomColor
{
    double randomRed = arc4random_uniform(256);
    double randomGreen = arc4random_uniform(256);
    double randomBlue = arc4random_uniform(256);
 
    return [[Color alloc]initWithRed:randomRed/255.0
                               green:randomGreen/255.0
                                blue:randomBlue/255.0];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"R: %f G: %f B: %f",self.red,self.green,self.blue];
}

@end


@implementation ColorTransformer

+(Class)transformedValueClass
{
    return [Color class];
}

@end

#import <UIKit/UIKit.h>

@implementation Color (UIColorFromColor)

-(UIColor*)UIColor
{
    return [[UIColor alloc]initWithRed:self.red green:self.green blue:self.blue alpha:1.0];
}

@end
