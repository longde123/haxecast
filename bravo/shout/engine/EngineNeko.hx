/**
 * ...
 * @author JB
 */

 package bravo.shout.engine;

import bravo.shout.protocol.ProtocolBase;
import haxe.io.Bytes;

import neko.net.Host;
import neko.net.Socket;

class EngineNeko extends EngineBase, implements IEngine
{
	var sock : Socket;
	var _host : Host;
	var _port : Int;
	var totalBytesLoaded : Float;
	var _resource : String;
	var _uvox : Bool;
	public function new(host : String, port : Int, resource : String, ?uvox : Bool = false) 
	{
		super();
		_host = new Host(host);
		_port = port;
		_resource = resource;
		_uvox = uvox;
		totalBytesLoaded = 0.0;
	}
	
	public function stop()
	{
		
	}
	
	public function go()
	{
		sock = new Socket();
		sock.connect(_host, _port);
		sock.write(
			"GET /" + _resource + " HTTP/1.1\r\n" +
			//"HOST " + _host + ':' + _port + "\r\n" +
			"User-Agent: Neko/4.1" + (_uvox ? ", Ultravox/2.1" : '') + "\r\n" +
			//"Ultravox-transport-type: TCP\r\n"+
			"Accept: */*\r\n" +
			//"Icy-MetaData: 1\r\n" +
			"Connection: close\r\n" +
			"\r\n"
		);
		sock.waitForRead();
		setProtocol("ProtocolShoutcast", []);
		var tbuf = Bytes.alloc(1024);
		var cont = true;
		while (cont)
		{
			var len = 0;
			sock.waitForRead();
			try
			{
				len = sock.input.readBytes(tbuf, 0, 1024);
			}
			catch (e:Dynamic)
			{
				trace(e);
				cont = false;
			}
			totalBytesLoaded += len;
			protocol.fill(tbuf, 0, len);
		}
	}
}