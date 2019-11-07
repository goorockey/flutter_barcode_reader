//
// Created by Matthew Smith on 11/7/17.
//

#import "BarcodeScannerViewController.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>
#import "ScannerOverlay.h"


@implementation BarcodeScannerViewController {
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.previewView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_previewView];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
  self.scanRect = [[ScannerOverlay alloc] initWithFrame:self.view.bounds];
  self.scanRect.translatesAutoresizingMaskIntoConstraints = NO;
  self.scanRect.backgroundColor = UIColor.clearColor;
  [self.view addSubview:_scanRect];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [_scanRect startAnimating];
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    UIButton *back = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 34, 58)];
    [back setImage:[UIImage imageNamed:@"back_left"] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: back];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
//  [self updateFlashButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.scanner.isScanning) {
        [self.scanner stopScanning];
    }
    [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
        if (success) {
            [self startScan];
        } else {
//          [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"PERMISSION_NOT_GRANTED"];
//          [self dismissViewControllerAnimated:NO completion:nil];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"需要授权摄像头权限" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:NO completion:nil];
            }];
            UIAlertAction *enter = [UIAlertAction actionWithTitle:@"点击授权" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UIApplication *application = [UIApplication sharedApplication];
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([application canOpenURL:url]) {
                    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                        if (@available(iOS 10.0, *)) {
                            [application openURL:url options:@{} completionHandler:nil];
                        } else {
                            // Fallback on earlier versions
                        }
                    } else {
                        [application openURL:url];
                    }
                }
                [self dismissViewControllerAnimated:NO completion:nil];
            }];
            [alert addAction:cancel];
            [alert addAction:enter];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.scanner stopScanning];
    [super viewWillDisappear:animated];
    if ([self isFlashOn]) {
        [self toggleFlash:NO];
    }
}

- (void)startScan {
    NSError *error;
    [self.scanner startScanningWithResultBlock:^(NSArray<AVMetadataMachineReadableCodeObject *> *codes) {
        [self.scanner stopScanning];
         AVMetadataMachineReadableCodeObject *code = codes.firstObject;
        if (code) {
            [self.delegate barcodeScannerViewController:self didScanBarcodeWithResult:code.stringValue];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    } error:&error];
}

- (void)cancel {
    [self.delegate dismissViewController];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)updateFlashButton {
    if (!self.hasTorch) {
        return;
    }
    if (self.isFlashOn) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash Off"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self action:@selector(toggle)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash On"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self action:@selector(toggle)];
    }
}

- (void)toggle {
    [self toggleFlash:!self.isFlashOn];
    [self updateFlashButton];
}

- (BOOL)isFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.torchMode == AVCaptureFlashModeOn || device.torchMode == AVCaptureTorchModeOn;
    }
    return NO;
}

- (BOOL)hasTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.hasTorch;
    }
    return false;
}

- (void)toggleFlash:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *err;
    if (device.hasFlash && device.hasTorch) {
        [device lockForConfiguration:&err];
        if (err != nil) return;
        if (on) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
        } else {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
        }
        [device unlockForConfiguration];
    }
}


@end
