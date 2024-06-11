/* -*- mode: objc -*- */
//
// Project: SoundKit framework.
//
// Copyright (C) 2019 Sergii Stoian
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
// 
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#include <pulse/pulseaudio.h>
#include <pulse/ext-stream-restore.h>
#import <Foundation/Foundation.h>

@interface PAStream : NSObject
{
  pa_ext_stream_restore_info *info_copy;
  pa_context *context;
  NSString   *name;
  NSString   *deviceName;

  NSUInteger volume;
  CGFloat    balance;
  BOOL       mute;
}

@property (assign) pa_context *context;
@property (retain) NSString   *name;
@property (retain) NSString   *deviceName;

@property (assign) NSUInteger volume;
@property (assign) CGFloat    balance;
@property (assign) BOOL       mute;

- (id)updateWithValue:(NSValue *)value;

- (NSString *)clientName;
- (NSString *)typeName;

- (void)applyMute:(BOOL)isMute;
- (NSUInteger)volume;
- (void)applyVolume:(NSUInteger)v;
- (void)applyBalance:(CGFloat)balance;

@end
