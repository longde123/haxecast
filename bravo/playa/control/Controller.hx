package bravo.playa.control;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;

/**
 * ...
 * @author JB
 */

class Controller extends Sprite
{

	var btn(default, null) : PlayButton;
	public var theVolume(default, null) : Float;
	public var bufferbar(default, null) : BufferBar;
	var volume(default, null) : Volume;
	
	public function new(w : Float, h:Float) 
	{
		super();
		graphics.lineStyle(0, 0, 0);
		graphics.beginFill(0x0, 0.5);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		bufferbar = new BufferBar(w);
		addChild(bufferbar);
		addChild(volume = new Volume(w - 20, 0, 20, h, volcb));
		bufferbar.y = h - BufferBar.ht;
		bufferbar.x = 0;
		bufferbar.setPart(1.0);
		volume.alpha = 0.9;
		btn = new PlayButton(true);
		addChild(btn);
		btn.x = (w - btn.width) / 2;
		btn.y = (h - btn.height) / 2;
	}

	static var div = -3.0;

	function volcb(vol : Float)
	{
		if (vol > 1.0) 
		{
			vol = 1.0;
		}
		else if (vol < 0.00)
		{
			vol = 0.0;
		}
		theVolume = vol;
		dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_SET, vol));
	}
	public function setVolume(v : Float)
	{
		volcb(v);
		volume.setPlay(theVolume);
	}
	
	public function setColor(c1 : Int, c2 : Int)
	{
		bufferbar.setColor(c1, c2);
	}
	
	public function setPart(p : Float)
	{
		bufferbar.setPart(p);
	}
}