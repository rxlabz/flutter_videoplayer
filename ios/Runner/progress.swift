//
// Created by rx on 19/03/2017.
// Copyright (c) 2017 The Chromium Authors. All rights reserved.
//

import Foundation


class ProgressWatcher{

  var currentValue:Double = 0.0
  var total:Double = 0.0

  init(total:Double){
    self.total = total
  }

  func unwatch(){

  }

  var progress:Progress{
    get{
      return Progress(currentValue: currentValue, total: total)
    }
  }
}

struct Progress{
  var currentValue:Double = 0.0
  var total:Double = 0.0
}