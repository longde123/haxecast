/**
 * ...
 * @author JB
 */

package bravo.shout.engine;

import flash.errors.IOError;
import flash.events.Event;
import flash.net.Socket;

class SocketConnection extends Socket
{
	var _resource:String;
	var _uvox : Bool;
	
	public function new(host : String, port : UInt, resource : String, ?uvox : Bool = false)
	{
		super();
		_resource = resource;
		_uvox = uvox;
		addEventListener(Event.CONNECT, connectHandler);
	}

	private function connectHandler(event:Event) : Void 
	{
		removeEventListener(Event.CONNECT, connectHandler);
		writeUTFBytes("GET /" + _resource + " HTTP/1.0\r\n" +
			"User-Agent: Flash Player/10.1" + (_uvox ? ", Ultravox/2.1" : "") + "\r\n" +
			//"User-Agent: WinampMPEG/5.58\r\n" +
			"Icy-MetaData:1\r\n" +
			"\r\n"				
		);
		flush();
	}
}