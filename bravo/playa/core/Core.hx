package bravo.playa.core;

/**
 * ...
 * @author JB
 */
import bravo.shout.flash.ShoutPlayer;
import bravo.shout.flash.PlayerEvent;

import flash.display.Sprite;

import flash.events.Event;

import flash.net.NetStream;

enum ConnectState
{
	SOCKET_OPEN;
	SOCKET_FAIL;
	URL_OPEN;
	URL_FAIL;
}

class Core extends Sprite
{
	static var div = -Math.PI;

	var eng : ShoutPlayer;
	
	var audioBg : Sprite;
	var videoBg : Sprite;
	var theHost : String;
	var thePort : Int;
	var theRes : String;
	var wantVideo : Bool;

	var havePlayed : Bool;

	var theVolume : Float;
	
	function new(inHost : String, inPort : UInt, inRes : String, ?inVideo : Bool = true)
	{
		theHost = inHost;
		thePort = inPort;
		theRes = inRes;
		wantVideo = inVideo;
		super();
		addEventListener(Event.UNLOAD, on_cleanup);

		audioBg = new Sprite();
		addChild(audioBg);
		videoBg = new Sprite();
		addChild(videoBg);
		
		havePlayed = false;
		
		if (stage == null)
		{
			addEventListener(Event.ADDED_TO_STAGE, on_init);
		}
		else
		{
			on_init(null);
		}
	}

	function on_init(e:Dynamic) 
	{
		if (e != null)
		{
			removeEventListener(Event.ADDED_TO_STAGE, on_init);
		}
		init();
	}

	function doeng()
	{
		videoBg.addChild(eng = new ShoutPlayer(theHost, thePort, theRes, false, wantVideo));

		eng.addEventListener(PlayerEvent.SONG_TITLE, on_song_title);
		eng.addEventListener(PlayerEvent.STREAM_TITLE, on_stream_title);
		eng.addEventListener(PlayerEvent.VIDEO_PARAMETERS, on_video_on);
		eng.addEventListener(PlayerEvent.SOCKET_OPEN, on_listen);
		eng.addEventListener(PlayerEvent.SOCKET_FAIL, on_listen);
		eng.addEventListener(PlayerEvent.URL_OPEN, on_listen);
		eng.addEventListener(PlayerEvent.URL_FAIL, on_listen);
		eng.addEventListener(PlayerEvent.BUFFER_STATUS, on_buffer_status);
		eng.addEventListener(PlayerEvent.NETSTREAM_VIDEO, on_netstream_video);
	}
	
	function doPlay()
	{
		if (eng == null)
		{
			doeng();
		}
		else // allow change of stream between stop/play
		{
			eng._host = theHost;
			eng._port = thePort;
			eng._resource = theRes;
			eng._wantVideo = wantVideo;
		}
		eng.go();
		if (!havePlayed) 
		{
			havePlayed = true;
			doVolume(0.5);
		}
		else
		{
			doVolume(theVolume);
		}
	}

	function doStop()
	{
		if(eng != null)
		{
			eng.stop();
		}
	}
	
	function doVolume(vol : Float)
	{
		theVolume = vol;
		if (vol > 0.95) 
		{
			vol = 1.0;
		}
		else if (vol < 0.05)
		{
			vol = 0.0;
		}
		else
		{
			vol = Math.log(1 - vol) / div;
			//vol = Math.pow(vol, 3);
		}
		if (vol > 1.0) 
		{
			vol = 1.0;
		}
		else if (vol < 0.00)
		{
			vol = 0.0;
		}
		eng.setVolume(vol);
	}

	private function stripQuotes(s : String)
	{
		var name = s;
		if (name != null)
		{
			if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
			{
				name = name.substr(1, name.length - 2);
			}
		}
		return name;
	}
	function on_song_title(e : PlayerEvent)
	{
		var o : SongTitle = e.objVal;
		setSongName(stripQuotes(o.StreamTitle));
		setSongUrl(stripQuotes(o.StreamUrl));
	}
	
	function on_stream_title(e: PlayerEvent)
	{
		var o : StreamName = e.objVal;
		setStreamTitle(stripQuotes(o.name));
	}
	
	function on_buffer_status(e : PlayerEvent)
	{
		var o : BufferStatus = e.objVal;
		bufferStatus(o);
	}

	function on_listen(e : PlayerEvent)
	{
		switch(e.eventType)
		{
			case PlayerEvent.SOCKET_OPEN:
				connectState(SOCKET_OPEN);
			case PlayerEvent.SOCKET_FAIL:
				connectState(SOCKET_FAIL);
			case PlayerEvent.URL_OPEN:
				connectState(URL_OPEN);
			case PlayerEvent.URL_FAIL:
				connectState(URL_FAIL);
		}
	}
	
	function on_cleanup(e:Event)
	{
		cleanup();
	}
	
	function cleanup()
	{
		removeEventListener(Event.UNLOAD, on_cleanup);
		eng.removeEventListener(PlayerEvent.SONG_TITLE, on_song_title);
		eng.removeEventListener(PlayerEvent.STREAM_TITLE, on_stream_title);
		eng.removeEventListener(PlayerEvent.VIDEO_PARAMETERS, on_video_on);
		eng.removeEventListener(PlayerEvent.SOCKET_OPEN, on_listen);
		eng.removeEventListener(PlayerEvent.SOCKET_FAIL, on_listen);
		eng.removeEventListener(PlayerEvent.URL_OPEN, on_listen);
		eng.removeEventListener(PlayerEvent.URL_FAIL, on_listen);
		eng.removeEventListener(PlayerEvent.BUFFER_STATUS, on_buffer_status);
		eng.removeEventListener(PlayerEvent.NETSTREAM_VIDEO, on_netstream_video);
		while (getChildAt(0) != null)
		{
			removeChildAt(0);
		}
	}
	
	function on_video_on(e : PlayerEvent)
	{
		var o : VideoParameters = e.objVal;
		videoOn(o);
	}

	function on_netstream_video(e : PlayerEvent)
	{
		var o : VideoNetstream = e.objVal;
		videoStream(o);
	}

	// the API

	function init()
	{
	}
	function setSongName(name : String)
	{
	}
	function setSongUrl(name : String)
	{
	}
	function setStreamTitle(name:String)
	{	
	}
	function bufferStatus(o : BufferStatus)
	{
	}
	function connectState(state:ConnectState)
	{
	}
	function videoOn(params : VideoParameters)
	{
	}
	function videoStream(params : VideoNetstream)
	{
	}
}