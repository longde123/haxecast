/**
 * ...
 * @author JB
 */

package bravo.playa.simplecore;

import bravo.shout.flash.ShoutPlayer;
import bravo.shout.flash.PlayerEvent;

import flash.external.ExternalInterface;

import flash.display.Sprite;
import flash.Lib;

import flash.events.Event;

class ScriptedCore extends Sprite
{
	var eng : ShoutPlayer;
	
	var audioBg : Sprite;
	var videoBg : Sprite;
	var theHost : String;
	var thePort : Int;
	var theRes : String;

	function cleanup(e:Event)
	{
		trace('cleaning');
		removeEventListener(Event.UNLOAD, cleanup);
		eng.removeEventListener(PlayerEvent.SONG_TITLE, song_title);
		eng.removeEventListener(PlayerEvent.STREAM_TITLE, stream_title);
		eng.removeEventListener(PlayerEvent.VIDEO_PARAMETERS, videoOn);
		eng.removeEventListener(PlayerEvent.SOCKET_OPEN, listen);
		eng.removeEventListener(PlayerEvent.SOCKET_FAIL, listen);
		eng.removeEventListener(PlayerEvent.URL_OPEN, listen);
		eng.removeEventListener(PlayerEvent.URL_FAIL, listen);
		eng.removeEventListener(PlayerEvent.BUFFER_STATUS, buffer_status);
		while (getChildAt(0) != null)
		{
			removeChildAt(0);
		}
	}
	var cb_fun : String;
	var canCb : Bool;
	
	function new(inHost : String, inPort : UInt, inRes : String)
	{
		var params = Lib.current.loaderInfo.parameters;
		cb_fun = params.cb;
		canCb = (cb_fun != null) && ExternalInterface.available;
		theHost = inHost;
		thePort = inPort;
		theRes = inRes;
		super();
		addEventListener(Event.UNLOAD, cleanup);
		if (stage == null)
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		else
		{
			init(null);
		}
	}

	function init(e:Dynamic) 
	{
		if (e != null)
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		audioBg = new Sprite();
		addChild(audioBg);
		videoBg = new Sprite();
		addChild(videoBg);
		
		if (ExternalInterface.available)
		{
			ExternalInterface.addCallback("setVolume", function(v) { doVolume(v); } );
			ExternalInterface.addCallback("stop", function() { doStop(); } );
			ExternalInterface.addCallback("play", function() { doPlay(); } );
		}
		docb("Status", "START");
		havePlayed = false;
		doPlay();
	}
	function doeng()
	{
		videoBg.addChild(eng = new ShoutPlayer(theHost, thePort, theRes, false, false));
		
		eng.addEventListener(PlayerEvent.SONG_TITLE, song_title);
		eng.addEventListener(PlayerEvent.STREAM_TITLE, stream_title);
		eng.addEventListener(PlayerEvent.VIDEO_PARAMETERS, videoOn);
		eng.addEventListener(PlayerEvent.SOCKET_OPEN, listen);
		eng.addEventListener(PlayerEvent.SOCKET_FAIL, listen);
		eng.addEventListener(PlayerEvent.URL_OPEN, listen);
		eng.addEventListener(PlayerEvent.URL_FAIL, listen);
		eng.addEventListener(PlayerEvent.BUFFER_STATUS, buffer_status);
	}
	var havePlayed : Bool;
	function doPlay()
	{
		if (eng == null)
		{
			doeng();
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
	var theVolume : Float;
	function doStop()
	{
		setSongName("");
		setStationName("");
		if(eng != null)
		{
			eng.stop();
		}
	}
	static var div = -Math.PI;
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

	function setStationName(name : String)
	{
		if (name != null)
		{
		}
	}
	
	function setSongName(name : String)
	{
		if (name != null)
		{
			if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
			{
				name = name.substr(1, name.length - 2);
			}
			docb("SongName", name);
		}
	}
	
	function setSongUrl(name : String)
	{
		if (name != null)
		{
			if (name.substr(0, 1) == "'" || name.substr(0, 1) == '"')
			{
				name = name.substr(1, name.length - 2);
			}
			docb("SongUrl", name);
		}
	}
	function videoOn(e : PlayerEvent)
	{
		var o : VideoParameters = e.objVal;
		docb("VideoParameters", {width:o.width, height:o.height, rate:o.rate, flip:o.flip});
	}
	function song_title(e : PlayerEvent)
	{
		var o : SongTitle = e.objVal;
		setSongName(o.StreamTitle);
		setSongUrl(o.StreamUrl);
	}
	function stream_title(e: PlayerEvent)
	{
		var o : StreamName = e.objVal;
		docb("StreamTitle", o.name);
	}
	function docb(fn: String, val : Dynamic)
	{
		if (canCb)
		{
			ExternalInterface.call(cb_fun, { fn:fn, val:val } );
		}
	}
	function buffer_status(e : PlayerEvent)
	{
		var o : BufferStatus = e.objVal;
		docb("BufferStatus", {time:o.bufferTime, length:o.bufferLength});
	}
	function listen(e : PlayerEvent)
	{
		switch(e.eventType)
		{
/*
			case PlayerEvent.CODEC_METADATA:
				//var o : MetaData = e.objVal;
			case PlayerEvent.XML_METADATA:
				//var o : XmlMeta = e.objVal;
			case PlayerEvent.SONG_TITLE:
				//var o : SongTitle = e.objVal;
			case PlayerEvent.STREAM_TITLE:
				//var o : StreamName = e.objVal;
			case PlayerEvent.VIDEO_PARAMETERS:
				//var o : VideoParameters = e.objVal;
			case PlayerEvent.BUFFER_STATUS:
				//var o : BufferStatus = e.objVal;
*/
			case PlayerEvent.SOCKET_OPEN:
				docb("Status", "SOCKET_OPEN");
			case PlayerEvent.SOCKET_FAIL:
				docb("Status", "SOCKET_FAIL");
			case PlayerEvent.URL_OPEN:
				docb("Status", "URL_OPEN");
			case PlayerEvent.URL_FAIL:
				docb("Status", "URL_FAIL");
		}
	}
}