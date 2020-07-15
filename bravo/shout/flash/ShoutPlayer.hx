/**
 * ...
 * @author JB
 */

package bravo.shout.flash;

import bravo.shout.engine.EngineFlash;
import flash.display.Sprite;

class ShoutPlayer extends Sprite
{

	var engine : EngineFlash;
	public var _host : String;
	public var _port : Int;
	public var _resource : String;
	public var _uvox : Bool;
	public var _wantVideo : Bool;
	
	var going : Bool;

	public function new(host : String, ?port : UInt = 8000, ?resource : String = "", ?uvox : Bool = false, ?wantVideo : Bool = true) 
	{
		_host = host;
		_port = port;
		_resource = resource;
		_uvox = uvox;
		_wantVideo = wantVideo;
		going = false;
		super();
	}
	
	public function go()
	{
		if (engine == null)
		{
			engine = new EngineFlash(this, _host, _port, _resource, _uvox, _wantVideo);
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