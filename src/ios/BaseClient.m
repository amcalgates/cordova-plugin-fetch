#import "BaseClient.h"

@implementation BaseClient

static BaseClient *_sharedClient = nil;

+ (instancetype)sharedClient {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedClient = [[BaseClient alloc] init];
  });
  
  return _sharedClient;
}

- (instancetype)init {

    if( (self = [super init]) )
    {
        
    }
    
    return self;
}

+ (NSString *) urlEncodeString:(NSString*) string
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    
    unsigned long sourceLen = strlen((const char *)source);
    
    for (int i = 0; i < sourceLen; ++i)
    {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ')
        {
            [output appendString:@"+"];
        }
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                 (thisChar >= 'a' && thisChar <= 'z') ||
                 (thisChar >= 'A' && thisChar <= 'Z') ||
                 (thisChar >= '0' && thisChar <= '9'))
        {
            [output appendFormat:@"%c", thisChar];
        }
        else
        {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

//supports NSString, NSNumber, NSArray, NSDictionary
+ (NSString *) urlEncodedStringForObject:(id)object
{
    if( object == nil || [object isEqual:[NSNull null]] )
    {
        return nil;
    }

    if( [object isKindOfClass:[NSString class]] )
    {
        return [BaseClient urlEncodeString:object];
    }
    else if( [object isKindOfClass:[NSNumber class]] )
    {
        return [BaseClient urlEncodeString:[((NSNumber*)object) stringValue]];
    }
    else if( [object isKindOfClass:[NSDictionary class]] )
    {
        /*
         this chokes on nested dictionaries a bit
         example:
         
         input:
         {
            location:{latitude:37.7873589, longitude:-122.408227}
         }
         
         output: location=longitude=-122.408227&latitude=37.7873589
         
         server will parse that as location = None!
        */
        NSMutableArray *arrayToCombine = [[NSMutableArray alloc] initWithCapacity:0];
        for( id key in object )
        {
            NSString *keyString = [BaseClient urlEncodedStringForObject:key];
            
            id innerObject = [object objectForKey:key];
            
            if( [innerObject isKindOfClass:[NSArray class]] )
            {
                //per theron - multiple prices will be pricing=1&pricing=2&pricing=4
                for( id subObject in innerObject )
                {
                    NSString *string = [BaseClient urlEncodedStringForObject:subObject];
                    if( string != nil )
                    {
                        [arrayToCombine addObject:[NSString stringWithFormat:@"%@=%@", keyString, string]];
                    }
                }
            }
            else
            {
                NSString *objectString = [BaseClient urlEncodedStringForObject:innerObject];
                
                if( keyString != nil && objectString != nil && [keyString length] > 0 )
                {
                    [arrayToCombine addObject:[NSString stringWithFormat:@"%@=%@", keyString, objectString]];
                }
            }

        }
        
        return [arrayToCombine componentsJoinedByString:@"&"];
    }
    
    return nil;
}

+ (void) addParameters:(nullable NSDictionary*)parameters
             toRequest:(nonnull NSMutableURLRequest*)request
{
    
    if( [request.HTTPMethod isEqualToString:@"GET"] )
    {
        //add to GET
        NSString *getString = [BaseClient urlEncodedStringForObject:parameters];
        
        if( getString != nil )
        {
            NSString *baseString = request.URL.absoluteString;
            
            request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", baseString, getString]];
        }
    }
    else
    {
        //encode as JSON, otherwise encode normally as GET string
        NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
        
        if( [[contentType lowercaseString] rangeOfString:@"json"].location != NSNotFound )
        {
            //add to POST and PUT as JSON per docs
            if( parameters == nil )
            {
                parameters = @{};
            }
            
            NSData *bodyData = nil;
            NSJSONWritingOptions options = 0;//IS_DEV ? NSJSONWritingPrettyPrinted : 0;
            NSError *jsonError = nil;
            
            @try{
                bodyData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:options
                                                             error:&jsonError];
                
            }@catch(NSException *e){}
            
            
            if( bodyData != nil
               && jsonError == nil )
            {
                request.HTTPBody = bodyData;
            }
            else if( jsonError != nil )
            {
                NSLog(@"ERROR parsing JSON: %@", jsonError.localizedDescription);
            }
        }
        else if( parameters != nil )
        {
            NSString *getString = [BaseClient urlEncodedStringForObject:parameters];
            request.HTTPBody = [getString dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
}


#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         headers:(id)headers
                               completionHandler:(void (^ __nullable)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
  

    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
    
    request.HTTPMethod = method;
    
    //not sure this is what everyone would want
    request.timeoutInterval = 8;
    
    [BaseClient addParameters:parameters
                    toRequest:request];
  
    if( headers != nil )
    {
        for( NSString *key in headers )
        {
            NSArray *value = headers[key];
      
            if( value != nil
               && value[0] != nil
               && key != nil )
            {
                [request setValue:value[0] forHTTPHeaderField:key];
            }
        }
    }
  
  __block NSURLSessionDataTask *dataTask = nil;
  dataTask = [self.urlSession
              dataTaskWithRequest:request
              completionHandler:completionHandler];
  
  return dataTask;
}

@end
