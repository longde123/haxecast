package bravo.playa.simplecore;

/**
 * ... External!!
 * @author JB
 */
import bravo.shout.flash.PlayerEvent;

enum ConnectState
{
	SOCKET_OPEN;
	SOCKET_FAIL;
	URL_OPEN;
	URL_FAIL;
}

extern class Core
{

	function new(inHost : String, inPort : UInt, inRes : String, ?inVideo : Bool = true) : Void;
	function doeng() : Void;
	function doPlay() : Void;
	function doStop() : Void;
	function doVolume(vol : Float) : Void;
	function cleanup() : Void;
	function init() : Void;
	function setSongName(name : String) : Void;
	function setSongUrl(name : String) : Void;
	function setStreamTitle(name:String) : Void;
	function bufferStatus(o : BufferStatus) : Void;
	function connectState(state:ConnectState) : Void;
	function videoOn(params : VideoParameters) : Void;
	function videoStream(params : VideoNetstream) : Void;
}