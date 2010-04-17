//
//  AFProtocolProxy.h
//  Priority
//
//  Created by Keith Duncan on 22/03/2009.
//  Copyright 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
	@brief
	Uses the faux implementations in the protocol to allow message-to-nil like behaviour for unimplemented selectors. It allows you to wrap a delegate in the proxy and message it without checking to see if it implements the selector.
 */
@interface AFProtocolProxy : NSProxy {
 @private
	id _target;
	Protocol *_protocol;
}

/*!
	@brief
	Designated Initialiser.
 */
- (id)initWithTarget:(id)target protocol:(Protocol *)protocol;

@end
