/* 
   Project: NotMon

   Created: 2023-07-08 22:24:53 +0200 by oflorian
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "MessageController.h"

@interface AppController : NSObject
{
  NSTextField* panelTitle;
  NSTextField* panelInfo;
  NSProgressIndicator* panelProgress;
  NSPanel* panel;

  NSMutableArray* messages;

  BOOL launched;
}

+ (void)  initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) showPanelWithTitle:(NSString*) title 
                       info:(NSString*) info;
- (void) hidePanelAfter:(NSTimeInterval) time;

- (void) showPrefPanel:(id)sender;
- (void) removeMessageController:(id) mctrl;

@end

#endif