//
//  MyMain.m
//  LK8000i
//
//  Created by Nicola Ferruzzi on 06/03/16.
//  Copyright © 2016 Nicola Ferruzzi. All rights reserved.
//

#import "ArchiveUnzip.h"
#import <ZipUtilities/NOZDecompress.h>

static NSOperationQueue *sQueue = nil;

@interface ArchiveUnzip () <NOZDecompressDelegate>
@property (copy, nonatomic) void (^onDone)(NSError *error);
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

+ (void)initialize
{
    dispatch_queue_t q = dispatch_queue_create("Unzip.GCD.Queue", DISPATCH_QUEUE_SERIAL);
    sQueue = [[NSOperationQueue alloc] init];
    sQueue.name = @"Unzip.Queue";
    sQueue.maxConcurrentOperationCount = 1;
    sQueue.underlyingQueue = q;
}

- (NSOperation *)startDecompression:(void (^)(NSError *))onDone
{
    NSString *fn = [[NSBundle mainBundle] pathForResource:@"Archive" ofType:@"zip"];
    
    self.onDone = onDone;
    
    NOZDecompressRequest *request = [[NOZDecompressRequest alloc] initWithSourceFilePath:fn destinationDirectoryPath:[ArchiveUnzip pathForArchiveRoot:nil]];
    
    NOZDecompressOperation *op = [[NOZDecompressOperation alloc] initWithRequest:request delegate:self];
    [sQueue addOperation:op];
    
    return op;
}

- (void)decompressOperation:(NOZDecompressOperation *)op didCompleteWithResult:(NOZDecompressResult *)result
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onDone(result.didSucceed ? nil : result.operationError);
    });
}

- (void)decompressOperation:(NOZDecompressOperation *)op didUpdateProgress:(float)progress
{
}

@end
