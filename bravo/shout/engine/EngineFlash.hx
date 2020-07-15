/**
 * ...
 * @author JB
 */

package bravo.shout.engine;

//import bravo.shout.codec.Tag;
import bravo.shout.protocol.IProtocol;
import bravo.shout.protocol.ProtocolBase;
import bravo.shout.engine.SocketConnection;
import bravo.shout.engine.EngineEvent;
import flash.display.DisplayObjectContainer;

import bravo.shout.flash.PlayerEvent;

import flash.net.ObjectEncoding;
import flash.system.Security;

import flash.display.Sprite;

import flash.media.SoundTransform;
import flash.media.Video;

import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.net.URLStream;

import flash.events.ActivityEvent;
import flash.events.AsyncErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.StatusEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;

import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.IDataInput;

import haxe.io.Bytes;

class EngineFlash extends EngineBase, implements IEngine
{
	var lastBytesLoaded : Float;
	var serverConnection : URLStream;
	var socketConnection : SocketConnection;
	var serverData : IDataInput;
	var url : URLRequest;
	var _host : String;
	var _port : UInt;
	var _resource : String;
	var netconnect : NetConnection;
	var netstream : NetStream;
	var _win : DisplayObjectContainer;
	var _video : Video;
	var _flip : Bool;
	var _width : Int;
	var _height : Int;
	var volume : SoundTransform;
	var _uvox : Bool;
	var _wantVideo : Bool;
	public var container(default, null) : Sprite;
	
	public function new(cont : Sprite, host : String, port : UInt, resource : String, ?uvox : Bool = false, ?wantVideo : Bool = true) 
	{
		super();
		volume = new SoundTransform(0.0);
		_wantVideo = wantVideo;
		_host = host;
		_port = port;
		_uvox = uvox;
		_resource = resource;
		_flip = false;
		container = cont;
		_win = cont.parent;
		engdata.bind(listen);
		lock = 0;
	}
	
	var lock : Int;
	
	private static inline function dbgtrace(s : Dynamic)
	{
#if debug
		trace(s);
#end
	}
    private function netStatusHandler( event: NetStatusEvent ):Void 
    {
		dbgtrace(event.currentTarget + event.info.code);
	}
	
    private function statusHandler( event: StatusEvent ):Void 
    {
		dbgtrace(event);
	}
	
	private function getByteArray(d : Bytes) : ByteArray
	{
		var ret = new ByteArray();
		ret.endian = Endian.BIG_ENDIAN;
		ret.objectEncoding = ByteArray.defaultObjectEncoding;
		ret.position = 0;
		for (i in 0...d.length)
		{
			ret.writeByte(d.get(i));
		}
		ret.position = 0;
		return ret;
	}

	function listen(e : EngineEvent) : Void
	{
		switch(e.msgtyp)
		{ 
			case EngHeader, EngAudioData, EngVideoData, EngAudioPreData, EngVideoPreData:
				while (++lock > 1)
				{
					lock--;
					dbgtrace('oops');
				}
				var ba = getByteArray(e.data);
				if (e.msgtyp == EngHeader)
				{
					var hasAudio = true;
					var hasVideo= true;
					if (netstream != null)
					{
						netstream.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
						dbgtrace('END SEQUENCE');
						hasAudio = (e.data.get(4) & 4) != 0;
						hasVideo = (e.data.get(4) & 1) != 0;
						netstream.receiveAudio(hasAudio);
						netstream.receiveVideo(hasVideo && _wantVideo);
						if (hasVideo && _wantVideo)
						{
							_video.attachNetStream(netstream);
						}
					}
					else
					{
						netstream = new NetStream(netconnect);
						hasAudio = (e.data.get(4) & 4) != 0;
						hasVideo = (e.data.get(4) & 1) != 0;
						netstream.receiveAudio(hasAudio);
						netstream.receiveVideo(hasVideo);
						netstream.backBufferTime = 0;
						netstream.bufferTime = 5;
						netstream.inBufferSeek = false;
						netstream.client = { onMetaData : onMetaData, onPlayStatus : onPlayStatus };
						netstream.addEventListener( NetStatusEvent.NET_STATUS,            netStatusHandler );
						netstream.addEventListener( SecurityErrorEvent.SECURITY_ERROR,    securityErrorHandler );
						netstream.addEventListener( IOErrorEvent.IO_ERROR,                ioErrorHandler );
						netstream.addEventListener( ActivityEvent.ACTIVITY,               activityHandler );
						if (hasVideo && _wantVideo)
						{
							_video.attachNetStream(netstream);
						}
						
						netstream.checkPolicyFile = true;
						netstream.play(null);
						netstream.soundTransform = volume;
					}
					netstream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
					netstream.appendBytes(ba);
					ba.clear();
					ba.position = 0;
					ba.writeByte(2);
					ba.writeUTF('|RtmpSampleAccess');
					ba.writeBoolean(true);
					ba.writeBoolean(true);
					ba.position = 0;
					ba = makeTagMeta(0, ba);
					netstream.appendBytes(ba);
					ba.position = 0;
					ba.clear();
					ba = null;
				}
				else
				{
					container.dispatchEvent(new PlayerEvent(PlayerEvent.BUFFER_STATUS, { 
						bufferLength : netstream.bufferLength,
						bufferTime : netstream.bufferTime,
					} ));
					netstream.appendBytes(ba);
					ba.clear();
					ba = null;
				}
				lock--;
			case EngInformation:
				if (e.object != null)
				{
					if (e.object.codec != null)
					{
						dbgtrace(e.object.codec);
					}
					else if (e.object.width != null && e.object.height != null && e.object.rate != null && e.object.flip != null)
					{
						if (_wantVideo)
						{
							container.dispatchEvent(new PlayerEvent(PlayerEvent.VIDEO_PARAMETERS, e.object));
							while (container.numChildren > 0) container.removeChildAt(0);
							container.scaleX = 1.0;
							container.scaleY = 1.0;
							container.x = 0;
							container.y = 0;
							_width = e.object.width;
							_height = e.object.height;
							var sw : Float;
							var sh : Float;
							var scl : Float;
							var xoff : Float = 0;
							var yoff : Float = 0;
							_video = new Video(_width, _height);
							scl = sw = _win.width / _width;
							sh = _win.height / _height;
							if (sh < sw)
							{
								scl = sh;
								xoff = ((_win.width / sh) - _width ) / 2;
							}
							else
							{
								yoff = ((_win.height / sw) - _height) / 2;
							}
							container.addChild(_video);
							container.scaleX = scl;
							_video.x = xoff;
							_video.y = yoff;
							container.scaleY = scl;
							if (cast(e.object.flip, Bool))
							{
								container.y = _win.height;
								container.scaleY = -container.scaleY;
							}
						}
					}
				}
			case EngMetaData:
				if (e.object != null)
				{
					if (e.object.StreamTitle != null)
					{
						container.dispatchEvent(new PlayerEvent(PlayerEvent.SONG_TITLE, e.object));
						dbgtrace(e.object.StreamTitle);
					}
					else if (e.object.metadata != null)
					{
						container.dispatchEvent(new PlayerEvent(PlayerEvent.CODEC_METADATA, e.object));
						dbgtrace(e.object.metadata);
					}
					else if (e.object.xmldata != null)
					{
						container.dispatchEvent(new PlayerEvent(PlayerEvent.XML_METADATA, e.object));
						dbgtrace(e.object.metadata);
					}
				}
			case EngStreamName:
				if (e.object != null && e.object.name != null)
				{
					container.dispatchEvent(new PlayerEvent(PlayerEvent.STREAM_TITLE, e.object));
				}
			case EngStreamStartError:
				container.dispatchEvent(new PlayerEvent(PlayerEvent.STREAM_FAIL, e.object));
				if (socketConnection != null)
				{
					var s : String = e.object.first;
					if (s.indexOf(" 404 ") < 0)
					{
						onNoPolicy(null);
					}
				}
			case EngUvoxProtocol, EngError, EngStreamBegin, EngCodecBegin:
				dbgtrace(e.msgtyp);
				dbgtrace(':data:' + e.data +':obj:' + e.object);
		}
	}

    public function onCuePoint( infoObject: Dynamic ):Void 
	{    
		onSubtitle( infoObject.name );  
	}
    public function onTextData( infoObject: Dynamic ):Void 
	{     
		onSubtitle( infoObject.text );  
	}
    public function onSubtitle( sub: String ):Void
	{             
		dbgtrace( sub );                   
	}
    
    public function onMetaData( infoObject: Dynamic ):Void 
    {
        dbgtrace(Std.string(infoObject));
    }
	
	public function onPlayStatus( infoObject : Dynamic):Void
	{
		dbgtrace(infoObject);
	}
	public function go()
	{
		netconnect = new NetConnection();
		netconnect.client = this;
        netconnect.addEventListener( NetStatusEvent.NET_STATUS,            netStatusHandler );
        netconnect.addEventListener( SecurityErrorEvent.SECURITY_ERROR,    securityErrorHandler );
        netconnect.addEventListener( IOErrorEvent.IO_ERROR,                ioErrorHandler );
		netconnect.addEventListener( ActivityEvent.ACTIVITY,               activityHandler );
		netconnect.addEventListener(StatusEvent.STATUS,					   statusHandler);
		netconnect.connect(null);
		var uvox : Bool = false;
		lastBytesLoaded = 0;
		container.dispatchEvent(new PlayerEvent(PlayerEvent.SOCKET_OPEN, { } ));
		dbgtrace('Connecting to ... ' + _host + ':' + _port);
		setProtocol("ProtocolShoutcast", []); // <===== 
		socketConnection = null;
		socketConnection = new SocketConnection(_host, _port, _resource, _uvox);
		socketConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
		socketConnection.addEventListener(IOErrorEvent.IO_ERROR, onIo);					
		socketConnection.addEventListener(ProgressEvent.SOCKET_DATA,sockloaded);
		socketConnection.addEventListener(Event.CLOSE, onClose);
		socketConnection.timeout = 5000;
		serverData = socketConnection;
		socketConnection.connect(_host, _port);
	}
	
	private function gourl()
	{
		container.dispatchEvent(new PlayerEvent(PlayerEvent.SOCKET_FAIL, { } ));
		container.dispatchEvent(new PlayerEvent(PlayerEvent.URL_OPEN, { } ));
		dbgtrace('Connecting to ... http://' + _host + ':' + _port + '/' + _resource);
		setProtocol("ProtocolShoutcast", []);
		serverConnection=new URLStream();
		serverConnection.addEventListener(ProgressEvent.PROGRESS,loaded);
		serverConnection.addEventListener(IOErrorEvent.IO_ERROR, onUrlIo);
		serverConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		serverConnection.addEventListener(Event.CLOSE, onServClose);
		serverData = serverConnection;
		url = new URLRequest("http://" + _host + ":" + _port + "/" + _resource);
		url.method = URLRequestMethod.GET;
		url.requestHeaders = 
		[
			new URLRequestHeader("Ultravox-transport-type", "TCP"),
			new URLRequestHeader("Icy-MetaData", "1"),
		];
		serverConnection.load(url);				
	}

	private function onIo(pe:IOErrorEvent):Void
	{
		dbgtrace('IO Error: ' + pe);
		localclean();
	}

	private function onUrlIo(pe:IOErrorEvent):Void
	{
		container.dispatchEvent(new PlayerEvent(PlayerEvent.URL_FAIL, { } ));
		dbgtrace('URL IO Error: ' + pe);
		localclean();
	}

	private function onNoPolicy(se:SecurityErrorEvent):Void
	{
		dbgtrace("No Policy: " + se);
		if (socketConnection.connected)
		{
			socketConnection.close();
			socketConnection = null;
		}
		gourl();
	}
	
	override public function cleanup()
	{
		localclean();
		engdata.unbind(listen);
		if (netconnect != null)
		{
			dbgtrace('cleaned netconnect');
			netconnect.removeEventListener( NetStatusEvent.NET_STATUS,            netStatusHandler );
			netconnect.removeEventListener( SecurityErrorEvent.SECURITY_ERROR,    securityErrorHandler );
			netconnect.removeEventListener( IOErrorEvent.IO_ERROR,                ioErrorHandler );
			netconnect.removeEventListener( ActivityEvent.ACTIVITY,               activityHandler );
			netconnect.removeEventListener(StatusEvent.STATUS,					  statusHandler);
			netconnect.close();
			netconnect = null;
		}
	}
	private function localclean()
	{
		if (socketConnection != null)
		{
			dbgtrace('cleaned socket');
			//socketConnection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
			//socketConnection.removeEventListener(IOErrorEvent.IO_ERROR,             onIo);					
			//socketConnection.removeEventListener(ProgressEvent.SOCKET_DATA,         sockloaded);
			//socketConnection.removeEventListener(Event.CLOSE,                       onClose);
			try socketConnection.close() catch (e:Dynamic) { }
			socketConnection = null;
		}
		if (serverConnection != null)
		{
			dbgtrace('cleaned server');
			serverConnection.removeEventListener(ProgressEvent.PROGRESS,            loaded);
			serverConnection.removeEventListener(IOErrorEvent.IO_ERROR,             onUrlIo);
			serverConnection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			serverConnection.removeEventListener(Event.CLOSE,                       onServClose);
			try serverConnection.close() catch (e:Dynamic) { }
			serverConnection = null;
		}
		if (netstream != null)
		{
			dbgtrace('cleaned netstream');
			netstream.removeEventListener( NetStatusEvent.NET_STATUS,            netStatusHandler );
			netstream.removeEventListener( SecurityErrorEvent.SECURITY_ERROR,    securityErrorHandler );
			netstream.removeEventListener( IOErrorEvent.IO_ERROR,                ioErrorHandler );
			netstream.removeEventListener( ActivityEvent.ACTIVITY,               activityHandler );
			netstream.close();
			netstream = null;
		}
		super.cleanup();
	}
	
	public function stop()
	{
		localclean();
	}
	
	private function onClose(e:Event):Void
	{
		localclean();
	}

	private function onServClose(e:Event):Void
	{
		localclean();
	}

    private function securityErrorHandler( event: SecurityErrorEvent ):Void 
	{   
		container.dispatchEvent(new PlayerEvent(PlayerEvent.URL_FAIL, { } ));
		dbgtrace("securityErrorHandler: " + event);    
	}
    private function asyncErrorHandler( event: AsyncErrorEvent ):Void 
	{         
		dbgtrace("asyncErrorHandler: " + event );      
	}
    private function ioErrorHandler( event: IOErrorEvent ):Void 
	{                
		dbgtrace("ioErrorHandler: " + event );      
	}
    private function activityHandler( event: ActivityEvent ):Void 
	{              
		dbgtrace("activityHandler: " + event );      
	}

	var hdrBytes : String;
	var gotHdr : Bool;
	
	private function loaded(e:ProgressEvent):Void
	{
		var thispacket = e.bytesLoaded - lastBytesLoaded;
		var iPack = Std.int(thispacket);
		var packet : Bytes = Bytes.alloc(iPack);
		lastBytesLoaded = e.bytesLoaded;
		for (i in 0...iPack)
		{
			packet.set(i, serverData.readByte());
		}
		protocol.fill(packet, 0, iPack);
	}

	private function sockloaded(e:ProgressEvent):Void
	{
		var thispacket = e.bytesLoaded;
		lastBytesLoaded += thispacket;
		var iPack = Std.int(thispacket);
		var packet : Bytes = Bytes.alloc(iPack);
		for (i in 0...iPack)
		{
			packet.set(i, serverData.readByte());
		}
		protocol.fill(packet, 0, iPack);
	}

	static function writeUi24(tag : ByteArray, v : UInt)
	{
		tag.writeByte(v >>> 16);
		tag.writeByte(v >>> 8);
		tag.writeByte(v);
	}
	static function writeUi32(tag : ByteArray, v : UInt)
	{
		tag.writeByte(v >>> 24);
		tag.writeByte(v >>> 16);
		tag.writeByte(v >>> 8);
		tag.writeByte(v);
	}
	static function makeTagMeta(tim : UInt, data : ByteArray) : ByteArray
	{
		
		var tag = new ByteArray();
		tag.writeByte(18);
		writeUi24(tag, data.bytesAvailable);
		writeUi24(tag, tim);
		tag.writeByte(tim >>> 24);
		writeUi24(tag, 0);
		tag.writeBytes(data);
		writeUi32(tag, tag.length);
		tag.position = 0;
		return tag;
	}

	public function setVolume(v : Float)
	{
		volume = null;
		volume = new SoundTransform(v);
		if (netstream != null)
		{
			netstream.soundTransform = volume;
		}
	}
}