/**
 * ...
 * @author JB
 */

package bravo.playa.control;
import flash.events.Event;

class VolumeEvent extends Event
{
	public static var VOLUME_SET:String = "control.VolumeEvent.SET";
	
	public static var VOLUME_EVENT:String = "control.VolumeEvent.VOLUME_EVENT";
	
	public var eventType(default, null):String;
	public var volume(default, null):Float;

	public function new(inEventType:String, inVolume : Float, ?inBubble:Bool=true)
	{
		eventType = inEventType;
		volume = inVolume;
		super(inEventType, inBubble);
	}
}