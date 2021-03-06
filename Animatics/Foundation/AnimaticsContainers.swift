//
//  AnimationReady.swift
//  PokeScrum
//
//  Created by Nikita Arkhipov on 20.09.15.
//  Copyright © 2015 Anvics. All rights reserved.
//

import Foundation

final class SimultaneousAnimations: AnimaticsReady, AnimaticsSettingsSettersWrapper{
   private let firstAnimator: AnimaticsReady
   private let secondAnimator: AnimaticsReady
   
   init(firstAnimator: AnimaticsReady, secondAnimator: AnimaticsReady){
      self.firstAnimator = firstAnimator
      self.secondAnimator = secondAnimator
   }
   
   func animateWithCompletion(completion: AnimaticsCompletionBlock?) {
      var animationsLeft = 2
      for animator in [firstAnimator, secondAnimator]{
         animator.animateWithCompletion { _ in
            animationsLeft--
            if animationsLeft == 0 { completion?(true) }
         }
      }
   }
   
   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [firstAnimator, secondAnimator] }
}

final class SequentialAnimations: AnimaticsReady, AnimaticsSettingsSettersWrapper{
   private let firstAnimator: AnimaticsReady
   private let secondAnimator: AnimaticsReady
   
   init(firstAnimator: AnimaticsReady, secondAnimator: AnimaticsReady){
      self.firstAnimator = firstAnimator
      self.secondAnimator = secondAnimator
   }
   
   func animateWithCompletion(completion: AnimaticsCompletionBlock?) {
      firstAnimator.animateWithCompletion { _ in
         self.secondAnimator.animateWithCompletion(completion)
      }
   }
   
   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [firstAnimator, secondAnimator] }
}

final class SimultaneousAnimationsTargetWaiter<T: AnimaticsTargetWaiter, U: AnimaticsTargetWaiter where T.TargetType == U.TargetType>: AnimaticsTargetWaiter, AnimaticsSettingsSettersWrapper{
   typealias TargetType = T.TargetType

   private let firstAnimator: T
   private let secondAnimator: U
   
   init(firstAnimator: T, secondAnimator: U){
      self.firstAnimator = firstAnimator
      self.secondAnimator = secondAnimator
   }

   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [firstAnimator, secondAnimator] }
   
   func to(t: TargetType) -> AnimaticsReady{
      return SimultaneousAnimations(firstAnimator: firstAnimator.to(t), secondAnimator: secondAnimator.to(t))
   }
}

final class SequentialAnimationsTargetWaiter<T: AnimaticsTargetWaiter, U: AnimaticsTargetWaiter where T.TargetType == U.TargetType>: AnimaticsTargetWaiter, AnimaticsSettingsSettersWrapper{
   typealias TargetType = T.TargetType
   
   private let firstAnimator: T
   private let secondAnimator: U
   
   init(firstAnimator: T, secondAnimator: U){
      self.firstAnimator = firstAnimator
      self.secondAnimator = secondAnimator //никитос красавчик
   }
   
   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [firstAnimator, secondAnimator] }
   
   func to(t: TargetType) -> AnimaticsReady{
      return SequentialAnimations(firstAnimator: firstAnimator.to(t), secondAnimator: secondAnimator.to(t))
   }
}

final class RepeatAnimator: AnimaticsReady, AnimaticsSettingsSettersWrapper{
   let animator: AnimaticsReady
   let repeatCount: Int
   
   init(animator: AnimaticsReady, repeatCount: Int){
      self.animator = animator
      self.repeatCount = repeatCount
   }
   
   func animateWithCompletion(completion: AnimaticsCompletionBlock?) {
      animateWithCompletion(completion, repeatsLeft: repeatCount)
   }
   
   private func animateWithCompletion(completion: AnimaticsCompletionBlock?, repeatsLeft: Int){
      if repeatsLeft == 0 {
         completion?(true)
         return
      }
      animator.animateWithCompletion { (_)  in
         self.animateWithCompletion(completion, repeatsLeft: repeatsLeft - 1)
      }
   }

   
   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [animator] }
}

final class EndlessAnimator: AnimaticsReady, AnimaticsSettingsSettersWrapper{
   let animator: AnimaticsReady
   
   init(_ animator: AnimaticsReady){
      self.animator = animator
   }
   
   func animateWithCompletion(completion: AnimaticsCompletionBlock?) {
      animator.animateWithCompletion { [weak self] _ in self?.animateWithCompletion(completion) }
   }
   
   func getSettingsSetters() -> [AnimaticsSettingsSetter] { return [animator] }
}

extension AnimaticsReady{
   func endless() -> EndlessAnimator { return EndlessAnimator(self) }
}

func +(left: AnimaticsReady, right: AnimaticsReady) -> AnimaticsReady{
   return SimultaneousAnimations(firstAnimator: left, secondAnimator: right)
}

func |->(left: AnimaticsReady, right: AnimaticsReady) -> AnimaticsReady{
   return SequentialAnimations(firstAnimator: left, secondAnimator: right)
}

func +<T: AnimaticsTargetWaiter, U: AnimaticsTargetWaiter where T.TargetType == U.TargetType>(left: T, right: U) -> SimultaneousAnimationsTargetWaiter<T, U>{
   return SimultaneousAnimationsTargetWaiter(firstAnimator: left, secondAnimator: right)
}

func |-><T: AnimaticsTargetWaiter, U: AnimaticsTargetWaiter where T.TargetType == U.TargetType>(left: T, right: U) -> SequentialAnimationsTargetWaiter<T, U>{
   return SequentialAnimationsTargetWaiter(firstAnimator: left, secondAnimator: right)
}


