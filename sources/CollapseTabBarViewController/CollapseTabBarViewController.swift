//
//  CollapseTabBarViewController.swift
//  PageTabBarControllerExample
//
//  Created by Mingloan Chan on 9/5/17.
//  Copyright © 2017 com.mingloan. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit

@objc public protocol CollapseTabBarViewControllerDelegate: PageTabBarControllerDelegate {
    @objc optional func collapseTabBarController(_ controller: CollapseTabBarViewController, tabBarDidReach position: CollapseTabBarPosition)
    @objc optional func collapseTabBarController(_ controller: CollapseTabBarViewController, scrollViewsForScrollingWithTabBarMoveAtIndex pageIndex: Int) -> [UIScrollView]
}

@objc public enum CollapseTabBarPosition: Int {
    case top = 0
    case bottom
}

@objc public enum CollapseTabBarAnimationType: Int {
    case easeInOut = 0
    case spring
}

public typealias CollapseTabBarLayoutSettings = CollapseCollectionViewLayoutSettings

@objc open class CollapseTabBarViewController: UIViewController {
    
    override open var childViewControllerForStatusBarHidden: UIViewController? {
        return pageTabBarController
    }
    
    override open var childViewControllerForStatusBarStyle: UIViewController? {
        return pageTabBarController
    }
    
    override open var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }
    
    open weak var delegate: CollapseTabBarViewControllerDelegate? {
        didSet {
            pageTabBarController.delegate = delegate
        }
    }
    
    // MARK: - PageTabBarController Properties
    open fileprivate(set) var pageTabBarController: PageTabBarController
    open var visibleViewController: UIViewController? {
        return pageTabBarController.selectedViewController
    }
    
    // MARK: - Scroll Control
    open var pageIndex: Int {
        get {
            return pageTabBarController.pageIndex
        }
        set {
            guard pageTabBarController.pageIndex != newValue else { return }
            pageTabBarController.setPageIndex(newValue, animated: false)
            collpaseCollectionView.otherScrollViews = constructScrollViewsToIgnoreToches()
        }
    }
    open var autoCollapse = false
    open var alwaysBouncesAtBottom = true
    
    open var minimumHeaderViewHeight: CGFloat = 0
    open fileprivate(set) var defaultHeaderHeight: CGFloat = 200
    open var headerViewStretchyHeight: CGFloat = 64
    
    open var staticHeaderView: UIView? {
        didSet {
            collpaseCollectionView.staticHeaderView = staticHeaderView
        }
    }
    
    /**
     LayoutGuide for attaching views to top of page view
     */
    open fileprivate(set) var topPageTabBarLayoutGuide: UILayoutGuide?
    
    fileprivate var tabBarItems = [PageTabBarItem]()
    
    // tabbar positioning
    fileprivate var _maximumHeaderViewHeight: CGFloat = 300

    fileprivate var viewControllers = [UIViewController]()
    fileprivate var headerView = UIView(frame: CGRect.zero)
    
    fileprivate var collpaseCollectionView: CollapseCollectionView
    
    @objc public init(viewControllers: [UIViewController],
                      tabBarItems: [PageTabBarItem],
                      headerView: UIView = UIView(frame: CGRect.zero),
                      headerHeight: CGFloat = 200) {
        
        pageTabBarController =
            PageTabBarController(
                viewControllers: viewControllers,
                items: tabBarItems)
        
        let layout = CollapseCollectionViewLayout(settings: CollapseCollectionViewLayoutSettings.defaultSettings())
        collpaseCollectionView = CollapseCollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
        
        assert(viewControllers.count > 0, "view controllers count == 0")
        assert(viewControllers.count == tabBarItems.count, "view controllers count != tabBarItems.count")
        
        self.viewControllers = viewControllers
        self.tabBarItems = tabBarItems
        self.headerView = headerView
        self.defaultHeaderHeight = headerHeight
        
        collpaseCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Content")
        collpaseCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: CollapseCollectionViewLayout.Element.header.kind, withReuseIdentifier: "Header")
        collpaseCollectionView.register(CollapseStaticHeaderView.self, forSupplementaryViewOfKind: CollapseCollectionViewLayout.Element.staticHeader.kind, withReuseIdentifier: "StaticHeader")
        collpaseCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collpaseCollectionView.revealedHeight = minimumHeaderViewHeight
        collpaseCollectionView.headerHeight = headerHeight
        collpaseCollectionView.stretchyHeight = headerViewStretchyHeight
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        collpaseCollectionView.revealedHeight = minimumHeaderViewHeight
        collpaseCollectionView.headerHeight = defaultHeaderHeight
        collpaseCollectionView.stretchyHeight = headerViewStretchyHeight
        let settings = CollapseCollectionViewLayoutSettings(headerSize: CGSize(width: view.frame.width, height: collpaseCollectionView.headerHeight),
                                                            isHeaderStretchy: true,
                                                            headerStretchHeight: collpaseCollectionView.stretchyHeight,
                                                            headerMinimumHeight: collpaseCollectionView.revealedHeight)
        let newLayout = CollapseCollectionViewLayout(settings: settings)
        newLayout.delegate = collpaseCollectionView
        collpaseCollectionView.setCollectionViewLayout(newLayout, animated: false)

        collpaseCollectionView.collapseDelegate = self
        
        view.addSubview(collpaseCollectionView)
        
        pageTabBarController.updateIndex = { _, index in
            if index == 0 {
            }
        }
        
        pageTabBarController.setPageIndex(pageIndex, animated: false)
        
        addChildViewController(pageTabBarController)
        pageTabBarController.view.frame = CGRect(x: 0, y: defaultHeaderHeight, width: view.frame.width, height: view.frame.height - defaultHeaderHeight)
        view.addSubview(pageTabBarController.view)
        pageTabBarController.didMove(toParentViewController: self)
        
        collpaseCollectionView.otherScrollViews = constructScrollViewsToIgnoreToches()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    public static func attachCollapseTabBarController(_ collapseTabBarViewController: CollapseTabBarViewController, into parentViewController: UIViewController, layoutClosure: (CollapseTabBarViewController, UIViewController) -> ()) {
        parentViewController.addChildViewController(collapseTabBarViewController)
        collapseTabBarViewController.view.frame = CGRect(x: 0, y: 0, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height)
        parentViewController.view.addSubview(collapseTabBarViewController.view)
        layoutClosure(collapseTabBarViewController, parentViewController)
        collapseTabBarViewController.didMove(toParentViewController: parentViewController)
    }
    
    // MARK: - Adjust HeaderViewHeight
    @objc open func setHeaderHeight(_ height: CGFloat) {
        defaultHeaderHeight = height
        scrollTabBar(to: .bottom, animated: false)
    }
    
    // MARK: - Select Tab
    @objc open func selectTabAtIndex(_ index: Int, scrollToPosition: CollapseTabBarPosition) {
        pageTabBarController.setPageIndex(index, animated: true)
        scrollTabBar(to: .top, animated: true)
    }
    
    // MARK: - Control Scroll
    @objc open func scrollTabBar(to position: CollapseTabBarPosition, animated: Bool = false) {
        
        switch position {
        case .top:
            collpaseCollectionView.setContentOffset(CGPoint(x: 0, y: defaultHeaderHeight - minimumHeaderViewHeight), animated: animated)
            break
        case .bottom:
            collpaseCollectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: animated)
            break
        }
    }
    
    private func constructScrollViewsToIgnoreToches() -> [UIScrollView] {
        var scrollViews = pageTabBarController.interceptTouchesScrollViews()
        if let fromDelegate = delegate?.collapseTabBarController?(self, scrollViewsForScrollingWithTabBarMoveAtIndex: pageIndex) {
            
            fromDelegate.forEach { additionalScrollView in
                if !scrollViews.contains( where: { $0 === additionalScrollView } ) {
                    scrollViews.append(additionalScrollView)
                }
            }
        }
        return scrollViews
    }
}

extension CollapseTabBarViewController: CollapseCollectionViewDelegate {
    func getCollapseTabBarViewController() -> CollapseTabBarViewController? {
        return self
    }
    
    func getPageTabBarController() -> PageTabBarController? {
        return pageTabBarController
    }
    
    func getHeaderView() -> UIView? {
        return headerView
    }
    
    func getContentViewControllers() -> [UIViewController] {
        return viewControllers
    }
}

