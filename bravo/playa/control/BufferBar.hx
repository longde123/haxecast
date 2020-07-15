package bravo.playa.control;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.events.MouseEvent;

/**
 * ...
 * @author JB
 */

class BufferBar extends Sprite
{

	var bar : Sprite;
	var mat : Matrix;
	public static inline var ht : Float = 20;
	public function new(w : Float) 
	{
		super();
		mat = new Matrix();
		mat.createGradientBox(w, ht, Math.PI/2.0);
		graphics.lineStyle(0, 0x888888);
		graphics.beginGradientFill(GradientType.LINEAR, [0xcccccc, 0x888888, 0xcccccc], [1.0, 1.0, 1.0], [0, 127, 255], mat);
		graphics.drawRect(0, 0, w, ht);
		graphics.endFill();

		bar = new Sprite();
		setColor(0x888888, 0xcccccc);
		setPart(0.0);
		addChild(bar);
		alpha = 0.3;
		addEventListener(MouseEvent.MOUSE_OVER, do_MouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, do_MouseOut);
		
	}
	function do_MouseOver(e:MouseEvent)
	{
		alpha = 1.0;
	}
	
	function do_MouseOut(e:MouseEvent)
	{
		alpha = 0.3;
	}
	public function setColor(c : Int, m : Int)
	{
		
		bar.graphics.lineStyle(0, c);
		bar.graphics.beginGradientFill(GradientType.LINEAR, [c, m, c], [1.0, 1.0, 1.0], [0, 127, 255], mat);
		bar.graphics.drawRect(0, 0, width, ht);
		bar.graphics.endFill();
	}
	public function setPart(p : Float)
	{
		bar.width = width * p;
	}
}