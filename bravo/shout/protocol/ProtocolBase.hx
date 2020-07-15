/**
 * ...
 * @author JB
 * Protocols:
 * 1: handle the initial handshaking
 * 2: create a stream and send raw data to it
 * 3: create an appropriate codec
 * 3: listen to stream messages and send unframed data to codec
 */

package bravo.shout.protocol;

import bravo.DynamicBuffer;

import bravo.shout.codec.ICodec;
import bravo.shout.protocol.IProtocol;
import bravo.shout.protocol.ProtocolEvent;
import bravo.shout.protocol.ProtocolShoutcast;
#if !flash
//import bravo.shout.protocol.ProtocolSource;
#end
import bravo.shout.stream.IStream;

import hsl.haxe.Signaler;
import hsl.haxe.DirectSignaler;
import haxe.io.Bytes;

class ProtocolBase
{
	public var protodata(default, null) : Signaler<ProtocolEvent>;
	public var stream(default, null) : IStream;
	public var codec(default, null) : ICodec;
	public var protocolName(default, null) : String;
	public var params(default, null) : Hash<String>;

	var thisIprotocol : IProtocol;
	var chunkData : DynamicBuffer;
	var firstFill : Bool;
	
	private function new() 
	{
		params = new Hash();
		firstFill = false;
		protodata = new DirectSignaler(this);
		thisIprotocol = cast this;
		chunkData = new DynamicBuffer(1024, 1024<<8);
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
			if(protodata.isListenedTo)
			{
				protodata.dispatch(new ProtocolEvent(ProStart, protocolName));
			}
		}
		if (buff.length < (pos + len))
		{
			if(protodata.isListenedTo)
			{
				protodata.dispatch(new ProtocolEvent(ProError, 'fixed bad data'));
			}
			len = buff.length - pos;
		}
		if(protodata.isListenedTo)
		{
			protodata.dispatch(new ProtocolEvent(ProData, len));
		}
		chunkData.add(buff.sub(pos, len), true);
		while (true)
		{
			var ret = thisIprotocol.process(chunkData.buff, chunkData.pos, chunkData.bytes);
			if (ret == null)
			{
				return;
			}
			if (ret > chunkData.bytes)
			{
				if(protodata.isListenedTo)
				{
					protodata.dispatch(new ProtocolEvent(ProError, "Pump consumed more bytes than available"));
				}
			}
			else
			{
				chunkData.used(ret);
			}
		}
	}
	public static function makeProtocol(str : String, parm : Array<Dynamic>) : IProtocol
	{
		return Type.createInstance(Type.resolveClass('bravo.shout.protocol.' + str), parm);
	}
	public function cleanup()
	{
		if (codec != null)
		{
			codec.cleanup();
		}
	}
}