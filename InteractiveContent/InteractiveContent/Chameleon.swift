//
//  Chameleon.swift
//  InteractiveContent
//
//  Created by mac126 on 2018/3/27.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit

class Chameleon: SCNScene {

    // 特殊节点控制模型动画
    /// 根节点
    private let contentRootNode = SCNNode()
    private var geometryRoot: SCNNode!
    private var head: SCNNode!
    private var leftEye: SCNNode!
    private var rightEye: SCNNode!
    /// 下巴
    private var jaw: SCNNode!
    /// 舌尖
    private var tongueTip: SCNNode!
    private var focusOfTheHead: SCNNode!
    private var focusOfLeftEye: SCNNode!
    private var focusOfRightEye: SCNNode!
    /// 舌头休息
    private var tongueRestPositionNode: SCNNode!
    /// 皮肤
    private var skin: SCNMaterial!
    
    // Animations
    private var idleAnimation: SCNAnimation?
    private var turnLeftAnimation: SCNAnimation?
    private var turnRightAnimation: SCNAnimation?
    
    // 状态变量
    private var modelLoaded: Bool = false
    private var headIsMoving: Bool = false
    private var chameleonIsTurning: Bool = false
    
    /// ??
    private var focusNodeBasePosition = simd_float3(0, 0.1, 0.25)
    private var leftEyeTargetOffset = simd_float3()
    private var rightEyeTargetOffset = simd_float3()
    private var currentTonguePosition = simd_float3()
    /// 相应吐舌头因子
    private var relativeTongueStickOutFactor: Float = 0
    /// 准备吐舌头计数器
    private var readyToShootCounter: Int = 0
    /// 触发左转计数器
    private var triggerTurnLeftCounter: Int = 0
    /// 触发右转计数器
    private var triggerTurnRightCounter: Int = 0
    /// 最后的相对位置
    private var lastRelativePosition: RelativeCameraPositionToHead = .tooHighOrLow
    private var distance: Float = Float.greatestFiniteMagnitude
    private var didEnterTargetLockDistance = false
    /// 嘴部动画状态
    private var mounthAnimationState: MouthAnimationState = .mouthClosed
    
    /// 更改颜色计时器
    private var changeColorTimer: Timer?
    private var lastColorFromEnvironment = SCNVector3(130.0 / 255.0, 196.0 / 255.0, 174.0 / 255.0)
    
    // Enums
    /// 相机位置相对头部的状态
    private enum RelativeCameraPositionToHead {
        case withinFieldOfView(Distance)
        case needToTurnLeft
        case needToTurnRight
        case tooHighOrLow
        
        var rawValue: Int {
            switch self {
            case .withinFieldOfView(_): return 0
            case .needToTurnLeft: return 1
            case .needToTurnRight: return 2
            case .tooHighOrLow : return 3
            }
        }
    }
    
    /// 距离
    private enum Distance {
        case outsideTargetLockDistance  // 超出目标锁定距离
        case withinTargetLockDistance   // 进入目标锁定距离
        case withinShootTongueDistance  // 进入发射舌头距离
    }
    
    /// 嘴部动画状态
    private enum MouthAnimationState {
        case mouthClosed
        case mouthMoving
        case shootingTongue     // 发射舌头
        case pullingBackTongue  // 收回舌头
    }
    
    // MARK: - Initialization and Loading
    
    override init() {
        super.init()
        
        // 加载环境地图
        self.lightingEnvironment.contents = UIImage(named: "art.scnassets/environment_blur.exr")!
        
        // 加载变色龙
        loadModel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 加载模型
    private func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else { return  }
        
        // 包装节点
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        self.rootNode.addChildNode(contentRootNode)
        contentRootNode.addChildNode(wrapperNode)
        // 隐藏
        hide()
        
        // 设置节点
        setupSpecialNodes()
        
    }
    
    // MARK: - public api
    func hide() {
        contentRootNode.isHidden = true
        // 重置状态
        resetState()
    }
    
    func show() {
        contentRootNode.isHidden = false
    }
    
    // MARK: - 转向和初始动画
    
}

// MARK: - Helper functions

extension Chameleon {
    
    
    /// 设置节点
    private func setupSpecialNodes() {
        geometryRoot = self.rootNode.childNode(withName: "Chameleon", recursively: true)
        head = self.rootNode.childNode(withName: "Neck02", recursively: true)
        leftEye = self.rootNode.childNode(withName: "Eye_L", recursively: true)
        rightEye = self.rootNode.childNode(withName: "Eye_R", recursively: true)
        jaw = self.rootNode.childNode(withName: "Jaw", recursively: true)
        tongueTip = self.rootNode.childNode(withName: "TongueTip_Target", recursively: true)
        
        skin = geometryRoot.geometry?.materials.first
        
        
        
    }
    
    /// 重置状态
    private func resetState() {
        relativeTongueStickOutFactor = 0
        
        mounthAnimationState = .mouthClosed
        
        readyToShootCounter = 0
        triggerTurnLeftCounter = 0
        triggerTurnRightCounter = 0
        
        // 清空计时器
        if changeColorTimer != nil {
            changeColorTimer?.invalidate()
            changeColorTimer = nil
        }
        
    }
}

