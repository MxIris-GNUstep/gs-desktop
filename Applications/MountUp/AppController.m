/* 
   Project: MountUp

   Created: 2023-08-09 19:25:27 +0000 by oflorian
   
   Application Controller
*/

#import "AppController.h"
#import "STScriptingSupport.h"
#import "MiniView.h"
#import "ServiceTask.h"
#import "LoopbackServiceTask.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
     MiniView *mv = [[MiniView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [[NSApp iconWindow] setContentView:mv];

    disks = [OSEUDisksAdaptor new];
    volumes = [NSMutableArray new];
    services = [[ServiceManager alloc]init];
  }
  return self;
}

- (void) dealloc {
  [volumes release];
  [disks release];
  [services release];

  [super dealloc];
}

- (void) awakeFromNib {
  [mountPanel setFrameAutosaveName:@"mount_window"];
  [volumesPanel setFrameAutosaveName:@"volume_window"];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif {
  [volumesBrowser setDelegate:self];
  [volumesBrowser setAction:@selector(selectRow)];
  [volumesBrowser setDoubleAction:@selector(open:)];

  [[[NSApp iconWindow] contentView] addSubview:controlView];
  [controlView setFrame:NSMakeRect(8, 8, 48, 48)];
  [controlView setNeedsDisplay:YES];
  
  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(didReceiveDeviceNotification:)
             name:OSEDiskAppeared
           object:nil];

  [nc addObserver:self
         selector:@selector(didReceiveDeviceNotification:)
             name:OSEDiskDisappeared
           object:nil];

  [nc addObserver:self
         selector:@selector(didReceiveServiceNotification:)
             name:@"serviceStatusHasChanged"
           object:nil];

  [self refreshDrives];
}

- (BOOL) applicationShouldTerminate: (id)sender {
  [services stopAllServices];
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif {
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName {

  [self openLoopbackFile:fileName];
  return NO;
}

- (void) openDocument:(id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  if ([panel runModal]) {
    [self openLoopbackFile:[panel filename]];
  }
}

- (void) openLoopbackFile:(NSString*) fileName {
  LoopbackServiceTask* lser = [[LoopbackServiceTask alloc]initWithName:fileName];
  [services startService:lser];
}

- (void) didReceiveServiceNotification:(NSNotification*) val {
  ServiceTask* ser = [val object];
  if ([ser isMounted]) {
    NSString* p = [ser mountPoint];
    if ([p length]) {
      [[NSWorkspace sharedWorkspace] selectFile:@"." inFileViewerRootedAtPath:p];
    }
  }

  [self performSelector:@selector(refreshDrives) withObject:nil afterDelay:1.0];
}

- (void) didReceiveDeviceNotification:(NSNotification*) val {
  NSLog(@"device notification:%@", val);
  [self performSelector:@selector(refreshDrives) withObject:nil afterDelay:1.0];
}

- (NSInteger) browser:(NSBrowser*) browser numberOfRowsInColumn:(NSInteger) col {
  return [volumes count];
}

- (BOOL)browser:(NSBrowser *)sender selectRow:(NSInteger)row inColumn:(NSInteger)col {
  return YES;
}

- (void) browser:(NSBrowser*) browser willDisplayCell:(NSBrowserCell*) cell atRow:(NSInteger)row column:(NSInteger)col {
  [cell setLeaf:YES];

  id d = [volumes objectAtIndex:row];
  if ([d isKindOfClass:[OSEUDisksVolume class]]) {
    OSEUDisksVolume* vol = d;
    NSString* title = [NSString stringWithFormat:@"%@: %@", [[vol drive]humanReadableName], [vol label]];
    [cell setStringValue:title];
  }
  else if ([d isKindOfClass:[ServiceTask class]]) {
    ServiceTask* ser = d;
    NSString* title = [NSString stringWithFormat:@"local: %@", [ser name]];
    [cell setStringValue:title];
  }
}

- (void) selectRow {
  [self refreshInfo];
}

- (void) refreshInfo {
  NSInteger row = [volumesBrowser selectedRowInColumn:0];
  if (row >= 0) {
    id d = [volumes objectAtIndex:row];
    if ([d isKindOfClass:[OSEUDisksVolume class]]) {
      OSEUDisksVolume* vol = d;

      NSString* stat = @"";
      if ([vol isMounted]) {
        stat = @"mounted";
        [actionButton setTitle:@"Eject"];
        [actionButton setEnabled:YES];
        [openButton setEnabled:YES];
      }
      else {
        [actionButton setTitle:@"Mount"];
        [actionButton setEnabled:YES];
        [openButton setEnabled:NO];
      }

      [device setStringValue:[vol UNIXDevice]];
      [path setStringValue:[vol mountPoints]];
      [status setStringValue:stat];
    }
    else if ([d isKindOfClass:[ServiceTask class]]) {
      ServiceTask* ser = d;
      if ([ser isMounted]) {
        [device setStringValue:[ser UNIXDevice]];
        [path setStringValue:[ser mountPoint]];
        [status setStringValue:@"mounted"];

        [actionButton setTitle:@"Unmout"];
        [actionButton setEnabled:YES];
        [openButton setEnabled:YES];
      }
      else {
        [actionButton setTitle:@"Mount"];
        [actionButton setEnabled:NO];
        [openButton setEnabled:NO];
      }
    }
  }
  else {
    [device setStringValue:@""];
    [path setStringValue:@""];
    [status setStringValue:@""];
    [actionButton setEnabled:NO];
    [openButton setEnabled:NO];
  }
}

- (void) refreshDrives {
  [volumes removeAllObjects];

  id d;
  NSEnumerator* e = [[disks availableDrives] objectEnumerator];
  while ((d = [e nextObject]) != nil) {
    NSDictionary* vl = [disks availableVolumesForDrive:[d objectPath]];
    NSEnumerator *ve = [vl objectEnumerator];
    OSEUDisksVolume *vol;
        
    while ((vol = [ve nextObject]) != nil) {
      if ([vol isFilesystem] && ![vol isSystem]) {
        [volumes addObject:vol];
      }
    }
  }

  e = [[services listServices] objectEnumerator];
  while ((d = [e nextObject]) != nil) {
    [volumes addObject:d];
  }

  [volumesBrowser reloadColumn:0];
  [self refreshInfo];
}

- (void) open:(id)sender {
  NSInteger row = [volumesBrowser selectedRowInColumn:0];
  id d = [volumes objectAtIndex:row];

  if ([d isKindOfClass:[OSEUDisksVolume class]]) {
    OSEUDisksVolume* vol = d;
    if (![vol isMounted]) {
      return;
    }

    NSString* p = [vol mountPoints];
    if ([p length]) {
      [[NSWorkspace sharedWorkspace] selectFile:@"." inFileViewerRootedAtPath:p];
    }
  }
  else if ([d isKindOfClass:[ServiceTask class]]) {
    ServiceTask* ser = d;
    NSString* p = [ser mountPoint];
    if ([p length]) {
      [[NSWorkspace sharedWorkspace] selectFile:@"." inFileViewerRootedAtPath:p];
    }
  }

  [self refreshInfo];
}

- (void) ejectLastMounted:(id)sender {
  for (id d in volumes) {
    if ([d isMounted]) {
      if ([d isKindOfClass:[OSEUDisksVolume class]]) {
        OSEUDisksVolume* vol = d;
        [[vol drive]unmountVolumes:YES];
        if ([[vol drive]isEjectable]) {
          [[vol drive]eject:YES];
          break;
        }
        else {
          break;
        }
      }
      else if ([d isKindOfClass:[ServiceTask class]]) {
        [services stopService:d];
        break;
      }
    }
  }

  [self performSelector:@selector(refreshDrives) withObject:nil afterDelay:1.0];
}

- (void) mountOrEject:(id)sender {
  NSInteger row = [volumesBrowser selectedRowInColumn:0];
  id d = [volumes objectAtIndex:row];

  if ([d isKindOfClass:[OSEUDisksVolume class]]) {
    OSEUDisksVolume* vol = d;
    if ([vol isMounted]) {
      [[vol drive]unmountVolumes:YES];

      if ([[vol drive]isEjectable]) {
        [[vol drive]eject:YES];
      }
    }
    else {
      [[vol drive]mountVolumes:YES];
    }
  }
  else if ([d isKindOfClass:[ServiceTask class]]) {
    ServiceTask* ser = d;
    if ([ser isMounted]) {
      [services stopService:ser];
    }
  }

  [self refreshDrives];
}

- (void) showPrefPanel:(id)sender {
}

- (void) showMountPanel:(id)sender {
  [mountPanel makeKeyAndOrderFront:sender];
}

- (void) showVolumesPanel:(id)sender {
  [self refreshDrives];
  [volumesPanel makeKeyAndOrderFront:sender];
}

@end
