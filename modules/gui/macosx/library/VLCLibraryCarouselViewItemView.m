/*****************************************************************************
 * VLCLibraryCarouselViewItemView.m: MacOS X interface module
 *****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
 *
 * Authors: Claudio Cambra <developer@claudiocambra.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCLibraryCarouselViewItemView.h"

#import "extensions/NSColor+VLCAdditions.h"
#import "extensions/NSFont+VLCAdditions.h"
#import "extensions/NSString+Helpers.h"
#import "extensions/NSView+VLCAdditions.h"

#import "library/VLCLibraryDataTypes.h"
#import "library/VLCLibraryImageCache.h"

#import "views/VLCImageView.h"

@implementation VLCLibraryCarouselViewItemView

+ (instancetype)fromNibWithOwner:(id)owner
{
    return (VLCLibraryCarouselViewItemView *)[NSView fromNibNamed:@"VLCLibraryCarouselViewItemView"
                                                        withClass:VLCLibraryCarouselViewItemView.class
                                                        withOwner:owner];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.titleTextField.font = NSFont.VLCLibrarySubsectionHeaderFont;
    self.detailTextField.font = NSFont.VLCLibrarySubsectionSubheaderFont;
    self.annotationTextField.font = NSFont.VLCLibraryItemAnnotationFont;
    self.annotationTextField.textColor = NSColor.VLClibraryAnnotationColor;
    self.annotationTextField.backgroundColor = NSColor.VLClibraryAnnotationBackgroundColor;

    [self prepareForReuse];
}

- (void)prepareForReuse
{
    self.playButton.hidden = YES;
    self.annotationTextField.hidden = YES;
    self.titleTextField.stringValue = @"";
    self.detailTextField.stringValue = @"";
    self.imageView.image = nil;
}

- (void)updateRepresentation
{
    [self prepareForReuse];

    [VLCLibraryImageCache thumbnailForLibraryItem:_representedItem withCompletion:^(NSImage * const thumbnail) {
        self.imageView.image = thumbnail;
    }];

    self.titleTextField.stringValue = self.representedItem.displayString;
    self.detailTextField.stringValue = self.representedItem.detailString;

    if ([_representedItem isKindOfClass:VLCMediaLibraryMediaItem.class]) {
        VLCMediaLibraryMediaItem * const mediaItem = (VLCMediaLibraryMediaItem *)self.representedItem;
        if (mediaItem.mediaType == VLC_ML_MEDIA_TYPE_VIDEO) {
            VLCMediaLibraryTrack * const videoTrack = mediaItem.firstVideoTrack;
            [self showVideoSizeIfNeededForWidth:videoTrack.videoWidth andHeight:videoTrack.videoHeight];
        }
    }
}

- (void)showVideoSizeIfNeededForWidth:(CGFloat)width andHeight:(CGFloat)height
{
    if (width >= VLCMediaLibrary4KWidth || height >= VLCMediaLibrary4KHeight) {
        _annotationTextField.stringValue = _NS("4K");
        _annotationTextField.hidden = NO;
    } else if (width >= VLCMediaLibrary720pWidth || height >= VLCMediaLibrary720pHeight) {
        _annotationTextField.stringValue = _NS("HD");
        _annotationTextField.hidden = NO;
    }
}

- (void)setRepresentedItem:(id<VLCMediaLibraryItemProtocol>)representedItem
{
    if (representedItem == _representedItem) {
        return;
    }

    _representedItem = representedItem;
    [self updateRepresentation];
}

@end
