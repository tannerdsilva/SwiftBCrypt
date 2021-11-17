import Ccrypt_blowfish
import Foundation

public struct BCrypt {
	public enum Error:Swift.Error {
		case invalidMethod
		case phraseTooLong
		case noMemory
		case notSupported
		case unknown
	}
	public static func makeSalt(passes:UInt = 12) throws -> Data {
		let seedBytes = UnsafeMutableBufferPointer<CChar>.allocate(capacity:256)
		defer {
			seedBytes.deallocate()
		}
		for i in 0..<256 {
			seedBytes[i] = CChar.random(in:CChar.min...CChar.max)
		}
		guard let newSaltBuffer = crypt_gensalt_ra("$2b$", passes, seedBytes.baseAddress, 256) else {
			switch errno {
				case EINVAL:
					throw Error.invalidMethod
				case ERANGE:
					throw Error.phraseTooLong
				case ENOMEM:
					throw Error.noMemory
				case ENOSYS:
					throw Error.notSupported
				case EOPNOTSUPP:
					throw Error.notSupported
				default:
					throw Error.unknown
			}
		}
		defer {
			newSaltBuffer.deallocate()
		}
		return Data(bytes:newSaltBuffer, count:strlen(newSaltBuffer))
	}
	public static func hash(phrase:String, salt:Data) throws -> Data {
		var count:Int32 = 0
		var dataBuff = UnsafeMutableRawPointer(mutating:nil)
		return try salt.withUnsafeBytes { saltRaw in
			guard let newHashBuffer = crypt_ra(phrase, saltRaw.bindMemory(to:CChar.self).baseAddress, &dataBuff, &count) else {
				switch errno {
					case EINVAL:
						throw Error.invalidMethod
					case ERANGE:
						throw Error.phraseTooLong
					case ENOMEM:
						throw Error.noMemory
					case ENOSYS:
						throw Error.notSupported
					case EOPNOTSUPP:
						throw Error.notSupported
					default:
						throw Error.unknown
				}
			}
			defer {
				newHashBuffer.deallocate()
			}
			let newData = Data(bytes:newHashBuffer, count:Int(count))
			return newData
		}
	}
}