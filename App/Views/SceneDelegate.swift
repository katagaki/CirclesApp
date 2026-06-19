//
//  SceneDelegate.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/06/20.
//

import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        DispatchQueue.main.async {
            windowScene.keyWindow?.tintColor = UIColor(named: "AccentColor")
        }
    }
}
