//
//  AFNetworkConnection.m
//  Amber
//
//  Created by Keith Duncan on 25/12/2008.
//  Copyright 2008 thirty-three software. All rights reserved.
//

#import "AFNetworkConnection.h"

@implementation AFNetworkConnection

@dynamic delegate;

- (AFNetworkLayer <AFConnectionLayer> *)lowerLayer {
	return [super lowerLayer];
}

- (void)open {
	[self.delegate layerDidOpen:self];
}

- (NSURL *)peer {
	CFTypeRef peer = [(id)super peer];
	
	if (CFGetTypeID(peer) == CFHostGetTypeID()) {
		CFHostRef host = (CFHostRef)peer;
		
		NSArray *hostnames = (NSArray *)CFHostGetNames(host, NULL);
		NSParameterAssert([hostnames count] == 1);
		
		return [NSURL URLWithString:[hostnames objectAtIndex:0]];
	} else if (CFGetTypeID(peer) == CFNetServiceGetTypeID()) {
		CFNetServiceRef service = (CFNetServiceRef)peer;
		
		// Note: this is assuming that the service has already been resolved
		CFStringRef host = CFNetServiceGetTargetHost(service);
		SInt32 port = CFNetServiceGetPortNumber(service);
		
		return [NSURL URLWithString:[NSString stringWithFormat:@"%@:%ld", host, port, nil]];
	}
	
	[NSException raise:NSInternalInconsistencyException format:@"%s, cannot determine the peer name.", __PRETTY_FUNCTION__, nil];
	return nil;
}

@end
