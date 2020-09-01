//
//  ServerEntry.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "ServerEntry.h"

@implementation ServerEntry

-(instancetype)initWithTimeStamp:(NSDate*)timestamp
                      firstColor:(Color*)firstColor
                     secondColor:(Color*)secondColor
               gradientDirection:(double)gradientDirection
{
    self = [super init];
    if (self)
    {
        _timestamp = timestamp;
        _firstColor = firstColor;
        _secondColor = secondColor;
        _gradientDirection = gradientDirection;
    }
    return self;;
}

@end
