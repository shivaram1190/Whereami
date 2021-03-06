//
//  WhereamiViewController.m
//  Whereami
//
//  Created by Sivaram Adhiappan on 5/12/13.
//  Copyright (c) 2013 Sivaram Adhiappan. All rights reserved.
//

#import "WhereamiViewController.h"
#import <MapKit/MapKit.h>
#import "Location.h"
#import "Atlas.h"
#import "Settings.h"

@interface WhereamiViewController ()
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) Atlas *atlas;
@property (nonatomic, strong) Settings *settings;
@end

@implementation WhereamiViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.title = @"Where Am I";
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup Map
    //[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    [self.mapView setShowsUserLocation:YES];
    self.mapView.delegate = self;
    self.mapView.mapType = [self.settings mapType];
    
    // Setup drop pin gesture
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //user needs to press for 2 seconds
    [self.mapView addGestureRecognizer:lpgr];
    
    // Get location coordinates from USUserDefaults
    NSMutableArray *locations = [self.atlas getLocations];
    
    // Annotate the saved points on the map
    for (id loc in locations) {
        [self.mapView addAnnotation:loc];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    self.mapView.mapType = [self.settings mapType];
    animated = YES;
}

- (Atlas *)atlas
{
    if (!_atlas) _atlas = [[Atlas alloc] init];
    return _atlas;
}

- (Settings *)settings
{
    if (!_settings) _settings = [[Settings alloc] init];
    return _settings;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D loc = [userLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [self.mapView setRegion:region animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *AnnotationViewID = @"annotationViewID";
    
    MKAnnotationView *annotationView = (MKAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
    
    if (annotationView == nil)
    {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    }
    
    annotationView.image = [UIImage imageNamed:@"pin.png"];
    annotationView.annotation = annotation;
    
    return annotationView;
}

- (IBAction)switchMapType:(id)sender
{
    UISegmentedControl *switchMapType = (UISegmentedControl *) sender;
    NSInteger selectedSegment = switchMapType.selectedSegmentIndex;
    
    // Switch the map types based on the switch control
    if (selectedSegment == 0) {
        self.mapView.mapType = MKMapTypeStandard;
    } else if (selectedSegment == 1) {
        self.mapView.mapType = MKMapTypeSatellite;
    } else if (selectedSegment == 2) {
        self.mapView.mapType = MKMapTypeHybrid;
    } else {
        self.mapView.mapType = MKMapTypeStandard;
    }
}

- (IBAction)saveLocation:(id)sender
{
    [self showAlert];
}

- (void)performSaveLocation:(CLLocationCoordinate2D)coordinate
                   withName:(NSString *)name
{    
    Location *currentLocation = [[Location alloc] init];
    currentLocation.coordinate = coordinate;
    currentLocation.title = name;
    
    // Save this location to our atlas
    [self.atlas addLocation:currentLocation];
    
    // Add this location to our map as an anotation
    [self.mapView addAnnotation:currentLocation];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        CLLocationCoordinate2D userLocation = self.mapView.userLocation.coordinate;
        NSString *locationName = [alertView textFieldAtIndex:0].text;
        [self performSaveLocation:userLocation withName:locationName];
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    // Handle long press to drop a pin in the map
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    Location *annotate = [[Location alloc] init];
    annotate.coordinate = touchMapCoordinate;
    [self.mapView addAnnotation:annotate];
    [self showAlert];
}

- (void)showAlert
{
    // Initial the alert view to capture the location name
    UIAlertView *alert = [[UIAlertView alloc]    initWithTitle:@"Save Location"
                                          message:@"Enter location name"
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Save", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

@end
