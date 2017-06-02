//
//  ViewController.swift
//  ios-stacked-menu-demo
//
//  Created by Kushida　Eiji on 2017/05/18.
//  Copyright © 2017年 Kushida　Eiji. All rights reserved.
//

import UIKit

extension Selector {
    static let handlePan = #selector(ViewController.handlePan(gestureRecognizer:))
}

class ViewController: UIViewController {

    let titles = ["Getting started with Swift", "SiriKit Basics", "SpriteKit for Apple Watch"]

    var views = [UIView]()
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    var snap: UISnapBehavior!
    var previousTouchPoint: CGPoint!
    var viewDragging = false
    var viewPinned = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //アニメーションの土台
        animator = UIDynamicAnimator(referenceView: self.view)

        //重力をつける
        gravity = UIGravityBehavior()

        //アニメーターに振る舞いを登録する
        animator.addBehavior(gravity)

        //重力の加減を指定する
        gravity.magnitude = 4

        //メニューを表示する位置
        var offset: CGFloat = 250

        //メニューを50ptごとに設定する
        for i in 0 ... titles.count - 1 {
            if let view = addViewController(atOffset: offset,
                                            dataForVC: titles[i] as AnyObject?) {
                views.append(view)
                offset -= 50
            }
        }
    }

    /// ViewControllerを追加する
    func addViewController (atOffset offset: CGFloat,
                            dataForVC data: AnyObject?) -> UIView? {

        let frameForView = self.view.bounds.offsetBy(dx: 0,
                                                     dy: self.view.bounds.size.height - offset)

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let stackElementVC = sb.instantiateViewController(withIdentifier: "StackElementViewController") as! StackElementViewController

        if let view = stackElementVC.view {
            view.frame = frameForView
            view.layer.cornerRadius = 5

            //影をつける
            view.layer.shadowOpacity = 0.5

            //影の位置を決める
            view.layer.shadowOffset = CGSize(width: 2, height: 2)

            //影の色
            view.layer.shadowColor = UIColor.black.cgColor

            //影のぼかし
            view.layer.shadowRadius = 3

            //タイトルを設定する
            if let headerStr = data as? String {
                stackElementVC.headerString = headerStr
            }

            //自前のコンテナにchildViewControllerを追加する
            self.addChildViewController(stackElementVC)
            self.view.addSubview(view)
            stackElementVC.didMove(toParentViewController: self)

            //panジェスチャーを追加する
            let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                              action: .handlePan)
            view.addGestureRecognizer(panGestureRecognizer)

            //バウンドを指定する
            let collision = UICollisionBehavior(items: [view])
            collision.collisionDelegate = self
            animator.addBehavior(collision)

            let boundary = view.frame.origin.y + view.frame.size.height

            // 下限
            var boundaryStart = CGPoint(x: 0, y: boundary)
            var boundaryEnd = CGPoint(x: self.view.bounds.size.width, y: boundary)
            collision.addBoundary(withIdentifier: 1 as NSCopying, from: boundaryStart, to: boundaryEnd)

            // 上限
            boundaryStart = CGPoint(x: 0, y: 0)
            boundaryEnd = CGPoint(x: self.view.bounds.size.width, y: 0)
            collision.addBoundary(withIdentifier: 2 as NSCopying, from: boundaryStart, to: boundaryEnd)

            gravity.addItem(view)

            let itemBehavior = UIDynamicItemBehavior(items: [view])
            animator.addBehavior(itemBehavior)

            return view
        }
        return nil
    }

    /// Panジェスチャー
    func handlePan (gestureRecognizer: UIPanGestureRecognizer) {

        //タッチした場所
        let touchPoint = gestureRecognizer.location(in: self.view)

        //ドラッグ対象のView
        let draggedView = gestureRecognizer.view!

        //タッチ開始
        if gestureRecognizer.state == .began {
            let dragStartPoint = gestureRecognizer.location(in: draggedView)

            //上に200pt以上移動したとき
            if dragStartPoint.y < 200 {
                viewDragging = true
                previousTouchPoint = touchPoint
            }

        } else if gestureRecognizer.state == .changed && viewDragging {
            let yOffset = previousTouchPoint.y - touchPoint.y

            //ドラッグ対象の位置を変更
            draggedView.center = CGPoint(x: draggedView.center.x,
                                         y: draggedView.center.y - yOffset)
            previousTouchPoint = touchPoint

        }else if gestureRecognizer.state == .ended && viewDragging {

            pin(view: draggedView)
            addVelocity(toView: draggedView,
                        fromGestureRecognizer: gestureRecognizer)

            animator.updateItem(usingCurrentState: draggedView)
            viewDragging = false
        }
    }

    /// メニューの表示切り替え
    func pin(view: UIView) {

        // メニュー表示位置まで到達したか？
        let viewHasReachedPinLocation = view.frame.origin.y < 100

        if viewHasReachedPinLocation {
            if !viewPinned {
                var snapPosition = self.view.center
                snapPosition.y += 30

                //特定の場所にスナップさせる(吸い付くイメージ）
                snap = UISnapBehavior(item: view, snapTo: snapPosition)
                animator.addBehavior(snap)

                //該当のビュー以外は非表示にする
                setVisibility(view: view, alpha: 0)

                viewPinned = true
            }
        }else{
            if viewPinned {

                //スナップを削除する
                animator.removeBehavior(snap)

                //すべてのビューを表示する
                setVisibility(view: view, alpha: 1)
                viewPinned = false
            }
        }
    }

    //ビューの表示切り替え
    func setVisibility (view: UIView, alpha: CGFloat) {

        for aView in views {
            if aView != view {
                aView.alpha = alpha
            }
        }
    }

    //速度を追加する
    func addVelocity (toView view: UIView,
                      fromGestureRecognizer panGesture: UIPanGestureRecognizer) {

        var velocity = panGesture.velocity(in: self.view)
        velocity.x = 0

        if let behavior = itemBehavior(forView: view) {
            behavior.addLinearVelocity(velocity, for: view)
        }
    }

    func itemBehavior (forView view:UIView) -> UIDynamicItemBehavior? {
        
        for behavior in animator.behaviors {
            if let itemBehavior = behavior as? UIDynamicItemBehavior {
                if let possibleView = itemBehavior.items.first as? UIView , possibleView == view {
                    return itemBehavior
                }
            }
        }

        return nil
    }
}

/// MARK - UICollisionBehaviorDelegate
extension ViewController: UICollisionBehaviorDelegate {

    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at p: CGPoint) {

        if NSNumber(integerLiteral: 2).isEqual(identifier) {
            let view = item as! UIView
            pin(view: view)
        }
    }
}



