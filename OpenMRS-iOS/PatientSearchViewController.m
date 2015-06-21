//
//  PatientSearchViewController.m
//  OpenMRS-iOS
//
//  Created by Parker Erway on 12/1/14.
//
//

#import "PatientSearchViewController.h"
#import "OpenMRSAPIManager.h"
#import "MRSPatient.h"
#import "PatientViewController.h"
#import "SVProgressHUD.h"

@interface PatientSearchViewController ()

@property (atomic, assign) BOOL searchButtonPressed;
@property (nonatomic) BOOL isOnline;
@property (nonatomic, strong) UISegmentedControl *onlineOrOffile;
@property (nonatomic, strong) UISearchBar *bar;

@end

@implementation PatientSearchViewController

- (void)viewDidLoad
{
    self.restorationIdentifier = NSStringFromClass([self class]);
    self.restorationClass = [self class];
    self.isOnline = YES;
    self.title = NSLocalizedString(@"Patients", @"Title label patients");
    [super viewDidLoad];
    [self reloadDataForSearch:@""];

    self.bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    self.bar .autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.bar .delegate = self;
    [self.bar  sizeToFit];

    self.onlineOrOffile = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Online", @"Label online"), NSLocalizedString(@"Offline", @"Label offline")]];
    self.onlineOrOffile.selectedSegmentIndex = 0;
    [self.onlineOrOffile addTarget:self action:@selector(switchOnline) forControlEvents:UIControlEventValueChanged];
    
    UIView *headerView = [[UIView alloc] init];

    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat segmentHeight = 33;
    CGFloat segmentWidth = 250;
    CGFloat height = 44;
    [headerView setFrame:CGRectMake(0, 0, width, 88)];
    [self.onlineOrOffile setFrame:CGRectMake((width-segmentWidth)/2.0, 44+((height-segmentHeight)/2), segmentWidth, segmentHeight)];
    self.onlineOrOffile.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    [headerView addSubview:self.onlineOrOffile];
    [headerView addSubview:self.bar ];
    self.tableView.tableHeaderView = headerView;

    [self.bar  becomeFirstResponder];

    self.searchButtonPressed = NO;
}

- (void)reloadDataForSearch:(NSString *)search
{
    if (self.searchButtonPressed) {
        [SVProgressHUD show];
    }
    [OpenMRSAPIManager getPatientListWithSearch:search online:self.isOnline completion:^(NSError *error, NSArray *patients) {
        if (!error) {
            self.currentSearchResults = patients;
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (patients.count == 0 && self.searchButtonPressed && [SVProgressHUD isVisible])
                {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Couldn't find patients", @"Message -could- -not- -find- -patients")];
                    self.searchButtonPressed = NO;
                }
                else if (self.searchButtonPressed && [SVProgressHUD isVisible])
                {
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%lu %@", self.currentSearchResults.count, NSLocalizedString(@"patients found", @"Message -patients- -found-")]];
                    self.searchButtonPressed = NO;
                }

                [self.tableView reloadData];
            });
        } else {
            if (self.searchButtonPressed && [SVProgressHUD isVisible])
            {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Can't load patients", @"Message -can- -not- -load- -patients-")];
                self.searchButtonPressed = NO;
            }
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    MRSPatient *patient = self.currentSearchResults[indexPath.row];
    cell.textLabel.text = patient.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MRSPatient *patient = self.currentSearchResults[indexPath.row];
    PatientViewController *vc = [[PatientViewController alloc] initWithStyle:UITableViewStyleGrouped];
    vc.patient = patient;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadDataForSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchButtonPressed = YES;
    [self reloadDataForSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)switchOnline{
    long index = self.onlineOrOffile.selectedSegmentIndex;
    self.onlineOrOffile.selectedSegmentIndex = index == 0 ? 0 : 1;
    self.isOnline = index == 0 ? YES : NO;
    [self reloadDataForSearch:@""];
    self.bar.text = @"";
}
@end
