Audio Editor

Audio Trimmer is a simple component, which lets you trim your audio files on the fly. You can record your audio and get start to trim! 
Feature:
• You can select a range of audio to be trimmed. • Ability to record your audio and trim it. • Ability to play selected range of audio before trimming. • After trimming if you don’t like the audio then you can get the original file again by pressing “Reset”. 

Pro’s 
• Easy & Fast to make audio modification. • Audio quality remain as it have in original files. • You can play audio range before actually trimming the audio. • You can get Original file by press “Reset”. • You can apply trimming on trimmed audio again. 

Required Framework
	#import <AVFoundation/AVFoundation.h>
	#import <CoreMedia/CoreMedia.h>

How to use:
To use this component in your project you need to perform below steps:

1) Import “AudioEditorViewController.h" file where you want to implement this feature.

2) Add below code where you want to implement this component:

	To Present Audio Editor View:

	[AudioEditorViewController presentAudioEditorController:self completion:^(BOOL success, NSURL *trimedFilePath) {
                	// Do your stuff here..
                	NSLog(@"%@", trimedFilePath);
        		}];

	To Push Audio Editor View:

	[AudioEditorViewController pushAudioEditorController:self completion:^(BOOL success, NSURL *trimedFilePath) {
         	        // Do your stuff here..
          		NSLog(@"%@", trimedFilePath);
	            }];



We used below library to complete this feature

• EZAudio: https://github.com/syedhali/EZAudio 

