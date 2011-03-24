//
//  PreyAppDelegate.m
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.

#import "PreyAppDelegate.h"
#import "LoginController.h"
#import "OldUserController.h"
#import "NewUserController.h"
#import "WelcomeController.h"
#import "PreyConfig.h"
#import "CongratulationsController.h"
#import "PreferencesController.h"
#import "Constants.h"
#import "AlertModuleController.h"
#import "PreyRunner.h"
#import "FakeWebView.h"




@interface PreyAppDelegate()

-(void)renderFirstScreen;

@end

@implementation PreyAppDelegate

@synthesize window,viewController;
//@synthesize viewController;

-(void)renderFirstScreen{

	
}

#pragma mark -
#pragma mark Some useful stuff
- (void)registerForRemoteNotifications {
    LogMessage(@"App Delegate", 10, @"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
	 registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeAlert | 
	  UIRemoteNotificationTypeBadge | 
	  UIRemoteNotificationTypeSound)];
}

- (void)showFakeScreen {
    LogMessage(@"App Delegate", 20,  @"Showing the guy our fake screen at: %@", url );
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *fakeView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 20, appFrame.size.width, appFrame.size.height)] autorelease];
    [fakeView setDelegate:self];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [fakeView loadRequest:requestObj];

    //[fakeView openUrl:url showingLoadingText:@"Accessing your account..."];
    
    [window addSubview:fakeView];
    [window makeKeyAndVisible];
    showFakeScreen = NO;
}

#pragma mark -
#pragma mark WebView delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    MBProgressHUD *HUD2 = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD2.labelText = NSLocalizedString(@"Accessing your account...",nil);
    HUD2.removeFromSuperViewOnHide=YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [MBProgressHUD hideHUDForView:webView animated:YES];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	//LoggerSetOptions(NULL, 0x01);  //Logs to console instead of nslogger.
	LoggerSetViewerHost(NULL, (CFStringRef)@"10.0.0.2", 50000);
    //LoggerSetupBonjour(NULL, NULL, (CFStringRef)@"Prey");
	//LoggerSetBufferFile(NULL, (CFStringRef)@"/tmp/prey.log");
    LogMessage(@"App Delegate", 20,  @"DID FINISH WITH OPTIONS!!");
    
	UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	id remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (remoteNotification) {
        LogMessage(@"App Delegate", 10, @"Prey remote notification received while not running!");	
        url = [remoteNotification objectForKey:@"url"];
        [[PreyRunner instance] startPreyService];
        showFakeScreen = YES;
        //[self showAlert: @"Remote notification received. Here we can send the app to the background or show a customized message."];	
    }
	
	if (localNotif) {
		application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1; 
		LogMessage(@"App Delegate", 10, @"Prey local notification clicked... running!");
        [[PreyRunner instance] startPreyService];
	}
	
	PreyConfig *config = [PreyConfig instance];
    if (config.alreadyRegistered) {
        
        [self registerForRemoteNotifications];
        [[PreyRunner instance] startOnIntervalChecking];
 
        NSOperationQueue *bgQueue = [[NSOperationQueue alloc] init];
        NSInvocationOperation* updateStatus = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateMissingStatus:) object:config] autorelease];
        [bgQueue addOperation:updateStatus];
        [bgQueue release];
    }
     
	/*
	LoginController *loginController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
    [window addSubview:loginController.view];
    [window makeKeyAndVisible];
    */
	/*
	OldUserController *ouController = [[OldUserController alloc] initWithNibName:@"OldUserController" bundle:nil];
	
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    ouController.view.frame = applicationFrame;
	
    [window addSubview:ouController.view];
    [window makeKeyAndVisible];
	*/
	
	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif {
	LogMessage(@"App Delegate", 10, @"Prey local notification received while in foreground... let's run Prey now!");
	PreyRunner *runner = [PreyRunner instance];
	[runner startPreyService];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	LogMessage(@"App Delegate", 10, @"Prey is now running in the background");
	wentToBackground = [NSDate date];
	for (UIView *view in [window subviews]) {
		[view removeFromSuperview];
	}
	
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	LogMessage(@"App Delegate", 10, @"Prey is now entering to the foreground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
     LogMessage(@"App Delegate", 20,  @"DID BECOME ACTIVE!!");
    if (showFakeScreen){
        [self showFakeScreen];
        return;
	}
	
    PreyConfig *config = [PreyConfig instance];
	
	UIViewController *nextController = nil;
	LogMessage(@"App Delegate", 10, @"Already registered?: %@", ([config alreadyRegistered] ? @"YES" : @"NO"));
	if (config.alreadyRegistered)
		if (ASK_FOR_LOGIN)
			nextController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
		else
			nextController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	else {
		nextController = [[WelcomeController alloc] initWithNibName:@"WelcomeController" bundle:nil];
	}
	viewController = [[UINavigationController alloc] initWithRootViewController:nextController];
	//[viewController setTitle:NSLocalizedString(@"Welcome to Prey!",nil)];
	[viewController setToolbarHidden:YES animated:NO];
	[viewController setNavigationBarHidden:YES animated:NO];
	
	//window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	[nextController release];
}
- (void)updateMissingStatus:(id)data {
    [(PreyConfig*)data updateMissingStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	int minutes=0;
	int seconds=0;
	if (wentToBackground != nil){
		NSTimeInterval inBg = [wentToBackground timeIntervalSinceNow];
		minutes = floor(-inBg/60);
		seconds = trunc(-inBg - minutes * 60);
	}
	LogMessage(@"App Delegate", 10, @"Application will terminate!. Time alive: %f minutes, %f seconds",minutes,seconds);
	
}

// Function to be called when the animation is complete
-(void)animDone:(NSString*) animationID finished:(BOOL) finished context:(void*) context
{
	// Add code here to be executed when the animation is done
}

#pragma mark -
#pragma mark Wizards and preferences delegate methods

- (void)showOldUserWizard {
	OldUserController *ouController = [[OldUserController alloc] initWithStyle:UITableViewStyleGrouped];
	ouController.title = NSLocalizedString(@"Log in to Prey",nil);
	[viewController pushViewController:ouController animated:YES];
	[ouController release];
}

- (void)showNewUserWizard {
	
	NewUserController *nuController = [[NewUserController alloc] initWithStyle:UITableViewStyleGrouped];
	nuController.title = NSLocalizedString(@"Create Prey account",nil);
	[viewController pushViewController:nuController animated:YES];
	[nuController release];
}

- (void)showPreferences {

	PreferencesController *preferencesController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	preferencesController.view.frame = applicationFrame;
	
	// Begin animation setup
	[UIView beginAnimations:nil context:NULL];
	
	// Set duration for animation
	[UIView setAnimationDuration:1];
	
	// Set function to be called when animation is complete
	[UIView setAnimationDidStopSelector: @selector(animDone:finished:context:)];
	
	// Set the delegate (This object must have the function animDone)
	[UIView setAnimationDelegate:self];
	
	// Set Animation type and which UIView should animate
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:YES];
	
	for (UIView *subview in window.subviews)
		[subview removeFromSuperview];

	// Add subview to the UIView set in the previous line
	[window addSubview:preferencesController.view];
	
	//Start the animation
	[UIView commitAnimations];
	[preferencesController release];
	
}

- (void)showAlert: (NSString *) textToShow {
	
	AlertModuleController *alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController" bundle:nil];
	[alertController setTextToShow:textToShow];
	CGRect applicationFrame = [[UIScreen mainScreen] bounds];
	alertController.view.frame = applicationFrame;
	[self setViewController:alertController];
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
	[alertController release];
}

#pragma mark -
#pragma mark Push notifications delegate

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
    NSString * tokenAsString = [[[deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    LogMessage(@"App Delegate", 10, @"Did register for remote notifications - Device Token=%@",tokenAsString);
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
    [http setPushRegistrationId:tokenAsString]; 
    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
	
    LogMessage(@"App Delegate", 10,  @"Failed to register for remote notifications - Error: %@", err);    
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    LogMessage(@"App Delegate", 10, @"Remote notification received! : %@", [userInfo description]);
    /*
    for (id key in userInfo) {
        LogMessage(@"App Delegate", 10, @"%@: %@", key, [userInfo objectForKey:key]);
    } */   
    url = [userInfo objectForKey:@"url"];
    [[PreyRunner instance] startPreyService];
    [self updateMissingStatus:[PreyConfig instance]];
	showFakeScreen = YES;
	
}

#pragma mark -
#pragma mark UINavigationController delegate methods
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	LogMessage(@"App Delegate", 10, @"UINAV did show: %@", [_viewController class]);
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	LogMessage(@"App Delegate", 10, @"UINAV will show: %@", [_viewController class]);
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[super dealloc];
    [window release];
	[viewController release];
}


@end