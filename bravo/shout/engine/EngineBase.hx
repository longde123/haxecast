/**
 * ...
 * @author JB
 */
/**
 * Engine -> protocol --> stream
 *                    |-> codec [ -> sub codecs ]
 * 
 * Engine captures protocol, stream and codec events
 * Codecs with sub-codecs (i.e. NSV) capture sub-codec messages and dispatch their own versions of them
 * 
 * Codecs output FLV and RAW data frames
 * 
 * Engines
 * 1: (optionally) initiate a connection, 
 * 2: create a protocol and pump data to it
 * 3: listen to protocol messages, attaching listeners to streams and codecs created by protocols
 * 4: dispatch various protocol, stream and codec messages as required
 */
package bravo.shout.engine;

import bravo.shout.codec.CodecEvent;
import bravo.shout.codec.ICodec;
import bravo.shout.protocol.IProtocol;
import bravo.shout.protocol.ProtocolBase;
import bravo.shout.protocol.ProtocolEvent;
import bravo.shout.stream.IStream;
import bravo.shout.stream.StreamEvent;
import bravo.shout.engine.EngineEvent;
import haxe.io.BytesInput;
#if neko
import haxe.Int32;
#end
import hsl.haxe.Signaler;
import hsl.haxe.DirectSignaler;
import haxe.io.Bytes;

class EngineBase 
{
	public var engdata(default, null) : Signaler<EngineEvent>;
	public var protocol(default, null) : IProtocol;

	var thisIengine : IEngine;
	var lastCodecTime : Float;
	
	
	private function new()
	{
		engdata = new DirectSignaler(this);
		lastCodecTime = 0.0;
		thisIengine = cast this;
	}
	
	function setProtocol(s : String, p : Array<Dynamic>)
	{
		if (protocol != null)
		{
			protocol.protodata.unbind(proto_listen);
			protocol = null;
		}
		protocol = ProtocolBase.makeProtocol(s, p);
		protocol.protodata.bind(proto_listen);
	}
	var stream : IStream;
	var codec : ICodec;
	
	function proto_listen(e : ProtocolEvent) : Void
	{
		var ev : EngineEvent = null;
		switch(e.msgtyp)
		{
			case ProStreamStart:
				stream = cast(e.data, IStream);
				ev = new EngineEvent(EngStreamBegin, null, { stream : stream.streamName }, 0.0);
				stream.streamdata.bind(strm_listen);
			case ProName:
				ev = new EngineEvent(EngStreamName, null, { name : cast(e.data, String) }, 0.0);
			case ProCodecStart:
				codec = cast(e.data, ICodec);
				ev = new EngineEvent(EngCodecBegin, null, { codec : codec.codecName }, 0.0);
				codec.flvdata.bind(code_listen);
			case ProMeta:
				ev = new EngineEvent(EngMetaData, null, { xmldata : e.data }, lastCodecTime);
			case ProStart:
			case ProHeader:
			case ProData:
			case ProHeaderError:
				var err : { first : String, data : String } = e.data;
				ev = new EngineEvent(EngStreamStartError, null, err, lastCodecTime);
			case ProError:
			case ProUvoxBroadcaster, ProUvoxListener, ProUvoxCacheableMetadata, ProUvoxNonCacheableMetadata:
			/* e.data = 
				{
					uvoxClass : uvoxClass, 1,2,3|4,5
					uvoxMsg: uvoxMsg,
					data : e.data,
				}
			*/
				ev = new EngineEvent(EngUvoxProtocol, null, e.data, 0.0);
		}
		if(ev != null && engdata.isListenedTo)
		{
			engdata.dispatch(ev);
		}
	}
	function strm_listen(e : StreamEvent) : Void
	{
		if (e.msgtyp == StrV1MetaData && e.data.length > 0)
		{
			var o : Dynamic = {};
			var l = e.data.toString().split(';');
			for (i in l)
			{
				if (i.indexOf('=') > 0)
				{
					var j = i.split('=');
					var k = j.shift();
					var v = j.join('=');
					Reflect.setField(o, k, v);
				}
			}
			if(engdata.isListenedTo)
			{
				engdata.dispatch(new EngineEvent(EngMetaData, e.data, o, lastCodecTime));
			}
		}
	}
	function code_listen(e : CodecEvent) : Void
	{
		var obj : Dynamic = null;
		var evtype = 
			switch(e.msgtyp)
			{
				case CodInfo:
					if (e.data.length == 8)
					{
						var d = new BytesInput(e.data);
						d.bigEndian = false;
						obj = { };
						Reflect.setField(obj, 'width', d.readInt16());
						Reflect.setField(obj, 'height', d.readInt16());
						Reflect.setField(obj, 'rate', d.readInt24());
						Reflect.setField(obj, 'flip', d.readByte() == 1);
					}
					EngInformation;
				case CodHeader:						
					EngHeader;
				case CodStart:
					obj = { codec : e.data.toString() };
					EngInformation;
				case CodAudioPreData:	
					lastCodecTime = e.chunktime; 
					EngAudioPreData;
				case CodVideoPreData:	
					lastCodecTime = e.chunktime; 
					EngVideoPreData;
				case CodAudioData:	
					lastCodecTime = e.chunktime; 
					EngAudioData;
				case CodVideoData:	
					lastCodecTime = e.chunktime;
					EngVideoData;
				case CodMetaData:
					obj = { metadata : e.data };
					EngMetaData;
				case CodError:
					obj = { error : e.data.toString() };
					EngError;
			}
		var ev = new EngineEvent(evtype, e.data, obj, e.chunktime);
		if (engdata.isListenedTo)
		{
			engdata.dispatch(ev);
		}
	}
	public function cleanup()
	{
		if (codec != null)
		{
			codec.flvdata.unbind(code_listen);
			codec = null;
		}
		if (stream != null)
		{
			stream.streamdata.unbind(strm_listen);
			stream.cleanup();
			stream = null;
		}
		if (protocol != null)
		{
			protocol.protodata.unbind(proto_listen);
			protocol.cleanup();
			protocol = null;
		}
	}
}