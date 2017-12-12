//
//  ParallaxHeaderPageTabBarController.swift
//  PageTabBarController
//
//  Created by Mingloan Chan on 12/11/17.
//  Copyright © 2017 com.mingloan. All rights reserved.
//

import Foundation
import UIKit

@objc
public protocol ParallaxHeaderPageTabBarControllerDelegate: NSObjectProtocol {
    @objc optional func parallaxHeaderPageTabBarController(_ controller: ParallaxHeaderPageTabBarController, revealPercentage: CGFloat)
}

@objcMembers
open class ParallaxHeaderPageTabBarController: UIViewController {
    
    open weak var delegate: ParallaxHeaderPageTabBarControllerDelegate?
    
    open let pageTabBarController: PageTabBarController
    open let parallaxHeaderContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    let supplementaryContainerView: SupplementaryView = {
        let view = SupplementaryView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    
    open var isStretchy = true {
        didSet {
            if isStretchy {
                pageTabBarController.setTabBarTopPosition(.topInsetAttached)
            } else {
                pageTabBarController.setTabBarTopPosition(.topAttached)
            }
        }
    }
    open var parallaxOffset = CGFloat(1)
    open var minimumRevealHeight = CGFloat(0)
    open var parallaxHeaderHeight = CGFloat(200)
    open var supplementaryViewHeight = CGFloat(60) {
        didSet {
            supplementaryViewHeightConstraint?.constant = supplementaryViewHeight
            view.setNeedsLayout()
        }
    }
    
    private var parallaxHeaderViewTopConstraint: NSLayoutConstraint?
    private var parallaxHeaderViewHeightConstraint: NSLayoutConstraint?
    private var supplementaryViewBottomConstraint: NSLayoutConstraint?
    private var supplementaryViewHeightConstraint: NSLayoutConstraint?
    private var pageTabBarTopConstraint: NSLayoutConstraint?
    
    private var isPanning = false
    private var initialSpacing = CGFloat(0)
    
    public required init(viewControllers: [UIViewController],
                         items: [PageTabBarItem],
                         parallaxHeaderHeight: CGFloat) {
        
        pageTabBarController = PageTabBarController(viewControllers: viewControllers, items: items, tabBarPosition: .topInsetAttached)
        super.init(nibName: nil, bundle: nil)
        
        self.parallaxHeaderHeight = parallaxHeaderHeight
        pageTabBarController.parallaxDelegate = self
        addChildViewController(pageTabBarController)
        pageTabBarController.didMove(toParentViewController: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(pageTabBarController.view)
        view.addSubview(parallaxHeaderContainerView)
        view.addSubview(supplementaryContainerView)

        parallaxHeaderContainerView.translatesAutoresizingMaskIntoConstraints = false
        pageTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        supplementaryContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // var topAnchor = view.topAnchor
        // var bottomAnchor = view.bottomAnchor
        var leadingAnchor = view.leadingAnchor
        var trailingAnchor = view.trailingAnchor
        if #available(iOS 11.0, *) {
            //topAnchor = view.safeAreaLayoutGuide.topAnchor
            //bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
            leadingAnchor = view.safeAreaLayoutGuide.leadingAnchor
            trailingAnchor = view.safeAreaLayoutGuide.trailingAnchor
        }
        
        NSLayoutConstraint.activate([parallaxHeaderContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     parallaxHeaderContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
        
        parallaxHeaderViewTopConstraint = parallaxHeaderContainerView.topAnchor.constraint(equalTo: view.topAnchor)
        parallaxHeaderViewTopConstraint?.isActive = true
        parallaxHeaderViewHeightConstraint = parallaxHeaderContainerView.heightAnchor.constraint(equalToConstant: parallaxHeaderHeight)
        parallaxHeaderViewHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([supplementaryContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     supplementaryContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
        
        supplementaryViewBottomConstraint = supplementaryContainerView.bottomAnchor.constraint(equalTo: parallaxHeaderContainerView.bottomAnchor)
        supplementaryViewBottomConstraint?.isActive = true
        supplementaryViewHeightConstraint = supplementaryContainerView.heightAnchor.constraint(equalToConstant: supplementaryViewHeight)
        supplementaryViewHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([pageTabBarController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     pageTabBarController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     pageTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        pageTabBarTopConstraint = pageTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: parallaxHeaderHeight)
        pageTabBarTopConstraint?.isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
    }
    
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state{
        case .began:
            let velocity = gesture.velocity(in: gesture.view)
            guard abs(velocity.y) > abs(velocity.x) else { return }
            guard let spacing = pageTabBarTopConstraint?.constant else { return }
            isPanning = true
            initialSpacing = spacing
            break
        case .changed:
            guard isPanning else { return }
            let translate = gesture.translation(in: gesture.view)
            let newConstant = min(parallaxHeaderHeight, max(minimumRevealHeight, initialSpacing + translate.y))
//            let newConstant = max(minimumRevealHeight, initialSpacing + translate.y)
//            if newConstant > parallaxHeaderHeight {
//                let gap = newConstant - parallaxHeaderHeight
//                let scale = 1 + (gap * 2)/parallaxHeaderHeight
//                parallaxHeaderContainerView.transform = CGAffineTransform(scaleX: scale, y: scale)
//                supplementaryViewBottomConstraint?.constant = gap
//            } else {
                parallaxHeaderContainerView.transform = .identity
                pageTabBarTopConstraint?.constant = newConstant
                parallaxHeaderViewTopConstraint?.constant = newConstant - parallaxHeaderHeight
            //}
            view.layoutIfNeeded()
            break
        case .ended, .cancelled:
            guard isPanning else { return }
            isPanning = false
            break
        default:
            isPanning = false
            break
        }
    }
}

// MARK: - Public Methods

extension ParallaxHeaderPageTabBarController {
    
    open func scrollTabBar(to top: Bool, animated: Bool = false) {
        
        if top {
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.parallaxHeaderViewTopConstraint?.constant = 0
                    self.pageTabBarTopConstraint?.constant = self.parallaxHeaderHeight
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else {
                parallaxHeaderViewTopConstraint?.constant = 0
                pageTabBarTopConstraint?.constant = self.parallaxHeaderHeight
                view.layoutIfNeeded()
            }
        }
        else {
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.parallaxHeaderViewTopConstraint?.constant = self.minimumRevealHeight - self.parallaxHeaderHeight
                    self.pageTabBarTopConstraint?.constant = self.minimumRevealHeight
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else {
                parallaxHeaderViewTopConstraint?.constant = self.minimumRevealHeight - self.parallaxHeaderHeight
                pageTabBarTopConstraint?.constant = self.minimumRevealHeight
                view.layoutIfNeeded()
            }
        }
    }
    
    open func setSelfSizingParallexHeaderView(_ view: UIView?) {
        
        parallaxHeaderContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        guard let customView = view else {
            // setParallexHeaderHeight(height, animated: false)
            return
        }
        
        parallaxHeaderContainerView.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([customView.leadingAnchor.constraint(equalTo: parallaxHeaderContainerView.leadingAnchor),
                                     customView.trailingAnchor.constraint(equalTo: parallaxHeaderContainerView.trailingAnchor),
                                     customView.topAnchor.constraint(equalTo: parallaxHeaderContainerView.topAnchor),
                                     customView.bottomAnchor.constraint(equalTo: parallaxHeaderContainerView.bottomAnchor)])
        let size = parallaxHeaderContainerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        setParallexHeaderHeight(size.height, animated: false)
    }
    
    open func setParallexHeaderView(_ view: UIView?, height: CGFloat) {
        
        parallaxHeaderContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        guard let customView = view else {
            setParallexHeaderHeight(height, animated: false)
            return
        }
        
        parallaxHeaderContainerView.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([customView.leadingAnchor.constraint(equalTo: parallaxHeaderContainerView.leadingAnchor),
                                     customView.trailingAnchor.constraint(equalTo: parallaxHeaderContainerView.trailingAnchor),
                                     customView.topAnchor.constraint(equalTo: parallaxHeaderContainerView.topAnchor)])
        
        setParallexHeaderHeight(height, animated: false)
    }
    
    open func setSupplementaryView(_ view: UIView?) {
        supplementaryContainerView.configureWithContentView(view)
    }
    
    /* @param height - new height
     * @param animated - run default animation
     */
    open func setParallexHeaderHeight(_ newHeight: CGFloat, animated: Bool) {
        
        guard parallaxHeaderHeight != newHeight else { return }
        parallaxHeaderHeight = newHeight
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.parallaxHeaderViewTopConstraint?.constant = 0
                self.pageTabBarTopConstraint?.constant = newHeight
                self.parallaxHeaderViewHeightConstraint?.constant = newHeight
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            parallaxHeaderViewTopConstraint?.constant = 0
            pageTabBarTopConstraint?.constant = newHeight
            parallaxHeaderViewHeightConstraint?.constant = newHeight
            view.layoutIfNeeded()
        }
    }
}

extension ParallaxHeaderPageTabBarController: PageTabBarControllerParallaxDelegate {
    func pageTabBarController(_ controller: PageTabBarController,
                              selectedViewController: UIViewController,
                              observedScrollView: UIScrollView,
                              contentOffsetObservingWithOldValue oldValue: CGPoint,
                              newValue: CGPoint) -> Bool {
        
        guard let currentSpacing = pageTabBarTopConstraint?.constant else {
            return true
        }
        
        // diff < 0 => scroll up, diff > 0 => scroll down
        let diff = oldValue.y - newValue.y
    
        guard diff != 0 else { return true }
        
        var contentInset = observedScrollView.contentInset
        if #available(iOS 11.0, *) {
            contentInset = observedScrollView.adjustedContentInset
        }
        
        if case .topAttached = controller.tabBarPosition {
            parallaxHeaderContainerView.transform = .identity
            supplementaryViewBottomConstraint?.constant = 0
            view.setNeedsLayout()
        } else {
            if observedScrollView.contentOffset.y < -contentInset.top {
                let gap = -contentInset.top - observedScrollView.contentOffset.y
                let scale = 1 + (gap * 2)/parallaxHeaderHeight
                parallaxHeaderContainerView.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                supplementaryViewBottomConstraint?.constant = gap
            } else {
                parallaxHeaderContainerView.transform = .identity
                supplementaryViewBottomConstraint?.constant = 0
                view.setNeedsLayout()
            }
        }
        
        print("contentInset \(contentInset.top)")
        print("newValue.y \(newValue.y)")
        print("diff \(diff)")
        if diff < 0 {
            // collpasing
            let shouldCollapse = pageTabBarController.view.frame.minY > minimumRevealHeight && newValue.y > -contentInset.top

            if shouldCollapse {
                let newConstant = min(parallaxHeaderHeight, max(minimumRevealHeight, currentSpacing + diff))
                pageTabBarTopConstraint?.constant = newConstant
                parallaxHeaderViewTopConstraint?.constant = newConstant - parallaxHeaderHeight
                view.layoutIfNeeded()
            }
            
            return !shouldCollapse
            
        } else {
            // expanding
            let shouldExpand = pageTabBarController.view.frame.minY < parallaxHeaderHeight && newValue.y < -contentInset.top
            
            if shouldExpand {
                let newConstant = min(parallaxHeaderHeight, max(minimumRevealHeight, currentSpacing + diff))
                pageTabBarTopConstraint?.constant = newConstant
                parallaxHeaderViewTopConstraint?.constant = newConstant - parallaxHeaderHeight
                view.layoutIfNeeded()
            }
            
            return !shouldExpand
        }
        
        //return true
    }
}

extension ParallaxHeaderPageTabBarController: UIGestureRecognizerDelegate {
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: gestureRecognizer.view)
            let translation = panGestureRecognizer.translation(in: gestureRecognizer.view)
            return abs(velocity.y) > abs(velocity.x) && abs(translation.y) > abs(translation.x)
        }
        return true
    }
    
}
