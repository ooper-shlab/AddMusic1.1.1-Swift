//
//  MainViewController.swift
//  AddMusic
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/4/5.
//
//
/*
    File: MainViewController.h
    File: MainViewController.m
Abstract: View controller class for AddMusic. Sets up user interface, responds
to and manages user interaction.
 Version: 1.1

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.

*/

let PLAYER_TYPE_PREF_KEY = "player_type_preference"
let AUDIO_TYPE_PREF_KEY = "audio_technology_preference"

import UIKit
import MediaPlayer
import AVFoundation
import AudioToolbox

@objc(MainViewController)
class MainViewController: UIViewController, MPMediaPickerControllerDelegate, MusicTableViewControllerDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate {
    
    @IBOutlet var artworkItem: UIBarButtonItem!				// the now-playing media item's artwork image, displayed in the Navigation bar
    @IBOutlet var navigationBar: UINavigationBar!				// the application's Navigation bar
    @IBOutlet var nowPlayingLabel: UILabel!			// descriptive text shown on the main screen about the now-playing media item
    var playedMusicOnce: Bool = false			// A flag indicating if the user has played iPod library music at least one time
    
    var playBarButton: UIBarButtonItem?				// the button for invoking Play on the music player
    var pauseBarButton: UIBarButtonItem?				// the button for invoking Pause on the music player
    var userMediaItemCollection: MPMediaItemCollection?	// the media item collection created by the user, using the media item picker
    var musicPlayer: MPMusicPlayerController!				// the music player, which plays media items from the iPod library
    var noArtworkImage: UIImage!				// an image to display when a media item has no associated artwork
    var backgroundColorTimer: NSTimer!		// a timer for changing the background color -- represents an application that is
    //										//		doing something else while iPod music is playing
    
    var appSoundPlayer: AVAudioPlayer!				// An AVAudioPlayer object for playing application sound
    var soundFileURL: NSURL!				// The path to the application sound
    @IBOutlet var appSoundButton: UIButton!				// the button to invoke playback for the application sound
    @IBOutlet var addOrShowMusicButton: UIButton!		// the button for invoking the media item picker. if the user has already
    //										//		specified a media item collection, the title changes to "Show Music" and
    //										//		the button invokes a table view that shows the specified collection
    var interruptedOnPlayback: Bool = false		// A flag indicating whether or not the application was interrupted during
    //										//		application audio playback
    var playing: Bool = false					// An application that responds to interruptions must keep track of its playing/
    //										//		not-playing state.
    
    
    //MARK: Audio session callbacks_______________________
    
    // Audio session callback function for responding to audio route changes. If playing
    //		back application audio when the headset is unplugged, this callback pauses
    //		playback and displays an alert that allows the user to resume or stop playback.
    //
    //		The system takes care of iPod audio pausing during route changes--this callback
    //		is not involved with pausing playback of iPod audio.
    func handle_RouteChangeNotification(notification: NSNotification) {
        
        // ensure that this callback was invoked for a route change
        if notification.name != AVAudioSessionRouteChangeNotification { return }
        
        // This callback, being outside the implementation block, needs a reference to the
        //		MainViewController object, which it receives in the inUserData parameter.
        //		You provide this reference when registering this callback (see the call to
        //		AudioSessionAddPropertyListener).
        
        // if application sound is not playing, there's nothing to do, so return.
        if !self.appSoundPlayer.playing {
            
            NSLog("Audio route change while application audio is stopped.")
            return
            
        } else {
            
            // Determines the reason for the route change, to ensure that it is not
            //		because of a category change.
            
            let routeChangeReasonRaw = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
            
            let routeChangeReason = AVAudioSessionRouteChangeReason(rawValue: routeChangeReasonRaw)
            
            // "Old device unavailable" indicates that a headset was unplugged, or that the
            //	device was removed from a dock connector that supports audio output. This is
            //	the recommended test for when to pause audio.
            if routeChangeReason == .OldDeviceUnavailable {
                
                self.appSoundPlayer.pause()
                NSLog("Output device removed, so application audio was paused.")
                
                if #available(iOS 8.0, *) {
                    let routeChangeAlert =
                    UIAlertController(title: NSLocalizedString("Playback Paused", comment: "Title for audio hardware route-changed alert view"),
                        message: NSLocalizedString("Audio output was changed", comment: "Explanation for route-changed alert view"),
                        preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("StopPlaybackAfterRouteChange", comment: "Stop button title"), style: .Cancel) {action in
                        self.routeChangeAlertClickedButtonAtIndex(0)
                    }
                    let otherAction = UIAlertAction(title: NSLocalizedString("ResumePlaybackAfterRouteChange", comment: "Play button title"), style: .Default) {action in
                        self.routeChangeAlertClickedButtonAtIndex(1)
                    }
                    routeChangeAlert.addAction(cancelAction)
                    routeChangeAlert.addAction(otherAction)
                    self.presentViewController(routeChangeAlert, animated: true, completion: nil)
                } else {
                    let routeChangeAlertView =
                    UIAlertView(title: NSLocalizedString("Playback Paused", comment: "Title for audio hardware route-changed alert view"),
                        message: NSLocalizedString("Audio output was changed", comment: "Explanation for route-changed alert view"),
                        delegate: self,
                        cancelButtonTitle: NSLocalizedString("StopPlaybackAfterRouteChange", comment: "Stop button title"))
                    routeChangeAlertView.addButtonWithTitle(NSLocalizedString("ResumePlaybackAfterRouteChange", comment: "Play button title"))
                    routeChangeAlertView.show()
                }
                
            } else {
                
                NSLog("A route change occurred that does not require pausing of application audio.")
            }
        }
    }
    
    
    
    //MARK: Music control________________________________
    
    // A toggle control for playing or pausing iPod library music playback, invoked
    //		when the user taps the 'playBarButton' in the Navigation bar.
    @IBAction func playOrPauseMusic(_: AnyObject) {
        
        let playbackState = musicPlayer!.playbackState
        
        if playbackState == .Stopped || playbackState == .Paused {
            musicPlayer.play()
        } else if playbackState == .Playing {
            musicPlayer.pause()
        }
    }
    
    // If there is no selected media item collection, display the media item picker. If there's
    // already a selected collection, display the list of selected songs.
    @IBAction func AddMusicOrShowMusic(_: AnyObject) {
        
        // if the user has already chosen some music, display that list
        if userMediaItemCollection != nil {
            
            let controller = MusicTableViewController(nibName: "MusicTableView", bundle: nil)
            controller.delegate = self
            
            controller.modalTransitionStyle = .CoverVertical
            
            self.presentViewController(controller, animated: true, completion: nil)
            
            // else, if no music is chosen yet, display the media item picker
        } else {
            
            let picker =
            MPMediaPickerController(mediaTypes: .Music)
            
            picker.delegate = self
            picker.allowsPickingMultipleItems = true
            picker.prompt = NSLocalizedString("Add songs to play", comment: "Prompt in media item picker")
            
            // The media item picker uses the default UI style, so it needs a default-style
            //		status bar to match it visually
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
            
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    
    // Invoked by the delegate of the media item picker when the user is finished picking music.
    //		The delegate is either this class or the table view controller, depending on the
    //		state of the application.
    func updatePlayerQueueWithMediaCollection(mediaItemCollection: MPMediaItemCollection?) {
        
        // Configure the music player, but only if the user chose at least one song to play
        if mediaItemCollection != nil {
            
            // If there's no playback queue yet...
            if userMediaItemCollection == nil {
                
                // apply the new media item collection as a playback queue for the music player
                self.userMediaItemCollection = mediaItemCollection
                musicPlayer.setQueueWithItemCollection(userMediaItemCollection!)
                self.playedMusicOnce = true
                musicPlayer.play()
                
                // Obtain the music player's state so it can then be
                //		restored after updating the playback queue.
            } else {
                
                // Take note of whether or not the music player is playing. If it is
                //		it needs to be started again at the end of this method.
                var wasPlaying = false
                if musicPlayer.playbackState == .Playing {
                    wasPlaying = true
                }
                
                // Save the now-playing item and its current playback time.
                let nowPlayingItem = musicPlayer.nowPlayingItem
                let currentPlaybackTime = musicPlayer.currentPlaybackTime
                
                // Combine the previously-existing media item collection with the new one
                var combinedMediaItems = userMediaItemCollection!.items
                let newMediaItems = mediaItemCollection!.items
                combinedMediaItems += newMediaItems
                
                self.userMediaItemCollection = MPMediaItemCollection(items: combinedMediaItems)
                
                // Apply the new media item collection as a playback queue for the music player.
                musicPlayer.setQueueWithItemCollection(userMediaItemCollection!)
                
                // Restore the now-playing item and its current playback time.
                musicPlayer.nowPlayingItem = nowPlayingItem
                musicPlayer.currentPlaybackTime = currentPlaybackTime
                
                // If the music player was playing, get it playing again.
                if wasPlaying {
                    musicPlayer.play()
                }
            }
            
            // Finally, because the music player now has a playback queue, ensure that
            //		the music play/pause button in the Navigation bar is enabled.
            navigationBar.topItem!.leftBarButtonItem!.enabled = true
            
            addOrShowMusicButton.setTitle(NSLocalizedString("Show Music", comment: "Alternate title for 'Add Music' button, after user has chosen some music"),
                forState: .Normal)
        }
    }
    
    // If the music player was paused, leave it paused. If it was playing, it will continue to
    //		play on its own. The music player state is "stopped" only if the previous list of songs
    //		had finished or if this is the first time the user has chosen songs after app
    //		launch--in which case, invoke play.
    private func restorePlaybackState() {
        
        if musicPlayer.playbackState == .Stopped && userMediaItemCollection != nil {
            
            addOrShowMusicButton.setTitle(NSLocalizedString("Show Music", comment: "Alternate title for 'Add Music' button, after user has chosen some music"),
                forState: .Normal)
            
            if !playedMusicOnce {
                
                self.playedMusicOnce = true
                musicPlayer.play()
            }
        }
        
    }
    
    
    
    //MARK: Media item picker delegate methods________
    
    // Invoked when the user taps the Done button in the media item picker after having chosen
    //		one or more media items to play.
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        // Dismiss the media item picker.
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // Apply the chosen songs to the music player's queue.
        self.updatePlayerQueueWithMediaCollection(mediaItemCollection)
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    }
    
    // Invoked when the user taps the Done button in the media item picker having chosen zero
    //		media items to play
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    }
    
    
    
    //MARK: Music notification handlers__________________
    
    // When the now-playing item changes, update the media item artwork and the now-playing label.
    func handle_NowPlayingItemChanged(notification: NSNotification!) {
        
        let currentItem = musicPlayer.nowPlayingItem
        
        // Assume that there is no artwork for the media item.
        var artworkImage = noArtworkImage
        
        // Get the artwork from the current media item, if it has artwork.
        let artwork = currentItem?.valueForProperty(MPMediaItemPropertyArtwork) as! MPMediaItemArtwork?
        
        // Obtain a UIImage object from the MPMediaItemArtwork object
        if artwork != nil {
            artworkImage = artwork!.imageWithSize(CGSizeMake(30, 30))
        }
        
        // Obtain a UIButton object and set its background to the UIImage object
        let artworkView = UIButton(frame: CGRectMake(0, 0, 30, 30))
        artworkView.setBackgroundImage(artworkImage, forState: .Normal)
        
        // Obtain a UIBarButtonItem object and initialize it with the UIButton object
        let newArtworkItem = UIBarButtonItem(customView: artworkView)
        self.artworkItem = newArtworkItem
        
        artworkItem.enabled = false
        
        // Display the new media item artwork
        navigationBar.topItem!.setRightBarButtonItem(artworkItem, animated: true)
        
        // Display the artist and song name for the now-playing media item
        nowPlayingLabel.text =
            String(format: "%@ %@ %@ %@",
                NSLocalizedString("Now Playing:", comment: "Label for introducing the now-playing song title and artist"),
                currentItem?.valueForProperty(MPMediaItemPropertyTitle) as! String? ?? "",
                NSLocalizedString("by", comment: "Article between song name and artist name"),
                currentItem?.valueForProperty(MPMediaItemPropertyArtist) as! String? ?? "")
        
        if musicPlayer.playbackState == .Stopped {
            // Provide a suitable prompt to the user now that their chosen music has
            //		finished playing.
            nowPlayingLabel.text =
                String(format: "%@",
                    NSLocalizedString("Music-ended Instructions", comment: "Label for prompting user to play music again after it has stopped"))
            
        }
    }
    
    // When the playback state changes, set the play/pause button in the Navigation bar
    //		appropriately.
    func handle_PlaybackStateChanged(notification: NSNotification) {
        
        let playbackState = musicPlayer.playbackState
        
        if playbackState == .Paused {
            
            navigationBar.topItem!.leftBarButtonItem = playBarButton
            
        } else if playbackState == .Playing {
            
            navigationBar.topItem!.leftBarButtonItem = pauseBarButton
            
        } else if playbackState == .Stopped {
            
            navigationBar.topItem!.leftBarButtonItem = playBarButton
            
            // Even though stopped, invoking 'stop' ensures that the music player will play
            //		its queue from the start.
            musicPlayer.stop()
            
        }
    }
    
    func handle_iPodLibraryChanged(notification: NSNotification) {
        
        // Implement this method to update cached collections of media items when the
        // user performs a sync while your application is running. This sample performs
        // no explicit media queries, so there is nothing to update.
    }
    
    
    
    //MARK: Application playback control_________________
    
    @IBAction func playAppSound(_: AnyObject) {
        
        appSoundPlayer.play()
        playing = true
        appSoundButton.enabled = false
    }
    
    // delegate method for the audio route change alert view; follows the protocol specified
    //	in the UIAlertViewDelegate protocol.
    func alertView(routeChangeAlertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        routeChangeAlertClickedButtonAtIndex(buttonIndex)
    }
    private func routeChangeAlertClickedButtonAtIndex(buttonIndex: Int) {
        
        if buttonIndex == 1 {
            appSoundPlayer.play()
        } else {
            appSoundPlayer.currentTime = 0
            appSoundButton.enabled = true
        }
        
    }
    
    
    
    //MARK: AV Foundation delegate methods____________
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        
        playing = false
        appSoundButton.enabled = true
    }
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        
        NSLog("Interrupted. The system has paused audio playback.")
        
        if playing {
            
            playing = false
            interruptedOnPlayback = true
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
        
        NSLog("Interruption ended. Resuming audio playback.")
        
        do {
            // Reactivates the audio session, whether or not audio was playing
            //		when the interruption arrived.
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        
        if interruptedOnPlayback {
            
            appSoundPlayer.prepareToPlay()
            appSoundPlayer.play()
            playing = true
            interruptedOnPlayback = false
        }
    }
    
    
    
    //MARK: Table view delegate methods________________
    
    // Invoked when the user taps the Done button in the table view.
    func musicTableViewControllerDidFinish(controller: MusicTableViewController) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.restorePlaybackState()
    }
    
    
    
    //MARK: Application setup____________________________
    
    //#if TARGET_IPHONE_SIMULATOR
    //#warning *** Simulator mode: iPod library access works only when running on a device.
    //#endif
    
    private func setupApplicationAudio() {
        
        // Gets the file system path to the sound to play.
        let soundFilePath = NSBundle.mainBundle().pathForResource("sound",
            ofType: "caf")!
        
        // Converts the sound's file path to an NSURL object
        let newURL = NSURL(fileURLWithPath: soundFilePath)
        self.soundFileURL = newURL
        
        do {
            // Registers this class as the delegate of the audio session.
            //###AVAudioSessionDelegate is deprecated.
        
            // The AmbientSound category allows application audio to mix with Media Player
            // audio. The category also indicates that application audio should stop playing
            // if the Ring/Siilent switch is set to "silent" or the screen locks.
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch _ {
        }
        /*
        // Use this code instead to allow the app sound to continue to play when the screen is locked.
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        let options = AVAudioSession.sharedInstance().categoryOptions
        
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: options & ~AVAudioSessionCategoryOptions.MixWithOthers, error: nil)
        */
        
        // Registers the audio route change listener callback function
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handle_RouteChangeNotification",
            //###Posted on the main thread when the system’s audio route changes.
            name: AVAudioSessionRouteChangeNotification,
            object: nil)
        
        // Activates the audio session.
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        
        // Instantiates the AVAudioPlayer object, initializing it with the sound
        let newPlayer: AVAudioPlayer!
        do {
            newPlayer = try AVAudioPlayer(contentsOfURL: soundFileURL)
        } catch _ {
            newPlayer = nil
        }
        self.appSoundPlayer = newPlayer
        
        // "Preparing to play" attaches to the audio hardware and ensures that playback
        //		starts quickly when the user taps Play
        appSoundPlayer.prepareToPlay()
        appSoundPlayer.volume = 1.0
        appSoundPlayer.delegate = self
    }
    
    
    // To learn about notifications, see "Notifications" in Cocoa Fundamentals Guide.
    private func registerForMediaPlayerNotifications() {
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self,
            selector: "handle_NowPlayingItemChanged:",
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: musicPlayer)
        
        notificationCenter.addObserver(self,
            selector: "handle_PlaybackStateChanged:",
            name: MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: musicPlayer)
        
        /*
        // This sample doesn't use libray change notifications; this code is here to show how
        //		it's done if you need it.
        notificationCenter.addObserver(self,
        selector: "handle_iPodLibraryChanged:",
        name: MPMediaLibraryDidChangeNotification,
        object: musicPlayer)
        
        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
        */
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    
    // To learn about the Settings bundle and user preferences, see User Defaults Programming Topics
    //		for Cocoa and "The Settings Bundle" in iPhone Application Programming Guide
    
    // Returns whether or not to use the iPod music player instead of the application music player.
    var useSystemPlayer: Bool {
        
        if NSUserDefaults.standardUserDefaults().boolForKey(PLAYER_TYPE_PREF_KEY) {
            return true
        } else {
            return false
        }
    }
    
    // Configure the application.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setupApplicationAudio()
        
        self.playedMusicOnce = false
        
        self.noArtworkImage = UIImage(named: "no_artwork.png")
        
        self.playBarButton = UIBarButtonItem(barButtonSystemItem: .Play,
            target: self,
            action: "playOrPauseMusic:")
        
        self.pauseBarButton = UIBarButtonItem(barButtonSystemItem: .Pause,
            target: self,
            action: "playOrPauseMusic:")
        
        addOrShowMusicButton.setTitle(NSLocalizedString("Add Music", comment: "Title for 'Add Music' button, before user has chosen some music"),
            forState: .Normal)
        
        appSoundButton.setTitle(NSLocalizedString("Play App Sound", comment: "Title for 'Play App Sound' button"),
            forState: .Normal)
        
        nowPlayingLabel.text = NSLocalizedString("Instructions", comment: "Brief instructions to user, shown at launch")
        
        // Instantiate the music player. If you specied the iPod music player in the Settings app,
        //		honor the current state of the built-in iPod app.
        if self.useSystemPlayer {
            
            self.musicPlayer = MPMusicPlayerController.systemMusicPlayer()
            
            if musicPlayer.nowPlayingItem != nil {
                
                navigationBar.topItem!.leftBarButtonItem!.enabled = true
                
                // Update the UI to reflect the now-playing item.
                self.handle_NowPlayingItemChanged(nil)
                
                if musicPlayer.playbackState == .Paused {
                    navigationBar.topItem!.leftBarButtonItem = playBarButton
                }
            }
            
        } else {
            
            self.musicPlayer = MPMusicPlayerController.applicationMusicPlayer()
            
            // By default, an application music player takes on the shuffle and repeat modes
            //		of the built-in iPod app. Here they are both turned off.
            musicPlayer.shuffleMode = .Off
            musicPlayer.repeatMode = .None
        }
        
        self.registerForMediaPlayerNotifications()
        
        // Configure a timer to change the background color. The changing color represents an
        //		application that is doing something else while iPod music is playing.
        self.backgroundColorTimer = NSTimer.scheduledTimerWithTimeInterval(3.5,
            target: self,
            selector: "updateBackgroundColor",
            userInfo: nil,
            repeats: true)
    }
    
    // Invoked by the backgroundColorTimer.
    func updateBackgroundColor() {
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(3.0)
        
        let redLevel = CGFloat(rand()) / CGFloat(RAND_MAX)
        let greenLevel = CGFloat(rand()) / CGFloat(RAND_MAX)
        let blueLevel = CGFloat(rand()) / CGFloat(RAND_MAX)
        
        self.view.backgroundColor = UIColor(red: redLevel,
            green: greenLevel,
            blue: blueLevel,
            alpha: 1.0)
        UIView.commitAnimations()
    }
    
    //MARK: Application state management_____________
    
    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
        
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    deinit {
        
        /*
        // This sample doesn't use libray change notifications; this code is here to show how
        //		it's done if you need it.
        NSNotificationCenter.defaultCenter().removeObserver(self,
        name: MPMediaLibraryDidChangeNotification,
        object: musicPlayer)
        
        MPMediaLibrary.defaultMediaLibrary().endGeneratingLibraryChangeNotifications()
        
        */
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: musicPlayer)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: musicPlayer)
        
        musicPlayer.endGeneratingPlaybackNotifications()
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionRouteChangeNotification,
            object: nil)
        
        backgroundColorTimer.invalidate()
        
    }
    
    
}