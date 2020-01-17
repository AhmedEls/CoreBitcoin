import Foundation

/// Helper model that plans a transaction
/// ```
/// // Initialize a planner
/// let planner = TransactionPlanner(feePerByte: 1)
///
/// // Plan a transaction with unspent transactions and target amount
/// let plan = planner.plan(unspentTransactions: unspentTransactions, amount: targetAmount)
/// ```
public struct TransactionPlanner {
    public enum DustPolicy {
        case toFee, toReceiver
    }
    public var feePerByte: UInt64
    public var dustPolicy: DustPolicy
    public init(feePerByte: UInt64, dustPolicy: DustPolicy = .toFee) {
        self.feePerByte = feePerByte
        self.dustPolicy = dustPolicy
    }

    /// Plan a transaction from available utxos and the target amount
    ///
    /// - Parameters:
    ///   - unspentTransactions: Available unspent transactions
    ///   - target: Target amount to send
    /// - Returns: A transaction plan. The amount of the plan may be different from target. Bit smaller when the funds are insufficient, bit bigger when the change is dust.
    public func plan(unspentTransactions: [UnspentTransaction], target amount: UInt64) -> TransactionPlan {
        let dustValue: UInt64 = FeeCalculator.calculateDust(feePerByte: feePerByte)
        let selected: [UnspentTransaction] = UnspentTransactionSelector
            .select(from: unspentTransactions, targetValue: amount, feePerByte: feePerByte)

        let availableAmount: UInt64 = selected.map { $0.output.value }.reduce(0, +)
        let fee: UInt64 = FeeCalculator.calculateFee(inputs: UInt64(selected.count), outputs: 2, feePerByte: feePerByte)
        let feeWithoutChange: UInt64 = FeeCalculator.calculateFee(inputs: UInt64(selected.count), outputs: 1, feePerByte: feePerByte)
        if availableAmount >= amount + fee + dustValue {
            let change: UInt64 = availableAmount - amount - fee
            return TransactionPlan(unspentTransactions: selected,
                                   amount: amount,
                                   fee: fee,
                                   change: change)
        } else if availableAmount >= amount + feeWithoutChange {
            // No change (because it will be dust)
            let newAmount: UInt64
            let newFee: UInt64
            switch dustPolicy {
            case .toFee:
                // Dust is going to fee
                newFee = availableAmount - amount
                newAmount = amount
            case .toReceiver:
                // Dust is going to receiver
                newFee = feeWithoutChange
                newAmount = availableAmount - newFee
            }
            return TransactionPlan(unspentTransactions: selected,
                                   amount: newAmount,
                                   fee: newFee,
                                   change: 0)
        } else if availableAmount >= feeWithoutChange + dustValue {
            // Insufficient funds, spend all
            return TransactionPlan(unspentTransactions: selected,
                                   amount: availableAmount - feeWithoutChange,
                                   fee: feeWithoutChange,
                                   change: 0)
        } else {
            return TransactionPlan(unspentTransactions: [],
                                   amount: 0,
                                   fee: 0,
                                   change: 0)
        }
    }
}
