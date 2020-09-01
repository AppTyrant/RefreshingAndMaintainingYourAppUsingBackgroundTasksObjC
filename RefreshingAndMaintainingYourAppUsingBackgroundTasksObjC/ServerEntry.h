//
//  ServerEntry.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "Color.h"

@interface ServerEntry : NSObject

-(instancetype)initWithTimeStamp:(NSDate*)timestamp
                      firstColor:(Color*)firstColor
                     secondColor:(Color*)secondColor
                gradientDirection:(double)gradientDirection;

@property (nonatomic,strong,readonly) NSDate *timestamp;
@property (nonatomic,strong,readonly) Color *firstColor;
@property (nonatomic,strong,readonly) Color *secondColor;
@property (nonatomic,readonly) double gradientDirection;

@end

