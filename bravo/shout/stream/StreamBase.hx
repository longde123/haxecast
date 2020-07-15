/**
 * ...
 * @author JB
 * Streams:
 * 1: handle the stream data coming in from Protocol
 * 2: strip any "framing" like in the case of uvox
 * 3: dispatch blocks of data to Protocols
 */

package bravo.shout.stream;

import bravo.DynamicBuffer;

import bravo.shout.stream.IStream;
import bravo.shout.stream.StreamEvent;
import bravo.shout.stream.StreamShoutcast;
import bravo.shout.stream.StreamUvox;

import hsl.haxe.Signaler;
import hsl.haxe.DirectSignaler;
import haxe.io.Bytes;

class StreamBase
{
	public var streamdata(default, null) : Signaler<StreamEvent>;
	public var streamName(default, null) : String;
	var thisIstream : IStream;
	var chunkData : DynamicBuffer;
	var firstFill : Bool;
	
	private function new() 
	{
		firstFill = true;
		streamdata = new DirectSignaler(this);
		thisIstream = cast this;
		chunkData = new DynamicBuffer(32768);
	}
	
	public function fill(buff : Bytes, pos : Int, len : Int) : Void
	{
		if (buff == null)
		{
			return;
		}
		if (len == 0)
		{
			return;
		}
		if (firstFill)
		{
			firstFill = false;
			if(streamdata.isListenedTo)
			{
				streamdata.dispatch(new StreamEvent(StrStart, 0, Bytes.ofString(streamName)));
			}
		}
		if (buff.length < (pos + len))
		{
			if(streamdata.isListenedTo)
			{
				streamdata.dispatch(new StreamEvent(StrError, 0, Bytes.ofString('fixed bad data')));
			}
			len = buff.length - pos;
		}
		chunkData.add(buff.sub(pos, len));
		while (true)
		{
			var ret = thisIstream.process(chunkData.buff, chunkData.pos, chunkData.bytes);
			if (ret == null)
			{
				return;
			}
			if (ret > chunkData.bytes)
			{
				if(streamdata.isListenedTo)
				{
					streamdata.dispatch(new StreamEvent(StrError, 0, Bytes.ofString("Pump consumed more bytes than available")));
				}
			}
			else
			{
				chunkData.used(ret);
			}
		}
	}
	public static function makeStream(str : String, parm : Array<Dynamic>) : IStream
	{
		return Type.createInstance(Type.resolveClass('bravo.shout.stream.' + str), parm);
	}
	public function cleanup()
	{
		
	}
}