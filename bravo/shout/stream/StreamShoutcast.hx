/**
 * ...
 * @author JB
 */

package bravo.shout.stream;

import haxe.io.Bytes;
import bravo.shout.stream.StreamEvent;
class StreamShoutcast extends StreamBase, implements IStream
{

	var charCount : Int;
	var gettingMeta : Bool;
	var metaLength : Int;
	var metaInterval : Int;

	public function new(meta : Int) 
	{
		streamName = 'SHOUTcast';
		metaInterval = meta;
		gettingMeta = false;
		charCount = 0;
		super();
	}
	
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		var usedBytes : Int;
		
		if (len < 1)
		{
			return null;
		}
		if (gettingMeta)
		{
			metaLength = (buff.get(pos) << 4);
			if (len < metaLength + 1)
			{
				return null;
			}
			usedBytes = metaLength + 1;
			if(streamdata.isListenedTo)
			{
				streamdata.dispatch(new StreamEvent(StrV1MetaData, 0, buff.sub(pos + 1, metaLength)));
			}
			gettingMeta = false;
			charCount = 0;
		}
		else
		{
			if (metaInterval > 0)
			{
				if ((len + charCount) < metaInterval)
				{
					usedBytes = len;
					charCount += len;
				}
				else
				{
					usedBytes = metaInterval - charCount;
					charCount += usedBytes;
					gettingMeta = true;
				}
			}
			else
			{
				usedBytes = len;
			}
			if(streamdata.isListenedTo)
			{
				streamdata.dispatch(new StreamEvent(StrData, 0, buff.sub(pos, usedBytes)));
			}
		}
		return usedBytes;
	}
}