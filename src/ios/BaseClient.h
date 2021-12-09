#import "DWAnyCertificateURLSession.h"

@interface BaseClient : DWAnyCertificateURLSession

+ (instancetype __nullable)sharedClient;


- (NSURLSessionDataTask * __nonnull)dataTaskWithHTTPMethod:(NSString * __nullable)method
                                       URLString:(NSString * __nullable)URLString
                                      parameters:(id __nullable)parameters
                                         headers:(id __nullable)headers
                                completionHandler:(void (^ __nullable)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end
