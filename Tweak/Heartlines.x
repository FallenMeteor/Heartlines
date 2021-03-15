#import "Heartlines.h"

SBUIProudLockIconView* faceIDLock = nil;
SBFLockScreenDateView* timeDateView = nil;

%group Heartlines

%hook SBUIProudLockIconView

- (id)initWithFrame:(CGRect)frame { // get an instance of the faceid lock

    id orig = %orig;
    faceIDLock = self;

    return orig;

}

- (void)didMoveToWindow { // hide faceid lock

    if (!hideFaceIDLockSwitch)
        %orig;
    else
        [self removeFromSuperview];
    
}

- (void)setFrame:(CGRect)frame { // align and set the size of the face id lock

    %orig;

    if (alignFaceIDLockSwitch) {
        if ([positionValue intValue] == 0) {
            if (smallerFaceIDLockSwitch) self.center = CGPointMake(self.center.x / 4, self.center.y + 10);
            else self.center = CGPointMake(self.center.x / 4, self.center.y);
        } else if ([positionValue intValue] == 1) {
            if (smallerFaceIDLockSwitch) self.center = CGPointMake(self.center.x, self.center.y + 10);
        } else if ([positionValue intValue] == 2) {
            if (smallerFaceIDLockSwitch) self.center = CGPointMake(self.center.x * 1.75, self.center.y + 10);
            else self.center = CGPointMake(self.center.x * 1.75, self.center.y);
        }
    }
    
    if (smallerFaceIDLockSwitch) self.transform = CGAffineTransformMakeScale(0.85, 0.85);
    if (!alignFaceIDLockSwitch && smallerFaceIDLockSwitch) self.center = CGPointMake(self.center.x, self.center.y + 10);

}

- (void)setContentColor:(UIColor *)arg1 { // set faceid lock color

    if (artworkBasedColorsSwitch && ([[%c(SBMediaController) sharedInstance] isPlaying] || [[%c(SBMediaController) sharedInstance] isPaused])) return %orig;
    if ([faceIDLockColorValue intValue] == 0)
        %orig(backgroundWallpaperColor);
    else if ([faceIDLockColorValue intValue] == 1)
        %orig(primaryWallpaperColor);
    else if ([faceIDLockColorValue intValue] == 2)
        %orig(secondaryWallpaperColor);
    else if ([faceIDLockColorValue intValue] == 3)
        %orig([SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customFaceIDLockColor"] withFallback:@"#FFFFFF"]);
    else
        %orig;

}

%end

%hook UIMorphingLabel

- (void)didMoveToWindow { // hide faceid lock label

    if (hideFaceIDLockSwitch) return %orig;
    UIViewController* ancestor = [self _viewControllerForAncestor];
    if ([ancestor isKindOfClass:%c(SBUIProudLockContainerViewController)])
        [self removeFromSuperview];
    else
        %orig;

}

%end

%hook SBFLockScreenDateViewController

- (void)setContentAlpha:(double)arg1 withSubtitleVisible:(BOOL)arg2 { // hide original time and date

    %orig(0, NO);

}

%end

%hook SBFLockScreenDateView

%property(nonatomic, retain)UILabel* weatherReportLabel;
%property(nonatomic, retain)UILabel* weatherConditionLabel;
%property(nonatomic, retain)UILabel* timeLabel;
%property(nonatomic, retain)UILabel* dateLabel;
%property(nonatomic, retain)UILabel* upNextLabel;
%property(nonatomic, retain)UILabel* upNextEventLabel;
%property(nonatomic, retain)UIView* invisibleInk;

- (id)initWithFrame:(CGRect)frame { // add notification observer

    id orig = %orig;
    timeDateView = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeartlinesUpNext:) name:@"heartlinesUpdateUpNext" object:nil];

    return orig;
    
}

- (void)didMoveToWindow { // add heartlines

	%orig;

    if (firstTimeLoaded) return;
    firstTimeLoaded = YES;

    // load sf pro text regular font if not using a custom chosen one
    if (!useCustomFontSwitch) {
        NSData* inData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/HeartlinesPrefs.bundle/SF-Pro-Text-Regular.otf"]];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);

        // load sf pro text semibold font
        NSData* inData2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/HeartlinesPrefs.bundle/SF-Pro-Text-Semibold.otf"]];
        CFErrorRef error2;
        CGDataProviderRef provider2 = CGDataProviderCreateWithCFData((CFDataRef)inData2);
        CGFontRef font2 = CGFontCreateWithDataProvider(provider2);
        if (!CTFontManagerRegisterGraphicsFont(font2, &error2)) {
            CFStringRef errorDescription2 = CFErrorCopyDescription(error2);
            CFRelease(errorDescription2);
        }
        CFRelease(font2);
        CFRelease(provider2);
    }

    if ([styleValue intValue] == 0) {
        // up next label
        if (showUpNextSwitch) {
            self.upNextLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomUpNextFontSizeSwitch) {
                    [[self upNextLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:19]];
                } else {
                    [[self upNextLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customUpNextFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomUpNextFontSizeSwitch) {
                    [[self upNextLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:19]];
                } else {
                    [[self upNextLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customUpNextFontSizeValue intValue]]];
                }
            }
                
            if ([[HLSLocalization stringForKey:@"UP_NEXT"] isEqual:nil]) [[self upNextLabel] setText:@"Up next"];
            else if (![[HLSLocalization stringForKey:@"UP_NEXT"] isEqual:nil]) [[self upNextLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"UP_NEXT"]]];
                
            if ([positionValue intValue] == 0) [[self upNextLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self upNextLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self upNextLabel] setTextAlignment:NSTextAlignmentRight];


            [[self upNextLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self upNextLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self upNextLabel].heightAnchor constraintEqualToConstant:21].active = YES;
                
            if (![[self upNextLabel] isDescendantOfView:self]) [self addSubview:[self upNextLabel]];
                
            if ([positionValue intValue] == 0) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
                
            [[self upNextLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:16].active = YES;
        }


        // up next event label
        if (showUpNextSwitch) {
            self.upNextEventLabel = [UILabel new];

            if (!useCustomFontSwitch){
                if (!useCustomUpNextEventFontSizeSwitch) {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:15]];
                } else {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customUpNextEventFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomUpNextEventFontSizeSwitch) {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:15]];
                } else {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customUpNextEventFontSizeValue intValue]]];
                }
            }
                
            if ([[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:@"No upcoming events"];
            else if (![[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"]]];
                
            if ([positionValue intValue] == 0) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentRight];
                

            [[self upNextEventLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self upNextEventLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self upNextEventLabel].heightAnchor constraintEqualToConstant:16].active = YES;
                
            if (![[self upNextEventLabel] isDescendantOfView:self]) [self addSubview:[self upNextEventLabel]];
                
            if ([positionValue intValue] == 0) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
                
            [[self upNextEventLabel].centerYAnchor constraintEqualToAnchor:[self upNextLabel].bottomAnchor constant:12].active = YES;
        }


        // invisible ink
        if (showUpNextSwitch && hideUntilAuthenticatedSwitch && invisibleInkEffectSwitch) {
            self.invisibleInk = [NSClassFromString(@"CKInvisibleInkImageEffectView") new];
            [[self invisibleInk] setHidden:YES];


            [[self invisibleInk] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self invisibleInk].widthAnchor constraintEqualToConstant:160].active = YES;
            [[self invisibleInk].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self invisibleInk] isDescendantOfView:self]) [self addSubview:[self invisibleInk]];
            
            if ([positionValue intValue] == 0) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.leftAnchor constant:87.5].active = YES;
            else if ([positionValue intValue] == 1) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-75].active = YES;
            
            [[self invisibleInk].centerYAnchor constraintEqualToAnchor:[self upNextLabel].bottomAnchor constant:16].active = YES;
        }


        // time label
        self.timeLabel = [UILabel new];

        if (!useCustomFontSwitch){
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:[customTimeFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customTimeFontSizeValue intValue]]];
            }
        }
            
        NSDateFormatter* timeFormat = [NSDateFormatter new];
        [timeFormat setDateFormat:timeFormatValue];
        [[self timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
            
        if ([positionValue intValue] == 0) [[self timeLabel] setTextAlignment:NSTextAlignmentLeft];
        else if ([positionValue intValue] == 1) [[self timeLabel] setTextAlignment:NSTextAlignmentCenter];
        else if ([positionValue intValue] == 2) [[self timeLabel] setTextAlignment:NSTextAlignmentRight];
            

        [[self timeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self timeLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self timeLabel].heightAnchor constraintEqualToConstant:73].active = YES;
            
        if (![[self timeLabel] isDescendantOfView:self]) [self addSubview:[self timeLabel]];
            
        if ([positionValue intValue] == 0) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:4].active = YES;
        else if ([positionValue intValue] == 1) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
        else if ([positionValue intValue] == 2) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-4].active = YES;
            
        if (showUpNextSwitch) [[self timeLabel].centerYAnchor constraintEqualToAnchor:[self upNextEventLabel].bottomAnchor constant:40].active = YES;
        else if (!showUpNextSwitch) [[self timeLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:40].active = YES;


        // date label
        self.dateLabel = [UILabel new];

        if (!useCustomFontSwitch){
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customDateFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customDateFontSizeValue intValue]]];
            }
        }
            
        if (!isTimerRunning) {
            NSDateFormatter* dateFormat = [NSDateFormatter new];
            [dateFormat setDateFormat:dateFormatValue];
            [[self dateLabel] setText:[[dateFormat stringFromDate:[NSDate date]] capitalizedString]];
        }
            
        if ([positionValue intValue] == 0) [[self dateLabel] setTextAlignment:NSTextAlignmentLeft];
        else if ([positionValue intValue] == 1) [[self dateLabel] setTextAlignment:NSTextAlignmentCenter];
        else if ([positionValue intValue] == 2) [[self dateLabel] setTextAlignment:NSTextAlignmentRight];
            

        [[self dateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self dateLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self dateLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
        if (![[self dateLabel] isDescendantOfView:self]) [self addSubview:[self dateLabel]];
            
        if ([positionValue intValue] == 0) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
        else if ([positionValue intValue] == 1) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
        else if ([positionValue intValue] == 2) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
        [[self dateLabel].centerYAnchor constraintEqualToAnchor:[self timeLabel].bottomAnchor constant:8].active = YES;


        // weather report label
        if (showWeatherSwitch) {
            self.weatherReportLabel = [UILabel new];

            if (!useCustomFontSwitch){
                if (!useCustomWeatherReportFontSizeSwitch) {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:14]];
                } else {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customWeatherReportFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomWeatherReportFontSizeSwitch) {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:14]];
                } else {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customWeatherReportFontSizeValue intValue]]];
                }
            }
                
            [[PDDokdo sharedInstance] refreshWeatherData];
            if ([[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[self weatherReportLabel] setText:[NSString stringWithFormat:@"Currently it's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[self weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"CURRENTLY_ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
                
            if ([positionValue intValue] == 0) [[self weatherReportLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self weatherReportLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self weatherReportLabel] setTextAlignment:NSTextAlignmentRight];


            [[self weatherReportLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self weatherReportLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self weatherReportLabel].heightAnchor constraintEqualToConstant:21].active = YES;
                
            if (![[self weatherReportLabel] isDescendantOfView:self]) [self addSubview:[self weatherReportLabel]];
                
            if ([positionValue intValue] == 0) [[self weatherReportLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self weatherReportLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self weatherReportLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
                
            [[self weatherReportLabel].centerYAnchor constraintEqualToAnchor:[self dateLabel].bottomAnchor constant:16].active = YES;
        }


        // weather condition label
        if (showWeatherSwitch) {
            self.weatherConditionLabel = [UILabel new];

            if (!useCustomFontSwitch){
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customWeatherConditionFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customWeatherConditionFontSizeValue intValue]]];
                }
            }
            
            [[self weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
            
            if ([positionValue intValue] == 0) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentRight];
            

            [[self weatherConditionLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self weatherConditionLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self weatherConditionLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self weatherConditionLabel] isDescendantOfView:self]) [self addSubview:[self weatherConditionLabel]];
            
            if ([positionValue intValue] == 0) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
            [[self weatherConditionLabel].centerYAnchor constraintEqualToAnchor:[self weatherReportLabel].bottomAnchor constant:8].active = YES;
        }
    } else if ([styleValue intValue] == 1) {
        // weather condition label
        if (showWeatherSwitch) {
            self.weatherConditionLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customWeatherConditionFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customWeatherConditionFontSizeValue intValue]]];
                }
            }
            
            [[PDDokdo sharedInstance] refreshWeatherData];
            [[self weatherConditionLabel] setText:[NSString stringWithFormat:@"%@, %@",[[PDDokdo sharedInstance] currentConditions], [[PDDokdo sharedInstance] currentTemperature]]];

            if ([positionValue intValue] == 0) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentRight];
            
            
            [[self weatherConditionLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self weatherConditionLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self weatherConditionLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self weatherConditionLabel] isDescendantOfView:self]) [self addSubview:[self weatherConditionLabel]];
            
            if ([positionValue intValue] == 0) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
            [[self weatherConditionLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:16].active = YES;
        }


        // date label
        self.dateLabel = [UILabel new];
            
        if (!useCustomFontSwitch){
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customDateFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customDateFontSizeValue intValue]]];
            }
        }
            
        if (!isTimerRunning) {
            NSDateFormatter* dateFormat = [NSDateFormatter new];
            [dateFormat setDateFormat:dateFormatValue];
            [[self dateLabel] setText:[[dateFormat stringFromDate:[NSDate date]] capitalizedString]];
        }
            
        if ([positionValue intValue] == 0) [[self dateLabel] setTextAlignment:NSTextAlignmentLeft];
        else if ([positionValue intValue] == 1) [[self dateLabel] setTextAlignment:NSTextAlignmentCenter];
        else if ([positionValue intValue] == 2) [[self dateLabel] setTextAlignment:NSTextAlignmentRight];
            

        [[self dateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self dateLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self dateLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
        if (![[self dateLabel] isDescendantOfView:self]) [self addSubview:[self dateLabel]];
            
        if ([positionValue intValue] == 0) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
        else if ([positionValue intValue] == 1) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
        else if ([positionValue intValue] == 2) [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
        if (showWeatherSwitch) [[self dateLabel].centerYAnchor constraintEqualToAnchor:[self weatherConditionLabel].bottomAnchor constant:10].active = YES;
        else if (!showWeatherSwitch) [[self dateLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:16].active = YES;


        // time label
        self.timeLabel = [UILabel new];
            
        if (!useCustomFontSwitch){
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:[customTimeFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customTimeFontSizeValue intValue]]];
            }
        }
            
        NSDateFormatter* timeFormat = [NSDateFormatter new];
        [timeFormat setDateFormat:timeFormatValue];
        [[self timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
            
        if ([positionValue intValue] == 0) [[self timeLabel] setTextAlignment:NSTextAlignmentLeft];
        else if ([positionValue intValue] == 1) [[self timeLabel] setTextAlignment:NSTextAlignmentCenter];
        else if ([positionValue intValue] == 2) [[self timeLabel] setTextAlignment:NSTextAlignmentRight];
            

        [[self timeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self timeLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self timeLabel].heightAnchor constraintEqualToConstant:73].active = YES;
            
        if (![[self timeLabel] isDescendantOfView:self]) [self addSubview:[self timeLabel]];
            
        if ([positionValue intValue] == 0) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:4].active = YES;
        else if ([positionValue intValue] == 1) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
        else if ([positionValue intValue] == 2) [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-4].active = YES;
            
        [[self timeLabel].centerYAnchor constraintEqualToAnchor:[self dateLabel].bottomAnchor constant:32].active = YES;


        // up next label
        if (showUpNextSwitch) {
            self.upNextLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomUpNextFontSizeSwitch) {
                    [[self upNextLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:19]];
                } else {
                    [[self upNextLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customUpNextFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomUpNextFontSizeSwitch) {
                    [[self upNextLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:19]];
                } else {
                    [[self upNextLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customUpNextFontSizeValue intValue]]];
                }
            }
            
            if ([[HLSLocalization stringForKey:@"UP_NEXT"] isEqual:nil]) [[self upNextLabel] setText:@"Up next"];
            else if (![[HLSLocalization stringForKey:@"UP_NEXT"] isEqual:nil]) [[self upNextLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"UP_NEXT"]]];
            
            if ([positionValue intValue] == 0) [[self upNextLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self upNextLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self upNextLabel] setTextAlignment:NSTextAlignmentRight];


            [[self upNextLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self upNextLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self upNextLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self upNextLabel] isDescendantOfView:self]) [self addSubview:[self upNextLabel]];
            
            if ([positionValue intValue] == 0) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self upNextLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
            [[self upNextLabel].centerYAnchor constraintEqualToAnchor:[self timeLabel].bottomAnchor constant:8].active = YES;
        }

        // up next event label
        if (showUpNextSwitch) {
            self.upNextEventLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomUpNextEventFontSizeSwitch) {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:15]];
                } else {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customUpNextEventFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomUpNextEventFontSizeSwitch) {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:15]];
                } else {
                    [[self upNextEventLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customUpNextEventFontSizeValue intValue]]];
                }
            }
            
            if ([[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:@"No upcoming events"];
            else if (![[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"]]];
            
            if ([positionValue intValue] == 0) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentLeft];
            else if ([positionValue intValue] == 1) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentCenter];
            else if ([positionValue intValue] == 2) [[self upNextEventLabel] setTextAlignment:NSTextAlignmentRight];
            

            [[self upNextEventLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self upNextEventLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self upNextEventLabel].heightAnchor constraintEqualToConstant:16].active = YES;
            
            if (![[self upNextEventLabel] isDescendantOfView:self]) [self addSubview:[self upNextEventLabel]];
            
            if ([positionValue intValue] == 0) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
            else if ([positionValue intValue] == 1) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self upNextEventLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            
            [[self upNextEventLabel].centerYAnchor constraintEqualToAnchor:[self upNextLabel].bottomAnchor constant:14].active = YES;
        }

        // invisible ink
        if (showUpNextSwitch && hideUntilAuthenticatedSwitch && invisibleInkEffectSwitch) {
            self.invisibleInk = [NSClassFromString(@"CKInvisibleInkImageEffectView") new];
            [[self invisibleInk] setHidden:YES];

            [[self invisibleInk] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self invisibleInk].widthAnchor constraintEqualToConstant:160].active = YES;
            [[self invisibleInk].heightAnchor constraintEqualToConstant:21].active = YES;
            if (![[self invisibleInk] isDescendantOfView:self]) [self addSubview:[self invisibleInk]];
            if ([positionValue intValue] == 0) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.leftAnchor constant:87.5].active = YES;
            else if ([positionValue intValue] == 1) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0].active = YES;
            else if ([positionValue intValue] == 2) [[self invisibleInk].centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-75].active = YES;
            [[self invisibleInk].centerYAnchor constraintEqualToAnchor:[self upNextLabel].bottomAnchor constant:16].active = YES;
        }
    } else if ([styleValue intValue] == 2) {
        // time label
        self.timeLabel = [UILabel new];
            
        if (!useCustomFontSwitch){
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:@"SFProText-Regular" size:[customTimeFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomTimeFontSizeSwitch) {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:61]];
            } else {
                [[self timeLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customTimeFontSizeValue intValue]]];
            }
        }
            
        NSDateFormatter* timeFormat = [NSDateFormatter new];
        [timeFormat setDateFormat:timeFormatValue];
        [[self timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
            
        [[self timeLabel] setTextAlignment:NSTextAlignmentLeft];
            

        [[self timeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self timeLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self timeLabel].heightAnchor constraintEqualToConstant:73].active = YES;
            
        if (![[self timeLabel] isDescendantOfView:self]) [self addSubview:[self timeLabel]];
            
        [[self timeLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:4].active = YES;
        [[self timeLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:50].active = YES;


        // date label
        self.dateLabel = [UILabel new];
            
        if (!useCustomFontSwitch){
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customDateFontSizeValue intValue]]];
            }
        } else {
            if (!useCustomDateFontSizeSwitch) {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:17]];
            } else {
                [[self dateLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customDateFontSizeValue intValue]]];
            }
        }
            
        if (!isTimerRunning) {
            NSDateFormatter* dateFormat = [NSDateFormatter new];
            [dateFormat setDateFormat:dateFormatValue];
            [[self dateLabel] setText:[[dateFormat stringFromDate:[NSDate date]] capitalizedString]];
        }
            
        [[self dateLabel] setTextAlignment:NSTextAlignmentLeft];
            

        [[self dateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self dateLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
        [[self dateLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
        if (![[self dateLabel] isDescendantOfView:self]) [self addSubview:[self dateLabel]];
            
        [[self dateLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:8].active = YES;
        [[self dateLabel].centerYAnchor constraintEqualToAnchor:[self timeLabel].bottomAnchor constant:8].active = YES;


        // weather report label
        if (showWeatherSwitch) {
            self.weatherReportLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomWeatherReportFontSizeSwitch) {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:14]];
                } else {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customWeatherReportFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomWeatherReportFontSizeSwitch) {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:14]];
                } else {
                    [[self weatherReportLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customWeatherReportFontSizeValue intValue]]];
                }
            }
            
            [[PDDokdo sharedInstance] refreshWeatherData];
            if ([[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[self weatherReportLabel] setText:[NSString stringWithFormat:@"It's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[self weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
            
            [[self weatherReportLabel] setTextAlignment:NSTextAlignmentRight];


            [[self weatherReportLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self weatherReportLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self weatherReportLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self weatherReportLabel] isDescendantOfView:self]) [self addSubview:[self weatherReportLabel]];
            
            [[self weatherReportLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            [[self weatherReportLabel].centerYAnchor constraintEqualToAnchor:self.topAnchor constant:55].active = YES;
        }

        // weather condition label
        if (showWeatherSwitch) {
            self.weatherConditionLabel = [UILabel new];
            
            if (!useCustomFontSwitch){
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:@"SFProText-Semibold" size:[customWeatherConditionFontSizeValue intValue]]];
                }
            } else {
                if (!useCustomWeatherConditionFontSizeSwitch) {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:14]];
                } else {
                    [[self weatherConditionLabel] setFont:[UIFont fontWithName:[NSString stringWithFormat:@"%@", [preferences objectForKey:@"customFont"]] size:[customWeatherConditionFontSizeValue intValue]]];
                }
            }
            
            [[self weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
            [[self weatherConditionLabel] setTextAlignment:NSTextAlignmentRight];

            
            [[self weatherConditionLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[self weatherConditionLabel].widthAnchor constraintEqualToConstant:self.bounds.size.width].active = YES;
            [[self weatherConditionLabel].heightAnchor constraintEqualToConstant:21].active = YES;
            
            if (![[self weatherConditionLabel] isDescendantOfView:self]) [self addSubview:[self weatherConditionLabel]];
            
            [[self weatherConditionLabel].centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-8].active = YES;
            [[self weatherConditionLabel].centerYAnchor constraintEqualToAnchor:[self weatherReportLabel].bottomAnchor constant:8].active = YES;
        }
    }

    // get lockscreen wallpaper
    NSData* lockWallpaperData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"];
    CFDataRef lockWallpaperDataRef = (__bridge CFDataRef)lockWallpaperData;
    NSArray* imageArray = (__bridge NSArray *)CPBitmapCreateImagesFromData(lockWallpaperDataRef, NULL, 1, NULL);
    UIImage* wallpaper = [UIImage imageWithCGImage:(CGImageRef)imageArray[0]];

    // get lockscreen wallpaper based colors
    backgroundWallpaperColor = [libKitten backgroundColor:wallpaper];
    primaryWallpaperColor = [libKitten primaryColor:wallpaper];
    secondaryWallpaperColor = [libKitten secondaryColor:wallpaper];

    // set colors
    if ([faceIDLockColorValue intValue] == 0)
        [faceIDLock setContentColor:backgroundWallpaperColor];
    else if ([faceIDLockColorValue intValue] == 1)
        [faceIDLock setContentColor:primaryWallpaperColor];
    else if ([faceIDLockColorValue intValue] == 2)
        [faceIDLock setContentColor:secondaryWallpaperColor];
    else if ([faceIDLockColorValue intValue] == 3)
        [faceIDLock setContentColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customFaceIDLockColor"] withFallback:@"#FFFFFF"]];

    if (showUpNextSwitch) {
        if ([upNextColorValue intValue] == 0)
            [[self upNextLabel] setTextColor:backgroundWallpaperColor];
        else if ([upNextColorValue intValue] == 1)
            [[self upNextLabel] setTextColor:primaryWallpaperColor];
        else if ([upNextColorValue intValue] == 2)
            [[self upNextLabel] setTextColor:secondaryWallpaperColor];
        else if ([upNextColorValue intValue] == 3)
            [[self upNextLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customUpNextColor"] withFallback:@"#FFFFFF"]];

        if ([upNextEventColorValue intValue] == 0)
            [[self upNextEventLabel] setTextColor:backgroundWallpaperColor];
        else if ([upNextEventColorValue intValue] == 1)
            [[self upNextEventLabel] setTextColor:primaryWallpaperColor];
        else if ([upNextEventColorValue intValue] == 2)
            [[self upNextEventLabel] setTextColor:secondaryWallpaperColor];
        else if ([upNextEventColorValue intValue] == 3)
            [[self upNextEventLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customUpNextEventColor"] withFallback:@"#FFFFFF"]];
    }

    if ([timeColorValue intValue] == 0)
        [[self timeLabel] setTextColor:backgroundWallpaperColor];
    else if ([timeColorValue intValue] == 1)
        [[self timeLabel] setTextColor:primaryWallpaperColor];
    else if ([timeColorValue intValue] == 2)
        [[self timeLabel] setTextColor:secondaryWallpaperColor];
    else if ([timeColorValue intValue] == 3)
        [[self timeLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customTimeColor"] withFallback:@"#FFFFFF"]];

    if ([dateColorValue intValue] == 0)
        [[self dateLabel] setTextColor:backgroundWallpaperColor];
    else if ([dateColorValue intValue] == 1)
        [[self dateLabel] setTextColor:primaryWallpaperColor];
    else if ([dateColorValue intValue] == 2)
        [[self dateLabel] setTextColor:secondaryWallpaperColor];
    else if ([dateColorValue intValue] == 3)
        [[self dateLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customDateColor"] withFallback:@"#FFFFFF"]];

    if (showWeatherSwitch) {
        if ([weatherReportColorValue intValue] == 0)
            [[self weatherReportLabel] setTextColor:backgroundWallpaperColor];
        else if ([weatherReportColorValue intValue] == 1)
            [[self weatherReportLabel] setTextColor:primaryWallpaperColor];
        else if ([weatherReportColorValue intValue] == 2)
            [[self weatherReportLabel] setTextColor:secondaryWallpaperColor];
        else if ([weatherReportColorValue intValue] == 3)
            [[self weatherReportLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customWeatherReportColor"] withFallback:@"#FFFFFF"]];

        if ([weatherConditionColorValue intValue] == 0)
            [[self weatherConditionLabel] setTextColor:backgroundWallpaperColor];
        else if ([weatherConditionColorValue intValue] == 1)
            [[self weatherConditionLabel] setTextColor:primaryWallpaperColor];
        else if ([weatherConditionColorValue intValue] == 2)
            [[self weatherConditionLabel] setTextColor:secondaryWallpaperColor];
        else if ([weatherConditionColorValue intValue] == 3)
            [[self weatherConditionLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customWeatherConditionColor"] withFallback:@"#FFFFFF"]];
    }

}

%new
- (void)updateHeartlinesUpNext:(NSNotification *)notification { // update up next

    EKEventStore* store = [EKEventStore new];
    NSCalendar* calendar = [NSCalendar currentCalendar];

    NSDateComponents* todayEventsComponents = [NSDateComponents new];
    todayEventsComponents.day = 0;
    NSDate* todayEvents = [calendar dateByAddingComponents:todayEventsComponents toDate:[NSDate date] options:0];

    NSDateComponents* todayRemindersComponents = [NSDateComponents new];
    todayRemindersComponents.day = -1;
    NSDate* todayReminders = [calendar dateByAddingComponents:todayRemindersComponents toDate:[NSDate date] options:0];

    NSDateComponents* daysFromNowComponents = [NSDateComponents new];
    daysFromNowComponents.day = [dayRangeValue intValue];
    NSDate* daysFromNow = [calendar dateByAddingComponents:daysFromNowComponents toDate:[NSDate date] options:0];

    NSPredicate* calendarPredicate = [store predicateForEventsWithStartDate:todayEvents endDate:daysFromNow calendars:nil];

    NSArray* events = [store eventsMatchingPredicate:calendarPredicate];

    NSPredicate* reminderPredicate = [store predicateForIncompleteRemindersWithDueDateStarting:todayReminders ending:daysFromNow calendars:nil];
    __block NSArray* availableReminders;

    // get first event
    if (showCalendarEventsSwitch) {
        if ([events count]) {
            [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [events[0] title]]];
            if (!(hideUntilAuthenticatedSwitch && isLocked)) [[self upNextEventLabel] setHidden:NO];
        } else {
            if ([[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:@"No upcoming events"];
            else if (![[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"]]];
        }
    }

    // get first reminder and manage no events status
    if (showRemindersSwitch) {
        if ((prioritizeRemindersSwitch && [events count]) || ![events count]) {
            [store fetchRemindersMatchingPredicate:reminderPredicate completion:^(NSArray* reminders) {
                availableReminders = reminders;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([reminders count]) {
                        [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [reminders[0] title]]];
                        if (!(hideUntilAuthenticatedSwitch && isLocked)) [[self upNextEventLabel] setHidden:NO];
                    } else if (![reminders count] && ![events count]) {
                        if ([[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:@"No upcoming events"];
                        else if (![[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"]]];
                    }
                });
            }];
        }
    }

    // get next alarm
    if (showNextAlarmSwitch) {
        if ((prioritizeAlarmsSwitch && ([events count] || [availableReminders count])) || (![events count] && ![availableReminders count])) {
            if ([[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] cache] nextAlarm]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    NSDate* fireDate = [[[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] cache] nextAlarm] nextFireDate];
                    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:fireDate];
                    if ([[HLSLocalization stringForKey:@"ALARM"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"Alarm: %02ld:%02ld", [components hour], [components minute]]];
                    else if (![[HLSLocalization stringForKey:@"ALARM"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@: %02ld:%02ld", [HLSLocalization stringForKey:@"ALARM"], [components hour], [components minute]]];
                    if (!(hideUntilAuthenticatedSwitch && isLocked)) [[self upNextEventLabel] setHidden:NO];
                });
            } else {
                if ([[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:@"No upcoming events"];
                else if (![[HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"] isEqual:nil]) [[self upNextEventLabel] setText:[NSString stringWithFormat:@"%@", [HLSLocalization stringForKey:@"NO_UPCOMING_EVENTS"]]];
            }
            
        }
    }

}

%end

%hook CSCoverSheetViewController

- (void)viewWillAppear:(BOOL)animated { // update heartlines when lockscreen appears

	%orig;

    if (showWeatherSwitch) [[PDDokdo sharedInstance] refreshWeatherData];
    if (showUpNextSwitch && [styleValue intValue] != 2) [[NSNotificationCenter defaultCenter] postNotificationName:@"heartlinesUpdateUpNext" object:nil];
	[self updateHeartlines];

	if (!timer) timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateHeartlines) userInfo:nil repeats:YES];

}

- (void)viewWillDisappear:(BOOL)animated { // stop timer when lockscreen disappears

	%orig;

	[timer invalidate];
	timer = nil;

}


%new
- (void)updateHeartlines { // update heartlines

    if (!justPluggedIn) {
        NSDateFormatter* timeFormat = [NSDateFormatter new];
        [timeFormat setDateFormat:timeFormatValue];
        [[timeDateView timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
    }

	if (!isTimerRunning) {
        NSDateFormatter* dateFormat = [NSDateFormatter new];
        [dateFormat setDateFormat:dateFormatValue];
        [[timeDateView dateLabel] setText:[[dateFormat stringFromDate:[NSDate date]] capitalizedString]];
    }

    if (showWeatherSwitch) {
        if ([styleValue intValue] == 0) {
            if ([[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"Currently it's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"CURRENTLY_ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
            
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
        } else if ([styleValue intValue] == 1) {
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@, %@",[[PDDokdo sharedInstance] currentConditions], [[PDDokdo sharedInstance] currentTemperature]]];
        } else if ([styleValue intValue] == 2) {
            if ([[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"It's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
            
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
        }
    }
    
}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // stop timer when device was locked

	%orig;

	[timer invalidate];
	timer = nil;

}

%end

%hook SBBacklightController

- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 { // update heartlines when screen turns on

	%orig;

    if (![[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible]) return;
    if (showWeatherSwitch) [[PDDokdo sharedInstance] refreshWeatherData];
    if (showUpNextSwitch && [styleValue intValue] != 2) [[NSNotificationCenter defaultCenter] postNotificationName:@"heartlinesUpdateUpNext" object:nil];
	[self updateHeartlines];

	if (!timer) timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateHeartlines) userInfo:nil repeats:YES];

}

%new
- (void)updateHeartlines { // update heartlines

	if (!justPluggedIn) {
        NSDateFormatter* timeFormat = [NSDateFormatter new];
        [timeFormat setDateFormat:timeFormatValue];
        [[timeDateView timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
    }

	if (!isTimerRunning) {
        NSDateFormatter* dateFormat = [NSDateFormatter new];
        [dateFormat setDateFormat:dateFormatValue];
        [[timeDateView dateLabel] setText:[[dateFormat stringFromDate:[NSDate date]] capitalizedString]];
    }

    if (showWeatherSwitch) {
        if ([styleValue intValue] == 0) {
            if ([[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"Currently it's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"CURRENTLY_ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"CURRENTLY_ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
            
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
        } else if ([styleValue intValue] == 1) {
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@, %@",[[PDDokdo sharedInstance] currentConditions], [[PDDokdo sharedInstance] currentTemperature]]];
        } else if ([styleValue intValue] == 2) {
            if ([[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"It's %@", [[PDDokdo sharedInstance] currentTemperature]]];
            else if (![[HLSLocalization stringForKey:@"ITS"] isEqual:nil]) [[timeDateView weatherReportLabel] setText:[NSString stringWithFormat:@"%@ %@", [HLSLocalization stringForKey:@"ITS"], [[PDDokdo sharedInstance] currentTemperature]]];
            
            [[timeDateView weatherConditionLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];
        }
    }
    
}

%end

%hook SBFLockScreenDateSubtitleView

- (void)setString:(NSString *)arg1 { // apply running timer to the date label

    %orig;

    if ([arg1 containsString:@":"]) {
        isTimerRunning = YES;
        [[timeDateView dateLabel] setText:arg1];
    } else {
        isTimerRunning = NO;
    }

}

%end

%hook CSTodayViewController

- (void)viewWillAppear:(BOOL)animated { // fade heartlines out when today view appears

    %orig;

    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [faceIDLock setAlpha:0.0];
        [[timeDateView upNextLabel] setAlpha:0.0];
        [[timeDateView upNextEventLabel] setAlpha:0.0];
        [[timeDateView invisibleInk] setAlpha:0.0];
        [[timeDateView timeLabel] setAlpha:0.0];
        [[timeDateView dateLabel] setAlpha:0.0];
        [[timeDateView weatherReportLabel] setAlpha:0.0];
        [[timeDateView weatherConditionLabel] setAlpha:0.0];
    } completion:nil];

}

- (void)viewWillDisappear:(BOOL)animated { // fade heartlines in when today view disappears

    %orig;

    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [faceIDLock setAlpha:1.0];
        [[timeDateView upNextLabel] setAlpha:1.0];
        [[timeDateView upNextEventLabel] setAlpha:1.0];
        [[timeDateView invisibleInk] setAlpha:1.0];
        [[timeDateView timeLabel] setAlpha:1.0];
        [[timeDateView dateLabel] setAlpha:1.0];
        [[timeDateView weatherReportLabel] setAlpha:1.0];
        [[timeDateView weatherConditionLabel] setAlpha:1.0];
    } completion:nil];

}

%end

%hook CSCombinedListViewController

- (double)_minInsetsToPushDateOffScreen { // adjust notification list position depending on style

    if ([styleValue intValue] == 0) {
        if (showUpNextSwitch && showWeatherSwitch) {
            double orig = %orig;
            return orig + 65;
        } else if (!showUpNextSwitch && showWeatherSwitch) {
            double orig = %orig;
            return orig + 15;
        } else if (showUpNextSwitch && !showWeatherSwitch) {
            double orig = %orig;
            return orig + 20;
        } else if (!showUpNextSwitch && !showWeatherSwitch) {
            return %orig;
        } else {
            return %orig;
        }
    } else if ([styleValue intValue] == 1) {
        if (showUpNextSwitch && showWeatherSwitch) {
            double orig = %orig;
            return orig + 30;
        } else if (!showUpNextSwitch && showWeatherSwitch) {
            return %orig;
        } else if (showUpNextSwitch && !showWeatherSwitch) {
            double orig = %orig;
            return orig + 10;
        } else if (!showUpNextSwitch && !showWeatherSwitch) {
            return %orig;
        } else {
            return %orig;
        }
    } else if ([styleValue intValue] == 2) {
        double orig = %orig;
        return orig - 15;
    } else {
        return %orig;
    }

}

- (UIEdgeInsets)_listViewDefaultContentInsets { // adjust notification list position depending on style

    if ([styleValue intValue] == 0) {
        if (showUpNextSwitch && showWeatherSwitch) {
            UIEdgeInsets originalInsets = %orig;
            originalInsets.top += 65;
            return originalInsets;
        } else if (!showUpNextSwitch && showWeatherSwitch) {
            UIEdgeInsets originalInsets = %orig;
            originalInsets.top += 15;
            return originalInsets;
        } else if (showUpNextSwitch && !showWeatherSwitch) {
            UIEdgeInsets originalInsets = %orig;
            originalInsets.top += 20;
            return originalInsets;
        } else if (!showUpNextSwitch && !showWeatherSwitch) {
            return %orig;
        } else {
            return %orig;
        }
    } else if ([styleValue intValue] == 1) {
        if (showUpNextSwitch && showWeatherSwitch) {
            UIEdgeInsets originalInsets = %orig;
            originalInsets.top += 30;
            return originalInsets;
        } else if (!showUpNextSwitch && showWeatherSwitch) {
            return %orig;
        } else if (showUpNextSwitch && !showWeatherSwitch) {
            UIEdgeInsets originalInsets = %orig;
            originalInsets.top += 10;
            return originalInsets;
        } else if (!showUpNextSwitch && !showWeatherSwitch) {
            return %orig;
        } else {
            return %orig;
        }
    } else if ([styleValue intValue] == 2) {
        UIEdgeInsets originalInsets = %orig;
        originalInsets.top -= 15;
        return originalInsets;
    } else {
        return %orig;
    }

}

%end

%hook SBUIController

- (void)ACPowerChanged { // display battery percentage in the time label when plugged in

	%orig;

	if ([self isOnAC]) {
        justPluggedIn = YES;
        [UIView transitionWithView:[timeDateView timeLabel] duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			[[timeDateView timeLabel] setText:[NSString stringWithFormat:@"%d%%", [self batteryCapacityAsPercentage]]];
		} completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView transitionWithView:[timeDateView timeLabel] duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    NSDateFormatter* timeFormat = [NSDateFormatter new];
                    [timeFormat setDateFormat:timeFormatValue];
                    [[timeDateView timeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];
                } completion:nil];
                justPluggedIn = NO;
            });
        }];
    }

}

%end

%hook CSCoverSheetViewController

- (void)_transitionChargingViewToVisible:(BOOL)arg1 showBattery:(BOOL)arg2 animated:(BOOL)arg3 { // hide charging view

	%orig(NO, NO, NO);

}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 completion:(id)arg3 { // unhide invisible ink and hide up next when authenticated

    %orig;

    if (!hideUntilAuthenticatedSwitch) return;
    isLocked = YES;
    [UIView transitionWithView:[timeDateView upNextEventLabel] duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [[timeDateView upNextEventLabel] setHidden:YES];
    } completion:nil];
    [UIView transitionWithView:[timeDateView invisibleInk] duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if (invisibleInkEffectSwitch) [[timeDateView invisibleInk] setHidden:NO];
    } completion:nil];

}

%end

%hook SBDashBoardLockScreenEnvironment

- (void)setAuthenticated:(BOOL)arg1 { // hide invisible ink and unhide up next when authenticated

	%orig;

    if (!hideUntilAuthenticatedSwitch) return;
	if (arg1) {
        isLocked = NO;
        [UIView transitionWithView:[timeDateView upNextEventLabel] duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [[timeDateView upNextEventLabel] setHidden:NO];
        } completion:nil];
        [UIView transitionWithView:[timeDateView invisibleInk] duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            if (invisibleInkEffectSwitch) [[timeDateView invisibleInk] setHidden:YES];
        } completion:nil];
    }

}

%end

%end

%group HeartlinesData

%hook SBMediaController

- (void)setNowPlayingInfo:(id)arg1 { // get artwork colors

    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary* dict = (__bridge NSDictionary *)information;

            currentArtwork = [UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]];

            if (dict) {
                if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
                    if (![lastArtworkData isEqual:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]) {
                        // get artwork colors
                        backgroundArtworkColor = [libKitten backgroundColor:currentArtwork];
                        primaryArtworkColor = [libKitten primaryColor:currentArtwork];
                        secondaryArtworkColor = [libKitten secondaryColor:currentArtwork];

                        // set artwork colors
                        if ([faceIDLockArtworkColorValue intValue] == 0)
                            [faceIDLock setContentColor:backgroundArtworkColor];
                        else if ([faceIDLockArtworkColorValue intValue] == 1)
                            [faceIDLock setContentColor:primaryArtworkColor];
                        else if ([faceIDLockArtworkColorValue intValue] == 2)
                            [faceIDLock setContentColor:secondaryArtworkColor];

                        if (showUpNextSwitch) {
                            if ([upNextArtworkColorValue intValue] == 0)
                                [[timeDateView upNextLabel] setTextColor:backgroundArtworkColor];
                            else if ([upNextArtworkColorValue intValue] == 1)
                                [[timeDateView upNextLabel] setTextColor:primaryArtworkColor];
                            else if ([upNextArtworkColorValue intValue] == 2)
                                [[timeDateView upNextLabel] setTextColor:secondaryArtworkColor];

                            if ([upNextEventArtworkColorValue intValue] == 0)
                                [[timeDateView upNextEventLabel] setTextColor:backgroundArtworkColor];
                            else if ([upNextEventArtworkColorValue intValue] == 1)
                                [[timeDateView upNextEventLabel] setTextColor:primaryArtworkColor];
                            else if ([upNextEventArtworkColorValue intValue] == 2)
                                [[timeDateView upNextEventLabel] setTextColor:secondaryArtworkColor];
                        }

                        if ([timeArtworkColorValue intValue] == 0)
                            [[timeDateView timeLabel] setTextColor:backgroundArtworkColor];
                        else if ([timeArtworkColorValue intValue] == 1)
                            [[timeDateView timeLabel] setTextColor:primaryArtworkColor];
                        else if ([timeArtworkColorValue intValue] == 2)
                            [[timeDateView timeLabel] setTextColor:secondaryArtworkColor];

                        if ([dateArtworkColorValue intValue] == 0)
                            [[timeDateView dateLabel] setTextColor:backgroundArtworkColor];
                        else if ([dateArtworkColorValue intValue] == 1)
                            [[timeDateView dateLabel] setTextColor:primaryArtworkColor];
                        else if ([dateArtworkColorValue intValue] == 2)
                            [[timeDateView dateLabel] setTextColor:secondaryArtworkColor];

                        if (showWeatherSwitch) {
                            if ([weatherReportArtworkColorValue intValue] == 0)
                                [[timeDateView weatherReportLabel] setTextColor:backgroundArtworkColor];
                            else if ([weatherReportArtworkColorValue intValue] == 1)
                                [[timeDateView weatherReportLabel] setTextColor:primaryArtworkColor];
                            else if ([weatherReportArtworkColorValue intValue] == 2)
                                [[timeDateView weatherReportLabel] setTextColor:secondaryArtworkColor];

                            if ([weatherConditionArtworkColorValue intValue] == 0)
                                [[timeDateView weatherConditionLabel] setTextColor:backgroundArtworkColor];
                            else if ([weatherConditionArtworkColorValue intValue] == 1)
                                [[timeDateView weatherConditionLabel] setTextColor:primaryArtworkColor];
                            else if ([weatherConditionArtworkColorValue intValue] == 2)
                                [[timeDateView weatherConditionLabel] setTextColor:secondaryArtworkColor];
                        }

                    }

                    lastArtworkData = [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData];
                }
            }
        } else { // reset colors when nothing is playing
            if ([faceIDLockColorValue intValue] == 0)
                [faceIDLock setContentColor:backgroundWallpaperColor];
            else if ([faceIDLockColorValue intValue] == 1)
                [faceIDLock setContentColor:primaryWallpaperColor];
            else if ([faceIDLockColorValue intValue] == 2)
                [faceIDLock setContentColor:secondaryWallpaperColor];
            else if ([faceIDLockColorValue intValue] == 3)
                [faceIDLock setContentColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customFaceIDLockColor"] withFallback:@"#FFFFFF"]];

            if (showUpNextSwitch) {
                if ([upNextColorValue intValue] == 0)
                    [[timeDateView upNextLabel] setTextColor:backgroundWallpaperColor];
                else if ([upNextColorValue intValue] == 1)
                    [[timeDateView upNextLabel] setTextColor:primaryWallpaperColor];
                else if ([upNextColorValue intValue] == 2)
                    [[timeDateView upNextLabel] setTextColor:secondaryWallpaperColor];
                else if ([upNextColorValue intValue] == 3)
                    [[timeDateView upNextLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customUpNextColor"] withFallback:@"#FFFFFF"]];

                if ([upNextEventColorValue intValue] == 0)
                    [[timeDateView upNextEventLabel] setTextColor:backgroundWallpaperColor];
                else if ([upNextEventColorValue intValue] == 1)
                    [[timeDateView upNextEventLabel] setTextColor:primaryWallpaperColor];
                else if ([upNextEventColorValue intValue] == 2)
                    [[timeDateView upNextEventLabel] setTextColor:secondaryWallpaperColor];
                else if ([upNextEventColorValue intValue] == 3)
                    [[timeDateView upNextEventLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customUpNextEventColor"] withFallback:@"#FFFFFF"]];
            }

            if ([timeColorValue intValue] == 0)
                [[timeDateView timeLabel] setTextColor:backgroundWallpaperColor];
            else if ([timeColorValue intValue] == 1)
                [[timeDateView timeLabel] setTextColor:primaryWallpaperColor];
            else if ([timeColorValue intValue] == 2)
                [[timeDateView timeLabel] setTextColor:secondaryWallpaperColor];
            else if ([timeColorValue intValue] == 3)
                [[timeDateView timeLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customTimeColor"] withFallback:@"#FFFFFF"]];

            if ([dateColorValue intValue] == 0)
                [[timeDateView dateLabel] setTextColor:backgroundWallpaperColor];
            else if ([dateColorValue intValue] == 1)
                [[timeDateView dateLabel] setTextColor:primaryWallpaperColor];
            else if ([dateColorValue intValue] == 2)
                [[timeDateView dateLabel] setTextColor:secondaryWallpaperColor];
            else if ([dateColorValue intValue] == 3)
                [[timeDateView dateLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customDateColor"] withFallback:@"#FFFFFF"]];

            if (showWeatherSwitch) {
                if ([weatherReportColorValue intValue] == 0)
                    [[timeDateView weatherReportLabel] setTextColor:backgroundWallpaperColor];
                else if ([weatherReportColorValue intValue] == 1)
                    [[timeDateView weatherReportLabel] setTextColor:primaryWallpaperColor];
                else if ([weatherReportColorValue intValue] == 2)
                    [[timeDateView weatherReportLabel] setTextColor:secondaryWallpaperColor];
                else if ([weatherReportColorValue intValue] == 3)
                    [[timeDateView weatherReportLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customWeatherReportColor"] withFallback:@"#FFFFFF"]];

                if ([weatherConditionColorValue intValue] == 0)
                    [[timeDateView weatherConditionLabel] setTextColor:backgroundWallpaperColor];
                else if ([weatherConditionColorValue intValue] == 1)
                    [[timeDateView weatherConditionLabel] setTextColor:primaryWallpaperColor];
                else if ([weatherConditionColorValue intValue] == 2)
                    [[timeDateView weatherConditionLabel] setTextColor:secondaryWallpaperColor];
                else if ([weatherConditionColorValue intValue] == 3)
                    [[timeDateView weatherConditionLabel] setTextColor:[SparkColourPickerUtils colourWithString:[preferencesColorDictionary objectForKey:@"customWeatherConditionColor"] withFallback:@"#FFFFFF"]];
            }
        }
  	});
    
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // reload data after respring

    %orig;

    [[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];
    
}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.heartlinespreferences"];
    preferencesColorDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/love.litten.heartlines.colorspreferences.plist"];

	[preferences registerBool:&enabled default:nil forKey:@"Enabled"];
    if (!enabled) return;

    // style & position
    [preferences registerObject:&styleValue default:@"0" forKey:@"style"];
    [preferences registerObject:&positionValue default:@"0" forKey:@"position"];

    // faceid lock
    [preferences registerBool:&hideFaceIDLockSwitch default:NO forKey:@"hideFaceIDLock"];
    [preferences registerBool:&alignFaceIDLockSwitch default:YES forKey:@"alignFaceIDLock"];
    [preferences registerBool:&smallerFaceIDLockSwitch default:YES forKey:@"smallerFaceIDLock"];

    // text
    [preferences registerBool:&useCustomFontSwitch default:NO forKey:@"useCustomFont"];
    [preferences registerObject:&timeFormatValue default:@"HH:mm" forKey:@"timeFormat"];
    [preferences registerObject:&dateFormatValue default:@"EEEE d MMMM" forKey:@"dateFormat"];
    [preferences registerBool:&useCustomUpNextFontSizeSwitch default:NO forKey:@"useCustomUpNextFontSize"];
    [preferences registerObject:&customUpNextFontSizeValue default:@"19.0" forKey:@"customUpNextFontSize"];
    [preferences registerBool:&useCustomUpNextEventFontSizeSwitch default:NO forKey:@"useCustomUpNextEventFontSize"];
    [preferences registerObject:&customUpNextEventFontSizeValue default:@"15.0" forKey:@"customUpNextEventFontSize"];
    [preferences registerBool:&useCustomTimeFontSizeSwitch default:NO forKey:@"useCustomTimeFontSize"];
    [preferences registerObject:&customTimeFontSizeValue default:@"61.0" forKey:@"customTimeFontSize"];
    [preferences registerBool:&useCustomDateFontSizeSwitch default:NO forKey:@"useCustomDateFontSize"];
    [preferences registerObject:&customDateFontSizeValue default:@"17.0" forKey:@"customDateFontSize"];
    [preferences registerBool:&useCustomWeatherReportFontSizeSwitch default:NO forKey:@"useCustomWeatherReportFontSize"];
    [preferences registerObject:&customWeatherReportFontSizeValue default:@"14.0" forKey:@"customWeatherReportFontSize"];
    [preferences registerBool:&useCustomWeatherConditionFontSizeSwitch default:NO forKey:@"useCustomWeatherConditionFontSize"];
    [preferences registerObject:&customWeatherConditionFontSizeValue default:@"14.0" forKey:@"customWeatherConditionFontSize"];

    // colors
    [preferences registerObject:&faceIDLockColorValue default:@"3" forKey:@"faceIDLockColor"];
    [preferences registerObject:&upNextColorValue default:@"3" forKey:@"upNextColor"];
    [preferences registerObject:&upNextEventColorValue default:@"1" forKey:@"upNextEventColor"];
    [preferences registerObject:&timeColorValue default:@"3" forKey:@"timeColor"];
    [preferences registerObject:&dateColorValue default:@"3" forKey:@"dateColor"];
    [preferences registerObject:&weatherReportColorValue default:@"1" forKey:@"weatherReportColor"];
    [preferences registerObject:&weatherConditionColorValue default:@"1" forKey:@"weatherConditionColor"];
    [preferences registerBool:&artworkBasedColorsSwitch default:YES forKey:@"artworkBasedColors"];
    [preferences registerObject:&faceIDLockArtworkColorValue default:@"0" forKey:@"faceIDLockArtworkColor"];
    [preferences registerObject:&upNextArtworkColorValue default:@"0" forKey:@"upNextArtworkColor"];
    [preferences registerObject:&upNextEventArtworkColorValue default:@"2" forKey:@"upNextEventArtworkColor"];
    [preferences registerObject:&timeArtworkColorValue default:@"0" forKey:@"timeArtworkColor"];
    [preferences registerObject:&dateArtworkColorValue default:@"0" forKey:@"dateArtworkColor"];
    [preferences registerObject:&weatherReportArtworkColorValue default:@"2" forKey:@"weatherReportArtworkColor"];
    [preferences registerObject:&weatherConditionArtworkColorValue default:@"2" forKey:@"weatherConditionArtworkColor"];

    // weather
    [preferences registerBool:&showWeatherSwitch default:YES forKey:@"showWeather"];

    // up next
    [preferences registerBool:&showUpNextSwitch default:YES forKey:@"showUpNext"];
    [preferences registerBool:&showCalendarEventsSwitch default:YES forKey:@"showCalendarEvents"];
    [preferences registerBool:&showRemindersSwitch default:YES forKey:@"showReminders"];
    [preferences registerBool:&showNextAlarmSwitch default:YES forKey:@"showNextAlarm"];
    [preferences registerBool:&prioritizeRemindersSwitch default:NO forKey:@"prioritizeReminders"];
    [preferences registerBool:&prioritizeAlarmsSwitch default:YES forKey:@"prioritizeAlarms"];
    [preferences registerObject:&dayRangeValue default:@"3" forKey:@"dayRange"];
    [preferences registerBool:&hideUntilAuthenticatedSwitch default:NO forKey:@"hideUntilAuthenticated"];
    [preferences registerBool:&invisibleInkEffectSwitch default:YES forKey:@"invisibleInkEffect"];

    // miscellaneous
    [preferences registerBool:&magsafeCompatibilitySwitch default:NO forKey:@"magsafeCompatibility"];

    if (hideUntilAuthenticatedSwitch && invisibleInkEffectSwitch) dlopen("/System/Library/PrivateFrameworks/ChatKit.framework/ChatKit", RTLD_NOW);
	%init(Heartlines);
	if (artworkBasedColorsSwitch) %init(HeartlinesData);

}