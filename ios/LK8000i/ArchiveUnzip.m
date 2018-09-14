//
//  MyMain.m
//  LK8000i
//
//  Created by Nicola Ferruzzi on 06/03/16.
//  Copyright © 2016 Nicola Ferruzzi. All rights reserved.
//

#import "ArchiveUnzip.h"
#import <ZipUtilities/NOZUnzipper.h>

@interface ArchiveUnzip ()
@end

@implementation ArchiveUnzip

+ (NSString *)pathForArchiveRoot:(NSString *)filename
{
    static dispatch_once_t onceToken;
    static NSString *path;
    
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        path = [paths objectAtIndex:0];
        path = [NSString stringWithFormat:@"%@/", path];
    });
    
    
    if (filename) {
        return [NSString stringWithFormat:@"%@%@", path, filename];
    }
    
    return path;
}

+ (const char *)pathForFont:(LK8000Font)font
{
    NSMutableString *p = [@"_System/_Fonts/" mutableCopy];
    
    switch (font) {
        default:
        case LK8000Font_Default:
            [p appendString:@"DejaVuSansCondensed.ttf"];
            break;
            
        case LK8000Font_Italic:
            [p appendString:@"DejaVuSansCondensed-Oblique.ttf"];
            break;

        case LK8000Font_Bold:
            [p appendString:@"DejaVuSansCondensed-Bold.ttf"];
            break;

        case LK8000Font_BoldItalic:
            [p appendString:@"DejaVuSansCondensed-BoldOblique.ttf"];
            break;

        case LK8000Font_Monospace:
            [p appendString:@"DejaVuSansMono.ttf"];
            break;
    }
    
    return [[self pathForArchiveRoot:p] UTF8String];
}

- (void)startDecompression:(void (^)(NSError *))onDone
{
    NSString *incomingVersionPath = [[NSBundle mainBundle] pathForResource:@"ArchiveVersion" ofType:@"plist"];
    NSString *currentVersionPath = [ArchiveUnzip pathForArchiveRoot:@"ArchiveVersion.plist"];
    NSDictionary *incomingVersion = [NSDictionary dictionaryWithContentsOfFile:incomingVersionPath];
    NSDictionary *currentVersion = [NSDictionary dictionaryWithContentsOfFile:currentVersionPath];
    NSString *rootOutput = [ArchiveUnzip pathForArchiveRoot:nil];
    NSString *fn = [[NSBundle mainBundle] pathForResource:@"Archive" ofType:@"zip"];
    BOOL ovveride = FALSE;

    if ([[incomingVersion valueForKey:@"version"] intValue] > [[currentVersion valueForKey:@"version"] intValue]) {
        ovveride = TRUE;
    }

    NSArray *blackList = [incomingVersion valueForKey:@"override"];

    if (ovveride) {
        NOZUnzipper *unzipper = [[NOZUnzipper alloc] initWithZipFile:fn];
        NSError *error;

        if (![unzipper openAndReturnError:&error]) {
            if (onDone) onDone(error);
            return;
        }

        if (nil == [unzipper readCentralDirectoryAndReturnError:&error]) {
            if (onDone) onDone(error);
            return;
        }

        __block NSError *enumError = nil;
        [unzipper enumerateManifestEntriesUsingBlock:^(NOZCentralDirectoryRecord * record, NSUInteger index, BOOL * stop) {
            if ([record.name containsString:@"_Configuration/DEFAULT_"] == TRUE) {
                NSString *lp = [record.name lastPathComponent];
                if (![blackList containsObject:lp]) {
                    return;
                }
            }

            [unzipper saveRecord:record
                     toDirectory:rootOutput
                         options:NOZUnzipperSaveRecordOptionOverwriteExisting
                   progressBlock:^(int64_t totalBytes, int64_t bytesComplete, int64_t bytesCompletedThisPass, BOOL *abort) {
                       NSLog(@"Unzipping");
                   } error:&enumError];

            if (enumError != nil && enumError.code != 21) {
                *stop = TRUE;
            }
        }];

        if (enumError != nil) {
            if (onDone) onDone(error);
            return;
        }

        if (![unzipper closeAndReturnError:&error]) {
            if (onDone) onDone(error);
            return;
        }

        [[NSFileManager defaultManager] copyItemAtPath:incomingVersionPath toPath:currentVersionPath error:nil];
    }

    if (onDone) onDone(nil);
}

@end
