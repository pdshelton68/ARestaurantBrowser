
#import "ConfigData.h"

@implementation ConfigData
@synthesize googleApiId;

-(id)init
{
    self = [super init];
    if (self)
    {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSString *finalPath = [path stringByAppendingPathComponent:@"ATxRScore-Info.plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        self.googleApiId = [dict objectForKey:@"GOOGLE_APPID"];
    }
    return self;
}
@end
