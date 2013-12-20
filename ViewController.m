

#import "ViewController.h"
#import "ConfigData.h"
#import <MapKit/MapKit.h>
typedef enum
{
    kGetListing,
    kGetScore
} QueryType;



@interface ViewController ()


@end

@implementation ViewController
@synthesize lblName;
@synthesize lblRating;
@synthesize btnNext;
@synthesize lblDistance;
@synthesize btnAddress;
@synthesize btnRefreshLocation;
@synthesize lblLoading;
@synthesize spinner;
@synthesize nameTitle;
@synthesize distanceTitle;
@synthesize addressTitle;
@synthesize ratingTitle;
@synthesize lblLastScore;
@synthesize lastScoreTitle;
@synthesize isOpenTitle;
@synthesize lblIsOpen;
@synthesize lblPhone;
@synthesize phoneTitle;
@synthesize hoursTitle;
@synthesize lblHours;


QueryType queryType = kGetListing;

NSDictionary* currentLocationData = nil;
NSURLConnection* theConnection = nil;
NSMutableData *receivedData = nil;
CLLocationManager *locationManager = nil;
CLLocation* currentLocation = nil;
NSMutableArray* arrayOfRestaurants = nil;
ConfigData* configData = nil;
int numberOfWarmupAttempts = 0;

//the lat long for dev purposes
double lat = 30.320898;
double lng = -97.676277;

int currentLocationIndex = 0;


NSString* mapsUrl = @"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&types=restaurant&sensor=true&rankby=distance&key=%@";

NSString* scoreUrl = @"http://data.austintexas.gov/resource/ecmv-9xxi.json?restaurant_name=%@";

NSString* locatoinDetailUrl = @"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&sensor=true&key=%@";

-(void)getRestaurantScoreForLocation:(NSString*)location
{
    queryType = kGetScore;
    
    
    location = [self urlEncodeUsingEncoding:NSUTF8StringEncoding andString:location];
    
    
    NSString* url = [NSString stringWithFormat:scoreUrl, location];
    
    NSLog(@"%@", url);
    
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL* restaurantDataUrl = [NSURL URLWithString:url];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:restaurantDataUrl
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];
    
    // create the connection with the request
    // and start loading the data
    theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

}


-(void)getRestaurantDetails:(NSString*)locationId
{
    queryType = kGetScore;
    
    
    locationId = [self urlEncodeUsingEncoding:NSUTF8StringEncoding andString:locationId];
    
    
    NSString* url = [NSString stringWithFormat:locatoinDetailUrl, locationId, configData.googleApiId];
    
    NSLog(@"%@", url);
    
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL* restaurantDataUrl = [NSURL URLWithString:url];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:restaurantDataUrl
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];
    
    // create the connection with the request
    // and start loading the data
    theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
}

-(void)callPhone
{
    //call the phone number
    NSString* command = [NSString stringWithFormat:@"tel:%@", [lblPhone text]];
    command = [command stringByReplacingOccurrencesOfString:@"(" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@")" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@"-" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:command]];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    configData = [[ConfigData alloc] init];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(callPhone)];
    [lblPhone addGestureRecognizer:tap];
    lblPhone.userInteractionEnabled = YES;
    
    
    [self toggleLoading:true];
    currentLocationData = nil;
    queryType = kGetListing;
    theConnection = nil;
    receivedData = nil;
    locationManager = nil;
    currentLocation = nil;
    arrayOfRestaurants = nil;
    
    numberOfWarmupAttempts = 0;
    
    [spinner setHidesWhenStopped:true];
    currentLocationIndex = 0;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
	receivedData = [NSMutableData dataWithCapacity: 0];
    
     arrayOfRestaurants = nil;
    
    //NSString* url =@"http://data.austintexas.gov/resource/ecmv-9xxi.json";
    
    /*
    NSLog(@"%@", url);
    NSURL* restaurantDataUrl = [NSURL URLWithString:url];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:restaurantDataUrl
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];
    
    
    // create the connection with the request
    // and start loading the data
    theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    */
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //TODO - refine stability check.
    if(numberOfWarmupAttempts < 3)
    {
        numberOfWarmupAttempts++;
        return;
    }
    
    if(currentLocation != nil)
    {
        return; //don't update until they tell us to.
    }
    
    //the following block is useful for autoupdate...
    /*
    if(currentLocation != nil) //we have a previous location (?)
    {
        //see if we've gone far enough to merit a refresh...
        CLLocation* lastLocation = currentLocation;
        CLLocationDistance distance = [lastLocation distanceFromLocation:[locations objectAtIndex:0]];
        
        if (distance < 10.0) { //have we moved a meter since the last update??
            return; //don'trefresh
        }
    }
    */
    
    queryType = kGetListing;
    
    currentLocation = [locations lastObject];

    currentLocationIndex = 0;

    lat = [currentLocation coordinate].latitude;
    lng = [currentLocation coordinate].longitude;

    //30.2500° N, 97.7500° W is austin
    
    NSString* url = [NSString stringWithFormat:mapsUrl, lat, lng, configData.googleApiId];
    
    NSLog(@"%@", url);
    NSURL* restaurantDataUrl = [NSURL URLWithString:url];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:restaurantDataUrl
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];
    
    // create the connection with the request
    // and start loading the data
    theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
}

-(void)processListData
{
    NSError* error = nil;
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:receivedData //1
                          options:kNilOptions
                          error:&error ];
    
    if( (error != nil) /* || ([json objectForKey:@"Message"] != nil)*/ /*for some reason this throws an error*/ )
    {
        UIAlertView* mes=[[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"An error occured while attempting to load the data listing." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        
        mes.tag = 1;
        [mes show];
        return;
    }
    arrayOfRestaurants = [[NSMutableArray alloc] init];
    
    NSEnumerator* data = [[json objectForKey:@"results"] objectEnumerator] ;
    
    id object = nil;
    
    //int i = 0;
    //NSDecimalNumber* latitude;
    //NSDecimalNumber* longitude;
    
    while((object = [data nextObject]))
    {
        [arrayOfRestaurants addObject:object];
    }
    
    if (arrayOfRestaurants.count > 0)
    {
        NSDictionary* value =[arrayOfRestaurants objectAtIndex:0];
        
        [self updateLocationWithData:value andLocation:currentLocation];
        
        [self getRestaurantDetails:[value objectForKey:@"reference"]];
        
        //kick off an attempt to find the score
        
    }
    else
    {
        [self toggleLoading:false];
    }

}



- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

    if(queryType == kGetListing)
    {
        [self processListData];
    }
    else
    {
        [self processScoreData];
    }
}

-(void)processScoreData
{
    NSError* error = nil;
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:receivedData //1
                          options:kNilOptions
                          error:&error ];
    
    if( (error != nil) /* || ([json objectForKey:@"Message"] != nil)*/ /*for some reason this throws an error*/ )
    {
        UIAlertView* mes=[[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"An error occured while attempting to load the data listing." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        
        mes.tag = 1;
        [mes show];
        return;
    }
    
    if(json.count > 0 )
    {
        //do something with the data
        NSLog(@"we got data");
        
        [self getRestaurantDetailData:[json objectForKey:@"result"] ];
        
        //int score = [self getHealthScore:json];
        
        //[lblLastScore setText:[NSString stringWithFormat:@"%d", score]];
        
    }
    else
    {
        //otherwise the score is unknown.
        [lblLastScore setText:@"---"];
        NSLog(@"no data");
    }
    
    
    NSDictionary* value =[arrayOfRestaurants objectAtIndex:currentLocationIndex];
    
    [self updateLocationWithData:value andLocation:currentLocation];
    [spinner stopAnimating];
    [self toggleLoading:false];
    //NSEnumerator* data = [[json objectForKey:@"results"] objectEnumerator] ;

}

-(void)getRestaurantDetailData:(NSDictionary*)data
{
    
    NSString* phoneNumber = [data objectForKey:@"formatted_phone_number"];
    
    [lblPhone setText:phoneNumber];
    
    NSString* address = [data objectForKey:@"formatted_address"];
    address = [address stringByReplacingOccurrencesOfString:@", United States" withString:@""];
    
    //yeah i know we should really build the address from the address components but I'm lazy
    address = [NSString stringWithFormat:@"%@ %@", address, [self getAddressComponent:data withComponentName:@"postal_code"]];
    
    NSArray* businessSpan = [self getHours:data];
    
    if(businessSpan.count > 0)
    {
        [lblHours setText:[NSString stringWithFormat:@"%@-%@", [businessSpan objectAtIndex:1], [businessSpan objectAtIndex:0] ]];
    }
    
    [btnAddress setTitle:address forState:UIControlStateNormal];
}



-(int)getHealthScore:(NSDictionary*)data
{
    id object;
    NSEnumerator* enumerator = [data objectEnumerator];
    int mostRecentIndex = 0;
    int latestDate = 0;
    int count = 0;
    int returnValue = -1;
    
    //the google "vicinity" field is an address followed by a comma, followed by a city. get a substring of everything up to the comma. that is our address candidate
    NSString* currentAddress = [currentLocationData objectForKey:@"vicinity"];
    
    NSMutableArray* candidates = [[NSMutableArray alloc] init];
    
    NSArray* addressComponents = [currentAddress componentsSeparatedByString:@" "];
    
    if(addressComponents.count > 1)
    {
        currentAddress = [addressComponents objectAtIndex:0];
    }
    //attempt to find records in the list that correspond to this restaurant address

    while (object = [enumerator nextObject])
    {
        //NSRange textRange;
        //NSString* humanAddress =[[object objectForKey:@"address"] objectForKey:@"human_address"];
        //NSLog(@"%@", humanAddress);
        
        //textRange =[humanAddress rangeOfString:currentAddress];
        
        //if(textRange.location != NSNotFound)
        {
            NSLog(@"%@", object);
            
            if(latestDate < [[object objectForKey:@"inspection_date"] integerValue])
            {
                latestDate =[[object objectForKey:@"inspection_date"] integerValue];
                mostRecentIndex = count;
            }
            
            [candidates addObject:object];
            count++;
            //Does contain the substring
        }
    }
    
    //find the latest record and return the score
    if (candidates.count > 0)
    {
        returnValue = (int)[[[candidates objectAtIndex:mostRecentIndex] objectForKey:@"score"] integerValue];
    }
    
    return returnValue;
}

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding andString:(NSString*)str
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)str,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding)));
}


-(void)updateLocationWithData:(NSDictionary*)locationData andLocation:(CLLocation*)currentLocation
{
    NSLog(@"%@", [locationData objectForKey:@"rating"] );
    
    currentLocationData = locationData;
    NSString* rating = [NSString stringWithFormat:@"%@", [locationData objectForKey:@"rating"]];
    if([rating isEqualToString:@"(null)"])
    {
        rating = @"---";
    }
    NSString* isopen = [NSString stringWithFormat:@"%@", [[locationData objectForKey:@"opening_hours"] objectForKey:@"open_now"]];
    
    if([isopen isEqualToString:@"1"])
    {
        isopen = @"YES";
    }
    else
    {
        isopen = @"NO";
    }
    
    
    [lblIsOpen setText:isopen];
    [lblRating setText:rating];
    
    //lblRating.text = rating;
    [lblName setText:[locationData objectForKey:@"name"]];
    
    double locationLat =
        [[[[locationData objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue] ;
    double locationLong =
        [[[[locationData objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue] ;
    
    CLLocation *destLoc = [[CLLocation alloc] initWithLatitude:locationLat longitude:locationLong];
    
    NSLog(@"lat = %f long = %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    
    CLLocationDistance distance = [destLoc distanceFromLocation:currentLocation];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.roundingIncrement = [NSNumber numberWithDouble:0.1];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber* number = [NSNumber numberWithFloat:distance];
    
    [lblDistance setText:[NSString stringWithFormat:@"%@ meters", [formatter stringFromNumber:number]]];
    //[btnAddress setTitle:[locationData objectForKey:@"vicinity"] forState:UIControlStateNormal];
}

-(void)toggleLoading:(bool)isLoading
{
    if (isLoading)
    {
        [spinner startAnimating];
    }
    else
    {
        [spinner stopAnimating];
    }
    [phoneTitle setHidden:isLoading];
    [isOpenTitle setHidden:isLoading];
    [lblIsOpen setHidden:isLoading];
    [lblLoading setHidden:!isLoading];
    [lblDistance setHidden:isLoading];
    [lblName setHidden:isLoading];
    [lblRating setHidden:isLoading];
    [btnAddress setHidden:isLoading];
    [nameTitle setHidden:isLoading];
    [distanceTitle setHidden:isLoading];
    [ratingTitle setHidden:isLoading];
    [addressTitle setHidden:isLoading];
    [lblLastScore setHidden:isLoading];
    [lastScoreTitle setHidden:isLoading];
    [btnRefreshLocation setHidden:isLoading];
    [lblPhone setHidden:isLoading];
    [hoursTitle setHidden:isLoading];
    [lblHours setHidden:isLoading];
}


-(int)getNearestRecord:(NSMutableArray*)array currentLat:(NSDecimalNumber*)lat currentLong:(NSDecimalNumber*)longitude
{
    CLLocation *currentLocation =
        [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[longitude doubleValue] ] ;
    
    
    NSDecimalNumber* destLat;
    NSDecimalNumber* destLong;
    
    for (int i = 0; i<array.count; i++)
    {
        NSString* latString =
        [[[array objectAtIndex:i ] objectForKey:@"address"] objectForKey:@"latitude"];
        destLat = [NSDecimalNumber decimalNumberWithString:latString];
        
        NSString* longString =
        [[[array objectAtIndex:i] objectForKey:@"address"] objectForKey:@"longitude"] ;
        
        destLong = [NSDecimalNumber decimalNumberWithString:longString];
        
        CLLocation *destLoc =
            [[CLLocation alloc] initWithLatitude:[destLat doubleValue] longitude:[destLong doubleValue]];
        
        
        currentLocation =
        [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:lng];
        
        CLLocationDistance distance = [destLoc distanceFromLocation:currentLocation];
        
        NSLog(@"%f", distance);
        
    }
}





-(BOOL)pointExistsInArray:(NSMutableArray*) array lat:(NSString*)latitude long: (NSString*)longitude
{
    
    for (int i = 0; i<[array count]; i++)
    {
        if([latitude isEqualToString:[[[array objectAtIndex:i] objectForKey:@"address"] objectForKey:@"latitude"]] )
        {
            if([longitude isEqualToString:[[[array objectAtIndex:i] objectForKey:@"address"] objectForKey:@"longitude"]] )
            {
                return true;
            }
        }
    }
    
    return false;
}

- (IBAction)swipePage:(id)sender
{
    if(currentLocationIndex + 1 >= arrayOfRestaurants.count)
    {
        return;
    }
    [self toggleLoading:true];
    
    NSDictionary* value =[arrayOfRestaurants objectAtIndex:++currentLocationIndex];
    
    [self updateLocationWithData:value andLocation:currentLocation];
    
    //[self getRestaurantScoreForLocation:[value objectForKey:@"name"]];
    
    [self getRestaurantDetails:[value objectForKey:@"reference"]];
    
    //NSDictionary* value =[arrayOfRestaurants objectAtIndex:++currentLocationIndex];
    
    //[self updateLocationWithData:value andLocation:currentLocation];
    
}

- (IBAction)clickRefreshLocation:(id)sender

{
    [self toggleLoading:true];
    numberOfWarmupAttempts = 0;
    currentLocation = nil; //force a refresh
}


- (IBAction)swipeLeft:(id)sender {
    
    if(currentLocationIndex == 0)
    {
        return;
    }
    [self toggleLoading:true];
    NSDictionary* value =[arrayOfRestaurants objectAtIndex:--currentLocationIndex];
    
    [self updateLocationWithData:value andLocation:currentLocation];
    
    [self getRestaurantDetails:[value objectForKey:@"reference"]];
    
    
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error.localizedFailureReason);
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) mapLocation:(NSString*)address
{
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
    {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:address
                     completionHandler:^(NSArray *placemarks, NSError *error) {
                         
                         // Convert the CLPlacemark to an MKPlacemark
                         // Note: There's no error checking for a failed geocode
                         CLPlacemark *geocodedPlacemark = [placemarks objectAtIndex:0];
                         MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:geocodedPlacemark.location.coordinate addressDictionary:geocodedPlacemark.addressDictionary];
                         
                         // Create a map item for the geocoded address to pass to Maps app
                         MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                         [mapItem setName:geocodedPlacemark.name];
                         
                         // Set the directions mode to "Driving"
                         // Can use MKLaunchOptionsDirectionsModeWalking instead
                         NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
                         
                         // Get the "Current User Location" MKMapItem
                         MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
                         
                         // Pass the current location and destination map items to the Maps app
                         // Set the direction mode in the launchOptions dictionary
                         [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
                         
                     }];
    }
}
- (IBAction)btnMapIt:(id)sender

{
    [self mapLocation:[btnAddress currentTitle] ];
    
}

-(NSString*)getAddressComponent:(NSDictionary*)data withComponentName:(NSString*)name
{
    NSEnumerator* components = [[data objectForKey:@"address_components"] objectEnumerator];
    NSEnumerator* types = nil;
    
    id component;
    id type;
    
    while ((component= [components nextObject]  ))
    {
        types = [[component objectForKey:@"types"] objectEnumerator] ;
        while ((type = [types nextObject]))
        {
            if([type isEqualToString:name ] )
            {
                return [component objectForKey:@"short_name"];
            }
        }
    }
    
    return @"";

}

//returns an array of opening and closing times
-(NSArray*)getHours:(NSDictionary*)data
{
    NSEnumerator* periods = [[[data objectForKey:@"opening_hours"] objectForKey:@"periods"] objectEnumerator];
    
    NSMutableArray* times = [[NSMutableArray alloc] init] ;
    
    id period;
    
    NSDateComponents *currDate = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSWeekdayCalendarUnit fromDate:[NSDate date]];
    
    while (period = [periods nextObject])
    {
        NSLog(@"%d", [[[period objectForKey:@"close"] objectForKey:@"day"] integerValue]);
        NSLog(@"%d", currDate.weekday);
        
        if([[[period objectForKey:@"close"] objectForKey:@"day"] integerValue] == currDate.weekday)
        {
            [times addObject:[[period objectForKey:@"close"] objectForKey:@"time" ]];
            [times addObject:[[period objectForKey:@"open"] objectForKey:@"time" ]];
        }
    }
    return [NSArray arrayWithArray:times];
}

@end
