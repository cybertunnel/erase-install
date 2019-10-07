//
//  NSXPCConnection.h
//  nl.prowarehouse.ShredderHelper
//
//  Created by Arnold Nefkens on 29/08/2019.
//  Copyright © 2019 Pro Warehouse. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSXPCConnection(PrivateAuditToken)

    // This property exists, but it's private. Make it available:
     @property (nonatomic, readonly) audit_token_t auditToken;

@end
