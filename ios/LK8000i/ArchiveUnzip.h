//
//  ArchiveUnzip.h
//  LK8000i
//
//  Created by Nicola Ferruzzi on 06/03/16.
//  Copyright © 2016 Nicola Ferruzzi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LK8000Font_Default,
    LK8000Font_Bold,
    LK8000Font_Italic,
    LK8000Font_BoldItalic,
    LK8000Font_Monospace,
} LK8000Font;

@interface ArchiveUnzip : NSObject

+ (NSString *)pathForArchiveRoot:(NSString *)filename;
- (NSOperation *)startDecompression:(void (^)(NSError *))onDone;

+ (const char *)pathForFont:(LK8000Font)font;

@end
