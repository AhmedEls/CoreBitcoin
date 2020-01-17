import Foundation

public struct GetBlocksMessage {
    /// the protocol version
    public let version: UInt32
    /// number of block locator hash entries
    public let hashCount: VarInt
    /// block locator object; newest back to genesis block (dense to start, but then sparse)
    public let blockLocatorHashes: Data
    /// hash of the last desired block; set to zero to get as many blocks as possible (500)
    public let hashStop: Data

    public func serialized() -> Data {
        var data = Data()
        data += version
        data += hashCount.serialized()
        data += blockLocatorHashes
        data += hashStop
        return data
    }
}
