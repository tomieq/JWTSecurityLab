import Foundation


/// No Algorithm, i-e, insecure
public final class NoneAlgorithm: AlgorithmJWA, SignAlgorithm, VerifyAlgorithm {
   public var name: String {
    return "none"
  }

  public init() {}

  public func sign(_ message: Data) -> Data {
    return Data()
  }
}
