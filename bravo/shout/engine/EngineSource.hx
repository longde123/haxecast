/**
 * ...
 * @author JB
 */

 package bravo.shout.engine;

import bravo.shout.protocol.IProtocol;
import bravo.shout.protocol.ProtocolBase;
import haxe.io.Bytes;

class EngineSource
{
	var protocol : IProtocol;
	public function new() 
	{
		protocol = ProtocolBase.makeProtocol("ProtocolSource", []);
	}
	
	public function fill(buff : Bytes, pos : Int, len : Int)
	{
		protocol.fill(buff, pos, len);
		return;
	}
}