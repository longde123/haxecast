/**
 * ...
 * @author JB
 */

package bravo.playa.control;
import flash.events.Event;

class PlayEvent extends Event
{
	public static var PLAY_STOP:String = "control.PlayEvent.STOP";
	public static var PLAY_START:String = "control.PlayEvent.PLAY";
	
	public static var PLAY_EVENT:String = "control.PlayEvent.PLAY_EVENT";
	
	public var eventType:String;

	public function new(inEventType:String, ?inBubble:Bool=true)
	{
		eventType = inEventType;
		super(inEventType, inBubble);
	}
}