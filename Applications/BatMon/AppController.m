/* 
   Project: batmon

   Copyright (C) 2005-2016 GNUstep Application Project

   Author: Riccardo Mottola

   Created: 2005-06-25 21:06:19 +0200 by multix
   
   Application Controller

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <math.h>
#import "AppController.h"

@implementation AppController

+ (void)initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];


  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init
{
    if ((self = [super init]))
      {
        batModel = [[BatteryModel alloc] init];
       
        /* localization */
        [rateLabel setStringValue:_(@"Discharge Rate")];

        batteryView = [[BatteryView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64) batteryModel:batModel];
        [batteryView setTarget:self];
        [batteryView setDoubleAction:@selector(showMonitor:)];
        [[NSApp iconWindow] setContentView:batteryView];
        [batteryView release];
      }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  NSTimer *timer;

  [self updateInfo:nil];
  
  timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateInfo:) userInfo:nil repeats:YES];
  [timer fire];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  return NO;
}

- (IBAction)showMonitor:(id)sender
{
  [monitorWin makeKeyAndOrderFront:nil];
}

- (IBAction)showBattInfo:(id)sender
{
  [infoWin makeKeyAndOrderFront:self];
}

- (void)showPrefPanel:(id)sender
{
}

- (IBAction)updateInfo:(id)sender
{
    float lifeVal;
    float timeRem;
    float chargePercentToDraw; /* we need this because chargePercent can go beyond 100% */

    [batModel update];

    chargePercentToDraw = [batModel chargePercent];
    if (chargePercentToDraw > 100)
        chargePercentToDraw = 100;

    /* main window */
    timeRem = [batModel timeRemaining];
    hours = timeRem;
    mins = (int)((timeRem - (float)hours) * 60);

    [voltage setStringValue:[NSString stringWithFormat:@"%3.2f V", [batModel volts]]];
    [level setDoubleValue:chargePercentToDraw];
    [percent setStringValue:[NSString stringWithFormat:@"%3.1f%%", [batModel chargePercent]]];
    [amperage setStringValue:[NSString stringWithFormat:@"%3.2f A", [batModel amps]]];
    [rate setStringValue:[NSString stringWithFormat:@"%3.2f W", [batModel watts]]];
    if (timeRem >= 0)
        [timeLeft setStringValue:[NSString stringWithFormat:@"%dh %d\'", hours, mins]];
    else
        [timeLeft setStringValue:@"unknown"];
    [chState setStringValue:[batModel state]];

    if ([batModel isUsingWattHours])
      [presentCap setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel remainingCapacity]]];
    else 
      [presentCap setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel remainingCapacity]]];
    
    if ([batModel isCharging])
      [rateLabel setStringValue:_(@"Charge Rate")];
    else
      [rateLabel setStringValue:_(@"Discharge Rate")];

    /* info window */
    lifeVal = [batModel lastCapacity]/[batModel designCapacity];
    [lifeGauge setDoubleValue:lifeVal*100];
    [lifeGaugePercent setStringValue:[NSString stringWithFormat:@"%3.1f%%", lifeVal*100]];

    [battType setStringValue:[batModel batteryType]];
    [manufacturer setStringValue:[batModel manufacturer]];

    if ([batModel isUsingWattHours])
      {
	[designCap setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel designCapacity]]];
	[lastFullCharge setStringValue:[NSString stringWithFormat:@"%3.2f Wh", [batModel lastCapacity]]];
      }
    else
      {
	[designCap setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel designCapacity]]];
	[lastFullCharge setStringValue:[NSString stringWithFormat:@"%3.2f Ah", [batModel lastCapacity]]];
      }

	[batteryView setNeedsDisplay:YES];
}

@end
