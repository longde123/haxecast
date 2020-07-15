/**
 * ...
 * @author JB
 * ProtocolSource:
 * 1: determines source protcol (shoutcast, uvox 2.0/2.1)
 * 2: Handles uvox source protocol
 * 3: Handles password for shoutcast source protocol
 * 4: Rest of shoutcast source protocol handled by ProtocolShoutcast
 */

package bravo.shout.protocol;

import bravo.shout.codec.CodecBase;
import bravo.shout.protocol.ProtocolShoutcast;
import bravo.shout.protocol.ProtocolEvent;
import bravo.shout.stream.StreamBase;
import bravo.shout.stream.StreamEvent;
import haxe.io.Bytes;

private enum SourceState
{
	Init;
	Uvox;
}
class ProtocolSource extends ProtocolShoutcast
{

	var doprocess : Bytes->Int->Int->Null<Int>;
	
	public function new() 
	{
		protocolName = "SHOUTsource";
		gettingHeader = true;
		super();
		doprocess = getProtocol;
	}

	override public function process(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		return doprocess(buff, pos, len);
	}
	
	function processuvox(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		var usedBytes : Int = 0;
		
		return usedBytes;
	}

	function processshout(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		// get password, then process as per client stream!
		return super.process(buff, pos, len);
	}
	function stringify(d : Bytes)
	{
		var s = d.toString();
		var x = s.indexOf('\x00');
		if (x < 0)
		{
			x = s.length;
		}
		return s.substr(0, x);
	}
	function uvox_strm_listen(e : StreamEvent) : Void
	{
		if (e.msgtyp == StrData)
		{
			if (e.uvoxtype > 0)
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
					// not shown, sc_trans v2 sends intro and/or failover stream data as a series of data chunks
					case 1: // Broadcaster messages - don't think we'll get these as a client
						ev = new ProtocolEvent(ProUvoxBroadcaster, o);
						var str = stringify(e.data);
						var astr = str.split(':');
						switch(uvoxMsg)
						{
							case 0x001: //Auth Broadcaster payload = "vers:sid:uid:pass\x00" - response(2.1) = "ACK:Allow\x00"
							case 0x002: //Setup Broadcater payload = "avgbps:maxbps\x00" - response(2.1) = "ACK\x00"
							case 0x003: //Negotiate Buffer Size payload = "bufferlo:bufferhi\x00" - response(2.1) = "ACK:buffersize\x00"
							case 0x004: //Broadcaster Standby - NOTE: before getting this, no messages of class other than 1 are sent
							case 0x005: //Broadcaster Termination
							case 0x006: //Flush Cached MetaData - response(2.1) = "ACK\x00"
							case 0x007: //Request Listener Auth
							case 0x008: //Negotiate Max Payload Size payload = "minchunk:maxchunk\x00" - response(2.1) = "ACK:chunksize\x00"
							case 0x009: //Temp Interruption // uvox cipher (uvox 2.1), payload = "2.1\x00", response = "ACK:cipherkey\x00"
							case 0x00a: //Broadcast Change
							case 0x040: //content-type - response(2.1) = "ACK\x00"
								params.set('content-type', str);
								codec = CodecBase.makeCodec(str, []);
							case 0x100: //ICY-NAME - response(2.1) = "ACK\x00"
								params.set('icy-name', str);
							case 0x101: //ICY-GENRE - response(2.1) = "ACK\x00"
								params.set('icy-genre', str);
							case 0x102: //ICY-URL - response(2.1) = "ACK\x00"
								params.set('icy-url', str);
							case 0x103: //ICY-PUB - response(2.1) = "ACK\x00"
								params.set('icy-pub', str);
							case 0x104: //ICY-IRC - response(2.1) = "ACK\x00"
								params.set('icy-irc', str);
							case 0x105: //ICY-ICQ - response(2.1) = "ACK\x00"
								params.set('icy-icq', str);
							case 0x106: //ICY-AIM - response(2.1) = "ACK\x00"
								params.set('icy-aim', str);
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
					case 7,8: // Data Messages
						switch(uvoxMsg)
						{
							case 0x7777,0x7000,0x7001,0x8003: // NSV, MP3, MP3, AAC
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
					if(eventer.isListenedTo)
					{
						eventer.dispatch(ev);
					}
				}
			}
		}
	}
	
	function getProtocol(buff : Bytes, pos : Int, len : Int) : Null<Int>
	{
		if (len < 2)
		{
			return null;
		}
		if ( buff.get(0) == 0x5A && buff.get(1) == 0x00)
		{
			gettingHeader = false;
			stream = StreamBase.makeStream("StreamUvox", []);
			stream.eventer.bind(uvox_strm_listen);
			doprocess = processuvox;
		}
		else
		{
			doprocess = processshout;
		}
		return doprocess(buff, pos, len);
	}
}