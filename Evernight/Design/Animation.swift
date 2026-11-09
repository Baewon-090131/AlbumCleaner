import SwiftUI

/// 不带任何动画地改状态。动效复位必须这样走——
/// 否则状态会在复位的那一帧重新播一遍过渡。
///
/// `Transaction(disablesAnimations:)` 这个初始化器**不存在**，
/// 只能先建 `Transaction` 再改属性，然后 `withTransaction`。
func withoutAnimation(_ work: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, work)
}
