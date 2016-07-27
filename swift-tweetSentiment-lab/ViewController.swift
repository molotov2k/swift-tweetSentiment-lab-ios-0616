//
//  ViewController.swift
//  swift-tweetSentiment-lab
//
//  Created by susan lovaglio on 7/23/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit
import Twitter
import STTwitter




class ViewController: UIViewController {
    
    @IBOutlet weak var polarityScoreLabel: UILabel!
    
    var tweets = [String]() {
        didSet {
            if tweets.count == tweetsCount {
                print("Tweets loaded!")
                self.tweetsLoaded = true
                self.getSentiments()
            }
        }
    }
    
    var tweetSentiments = [Int]() {
        didSet {
            if tweetSentiments.count == tweetsCount {
                dispatch_async(dispatch_get_main_queue()) {
                    let averagePolatity = self.calculateAveragePolarity()
                    self.polarityScoreLabel.text = String(averagePolatity)
                }
            }
        }
    }
    
    
    var tweetsLoaded = false
    var tweetsCount = 0
    let secrets = Secrets()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchTwits()
        self.polarityScoreLabel.text = "Calculating!"
        
    }
    
    
    func fetchTwits() {
        let twitter = STTwitterAPI(appOnlyWithConsumerKey: secrets.userKey, consumerSecret: secrets.userSecret)
        
        twitter.verifyCredentialsWithUserSuccessBlock({ (userName, userID) in
            twitter.getSearchTweetsWithQuery("FlatironSchool", successBlock: { (metaData, tweets) in
                self.tweetsCount = tweets.count
                for tweet in tweets {
                    let dictionary = tweet as! NSDictionary
                    if let tweetNSString = dictionary["text"] {
                        let tweetString = String(tweetNSString)
                        self.tweets.append(tweetString)
                    } else {
                        self.tweetsCount -= 1
                    }
                }
                
                }, errorBlock: { (error) in
                    print("--- Error in fetching: \(error)")
            })
            
        }) { (error) in
            print("--- Error in verification: \(error)")
        }
    }
    
    
    func getSentiments() {
        
        
        for tweet in tweets {
            var apiURLString = "http://www.sentiment140.com/api/classify?text="
            let unescapedString = tweet.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
            apiURLString.appendContentsOf(unescapedString!)
            let url = NSURL(string: apiURLString)
            
            let session = NSURLSession.sharedSession()
            let dataTask = session.dataTaskWithURL(url!) {
                data, response, error in
                if let data = data {
                    do {
                        
                        let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: [NSJSONReadingOptions.AllowFragments]) as! NSDictionary
                        
                        if let polarity = dictionary["results"]!["polarity"]! {
                            let intPolarity = Int(String(polarity))
                            if let intPolarity = intPolarity {
                            self.tweetSentiments.append(intPolarity)
                            }
                        }
                    } catch {
                        self.tweetSentiments.append(-1)
                        print("--- Error getting sentiment:  \(error)\n")
                    }
                }
            }
            dataTask.resume()
        }
    }
    
    
    func calculateAveragePolarity() -> Int {
        let properPolarity = self.tweetSentiments.filter({$0 != -1})
        let totalPolarity = properPolarity.reduce(0, combine: {$0 + $1})
        return totalPolarity / properPolarity.count
    }
    
    
}

