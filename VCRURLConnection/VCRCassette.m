//
// VCRCassette.m
//
// Copyright (c) 2012 Dustin Barker
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VCRCassette.h"
#import "VCRCassette_Private.h"
#import "VCRRequestKey.h"


@implementation VCRCassette

+ (VCRCassette *)cassetteWithURL:(NSURL *)url {
    return [[VCRCassette alloc] initWithURL:url];
}

+ (VCRCassette *)cassetteWithURL:(NSURL *)indexUrl url:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:indexUrl];
    return [[VCRCassette alloc] initWithData:data url:url];
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        self.cassetteURL = url;
        self.responseDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithJSON:(id)json url:(NSURL *)url {
    NSAssert(json != nil, @"Attempted to intialize VCRCassette with nil JSON");
    if ((self = [self initWithURL:url])) {
        for (id recordingJSON in json) {
            VCRRecording *recording = [[VCRRecording alloc] initWithJSON:recordingJSON];
            NSURL *dataUrl = [self.cassetteURL URLByAppendingPathComponent:recording.asset];
            NSData *data = [NSData dataWithContentsOfURL:dataUrl];
            recording.data = data;
            
            [self addRecording:recording];
        }
    }
    return self;
}

- (id)initWithData:(NSData *)data url:(NSURL *)url {
    NSError *error = nil;
    self.cassetteURL = url;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert([error code] == 0, @"Attempted to initialize VCRCassette with invalid JSON");
    return [self initWithJSON:json url:url];
    
}

- (void)addRecording:(VCRRecording *)recording {
    VCRRequestKey *key = [VCRRequestKey keyForObject:recording];
    [self.responseDictionary setObject:recording forKey:key];
}

- (VCRRecording *)recordingForRequestKey:(VCRRequestKey *)key {
    return [self.responseDictionary objectForKey:key];
}

- (VCRRecording *)recordingForRequest:(NSURLRequest *)request {
    VCRRequestKey *key = [VCRRequestKey keyForObject:request];
    return [self recordingForRequestKey:key];
}

- (id)JSON {
    NSMutableArray *recordings = [NSMutableArray array];
    for (VCRRecording *recording in self.responseDictionary.allValues) {
        [recordings addObject:[recording JSON]];
        
        NSURL *dataUrl = [self.cassetteURL URLByAppendingPathComponent:recording.asset isDirectory:NO];
        
        NSError *error = nil;
        [recording.data writeToURL:dataUrl options:NSDataWritingAtomic error:&error];
        if (error) {
            NSLog(@"error");
        }
    }
    return recordings;
}

- (NSData *)data {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self JSON]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if ([error code] != 0) {
        NSLog(@"Error serializing json data %@", error);
    }
    return data;
}

- (BOOL)isEqual:(VCRCassette *)cassette {
    return [self.responseDictionary isEqual:cassette.responseDictionary];
}

- (NSArray *)allKeys {
    return [self.responseDictionary allKeys];
}

@end
