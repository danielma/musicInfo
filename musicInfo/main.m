//
//  main.m
//  musicInfo
//
//  Created by drailskid on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "Spotify.h"
#import "Grooveshark.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        NSUserDefaults *args = [NSUserDefaults standardUserDefaults];

        NSString *formatArg = [args stringForKey:@"f"];
        NSMutableString *format = [[NSMutableString alloc] init];
        if (formatArg) {
            [format setString:formatArg];
        } else {
            [format setString:@"%t - %a"];
        }
        
        BOOL uppercase = [args boolForKey:@"u"];
        
        NSString *trackName = @"";
        NSString *trackArtist = @"";
        NSString *trackAlbum = @"";
        
        iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        Boolean vlcRunning = NO;
        Boolean groovesharkRunning = NO;
        
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSArray *runningApplications = [ws runningApplications];
        NSRunningApplication *runningApp = [[NSRunningApplication alloc] init];
        NSString *currentAppName = @"";
        
        for (runningApp in runningApplications)
        {
            //	NSLog(@"Open App: %@", [aDictionary valueForKey:@"NSApplicationName"]);
            
            currentAppName = [runningApp bundleIdentifier]; 
            
            if ([currentAppName isEqualToString:@"org.videolan.vlc"]) {
                vlcRunning = YES;
            } else if ([currentAppName isEqualToString:@"com.fluidapp.FluidInstance.Grooveshark"]) {
                groovesharkRunning = YES;
            }
        }
        
        if (groovesharkRunning) {
            GroovesharkApplication *grooveshark = [SBApplication applicationWithBundleIdentifier:@"com.fluidapp.FluidInstance.Grooveshark"];
            //            we'll do our stuff here
            NSString *windowName = [[[grooveshark windows] objectAtIndex:0] name];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^Playing:\\s(.+?)\\s\\|\\s(.+?)\\s\\|\\s(.+)" options:0 error:nil];
            NSArray *matches = [regex matchesInString:windowName options:0 range:NSMakeRange(0, [windowName length])];
            
            trackName = [windowName substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
            trackArtist = [windowName substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:2]];
            trackAlbum = [windowName substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:3]];            
        } else if ([iTunes isRunning]) {
            iTunesTrack *currentTrack = [iTunes currentTrack];
            
            trackName = [currentTrack name];
            trackArtist = [currentTrack artist];
            trackAlbum = [currentTrack album];
            
        } else if ([spotify isRunning]) {
            SpotifyTrack *currentTrack = [spotify currentTrack];
            
            trackName = [currentTrack name];
            trackArtist = [currentTrack artist];
            trackAlbum = [currentTrack album];
        } else if (vlcRunning) {
//            curl -s http://localhost:8080/requests/status.xml | grep -e "<info name='title'>" | sed -e "s/.*<info name='title'>\([^<]*\)<\/info>.*/\1/"
            NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080/requests/status.json"]];
            NSURLResponse *resp = nil;
            NSError *err = nil;
            NSData *response = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&resp error:&err];
            NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            NSRange range = NSMakeRange(0, [responseString length]);
            
//            NSLog(@"%@", responseString);
            
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\"artist\":\"(.+)\".+\"album\":\"(.+)\".+\"title\":\"(.+)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\"state\":\"(.+?)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
            NSArray *matches = [regex matchesInString:responseString options:NSRegularExpressionDotMatchesLineSeparators range:range];
            
            NSString *matchString = [responseString substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
            
            if ([matchString isEqualToString:@"paused"] || [matchString isEqualToString:@"playing"]) {
                regex = [NSRegularExpression regularExpressionWithPattern:@".+\"artist\":\"(.+?)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
                matches = [regex matchesInString:responseString options:NSRegularExpressionDotMatchesLineSeparators range:range];
                
                if (matches && matches.count) {
                    trackArtist = [responseString substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
                }
                
                regex = [NSRegularExpression regularExpressionWithPattern:@".+\"album\":\"(.+?)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
                matches = [regex matchesInString:responseString options:NSRegularExpressionDotMatchesLineSeparators range:range];
                
                if (matches && matches.count) {
                    trackAlbum = [responseString substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
                }
                
                regex = [NSRegularExpression regularExpressionWithPattern:@".+\"title\":\"(.+?)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
                matches = [regex matchesInString:responseString options:NSRegularExpressionDotMatchesLineSeparators range:range];
                
                if (matches && matches.count) {
                    trackName = [responseString substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
                }
            } else {
                return 0;
            }
        } else {
           return 0; // we're done then
        }
        
        if (trackName == NULL && trackArtist == NULL && trackAlbum == NULL) {
            return 0;
        }
        
        [format replaceOccurrencesOfString:@"%t" withString:trackName options:0 range:NSMakeRange(0, [format length])];
        [format replaceOccurrencesOfString:@"%a" withString:trackArtist options:0 range:NSMakeRange(0, [format length])];
        [format replaceOccurrencesOfString:@"%A" withString:trackAlbum options:0 range:NSMakeRange(0, [format length])];            
        
//        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\"artist\":\"(.+?)\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
//        NSArray *matches = [regex matchesInString:format options:NSRegularExpressionDotMatchesLineSeparators range:NSMakeRange(0, [format length])];
        
//        NSString *truncatedFormat = [format substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
    
        if (uppercase) {
            printf("%s\n", [[format uppercaseString] UTF8String]);
        } else {
            printf("%s\n", [format UTF8String]);
        }
    }
    return 0;
}