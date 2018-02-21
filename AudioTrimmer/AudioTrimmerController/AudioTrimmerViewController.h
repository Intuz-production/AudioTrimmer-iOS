/*
 
 The MIT License (MIT)
 
 Copyright (c) 2018 INTUZ
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */


#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

#import "EZAudio.h"

typedef void(^CompleteAudioEditing)(BOOL success, NSURL *trimedFilePath);

@interface AudioTrimmerViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIGestureRecognizerDelegate>
{
    IBOutlet UIView *viewStartRecord;
    IBOutlet UIView *viewRecording;
    IBOutlet UIView *viewEditRecording;
    IBOutlet UILabel *lblRecordingTime;
    
    IBOutlet UIView *viewAudioPlotContainer;
    IBOutlet EZAudioPlot *audioPlot;
    IBOutlet UIImageView *imgViewLeftThumb;
    IBOutlet UIImageView *imgViewRightThumb;
    IBOutlet UIImageView *imgViewAudioIndicatorLine;
    IBOutlet UILabel *lblAudioStartTime;
    IBOutlet UILabel *lblAudioEndTime;
    IBOutlet UILabel *lblAudioDuration;
    
    IBOutlet UIButton *btnCancel;
    IBOutlet UIButton *btnUpload;
    
    IBOutlet UIButton *btnReset;
    IBOutlet UIButton *btnPlayPause;
    IBOutlet UIButton *btnResetAudio;
    IBOutlet UIButton *btnEditTrimmedAudio;

    EZAudioFile *audioFile;
    AVAudioPlayer *audioPlayer;
    AVAudioRecorder *audioRecorder;
    NSString *strAudioURL;
    NSString *strOriginalAudioURL;

    NSTimer *timerRecording;
    NSTimer *timerAudioPlayer;
    
    BOOL videoTrimTimeChanged;
    CGFloat audioDuration;
    CGFloat audioTrimStartTime;
    CGFloat audioTrimEndTime;
    
    BOOL isPlaying;
    BOOL isAudioTrimmed;
}

@property (copy, nonatomic) CompleteAudioEditing completionBlock;

+ (void) presentAudioTrimmerController:(UIViewController *)controller completion:(CompleteAudioEditing)complete;
+ (void) pushAudioTrimmerController:(UIViewController *)controller completion:(CompleteAudioEditing)complete;

@end
