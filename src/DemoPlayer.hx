/**
 * ...
 * @author JB
 */

package ;

import flash.Lib;
import bravo.playa.control.DummyMenu;
import bravo.playa.core.ControlCore;

class DemoPlayer extends ControlCore
{
	static var gHost : String;
	static var gPort : Null<Int>;
	static var gRes : String;
	static var gLogoText : String;
	

	static function main() 
	{
		Lib.current.addChild(new DemoPlayer());
	}

	public function new()
	{
		TextConfig.useBeat = true;
		TextConfig.wantVideo = true;
		Lib.current.contextMenu = new DummyMenu("*cast player (demo)").menu;
		super("www.nakedfm.co.nz", 8000, ";stream.aac", "demo"); // aac stream
		//super("99.198.118.250", 8010, ";stream.nsv", "demo"); // video
		bufferDiv = 8.0;
	}
}