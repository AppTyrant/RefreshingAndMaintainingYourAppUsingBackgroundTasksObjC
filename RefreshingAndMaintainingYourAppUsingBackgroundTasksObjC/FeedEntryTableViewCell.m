//
//  FeedEntryTableViewCell.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/20/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "FeedEntryTableViewCell.h"
#import "Color.h"

@interface ColorViewParameters : NSObject

-(instancetype)initWithFirstColor:(UIColor*)firstColor
                      secondColor:(UIColor*)secondColor
                gradientDirection:(double)gradientDirection
                             text:(NSString*)text;

@property (nonnull,nonatomic,strong,readonly) UIColor *firstColor;
@property (nonnull,nonatomic,strong,readonly) UIColor *secondColor;
@property (nonatomic,readonly) double gradientDirection;
@property (nullable,nonatomic,strong,readonly) NSString *text;
   
@end

@implementation ColorViewParameters

-(instancetype)initWithFirstColor:(UIColor*)firstColor
      secondColor:(UIColor*)secondColor
gradientDirection:(double)gradientDirection
             text:(NSString*)text
{
    self = [super init];
    if (self)
    {
        _firstColor = firstColor;
        _secondColor = secondColor;
        _gradientDirection = gradientDirection;
        _text = text;
    }
    return self;
}

-(instancetype)initWithFeedEntry:(FeedEntry*)feedEntry
{
    static NSDateFormatter *ShortDateFormatter = nil;
    if (ShortDateFormatter == nil)
    {
        ShortDateFormatter = [[NSDateFormatter alloc]init];
        ShortDateFormatter.dateFormat = @"M/d h:mma";
    }
    NSString *text = [ShortDateFormatter stringFromDate:feedEntry.timestamp];
    return [self initWithFirstColor:feedEntry.firstColor.UIColor
                        secondColor:feedEntry.secondColor.UIColor
                  gradientDirection:feedEntry.gradientDirection
                               text:text];
}

-(BOOL)isEqual:(id)object
{
    if (object == nil) { return NO; }
    if (![object isKindOfClass:[ColorViewParameters class]]) { return NO; }
    ColorViewParameters *otherParams = object;
    if ([self.firstColor isEqual:otherParams.firstColor]
        && [self.secondColor isEqual:otherParams.secondColor]
        && self.gradientDirection == otherParams.gradientDirection)
    {
        if ((self.text == nil && otherParams.text == nil)
            || ([self.text isEqual:otherParams.text]))
        {
            return YES;
        }
    }
    return NO;
}

@end

@interface ColorView : UIView

@property (nonatomic,strong) ColorViewParameters *parameters;

@end

@interface FeedEntryTableViewCell()

@property (nonatomic,weak) IBOutlet ColorView *colorView;

@end

@implementation FeedEntryTableViewCell

-(void)setFeedEntry:(FeedEntry*)feedEntry
{
    if (_feedEntry != feedEntry)
    {
        _feedEntry = feedEntry;
        if (feedEntry != nil)
        {
            ColorViewParameters *params =  [[ColorViewParameters alloc]initWithFeedEntry:feedEntry];
            self.colorView.parameters = params;
        }
        else
        {
            self.colorView.parameters = nil;
        }
    }
}

@end

@interface ColorView()

@property (nonatomic,strong) NSOperationQueue *queue;
@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation ColorView

-(void)_setUpOnInit
{
    _imageView = [[UIImageView alloc]init];
    [self addSubview:_imageView];
}

-(instancetype)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self _setUpOnInit];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _setUpOnInit];
    }
    return self;
}


-(NSOperationQueue*)queue
{
    if (_queue == nil)
    {
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 1;
        _queue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return _queue;
}

-(void)setImage:(UIImage*)image animated:(BOOL)animated
{
    if (animated)
    {
        UIViewAnimationOptions options = UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState
                                          | UIViewAnimationOptionAllowUserInteraction;
        [UIView transitionWithView:self.imageView
                          duration:0.2
                           options:options
                        animations:^{
            
            self.imageView.image = image;
            
        } completion:nil];
    }
    else
    {
        self.imageView.image = image;
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    [self updateContentsResetExisting:NO];
}

-(void)updateContentsResetExisting:(BOOL)resetExisting
{
    [self.queue cancelAllOperations];
    ColorViewParameters *parameters = self.parameters;
    if (resetExisting || parameters == nil)
    {
        [self setImage:nil animated:NO];
    }
    
    if (parameters == nil) { return; }
    
    CGRect rect = self.bounds;
    NSBlockOperation *operation = [[NSBlockOperation alloc]init];
    __weak NSBlockOperation *weakOperation = operation;
    __weak ColorView *weakSelf = self;
    [operation addExecutionBlock:^{
        __strong NSBlockOperation *strongOperation = weakOperation;
        __strong ColorView *strongSelf = weakSelf;
        UIImage *image = [strongSelf renderWithParameters:parameters inRect:rect];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!strongOperation.isCancelled)
            {
                [strongSelf setImage:image animated:YES];
            }
            else
            {
                //Operation was cancelled.
            }
        });
    }];
    
    [self.queue addOperation:operation];
}

-(UIImage*)renderWithParameters:(ColorViewParameters*)parameters inRect:(CGRect)rect
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]initWithSize:rect.size];
    
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (context == nil)
        {
            NSLog(@"failed to get CGCotext!");
            return;
        }
        
        CGColorRef cgColors[] = {parameters.firstColor.CGColor,
                                 parameters.secondColor.CGColor};
        CFArrayRef colorsArray = CFArrayCreate(NULL, (void*)cgColors, 2, NULL);
        CGFloat gradientLocations[] = {0,1};
        CGGradientRef gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(),
                                                            colorsArray,
                                                            gradientLocations);
        
        CGFloat angle = parameters.gradientDirection / 360.0;
        CGFloat startX = pow(sin(2 * M_PI * (0.75 + angle) / 2), 2) * rect.size.width;
        CGFloat startY = pow(sin(2 * M_PI * angle / 2), 2) * rect.size.height;
        
        CGFloat endX = pow(sin(2 * M_PI * (0.25 + angle) / 2), 2) * rect.size.width;
        CGFloat endY = pow(sin(2 * M_PI * (0.5 + angle) / 2), 2) * rect.size.height;
        
        CGContextDrawLinearGradient(context,
                                    gradient,
                                    CGPointMake(startX, startY),
                                    CGPointMake(endX, endY),
                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        
        NSString *text = parameters.text;
        
        if (text != nil)
        {
            CGContextSetBlendMode(context, kCGBlendModeScreen);
            UIFont *font = [UIFont systemFontOfSize:48.0 weight:UIFontWeightBold];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            CGRect drawBounds = CGRectInset(rect, 0.0, (rect.size.height - font.pointSize) / 2.0);
            NSAttributedString *attributedString = [[NSAttributedString alloc]initWithString:text
                                                                                  attributes:@{NSParagraphStyleAttributeName:paragraphStyle,
                                                                                               NSForegroundColorAttributeName:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5],
                                                                                               NSFontAttributeName:font}];
            
            [attributedString drawInRect:drawBounds];
        }
    }];
    
    return image;
}

-(void)setParameters:(ColorViewParameters*)parameters
{
    if (![_parameters isEqual:parameters])
    {
        _parameters = parameters;
        [self updateContentsResetExisting:YES];
    }
}



@end
