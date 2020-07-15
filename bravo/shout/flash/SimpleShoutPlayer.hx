/**
 * ...
 * @author JB
 */

package bravo.shout.flash;

import bravo.shout.engine.SimpleEngineFlash;
import flash.display.Sprite;
import flash.events.EventDispatcher;

class SimpleShoutPlayer extends EventDispatcher
{

	public var engine(default, null) : SimpleEngineFlash;
	public var _host : String;
	public var _port : Int;
	public var _resource : String;
	public var _uvox : Bool;
	public var _wantVideo : Bool;
	
	var going : Bool;

	public function new(host : String, ?port : UInt = 8000, ?resource : String = "", ?uvox : Bool = false, ?wantVideo : Bool = true) 
	{
		super();
		_host = host;
		_port = port;
		_resource = resource;
		_uvox = uvox;
		_wantVideo = wantVideo;
		going = false;
	}
	
	public function go()
	{
		if (engine == null)
		{
			engine = new SimpleEngineFlash(this, _host, _port, _resource, _uvox, _wantVideo);
		}
		if (!going)
		{
			going = true;
			engine.go();
		}
	}
	public function stop()
	{
		if (going)
		{
			going = false;
			engine.cleanup();
			engine = null;
		}
	}
#if swc
	static function main() { }
#end
	public function setVolume(v:Float)
	{
		if (engine != null)
		{
			engine.setVolume(v);
		}
	}
}