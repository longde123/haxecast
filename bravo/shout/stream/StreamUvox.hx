/**
 * ...
 * @author JB
 */

package bravo.shout.stream;

import haxe.io.Bytes;
import bravo.shout.stream.StreamEvent;
import haxe.io.BytesInput;

private enum UvoxState {
	UVOXdetect;
	UVOXframe;															// 0x5A 0xFF 0xtttt 0xllll payload 0x00
	UVOXnsv(c : Int, l : Int, t : Int);									//0x7777
	UVOXaac(c : Int, l : Int, t : Int);									//0x8003
	UVOXeat(c : Int, l : Int, cls : Int, typ : Int);					//0x????
	UVOXprocess;
}

class StreamUvox extends StreamBase, implements IStream
{
	var maxblocklength : Int;
	public function new(maxBlockLength : Int) 
	{
		streamName = 'UVOX';
		maxblocklength = maxBlockLength;
		if (maxblocklength == 0)
		{
			maxblocklength = 16384 - 7;
		}
		super();
	}
	
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		var retData : Bytes;
		var bytesUsed = 0;
		if (len < 7) // minimum packet length
		{
			return null;
		}
		if (buff.get(pos) != 0x5A)
		{
			bytesUsed = 1;
		}
		else
		{
			// 0xSS : 0%RRRRRRRE : 0xCTTT : ... : 0xZZ
			// S = 0x5A
			// R = 0%0
			// E = 0%1 for Encryption
			// C = Class
			// T = Type
			// Z = 0x00
			var datalen = buff.get(pos + 4) * 256 + buff.get(pos + 5);
			if (datalen <= maxblocklength) // absolute maximum frame length = 16384 - 6 (hdr) - 1 (trailing NULL)
			{
				var packlen = datalen + 7;
				if (len < packlen)
				{
					return null; // need more input
				}
				// now have a FULL packet
				if (buff.get(pos + packlen - 1) == 0)
				{
					var screader = new BytesInput(buff, pos, packlen);
					var b = screader.read(6);
					var c = b.get(1);
					var t = b.get(2) * 256 + b.get(3);
					var cls = t >> 12;
					var typ = t & 0x0FFF;
					if(streamdata.isListenedTo)
					{
						streamdata.dispatch(new StreamEvent(StrData, t, screader.read(datalen)));
					}
					bytesUsed = packlen;
				}
			}
			else
			{
				bytesUsed = 1;
				for (i in 1...datalen)
				{
					if (buff.get(pos + i) == 0x5A)
					{
						bytesUsed = i;
						break;
					}
				}
				var t = (buff.get(pos + 2) << 8) + buff.get(pos + 3);
				if(streamdata.isListenedTo)
				{
					streamdata.dispatch(new StreamEvent(StrError, t, Bytes.ofString("datablock " + datalen + " > " + maxblocklength + ", type=" + t)));
				}
			}
		} 
		return bytesUsed;
	}
}