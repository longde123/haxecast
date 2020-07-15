/**
 * ...
 * @author JB
 */

package bravo.playa.simplecore;

import bravo.shout.flash.PlayerEvent;
import bravo.playa.simplecore.Core;
import flash.external.ExternalInterface;
import flash.Lib;

class ScriptCore extends Core
{
	var cb_fun : String;
	var canCb : Bool;
	
	function new(inHost : String, inPort : UInt, inRes : String)
	{
		var params = Lib.current.loaderInfo.parameters;
		cb_fun = params.cb;
		canCb = (cb_fun != null) && ExternalInterface.available;
		super(inHost, inPort, inRes);
	}

	override function init() 
	{
		if (ExternalInterface.available)
		{
			ExternalInterface.addCallback("setVolume", function(v) { doVolume(v); } );
			ExternalInterface.addCallback("stop", function() { doStop(); } );
			ExternalInterface.addCallback("play", function() { doPlay(); } );
		}
		docb("Status", "START");
		doPlay();
	}
	override function setStreamTitle(name : String)
	{
		if (name != null)
		{
			docb("StreamTitle", name);
		}
	}
	override function setSongName(name : String)
	{
		if (name != null)
		{
			docb("SongName", name);
		}
	}
	
	override function setSongUrl(name : String)
	{
		if (name != null)
		{
			docb("SongUrl", name);
		}
	}
	override function videoOn(o : VideoParameters)
	{
		docb("VideoParameters", {width:o.width, height:o.height, rate:o.rate, flip:o.flip});
	}
	
	function docb(fn: String, val : Dynamic)
	{
		if (canCb)
		{
			ExternalInterface.call(cb_fun, { fn:fn, val:val } );
		}
	}

	override function bufferStatus(o : BufferStatus)
	{
		docb("BufferStatus", {time:o.bufferTime, length:o.bufferLength});
	}

	override function connectState(state:ConnectState)
	{
		switch(state)
		{
			case SOCKET_OPEN:
				docb("Status", "SOCKET_OPEN");
			case SOCKET_FAIL:
				docb("Status", "SOCKET_FAIL");
			case URL_OPEN:
				docb("Status", "URL_OPEN");
			case URL_FAIL:
				docb("Status", "URL_FAIL");
		}
	}
}