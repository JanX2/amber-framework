//
//  AFNetService.m
//  Bonjour
//
//  Created by Keith Duncan on 03/02/2009.
//  Copyright 2009 thirty-three software. All rights reserved.
//

#import "AFNetService.h"

#import <dns_sd.h>

#if TARGET_OS_MAC && TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif

#import "AFNetworkConstants.h"

NSDictionary *AFNetServiceProcessTXTRecordData(NSData *TXTRecordData) {
	NSMutableDictionary *TXTDictionary = [[[NSNetService dictionaryFromTXTRecordData:TXTRecordData] mutableCopy] autorelease];
	
	for (NSString *currentKey in [TXTDictionary allKeys]) {
		NSData *currentValue = [TXTDictionary objectForKey:currentKey];
		[TXTDictionary setObject:[[[NSString alloc] initWithData:currentValue encoding:NSUTF8StringEncoding] autorelease] forKey:currentKey];
	}
	
	return TXTDictionary;
}

@interface AFNetService ()
@property (readwrite, retain) NSDictionary *presence;
@end

@implementation AFNetService

@synthesize delegate;
@synthesize presence;

+ (id)serviceWithNetService:(NSNetService *)service {
	return [[[self alloc] initWithDomain:[service valueForKey:@"domain"] type:[service valueForKey:@"type"] name:[service valueForKey:@"name"]] autorelease];
}

- (id)init {
	[super init];
		
	presence = [[NSMutableDictionary alloc] init];
	
	return self;
}

static void AFNetServiceMonitorClientCallBack(CFNetServiceMonitorRef monitor, CFNetServiceRef service, CFNetServiceMonitorType typeInfo, CFDataRef rdata, CFStreamError *error, void *info) {
	AFNetService *self = info;
	
	NSDictionary *values = AFNetServiceProcessTXTRecordData((NSData *)rdata);
	
	[self updatePresenceWithValuesForKeys:values];
}

static void AFNetServiceClientCallBack(CFNetServiceRef service, CFStreamError *error, void *info) {
	AFNetService *self = info;
	NSArray *resolvedAddresses = [self addresses];
	
	if (resolvedAddresses == nil) {
		if ([self->delegate respondsToSelector:@selector(netService:didNotResolveAddress:)]) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  NSLocalizedString(@"Couldn't resolve the remote client's address.", @"AFNetService resolve failure"), NSLocalizedDescriptionKey,
									  nil];
			
			NSError *error = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:-1 userInfo:userInfo] autorelease];
			
			[self->delegate netService:self didNotResolveAddress:error];
		}
		
		return;
	}
	
	if ([self->delegate respondsToSelector:@selector(netServiceDidResolveAddress:)]) {
		[self->delegate netServiceDidResolveAddress:self];
	}
}

- (id)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name {
	[self init];
	
	CFNetServiceClientContext context;
	memset(&context, 0, sizeof(CFNetServiceClientContext));
				
	context.info = self;
	
	service =  CFNetServiceCreate(kCFAllocatorDefault, (CFStringRef)domain, (CFStringRef)type, (CFStringRef)name, 0);
	Boolean client = CFNetServiceSetClient(service, AFNetServiceClientCallBack, &context);
	
	if (!client) {
		[NSException raise:NSInternalInconsistencyException format:@"%s, couldn't set service client", __PRETTY_FUNCTION__, nil];
		
		[self release];
		return nil;
	}
	
	monitor = CFNetServiceMonitorCreate(kCFAllocatorDefault, service, AFNetServiceMonitorClientCallBack, &context);
	
	return self;
}

- (void)dealloc {
	[self stop];
	
	CFNetServiceMonitorInvalidate(monitor);
	CFRelease(monitor);
	
	CFRelease(service);
	
	[presence release];
	
	[super dealloc];
}

- (BOOL)isEqual:(id)object {
	NSArray *equalKeys = [NSArray arrayWithObjects:@"name", @"type", @"domain", nil];
	return [[self dictionaryWithValuesForKeys:equalKeys] isEqual:[object dictionaryWithValuesForKeys:equalKeys]];
}

- (NSUInteger)hash {
	return [[self name] hash];
}

- (NSString *)domain {
	return (id)CFNetServiceGetDomain(service);
}

- (NSString *)type {
	return (id)CFNetServiceGetType(service);
}

- (NSString *)name {
	return (id)CFNetServiceGetName(service);
}

- (void)startMonitoring {
	CFNetServiceMonitorScheduleWithRunLoop(monitor, CFRunLoopGetMain(), kCFRunLoopCommonModes);
	CFNetServiceMonitorStart(monitor, kCFNetServiceMonitorTXT, NULL);
}

- (void)stopMonitoring {
	CFNetServiceMonitorStop(monitor, NULL);
	CFNetServiceMonitorUnscheduleFromRunLoop(monitor, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (void)updatePresenceWithValuesForKeys:(NSDictionary *)newPresence {
	[presence setDictionary:newPresence];
}

- (void)resolveWithTimeout:(NSTimeInterval)delta {
	CFNetServiceScheduleWithRunLoop(service, CFRunLoopGetMain(), kCFRunLoopCommonModes);
	CFNetServiceResolveWithTimeout(service, delta, NULL);
}

- (void)stopResolve {
	CFNetServiceCancel(service);
	CFNetServiceUnscheduleFromRunLoop(service, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (void)stop {
	[self stopMonitoring];
	[self stopResolve];	
}

- (NSArray *)addresses {	
	return (id)CFNetServiceGetAddressing(service);
}

- (NSString *)fullName {
	NSMutableString *fullName = [NSMutableString string];
	
	[fullName appendString:[self name]];
	if (![fullName hasSuffix:@"."]) [fullName appendString:@"."];
	
	[fullName appendString:[self type]];
	if (![fullName hasSuffix:@"."]) [fullName appendString:@"."];
	
	[fullName appendString:[self domain]];
	if (![fullName hasSuffix:@"."]) [fullName appendString:@"."];
	
	return fullName;
}

@end

@implementation NSNetService (_AFAdditions)

- (NSString *)fullName {
	return (id)(*[AFNetService instanceMethodForSelector:_cmd])(self, _cmd);
}

@end