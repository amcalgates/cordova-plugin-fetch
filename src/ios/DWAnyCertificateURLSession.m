//
//  DWAnyCertificateURLSession.m
//  DWFoundation
//
//  Created by Andrew Gates on 12/8/21.
//  Copyright © 2021 Guest Innovations. All rights reserved.
//

#import "DWAnyCertificateURLSession.h"

@implementation DWAnyCertificateURLSession

@synthesize urlSession = _urlSession;
@synthesize sessionOperationQueue = _sessionOperationQueue;
@synthesize underlyingQueue = _underlyingQueue;

- (instancetype) initWithQueueName:(nonnull NSString*)queueName
{
    if( (self = [super init]) )
    {
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        operationQueue.name = queueName;
        
        _underlyingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        operationQueue.underlyingQueue = _underlyingQueue;
        
        //just in case we need a strong reference to it?
        _sessionOperationQueue = operationQueue;
        
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self
                                               delegateQueue:operationQueue];
    }
    return self;
}

#pragma mark - NSURLSession Delegate

/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
                                             completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    //https://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    if( [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] )
    {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
        
        //don't bother with the below - host is the IP address... we _probably_ have that in our probed ips somewhere or otherwise... but why risk failure here?
        /*
        if( [challenge.protectionSpace.host isEqualToString:@"mydomain.com"] )
        {
          
        }
         */
      }
}


@end
