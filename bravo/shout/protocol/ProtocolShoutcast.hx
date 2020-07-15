/**
 * ...
 * @author JB
 */

package bravo.shout.protocol;

import bravo.shout.codec.CodecBase;
import bravo.shout.codec.CodecEvent;
import bravo.shout.stream.StreamBase;
import bravo.shout.stream.StreamEvent;
import bravo.shout.stream.StreamShoutcast;
import bravo.shout.protocol.ProtocolEvent;

import haxe.io.Bytes;

class ProtocolShoutcast extends ProtocolBase, implements IProtocol
{

	var charCount : Int;
	var gettingHeader : Bool;
	var hdr : String;
	var firstOK : String;
	
	public function new() 
	{
		firstOK = ' 200 OK';
		protocolName = "SHOUTcast";
		gettingHeader = true;
		charCount = 0;
		super();
	}
	
	function ultraIcy(icy : String, ultra : String)
	{
		var rep = params.get(ultra.toLowerCase());
		if (params.get(icy.toLowerCase()) == null && rep != null)
		{
			params.set(icy.toLowerCase(), rep);
		}
	}
	
	public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		var usedBytes : Int;
		
		if (len < 1)
		{
			return null;
		}
		if (gettingHeader)
		{
			var split = "\r\n";
			var x = buff.sub(pos, len).toString();
			var e = x.indexOf("\r\n\r\n");
			if (e < 0)
			{
				e = x.indexOf("\n\n");
				if (e >= 0 )
				{
					split = "\n";
					e += 2;
				}
			}
			else
			{
				e += 4;
			}
			if (e < 0)
			{
				return null;
			}
			hdr = x.substr(0, e);
			usedBytes = e;
			gettingHeader = false;
			var lines = hdr.split(split);
			var frst = lines.shift();
			if (frst.indexOf(firstOK) >= 0)
			{
				for (line in lines)
				{
					var parval = line.split(':');
					var param = parval.shift().toLowerCase();
					var value = parval.join(':');
					if (value.length > 0)
					{
						params.set(param, value);
					}
				}
				if (params.get('ultravox-bitrate') != null)
				{
					var t = params.get('ultravox-bitrate');
					var n = Std.int(Std.parseFloat(t) / 1000);
					params.set('icy-br', n + '');
				}
				ultraIcy('icy-name', 'ultravox-title');
#if debug
				trace(frst);
				trace('[' + params.get('content-type') + ']');
				trace(params.get('icy-metaint'));
				trace(params.get('icy-br'));
#end
				var metaInt : Int = Std.parseInt(params.get('icy-metaint'));
				#if neko
				if (metaInt == null)
				{
					metaInt = 0;
				}
				#end
				if (params.get('ultravox-sid') == null)
				{
					stream = StreamBase.makeStream("StreamShoutcast", [metaInt]);
				}
				else
				{
					var maxblock : Int = Std.parseInt(params.get('ultravox-max-msg'));
					#if neko
					if (maxblock == null)
					{
						maxblock = 16377;
					}
					#end
					stream = StreamBase.makeStream("StreamUvox", [maxblock]);
				}
				stream.streamdata.bind(strm_listen);
				codec = CodecBase.makeCodec(params.get('content-type'), []);
				//codec.eventer.bind(code_listen);
				if(protodata.isListenedTo)
				{
					protodata.dispatch(new ProtocolEvent(ProName, params.get('icy-name')));
					protodata.dispatch(new ProtocolEvent(ProStreamStart, stream));
					protodata.dispatch(new ProtocolEvent(ProCodecStart, codec));
				}
			}
			else
			{
#if debug
				trace(frst+':'+lines);
#end
				if(protodata.isListenedTo)
				{
#if debug
					trace('dispatching ProHeaderError');
#end
					protodata.dispatch(new ProtocolEvent(ProHeaderError, { first : frst, data : lines }));
				}

			}
		}
		else
		{
			if (stream != null)
			{
				stream.fill(buff, pos, len);
			}
			usedBytes = len;
		}
		return usedBytes;
	}
	
	function strm_listen(e : StreamEvent) : Void
	{
		if (e.msgtyp == StrData)
		{
			if (e.uvoxtype < 1)
			{
				codec.fill(e.data, 0, e.data.length);
			}
			else
			{
				var uvoxClassMsg = e.uvoxtype;
				var uvoxClass = e.uvoxtype >> 12;
				var uvoxMsg = e.uvoxtype & 0x0FFF;
				var ev : ProtocolEvent = null;
				var o = 
				{
					uvoxClass : uvoxClass,
					uvoxMsg: uvoxMsg,
					uvoxData : e.data,
				}
				switch(uvoxClass)
				{
					case 1: // Broadcaster messages - don't think we'll get these as a client
						ev = new ProtocolEvent(ProUvoxBroadcaster, o);
						switch(uvoxMsg)
						{
							case 0x001: //Auth Broadcaster payload = "vers:sid:uid:pass\x00" - response(2.1) = "ACK:Allow\x00"
							case 0x002: //Setup Broadcater payload = "avgbps:maxbps\x00" - response(2.1) = "ACK\x00"
							case 0x003: //Negotiate Buffer Size payload = "bufferlo:bufferhi\x00" - response(2.1) = "ACK:buffersize\x00"
							case 0x004: //Broadcaster Standby
							case 0x005: //Broadcaster Termination
							case 0x006: //Flush Cached MetaData - response(2.1) = "ACK\x00"
							case 0x007: //Request Listener Auth
							case 0x008: //Negotiate Max Payload Size payload = "minchunk:maxchunk\x00" - response(2.1) = "ACK:chunksize\x00"
							case 0x009: //Temp Interruption // uvox cipher (uvox 2.1), payload = "2.1\x00", response = "ACK:cipherkey\x00"
							case 0x00a: //Broadcast Change
							case 0x040: //content-type - response(2.1) = "ACK\x00"
							case 0x100: //ICY-NAME - response(2.1) = "ACK\x00"
							case 0x101: //ICY-GENRE - response(2.1) = "ACK\x00"
							case 0x102: //ICY-URL - response(2.1) = "ACK\x00"
							case 0x103: //ICY-PUB - response(2.1) = "ACK\x00"
							case 0x104: //ICY-IRC - response(2.1) = "ACK\x00"
							case 0x105: //ICY-ICQ - response(2.1) = "ACK\x00"
							case 0x106: //ICY-AIM - response(2.1) = "ACK\x00"
							default:
						}
					case 2: // Listener Messages
						ev = new ProtocolEvent(ProUvoxListener, o);
						switch(uvoxMsg)
						{
							case 0x001: //Temp Interruption
							case 0x002: //Broadcast terminated
							case 0x003: //Broadcast Failover
							case 0x004: //Broadcast Discontinuity
							default:
						}
					case 3: // Cacheable MetaData Messages
						ev = new ProtocolEvent(ProUvoxCacheableMetadata, o);
						switch(uvoxMsg)
						{
							case 0x000: //Content Information
							case 0x001: //Content info URL
							case 0x901: //Extended Content (Song) Info
								ev = new ProtocolEvent(ProMeta, o);
							case 0x902: //Secure Ultravox Key Table / Debug MetaData
							case 0xa01: //Proposed MPEG-4 config
							case 0xa02: //Proposed MPEG-4 sync
							default:
						}
					case 4: // Cacheable MetaData Messages
						ev = new ProtocolEvent(ProUvoxCacheableMetadata, o);
						switch(uvoxMsg)
						{
							case 0x000: //NSV2 Group Descriptor
							default: //NSV2 Cacheable MetaData
								ev = new ProtocolEvent(ProMeta, o);
						}
					case 5: // Non-Cacheable MetaData Messages
						ev = new ProtocolEvent(ProUvoxNonCacheableMetadata, o);
						switch(uvoxMsg)
						{
							case 0x001: //File Progress (Time Remain)
							case 0xf00: // Write text to log file
							default: //
						}
					case 7, 8: // Data Messages
						switch(uvoxClassMsg)
						{
							case 0x7777, 0x7000, 0x7001, 0x8003: // NSV, MP3, MP3, AAC
								codec.fill(e.data, 0, e.data.length);
							case 0x8000: // Dolby AAC/VLB
							case 0x8001: // Ogg
							case 0x8002: // Speex
							default:
								// do nothing
						}
					case 9: // Data Messages
						// NSV2 Data
					case 10:
						//MPEG-4 Data
					default:
				}
				if (ev != null)
				{
					if(protodata.isListenedTo)
					{
						protodata.dispatch(ev);
					}
				}
			}
		}
	}
	//function code_listen(e : CodecEvent) : Void
	//{
	//}
}