//
//  ImageSelectorStateIndicator.m
//  VideoEditor2
//
//  Created by Alexander on 9/14/15.
//  Copyright (c) 2015 Onix-Systems. All rights reserved.
//

#import "ImageSelectorStateIndicator.h"
#import <CoreGraphics/CoreGraphics.h>

#define radians(angle) (angle * M_PI)/180

@interface ImageSelectorStateIndicator ()

@property (nonatomic) NSInteger selectionNumber;
@property (nonatomic) BOOL downloading;
@property (nonatomic) CGFloat downloadProgress;
@property (nonatomic, strong) UILabel* selectionLabel;

@end

@implementation ImageSelectorStateIndicator

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup {
    self.borderColor = [UIColor whiteColor];
    self.borderShadowColor = [UIColor darkGrayColor];
    self.selectedBackgroundColor = [UIColor colorWithRed:0x14/0xFF green:0x76/0xFF blue:0xFF/0xFF alpha:0xFF/0xF];
    self.downloadColor = [UIColor colorWithRed:0x29/0xFF green:0xFF/0xFF blue:0x37/0xFF alpha:0xFF/0xFF];
    
    self.selectionLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.selectionLabel.backgroundColor = [UIColor clearColor];
    self.selectionLabel.opaque = NO;
    self.selectionLabel.textAlignment = NSTextAlignmentCenter;
    self.selectionLabel.font = [self.selectionLabel.font fontWithSize: 12];
    
    [self addSubview:self.selectionLabel];
    self.selectedTextColor = [UIColor whiteColor];
    
    
    UITapGestureRecognizer *gestureRecogniger = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchupAction:)];
    gestureRecogniger.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:gestureRecogniger];
    
    [self setClearState];
    
}

-(void) touchupAction: (UITapGestureRecognizer*) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.delegate != nil) {
            [self.delegate stateIndicatorTouchUpInsideAction];
        }
    }
}

-(void) setSelectedTextColor:(UIColor *)selectedTextColor
{
    _selectedTextColor = selectedTextColor;
    self.selectionLabel.textColor = selectedTextColor;
}

-(void)setClearState
{
    self.selectionNumber = -1;
    self.downloading = NO;
    self.downloadProgress = -1;
    
    self.selectionLabel.text = @"";
    [self setNeedsDisplay];
}

-(void)setSelected: (NSInteger) selectionNumber
{
    self.selectionNumber = selectionNumber;
    [self updateSelectionLabel];
    [self setNeedsDisplay];
}

-(void)updateSelectionLabel
{
    if (self.downloading) {
        self.selectionLabel.text = @"↓";
    } else if (self.selectionNumber == NSIntegerMax) {
        self.selectionLabel.text = @"✓";
    } else if (self.selectionNumber >= 0) {
        self.selectionLabel.text = [NSString stringWithFormat:@"%ld", (long)self.selectionNumber + 1];
    } else {
        self.selectionLabel.text = @"";
    }
}

-(void) setDownloading:(BOOL)downloading {
    if (self.downloading != downloading) {
        _downloading = downloading;
        [self setNeedsDisplay];
    }
}

-(void)setDownloadingProgress: (CGFloat) downloadPercent
{
    self.downloadProgress = downloadPercent > 0 ? downloadPercent : 0;
    [self setNeedsDisplay];
}

-(BOOL) isSelected
{
    return self.selectionNumber >= 0;
}

-(BOOL)isDownloading
{
    return self.downloading;
}

- (void) drawRect:(CGRect)rect {
    [self updateSelectionLabel];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect controlRect = self.bounds;
    
    CGFloat borderWidth = 1;
    CGFloat borderRectOuterSpace = borderWidth + 4;
    
    CGRect borderRect = CGRectMake(controlRect.origin.x + borderRectOuterSpace, controlRect.origin.y + borderRectOuterSpace, controlRect.size.width - borderRectOuterSpace, controlRect.size.height - borderRectOuterSpace);
    
    CGFloat r = MIN(controlRect.size.width - controlRect.origin.x, controlRect.size.height - controlRect.origin.y)/ 2;
    r = r - borderRectOuterSpace;
    
    CGPathRef borderPath = [self makeBorderPathInRect:borderRect context: context radius:r];

    CGContextBeginPath (context);
    CGContextAddPath(context, borderPath);
    CGContextSetStrokeColorWithColor(context, self.borderShadowColor.CGColor);
    CGContextSetLineWidth(context, borderWidth + 0.5);
    CGContextStrokePath(context);
    
    CGContextBeginPath (context);
    CGContextAddPath(context, borderPath);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextSetLineWidth(context, borderWidth);
    
    if ([self isSelected] || [self isDownloading]) {
        CGContextSetFillColorWithColor(context, self.selectedBackgroundColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    }
    CGContextDrawPath(context, kCGPathFillStroke);
    
    if ([self isDownloading]) {
        CGFloat downlloadLineWidth = 3;
        CGRect downloadRect = CGRectMake(borderRect.origin.x + downlloadLineWidth, borderRect.origin.y + downlloadLineWidth, borderRect.size.width - downlloadLineWidth, borderRect.size.height - downlloadLineWidth);
        CGPathRef downloadPath = [self makeBorderPathInRect:downloadRect context: context radius:r-downlloadLineWidth];

        CGContextSaveGState(context);
        
        CGContextBeginPath (context);
        CGContextMoveToPoint(context, CGRectGetMidX(controlRect), CGRectGetMidY(controlRect));
        CGContextAddArc(context, CGRectGetMidX(controlRect), CGRectGetMidY(controlRect), r, 3*M_PI/2 + radians(0), 3*M_PI/2 + radians(360*self.downloadProgress), 0);
        CGContextAddLineToPoint(context, CGRectGetMidX(controlRect), CGRectGetMidY(controlRect));
        CGContextClosePath (context);
        CGContextClip (context);
        
        CGContextBeginPath (context);
        CGContextAddPath(context, downloadPath);
        CGContextSetStrokeColorWithColor(context, self.downloadColor.CGColor);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextSetLineWidth(context, downlloadLineWidth + 1);
        
        CGContextDrawPath(context, kCGPathFillStroke);
        
        CGContextRestoreGState(context);
    }
    
}

- (CGPathRef) makeBorderPathInRect: (CGRect) rect context: (CGContextRef) c radius: (CGFloat) radius
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat x1 = CGRectGetMinX(rect);
    CGFloat x2 = CGRectGetWidth(rect);
    CGFloat y1 = CGRectGetMinY(rect);
    CGFloat y2 = CGRectGetHeight(rect);
    
    CGPathMoveToPoint(path, nil, x2, y2 - radius);
    CGPathAddArc(path, nil, x2 - radius, y2 - radius, radius, radians(0), radians(90), 0);
    CGPathAddLineToPoint(path, nil, x1 + radius, y2);
    CGPathAddArc(path, nil, x1 + radius, y2 - radius, radius, radians(90), radians(180), 0);
    CGPathAddLineToPoint(path, nil, x1, y1 + radius);
    CGPathAddArc(path, nil, x1 + radius, y1 + radius, radius, radians(180), radians(270), 0);
    CGPathAddLineToPoint(path, nil, x2 - radius, y1);
    CGPathAddArc(path, nil, x2 - radius, y1 + radius, radius, radians(270), radians(0), 0);
    CGPathAddLineToPoint(path, nil, x2, y2 - radius);
    CGPathCloseSubpath(path);
    
    return path;
}

@end