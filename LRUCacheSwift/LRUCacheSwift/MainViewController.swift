//
//  ViewController.swift
//  LRUCacheSwift
//
//  Created by Frederick C. Lee on 8/5/23.
//

import UIKit

class MainViewController: UIViewController {
    private var arrayItems: [String] = []
    private var ricCache: RicCache!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arrayItems = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        ricCache = RicCache(name: "myCache")
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        // arrayItems = ricCache.getCachedArrayItems() as? [String] ?? []
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    
    override func viewWillDisappear(_ animated: Bool) {
        ricCache.cachedArrayItems(arrayItems)
        super.viewWillDisappear(animated)
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    // MARK: - Action methods
    
    @IBAction func cacheSomething(_ sender: UIBarButtonItem) {
        ricCache.cachedArrayItems(arrayItems)
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    
    @IBAction func retrieveCache(_ sender: UIBarButtonItem) {
        arrayItems = ricCache.getCachedArrayItems() as? [String] ?? []
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    
    @IBAction func exitButton(_ sender: UIBarButtonItem) {
        exit(0)
    }
    
    // -----------------------------------------------------------------------------------------------------------------------
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        ricCache.clearCache()
    }
}

