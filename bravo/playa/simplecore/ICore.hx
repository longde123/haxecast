package bravo.playa.simplecore;

/**
 * ...
 * @author JB
 */

enum ConnectState
{
	SOCKET_OPEN;
	SOCKET_FAIL;
	URL_OPEN;
	URL_FAIL;
}

typedef VideoParameters =
{
	var width : Int;
	var height : Int;
	var rate : Float;
	var flip : Bool;
}
typedef VideoNetstream =
{
	var netstream : flash.net.NetStream;
}
typedef BufferStatus =
{
	var bufferLength : Float;
	var bufferTime : Float;
}

interface ICore
{
	public function init();
	public function setSongName(name : String)
	public function setSongUrl(name : String)
	public function setStreamTitle(name:String)
	public function bufferStatus(o : BufferStatus)
	public function connectState(state:ConnectState)
	public function videoOn(params : VideoParameters)
	public function videoStream(params : VideoNetstream)
}