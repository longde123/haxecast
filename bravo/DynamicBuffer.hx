/**
 * ...
 * @author JB
 */
package bravo;

import haxe.io.Bytes;

class DynamicBuffer 
{
	var startSize : Int;
	public var size(default, null) : Int;
	var maxSize : Int;
	public var pos(default, null) : Int;
	public var bytes(default, null) : Int;
	public var buff(default, null) : Bytes;
	public var compactPoint(default, null) : Int;
	
	public function new(inStartSize : Int, ?inMaxSize : Int = -1) {
		startSize = inStartSize;
		if (inMaxSize < 0) 
		{
			inMaxSize = inStartSize << 2;
		}
		if (inMaxSize < inStartSize) 
		{
			inMaxSize = inStartSize;
		}
		compactPoint = inStartSize << 2;
		if (compactPoint > inMaxSize)
		{
			compactPoint = (inStartSize + inMaxSize) >> 1;
		}
		maxSize = inMaxSize;
		buff = Bytes.alloc(size = inStartSize);
		bytes = 0;
		pos = 0;
	}
	
	public function add(data : Bytes, ?docompact : Bool = false) : Void 
	{
		var len = data.length;
		if (size != buff.length)
		{
			throw "ERROR: size != buff.length";
		}
		var space = size - bytes;
		if (space < len)
		{
			var newSize = size + ((len - space) << 1);
			if (newSize > maxSize) 
			{
				newSize = maxSize;
				if (newSize - bytes < len)
				{
					throw 'DynamicBuffer: Max buffer size reached';
				}
			}
			var newBuf : Bytes = Bytes.alloc(newSize);
			newBuf.blit(0, buff, 0, bytes);
			buff = newBuf;
			size = newSize;
		}
		buff.blit(bytes, data, 0, len);
		bytes += len;
		if (docompact)
		{
			if (size > compactPoint && bytes < compactPoint)
			{
				var newSize = compactPoint;
				var newBuf = buff.sub(0, compactPoint);
				buff = newBuf;
				size = newSize;
			}
		}
	}

	public function used(cnt : Int) : Int {
		if (cnt > bytes || cnt < 0)
			return -1;
		if (cnt == 0 || bytes == 0)
			return 0;
		buff.blit(0, buff, cnt, bytes - cnt);
		bytes -= cnt;
		return cnt;
	}
}
