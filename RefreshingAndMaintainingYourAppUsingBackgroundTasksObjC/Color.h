//
//  Color.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

// A platform-agnostic model object representing a color, suitable for persisting with Core Data
@interface Color : NSObject <NSSecureCoding>

-(instancetype)initWithRed:(double)red green:(double)green blue:(double)blue;

@property (nonatomic,readonly) double red;
@property (nonatomic,readonly) double green;
@property (nonatomic,readonly) double blue;

+(Color*)makeRandomColor;

@end

@interface ColorTransformer : NSSecureUnarchiveFromDataTransformer

@end

@class UIColor;

@interface Color (UIColorFromColor)

@property (nonatomic,copy,readonly) UIColor *UIColor;

@end
