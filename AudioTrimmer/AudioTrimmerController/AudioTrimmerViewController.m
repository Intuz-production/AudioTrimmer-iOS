/*
 
 The MIT License (MIT)
 
 Copyright (c) 2018 INTUZ
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */


#import "NSTimer+Blocks.h"
#import "AudioTrimmerViewController.h"

CGFloat const minimumAudioDuration = 1;
CGFloat const maximumAudioDuration = 1;

@interface AudioTrimmerViewController ()

@property (strong, nonatomic) NSString *strTrimmedAudioURL;
@property (strong, nonatomic) AVAssetExportSession *exportSession;

@property (assign, nonatomic) BOOL isPushAudioTrimmer;

@end

@implementation AudioTrimmerViewController

@synthesize strTrimmedAudioURL;

+ (void) presentAudioTrimmerController:(UIViewController *)controller completion:(CompleteAudioEditing)complete {
    AudioTrimmerViewController *audioEditorController = [[AudioTrimmerViewController alloc] initWithNibName:@"AudioTrimmerViewController" bundle:nil];
    audioEditorController.completionBlock=complete;
    audioEditorController.isPushAudioTrimmer = false;
    audioEditorController.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.3];
    [controller presentViewController:audioEditorController animated:true completion:nil];
}

+ (void) pushAudioTrimmerController:(UIViewController *)controller completion:(CompleteAudioEditing)complete {
    AudioTrimmerViewController *audioEditorController = [[AudioTrimmerViewController alloc] initWithNibName:@"AudioTrimmerViewController" bundle:nil];
    audioEditorController.completionBlock=complete;
    audioEditorController.isPushAudioTrimmer = true;
    audioEditorController.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.3];
    [controller.navigationController pushViewController:audioEditorController animated:true];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [viewStartRecord setHidden:FALSE];
    [viewRecording setHidden:TRUE];
    [viewEditRecording setHidden:TRUE];
    [imgViewAudioIndicatorLine setHidden:TRUE];
    [btnUpload setHidden:YES];
    
    strOriginalAudioURL = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"originalRecording.wav"];
    strAudioURL = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"recording.wav"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:strAudioURL]) {
        [[NSFileManager defaultManager] removeItemAtPath:strAudioURL error:nil];
    }
    
    
    [self prepareToRecordAudio];
    
    UIPanGestureRecognizer *panGestureLeftThumb = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panGestureLeftThumb setDelegate:self];
    [imgViewLeftThumb addGestureRecognizer:panGestureLeftThumb];
    
    UIPanGestureRecognizer *panGestureRightThumb = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panGestureRightThumb setDelegate:self];
    [imgViewRightThumb addGestureRecognizer:panGestureRightThumb];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (void) dismissAudioTrimmer:(NSString *)strTrimedFilePath {
    
    // Call Completion Block.
    if (self.completionBlock) {
        if (strTrimedFilePath != nil) {
            NSURL *fileUrl = [NSURL fileURLWithPath:strTrimedFilePath];
            self.completionBlock(true, fileUrl);
        }
        else {
            self.completionBlock(false, nil);
        }
    }

    if (self.isPushAudioTrimmer == true) {
        [self.navigationController popViewControllerAnimated:true];
    }
    else {
        [self dismissViewControllerAnimated:true completion:nil];
    }
}

- (IBAction)btnCancelTapped:(id)sender {
    strTrimmedAudioURL = nil;
    [self dismissAudioTrimmer:strTrimmedAudioURL];
}

- (IBAction)btnUploadTapped:(id)sender {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:strAudioURL]) {
        [self stopAudioPlayer];
        if(isAudioTrimmed) {
             [self dismissAudioTrimmer:strTrimmedAudioURL];
        }
        else {
            [self trimAudioWithCompletion:^{
                isAudioTrimmed = TRUE;
                [self resetAudioPlayer];
                [self hideUnhideControls:TRUE];
                [self dismissAudioTrimmer:strTrimmedAudioURL];
            }];
        }
    }
}

- (IBAction)btnStartRecordingTapped:(id)sender {
    [self startRecording];
}

- (IBAction)btnStopRecordingTapped:(id)sender {
    [self stopRecording];
}

- (IBAction)btnResetTapped:(id)sender {

     isAudioTrimmed = FALSE;
    if([[NSFileManager defaultManager] fileExistsAtPath:strAudioURL]) {
        [[NSFileManager defaultManager] removeItemAtPath:strAudioURL error:nil];
    }
    [[NSFileManager defaultManager] copyItemAtPath:strOriginalAudioURL toPath:strAudioURL error:nil];
    [self resetAudioPlayer];
}

- (IBAction)btnPlayPauseTapped:(id)sender {
    if(isPlaying) {
        [self pauseAudioPlayer];
    }
    else {
        [self playAudioPlayer];
        [audioPlayer setCurrentTime:audioTrimStartTime];
    }
}

- (IBAction)btnResetAudioTapped:(id)sender {
    [self resetAudioPlayer];
    [self hideUnhideControls:FALSE];
    [self startRecording];
}

- (IBAction)btnEditTrimmedVideoTapped:(id)sender {
    if (((UIButton *) sender).selected) {
        isAudioTrimmed = FALSE;
        [self resetAudioPlayer];
        
        [self hideUnhideControls:FALSE];
    }
    else {
        [self btnTrimFinalAudio];
    }
    
}

- (void)btnTrimFinalAudio {
    [self stopAudioPlayer];
    [self trimAudioWithCompletion:^{
        isAudioTrimmed = TRUE;
        [self resetAudioPlayer];
        [self hideUnhideControls:TRUE];
    }];
}

#pragma mark - Gesture

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    [self stopAudioPlayer];
    if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = sender.view;
        [view.superview bringSubviewToFront:view];
        CGPoint translation = [sender translationInView:view];
        CGPoint viewPosition = view.center;
        viewPosition.x += translation.x;
        
        [self calculateAudioTrimTime];

        //NSLog(@"audioTrimStartTime: %f audioTrimEndTime : %f", audioTrimStartTime, audioTrimEndTime);
        if(audioTrimEndTime - audioTrimStartTime > minimumAudioDuration ||
           ([view isEqual:imgViewLeftThumb] && translation.x <= 0) ||
           ([view isEqual:imgViewRightThumb] && translation.x >= 0)) {
            view.center = viewPosition;
            
            CGRect frame = view.frame;
            if(view.frame.origin.x <= (-view.frame.size.width/2)) {
                frame.origin.x = -view.frame.size.width/2;
                view.frame = frame;
            }
            else if(view.center.x >= viewAudioPlotContainer.frame.size.width){
                frame.origin.x = viewAudioPlotContainer.frame.size.width - (view.frame.size.width/2);
                view.frame = frame;
            }
        }
        else {
            [self calculateAudioTrimTime];
        }
        [sender setTranslation:CGPointZero inView:imgViewLeftThumb];
    }
    else {
        [self calculateAudioTrimTime];
    }
}

#pragma mark - Other Methods

- (NSString *)timeFormatted:(CGFloat)interval isWithMinutes:(BOOL)isWithMinutes {
    unsigned long milliseconds = interval * 1000;
    unsigned long seconds = milliseconds / 1000;
    milliseconds %= 1000;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
//    unsigned long hours = minutes / 60;
//    minutes %= 60;
    
    NSString *strMillisec = @(milliseconds).stringValue;
    if (strMillisec.length > 2) {
        strMillisec = [strMillisec substringToIndex:2];
    }
    
    if(isWithMinutes) {
        return [NSString stringWithFormat:@"%02ld:%02ld.%02ld",(long)minutes, (long)seconds, (long)[strMillisec integerValue]];
    }
    else {
        return [NSString stringWithFormat:@"%02ld.%02ld",(long)seconds, (long)[strMillisec integerValue]];
    }
}

- (void)setupAudioPlot {
    
    audioPlot.backgroundColor = [UIColor colorWithRed:(231)/255.0f green:(231)/255.0f blue:(231)/255.0f alpha:1];
    audioPlot.color = [UIColor colorWithRed:(231)/255.0f green:(161)/255.0f blue:(186)/255.0f alpha:1];
    audioPlot.plotType = EZPlotTypeBuffer;
    audioPlot.shouldFill = YES;
    audioPlot.shouldMirror = YES;
    audioPlot.shouldOptimizeForRealtimePlot = NO;
    audioPlot.waveformLayer.shadowOffset = CGSizeMake(0.0, 1.0);
    audioPlot.waveformLayer.shadowRadius = 0.0;
    audioPlot.waveformLayer.shadowColor = [UIColor clearColor].CGColor;
    audioPlot.waveformLayer.shadowOpacity = 1.0;

    audioFile = [EZAudioFile audioFileWithURL:[NSURL fileURLWithPath:strAudioURL]];
    [audioFile getWaveformDataWithCompletionBlock:^(float **waveformData, int length) {
        [audioPlot updateBuffer:waveformData[0] withBufferSize:length];
    }];
}

- (void)trimAudioWithCompletion:(void(^)(void))completion {
    
    if(!strTrimmedAudioURL) {
        strTrimmedAudioURL = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"trimmerRecording.wav"];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:strTrimmedAudioURL]) {
        [[NSFileManager defaultManager] removeItemAtPath:strTrimmedAudioURL error:nil];
    }
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:strAudioURL]];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
        self.exportSession.outputURL = [NSURL fileURLWithPath:strTrimmedAudioURL];
        self.exportSession.outputFileType = AVFileTypeWAVE;
        
        CMTime start = CMTimeMakeWithSeconds(audioTrimStartTime, asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(audioTrimEndTime - audioTrimStartTime, asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export cancelled");
                    break;
                case AVAssetExportSessionStatusCompleted: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSError *error;
                        if([[NSFileManager defaultManager] fileExistsAtPath:strAudioURL]) {
                            [[NSFileManager defaultManager] removeItemAtPath:strAudioURL error:nil];
                        }
                        [[NSFileManager defaultManager] copyItemAtPath:strTrimmedAudioURL toPath:strAudioURL error:&error];
                        if(completion) {
                            completion();
                        }
                    });
                    break;
                }
                default:
                    NSLog(@"NONE");
                    break;
            }
        }];
    }
}

- (void)calculateAudioTrimTime {
    
    audioTrimStartTime = imgViewLeftThumb.center.x * audioDuration / viewAudioPlotContainer.frame.size.width;
    audioTrimEndTime = imgViewRightThumb.center.x * audioDuration / viewAudioPlotContainer.frame.size.width;
    [lblAudioStartTime setText:[self timeFormatted:audioTrimStartTime isWithMinutes:FALSE]];
    [lblAudioEndTime setText:[self timeFormatted:audioTrimEndTime isWithMinutes:FALSE]];
    
    //[lblAudioStartTime sizeToFit];
    //[lblAudioEndTime sizeToFit];
    
    [lblAudioStartTime setCenter:CGPointMake(imgViewLeftThumb.center.x, lblAudioStartTime.center.y)];
    [lblAudioEndTime setCenter:CGPointMake(imgViewRightThumb.center.x, lblAudioEndTime.center.y)];
    
    CGRect startFrame = lblAudioStartTime.frame;
    if(lblAudioStartTime.frame.origin.x < 0) {
        startFrame.origin.x = 0;
        [lblAudioStartTime setFrame:startFrame];
    }
    else if(lblAudioStartTime.frame.origin.x > viewAudioPlotContainer.frame.size.width - lblAudioStartTime.frame.size.width) {
        startFrame.origin.x = viewAudioPlotContainer.frame.size.width - lblAudioStartTime.frame.size.width;
        [lblAudioStartTime setFrame:startFrame];
    }
    
    CGRect endFrame = lblAudioEndTime.frame;
    if(lblAudioEndTime.frame.origin.x < 0) {
        endFrame.origin.x = 0;
        [lblAudioEndTime setFrame:endFrame];
    }
    else if(lblAudioEndTime.frame.origin.x > viewAudioPlotContainer.frame.size.width - lblAudioEndTime.frame.size.width) {
        endFrame.origin.x = viewAudioPlotContainer.frame.size.width - lblAudioEndTime.frame.size.width;
        [lblAudioEndTime setFrame:endFrame];
    }
}

- (void)hideUnhideControls:(BOOL)isHidden {
    [btnEditTrimmedAudio setSelected:isHidden];
    [imgViewLeftThumb setHidden:isHidden];
    [imgViewRightThumb setHidden:isHidden];
    
    [lblAudioStartTime setHidden:isHidden];
    [lblAudioEndTime setHidden:isHidden];
}

#pragma mark - Audio Recorder

- (void)prepareToRecordAudio {
    NSURL *outputFileURL = [NSURL fileURLWithPath:strOriginalAudioURL];
    if([[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
    }
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber  numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    
    
    // Initiate and prepare the recorder
    NSError *error = nil;
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:&error];
    if (error) {
        NSLog(@"Audio Session Error: %@", error.localizedDescription);
    }
    else {
        audioRecorder.delegate = self;
        audioRecorder.meteringEnabled = YES;
        [audioRecorder prepareToRecord];
    }
}

- (void)startRecording {
    [btnUpload setHidden:YES];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [audioRecorder record];
    [self startRcorderTimer];
    
    [viewStartRecord setHidden:TRUE];
    [viewRecording setHidden:FALSE];
    [viewEditRecording setHidden:TRUE];
}

- (void)stopRecording {
    [audioRecorder stop];
    [btnUpload setHidden:NO];
    [self stopRecorderTimer];
}

- (void)startRcorderTimer {
    __block NSDate *date = [NSDate date];
    timerRecording = [NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
        audioDuration = [[NSDate date] timeIntervalSinceDate:date];
        [lblRecordingTime setText:[self timeFormatted:audioDuration isWithMinutes:TRUE]];
    } repeats:YES];
}

- (void)stopRecorderTimer {
    if (timerRecording) {
        [timerRecording invalidate];
        timerRecording = nil;
    }
}

#pragma mark - Audio Player

- (void)resetAudioPlayer {
    [self stopAudioPlayer];
    audioPlayer = nil;
    [self setupAudioPlot];
    [self prepareToPlayAudio];
    [imgViewLeftThumb setCenter:CGPointMake(viewAudioPlotContainer.center.x, imgViewLeftThumb.center.y)];
    [imgViewRightThumb setCenter:CGPointMake(viewAudioPlotContainer.frame.size.width, imgViewRightThumb.center.y)];
    [self calculateAudioTrimTime];
}

- (void)prepareToPlayAudio {
    if (strAudioURL) {
        NSURL *url = [NSURL fileURLWithPath:strAudioURL];
        NSError *error;
        if (!audioPlayer) {
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            if (error) {
                NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
            } else {
                audioPlayer.delegate = self;
                [audioPlayer prepareToPlay];
                audioDuration = audioPlayer.duration;
                [lblAudioDuration setText:[self timeFormatted:audioDuration isWithMinutes:TRUE]];
            }
        }
    }
}

- (void)playAudioPlayer {
    if (!audioPlayer) {
        [self prepareToPlayAudio];
    }
    
    if(audioPlayer) {
        isPlaying = YES;
        [audioPlayer play];
        [btnPlayPause setSelected:TRUE];
        [self startAudioTimerToDisplay];
    }
}

- (void)pauseAudioPlayer {
    if (isPlaying) {
        isPlaying = NO;
        [audioPlayer pause];
        [btnPlayPause setSelected:FALSE];
        [imgViewAudioIndicatorLine setHidden:TRUE];
        [self stopAudioTimerToDisplay];
    }
}

- (void)stopAudioPlayer {
    if (isPlaying) {
        isPlaying = NO;
        [audioPlayer stop];
        [btnPlayPause setSelected:FALSE];
        [imgViewAudioIndicatorLine setHidden:TRUE];
        [self stopAudioTimerToDisplay];
    }
}

- (void)startAudioTimerToDisplay {
    if (timerAudioPlayer) {
        [timerAudioPlayer invalidate];
        timerAudioPlayer = nil;
    }
    
    timerAudioPlayer = [NSTimer scheduledTimerWithTimeInterval:.1 block:^{
        [imgViewAudioIndicatorLine setCenter:CGPointMake((viewAudioPlotContainer.frame.size.width * audioPlayer.currentTime / audioDuration), imgViewAudioIndicatorLine.center.y)];
        [imgViewAudioIndicatorLine setHidden:FALSE];
        if(audioPlayer.currentTime >= audioTrimEndTime) {
            [self stopAudioPlayer];
        }
    } repeats:YES];
}

- (void)stopAudioTimerToDisplay {
    if (timerAudioPlayer) {
        [timerAudioPlayer invalidate];
        timerAudioPlayer = nil;
    }
}


#pragma mark - Audio Recorder Delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag {
    // Stop recording
    [audioRecorder stop];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:strOriginalAudioURL]];
    audioDuration = CMTimeGetSeconds(asset.duration);
    [self calculateAudioTrimTime];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:NO error:nil];

    [viewStartRecord setHidden:TRUE];
    [viewRecording setHidden:TRUE];
    [viewEditRecording setHidden:FALSE];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:strAudioURL]) {
        [[NSFileManager defaultManager] removeItemAtPath:strAudioURL error:nil];
    }
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:strOriginalAudioURL toPath:strAudioURL error:&error];
    
    [self resetAudioPlayer];
    [self prepareToPlayAudio];

    [self setupAudioPlot];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

#pragma mark - Audio Player Delegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopAudioPlayer];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopAudioPlayer];
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    [self pauseAudioPlayer];
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    [self playAudioPlayer];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view];
    return fabs(velocity.x) > fabs(velocity.y);
}

@end
