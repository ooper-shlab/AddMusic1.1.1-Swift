//
//  MusicTableViewController.swift
//  AddMusic
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/4/5.
//
//
/*
    File: MusicTableViewController.h
    File: MusicTableViewController.m
Abstract: Table view controller class for AddMusic. Shows the list
of music chosen by the user.
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

import MediaPlayer



@objc(MusicTableViewControllerDelegate)
protocol MusicTableViewControllerDelegate {
    
    // implemented in MainViewController.m
    func musicTableViewControllerDidFinish(controller: MusicTableViewController)
    func updatePlayerQueueWithMediaCollection(mediaItemCollection: MPMediaItemCollection?)
    
}



@objc(MusicTableViewController)
class MusicTableViewController: UIViewController, MPMediaPickerControllerDelegate, UITableViewDelegate {
    
    private let kCellIdentifier = "Cell"
    //
    weak var delegate: MusicTableViewControllerDelegate?					// The main view controller is the delegate for this class.
    @IBOutlet var mediaItemCollectionTable: UITableView!	// The table shown in this class's view.
    @IBOutlet var addMusicButton: UIBarButtonItem!				// The button for invoking the media item picker. Setting the title
    //		programmatically supports localization.
    
    
    // Configures the table view.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.addMusicButton.title = NSLocalizedString("AddMusicFromTableView", comment: "Add button shown on table view for invoking the media item picker")
        
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    
    // When the user taps Done, invokes the delegate's method that dismisses the table view.
    @IBAction func doneShowingMusicList(AnyObject) {
        
        self.delegate?.musicTableViewControllerDidFinish(self)
    }
    
    
    // Configures and displays the media item picker.
    @IBAction func showMediaPicker(AnyObject) {
        
        let picker =
        MPMediaPickerController(mediaTypes: .AnyAudio)
        
        picker.delegate = self
        picker.allowsPickingMultipleItems = true
        picker.prompt = NSLocalizedString("AddSongsPrompt", comment: "Prompt to user to choose some songs to play")
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        
        self.presentViewController(picker, animated: true, completion: {})
    }
    
    
    // Responds to the user tapping Done after choosing music.
    func mediaPicker(mediaPicker: MPMediaPickerController!, didPickMediaItems mediaItemCollection: MPMediaItemCollection!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.updatePlayerQueueWithMediaCollection(mediaItemCollection)
        self.mediaItemCollectionTable.reloadData()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    
    // Responds to the user tapping done having chosen no music.
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    
    
    //MARK: Table view methods________________________
    
    // To learn about using table views, see the TableViewSuite sample code
    //		and Table View Programming Guide for iPhone OS.
    
    func tableView(table: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let mainViewController = self.delegate as! MainViewController?
        let currentQueue = mainViewController?.userMediaItemCollection
        return currentQueue?.items.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell? {
        
        let row = indexPath.row
        var cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as! UITableViewCell?
        
        if cell == nil {
            
            cell = UITableViewCell(style: UITableViewCellStyle.Default,
                reuseIdentifier: kCellIdentifier)
        }
        
        let mainViewController = self.delegate as! MainViewController?
        let currentQueue = mainViewController?.userMediaItemCollection
        if let anItem = currentQueue?.items[row] as! MPMediaItem? {
            
            cell!.textLabel!.text = anItem.valueForProperty(MPMediaItemPropertyTitle) as! String?
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        return cell
    }
    
    //	 To conform to the Human Interface Guidelines, selections should not be persistent --
    //	 deselect the row after it has been selected.
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK: Application state management_____________
    // Standard methods for managing application state.
    override func didReceiveMemoryWarning() {
        
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
        
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    
    
}