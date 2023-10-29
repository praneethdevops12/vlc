/*****************************************************************************
 * VLCLibraryRepresentedItem.m: MacOS X interface module
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

#import "VLCLibraryRepresentedItem.h"

#import "extensions/NSString+Helpers.h"

#import "library/VLCLibraryDataTypes.h"
#import "library/audio-library/VLCLibraryAllAudioGroupsMediaLibraryItem.h"

@interface VLCLibraryRepresentedItem ()
{
    NSInteger _itemIndexInParent;
    id<VLCMediaLibraryItemProtocol> _parentItem;
}
@end

@implementation VLCLibraryRepresentedItem

- (instancetype)initWithItem:(const id<VLCMediaLibraryItemProtocol>)item
                  parentType:(const enum vlc_ml_parent_type)parentType
{
    self = [self init];
    if (self) {
        _item = item;
        _parentType = parentType;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _itemIndexInParent = NSNotFound;
}

- (NSInteger)itemIndexInParent
{
    if (_itemIndexInParent != NSNotFound) {
        return _itemIndexInParent;
    }

    __block NSInteger index = 0;
    const NSInteger itemId = self.item.libraryID;

    [self.item iterateMediaItemsWithBlock:^(VLCMediaLibraryMediaItem * const mediaItem) {
        if (mediaItem.libraryID == itemId) {
            return;
        }

        index++;
    }];

    _itemIndexInParent = index;
    return _itemIndexInParent;
}

- (const id<VLCMediaLibraryItemProtocol>)parentItemForItem:(const id<VLCMediaLibraryItemProtocol>)item
{
    const enum vlc_ml_parent_type parentType = self.parentType;
    if (parentType == VLC_ML_PARENT_UNKNOWN) {
        return [[VLCLibraryAllAudioGroupsMediaLibraryItem alloc] initWithDisplayString:_NS("All items")];
    }

    // Decide which other items we are going to be adding to the playlist when playing the item.
    // Key for playing in library mode, not in individual mode
    int64_t parentItemId = -1;

    if ([item isKindOfClass:VLCMediaLibraryMediaItem.class]) {
        VLCMediaLibraryMediaItem * const mediaItem = (VLCMediaLibraryMediaItem *)item;

        switch (parentType) {
        case VLC_ML_PARENT_ALBUM:
            parentItemId = mediaItem.albumID;
            break;
        case VLC_ML_PARENT_ARTIST:
            parentItemId = mediaItem.artistID;
            break;
        case VLC_ML_PARENT_GENRE:
            parentItemId = mediaItem.genreID;
            break;
        default:
            break;
        }
    } else if ([item isKindOfClass:VLCMediaLibraryAlbum.class]) {
        VLCMediaLibraryAlbum * const album = (VLCMediaLibraryAlbum *)item;

        switch (parentType) {
        case VLC_ML_PARENT_ARTIST:
            parentItemId = album.artistID;
            break;
        case VLC_ML_PARENT_GENRE:
        {
            VLCMediaLibraryMediaItem * const firstChildItem = album.firstMediaItem;
            parentItemId = firstChildItem.genreID;
            break;
        }
        default:
            break;
        }
    }

    if (parentItemId < 0) {
        return nil;
    }

    switch (parentType) {
    case VLC_ML_PARENT_ALBUM:
        return [VLCMediaLibraryAlbum albumWithID:parentItemId];
    case VLC_ML_PARENT_ARTIST:
        return [VLCMediaLibraryArtist artistWithID:parentItemId];
    case VLC_ML_PARENT_GENRE:
        return [VLCMediaLibraryGenre genreWithID:parentItemId];
    default:
        return nil;
    }
}

- (id<VLCMediaLibraryItemProtocol>)parentItem
{
    if (_parentItem != nil) {
        return _parentItem;
    }

    _parentItem = [self parentItemForItem:self.item];
    return _parentItem;
}

@end