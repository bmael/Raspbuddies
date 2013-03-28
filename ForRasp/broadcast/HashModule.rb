require 'digest/md5'

module HashFunctions

	@@a1 = [18, 39, 3, 37, 12, 29, 7, 30, 23, 2, 5, 39, 24, 12, 26, 12, 27, 0, 25, 24, 9, 12, 9, 18, 32, 27, 38, 30, 18, 27, 12, 25]
	@@a2 = [6, 9, 38, 16, 21, 26, 3, 7, 13, 5, 30, 22, 15, 19, 31, 30, 32, 9, 9, 0, 18, 10, 7, 1, 16, 6, 12, 6, 22, 3, 5, 29]

	def h1(k)
		result = 0
		n = 0
		k.each_byte do |b|
			result = result + @@a1[n] * b
			n = n + 1
		end
		return result.modulo(41)
	end

	def h2(k)
		result = 0
		n = 0
		k.each_byte do |b|
			result = result + @@a2[n] * b
			n = n + 1
		end
		return result.modulo(41)
	end

	def hashKey(k)
		md5 = Digest::MD5.hexdigest(k)
		return [h1(md5), h2(md5)]
	end

end
