//
//  NSURLRequest+AFHTTPAdditions.m
//  Amber
//
//  Created by Keith Duncan on 14/04/2010.
//  Copyright 2010 Realmac Software. All rights reserved.
//

#import "NSURLRequest+AFHTTPAdditions.h"

static NSString *const AFHTTPBodyFileLocationKey = @"AFHTTPBodyFileLocation";

@implementation NSURLRequest (AFHTTPAdditions)

- (NSURL *)HTTPBodyFile {
	return [NSURLProtocol propertyForKey:AFHTTPBodyFileLocationKey inRequest:self];
}

@end

@implementation NSMutableURLRequest (AFHTTPAdditions)

@dynamic HTTPBodyFile;

- (void)setHTTPBodyFile:(NSURL *)HTTPBodyFile {
	[NSURLProtocol setProperty:[HTTPBodyFile copy] forKey:AFHTTPBodyFileLocationKey inRequest:self];
}

@end
