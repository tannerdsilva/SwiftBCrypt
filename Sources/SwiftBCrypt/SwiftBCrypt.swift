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
		let randomFH = open("/dev/random", 0)
		defer {
			close(randomFH)
		}
		guard randomFH != -1 else {
			throw Error.unknown
		}
		var readCount:Int = 0
		repeat {
			let result = read(randomFH, UnsafeMutableRawPointer(seedBytes.baseAddress), 256)
			guard result != -1 else {
				throw Error.unknown
			}
			readCount += result
		} while readCount == 0
		guard let newSaltBuffer = crypt_gensalt_ra("$2b$", passes, seedBytes.baseAddress, Int32(readCount)) else {
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