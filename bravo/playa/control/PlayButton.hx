package bravo.playa.control;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
/**
 * ...
 * @author JB
 */

@:bitmap("../../../Lib/bravo/playa/control/play.png") class PlayBitmap extends BitmapData { }
@:bitmap("../../../Lib/bravo/playa/control/pause.png") class PauseBitmap extends BitmapData { }

class PlayButton extends Sprite
{

	var btnmode : Bool;
	var Play : Bitmap;
	var Pause : Bitmap;
	
	public function new(?isPlaying : Bool = true) 
	{
		super();
		
		var Playd = new PlayBitmap(0,0);
		var Paused = new PauseBitmap(0,0);
		
		Play = new Bitmap(Playd);
		Pause = new Bitmap(Paused);
		btnmode = !isPlaying;
		alpha = 0.3;
		
		addChild(Play);
		addChild(Pause);
		mouseEnabled = true;
		addEventListener(MouseEvent.MOUSE_OVER, do_MouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, do_MouseOut);
		addEventListener(MouseEvent.CLICK, clicker);
		Play.visible = btnmode;
		Pause.visible = !btnmode;
	}
	
	function do_MouseOver(e:MouseEvent)
	{
		alpha = 1.0;
	}
	
	function do_MouseOut(e:MouseEvent)
	{
		alpha = 0.3;
	}
	
	function clicker(e:MouseEvent)
	{
		btnmode = !btnmode;
		Play.visible = btnmode;
		Pause.visible = !btnmode;
		dispatchEvent(new PlayEvent(if(btnmode) PlayEvent.PLAY_STOP else PlayEvent.PLAY_START, true));
	}
}