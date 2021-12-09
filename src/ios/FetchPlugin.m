#import "FetchPlugin.h"
#import "BaseClient.h"

@interface FetchPlugin()

@end


@implementation FetchPlugin

- (void)pluginInitialize {
  
  
}

- (void)fetch:(CDVInvokedUrlCommand *)command {
  NSString *method = [command.arguments objectAtIndex:0];
  NSString *urlString = [command.arguments objectAtIndex:1];
  id body = [command.arguments objectAtIndex:2];
  id headers = [command.arguments objectAtIndex:3];
  
  if (![body isKindOfClass:[NSString class]]) {
    body = nil;
  }
  
  if (headers[@"map"] != nil && [headers[@"map"] isKindOfClass:[NSDictionary class]]) {
    headers = headers[@"map"];
  }
  
  FetchPlugin *__weak weakSelf = self;
  NSURLSessionDataTask *dataTask = [[BaseClient sharedClient]
                                    dataTaskWithHTTPMethod:method
                                    URLString:urlString
                                    parameters:body
                                    headers:headers
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    
      NSMutableDictionary *result = [NSMutableDictionary dictionary];
      
      if( [response isKindOfClass:[NSHTTPURLResponse class]] )
      {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
          [result setObject:[NSNumber numberWithInteger:httpResponse.statusCode] forKey:@"status"];
          [result setObject:[httpResponse allHeaderFields] ?: @{} forKey:@"headers"];
      }
      
      if( error != nil )
      {
          [result setObject:[error localizedDescription] forKey:@"error"];

          if( error != nil
             && data == nil )
          {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
            [pluginResult setKeepCallbackAsBool:YES];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

          }
          else
          {
            if(data != nil ) {
              [result setObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] forKey:@"statusText"];
            }
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
            [pluginResult setKeepCallbackAsBool:YES];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
          }
      }
      else
      {
          if (response.URL != nil && response.URL.absoluteString != nil) {
            [result setObject:response.URL.absoluteString forKey:@"url"];
          }
          
          if( data !=nil )
          {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (body == nil) {
                body = [data base64EncodedStringWithOptions:0];
                [result setObject:[NSNumber numberWithBool:true] forKey:@"isBlob"];
            }
            [result setObject:body forKey:@"body"];
          }
          
          CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
          [pluginResult setKeepCallbackAsBool:YES];
          [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      }
  }];
  
  [dataTask resume];
}

@end
