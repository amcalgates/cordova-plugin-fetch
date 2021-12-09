//
//  DWAnyCertificateURLSession.h
//  DWFoundation
//
//  Created by Andrew Gates on 12/8/21.
//  Copyright © 2021 Guest Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DWAnyCertificateURLSession : NSObject <NSURLSessionDelegate>

@property(nonnull, strong, readonly) NSURLSession *urlSession;

@property(nonnull, strong, readonly) NSOperationQueue *sessionOperationQueue;

@property(nonnull) dispatch_queue_t underlyingQueue;

/*!
 * name the dispatch queue this will run on
 */
- (instancetype _Nonnull ) initWithQueueName:(nonnull NSString*)queueName;

@end

