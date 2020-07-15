/**
 * ...
 * @author JB
 * Codecs:
 * 1: receive raw unframed data from Protocol
 * 2: dispatch FLV and Raw packets which are processed by Engine
 */

package bravo.shout.codec;

import bravo.DynamicBuffer;

import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.Aac;
import bravo.shout.codec.Mp3;
import bravo.shout.codec.Nsv;
import bravo.shout.codec.Vp6;
import bravo.shout.codec.Vp60;
import bravo.shout.codec.Vp61;
import bravo.shout.codec.Vp62;
import bravo.shout.codec.Avc;
import bravo.shout.codec.Unknown;

import hsl.haxe.Signaler;
import hsl.haxe.DirectSignaler;
import haxe.io.Bytes;
import bravo.shout.tag.DataTag;

class CodecBase
{
	public var flvdata(default, null) : Signaler<CodecEvent>;
	public var rawdata(default, null) : Signaler<CodecEvent>;
	var thisIcodec : ICodec;
	var chunkData : DynamicBuffer;
	var frameIncrement : Float;
	public var audioStream(default, null) : ICodec;
	public var videoStream(default, null) : ICodec;
	
	public var frameTime(default, null) : Float;
	public var frames(default, null) : Float;
	public var codecType(default, null) : CodecMsgTypes;

	public var codecName(default, null) : String;

	var firstFill : Bool;
	
	private function new(?inc : Float = 0.0) 
	{
		firstFill = true;
		flvdata = new DirectSignaler(this);
		rawdata = new DirectSignaler(this);
		thisIcodec = cast this;
		frameTime = 0.0;
		frameIncrement = inc;
		frames = 0.0;
		chunkData = new DynamicBuffer(32768, 1024<<8);
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
			if(flvdata.isListenedTo)
			{
				flvdata.dispatch(new CodecEvent(CodStart, Bytes.ofString(codecName)));
			}
		}
		if (buff.length < (pos + len))
		{
			if(flvdata.isListenedTo)
			{
				flvdata.dispatch(new CodecEvent(CodError, Bytes.ofString('fixed bad data')));
			}
			len = buff.length - pos;
		}
		chunkData.add(buff.sub(pos, len));
		while (true)
		{
			var ret = thisIcodec.process(chunkData.buff, chunkData.pos, chunkData.bytes);
			if (ret == null)
			{
				return;
			}
			if (ret > chunkData.bytes)
			{
				if(flvdata.isListenedTo)
				{
					flvdata.dispatch(new CodecEvent(CodError, Bytes.ofString("Pump consumed more bytes than available")));
				}
			}
			else
			{
				chunkData.used(ret);
			}
		}
	}
	public static function makeCodec(cod : String, parm : Array<Dynamic>) : ICodec
	{
		var uvox = cod.toLowerCase().indexOf('misc/ultravox(');
		if (uvox >= 0)
		{
			var uvstart = cod.indexOf('(');
			var uvend = cod.lastIndexOf(')');
			cod = cod.substr(uvstart + 1, uvend - uvstart - 1);
		}
		var codec = switch(StringTools.trim(cod).toLowerCase())
		{
			case 'mp3', 'audio/mpeg', 'audio/mpg':	'Mp3';
			case 'audio/aacp', 'aac', 'aacp':		'Aac';
			case 'video/nsv': 						'Nsv';
			case 'vp60':							'Vp60';
			case 'vp61':							'Vp61';
			case 'vp62':							'Vp62';
			case 'avc', 'h264', 'x264':				'Avc';
			case 'misc/ultravox':					'Unknown';
			default: 								'Unknown';
		}
		return Type.createInstance(Type.resolveClass('bravo.shout.codec.' + codec), parm);
	}
	public function addFrames(n : Int) : Void
	{
		var f : Float = n;
		frames += f;
		frameTime += (f * frameIncrement);
	}
	public function cleanup()
	{
		
	}
#if false
	function codecMsg(type : CodecMsgTypes, data : Null<Bytes>, ?chunktime : Float = 0.0) : CodecMsg
	{
		return 
		{
			msgtype : type,
			msgdata : data,
			//rawdata : raw,
			chunktime : chunktime,
		}
	}
	
	function codecString(type : CodecMsgTypes, data : String) : CodecMsg
	{
		return codecMsg(type, Bytes.ofString(data));
	}
#end
}