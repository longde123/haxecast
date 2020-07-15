/**
 * ...
 * @author JB
 */

package bravo.shout.codec;

import bravo.shout.tag.IDataTag;
import haxe.io.Bytes;
import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.Video;
import bravo.shout.tag.DataTag;

class Vp6 extends Video, implements ICodec
{

	var doSend : Bool;
	
	private function new(?inc : Float = 0.0) 
	{
		doSend = false;
		super(inc);
	}
	
	// we get exactly full frames ONLY
	override public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		if (len < 1)
		{
			return null;
		}
		var retMsg : CodecMsg = null;
		var isKey = ((buff.get(pos) & 0x80) == 0);
		doSend = isKey ? true : doSend;
#if debug
		if (isKey && len > 15)
		{
			var s = StringTools.hex(len,4) + ' : ';
			for (i in 0...16)
			{
				s += StringTools.hex(buff.get(pos + i), 2) + ' ';
			}
			trace(s);
		}
#end
		if (doSend)
		{
			var d = Bytes.alloc(len + 1);
			d.set(0, 0);
			d.blit(1, buff, pos, len);
			if(flvdata.isListenedTo)
			{
				flvdata.dispatch(
					new CodecEvent(
						codecType, 
						new VideoTag(d, frameTime, VP6, isKey ? Key : Inter).tag, 
						frameTime
					)
				);
			}
			if(rawdata.isListenedTo)
			{
				rawdata.dispatch(
					new CodecEvent(
						codecType, 
						buff.sub(pos, len), 
						frameTime
					)
				);
			}
		}
		addFrames(1);
		return len;
	}
}

class DataTagVideoVp6 extends DataTagVideo, implements IDataTag
{
	public function new(flvPreData : Bytes, data : Bytes, time : Float, type : TagVideoTypes)
	{
		super(time, VP6, type);
		if (flvPreData != null)
		{
			writeBytes(flvPreData, 0, flvPreData.length, DTWFlv);
		}
		if (data != null)
		{
			writeBytes(data, 0, data.length, DTWBoth);
		}
		this.endtag();
	}
}
