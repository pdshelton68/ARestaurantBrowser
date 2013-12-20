
#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>
@interface ViewController : UIViewController<NSURLConnectionDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lblName;
@property (strong, nonatomic) IBOutlet UILabel *lblRating;
@property (strong, nonatomic) IBOutlet UIButton *btnNext;
@property (strong, nonatomic) IBOutlet UILabel *lblDistance;
@property (strong, nonatomic) IBOutlet UIButton *btnAddress;
@property (strong, nonatomic) IBOutlet UIButton *btnRefreshLocation;
@property (strong, nonatomic) IBOutlet UILabel *lblLoading;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UILabel *nameTitle;
@property (strong, nonatomic) IBOutlet UILabel *ratingTitle;
@property (strong, nonatomic) IBOutlet UILabel *distanceTitle;
@property (strong, nonatomic) IBOutlet UILabel *addressTitle;
@property (strong, nonatomic) IBOutlet UILabel *lblLastScore;
@property (strong, nonatomic) IBOutlet UILabel *lastScoreTitle;
@property (strong, nonatomic) IBOutlet UILabel *isOpenTitle;
@property (strong, nonatomic) IBOutlet UILabel *lblIsOpen;
@property (strong, nonatomic) IBOutlet UILabel *lblPhone;
@property (strong, nonatomic) IBOutlet UILabel *phoneTitle;
@property (strong, nonatomic) IBOutlet UILabel *hoursTitle;
@property (strong, nonatomic) IBOutlet UILabel *lblHours;

@end
