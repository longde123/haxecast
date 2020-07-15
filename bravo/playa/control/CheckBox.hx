package bravo.playa.control;
import flash.display.GradientType;
import flash.display.InterpolationMethod;
import flash.display.SpreadMethod;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;

/**
 * ...
 * @author JB
 */

class CheckBoxEvent extends Event
{
	public static var SELECT:String = "control.CheckBoxEvent.SELECT";
	public static var DESELECT:String = "control.CheckBoxEvent.DESELECT";
	public static var CHANGE:String = "control.CheckBoxEvent.CHANGE";
	
	public var eventType:String;
	public var state : Bool;
	
	public function new(inEventType:String, inState : Bool, ?inBubble:Bool=true)
	{
		eventType = inEventType;
		state = inState;
		super(inEventType, inBubble);
	}
}

class CheckBox extends Sprite
{

	var state : Bool;
	var _size : Float;
	var normalAlpha : Null<Float>;
	var hoverAlpha : Null<Float>;
	var pressedAlpha : Null<Float>;
	
	public var colorOn : Null<Int>;
	public var colorOff : Null<Int>;
	var btn : Sprite;
	
	public function new(?inSize : Float = 12.0) 
	{
		state = false;
		_size = inSize;
		super();
		graphics.clear();
		graphics.beginFill(0x000000, 1.0);
		graphics.drawCircle(_size, _size, _size);
		graphics.endFill();
		if (colorOn == null) colorOn = 0x00ff00;
		if (colorOff == null) colorOff = 0xff0000;
		if (normalAlpha == null) normalAlpha = 0.7;
		if (hoverAlpha == null) hoverAlpha = 0.9;
		if (pressedAlpha == null) pressedAlpha = 1.0;
		addChild(btn = new Sprite());
		drawme(false, false);
		btn.addEventListener(MouseEvent.MOUSE_OVER, onOver);
		btn.addEventListener(MouseEvent.MOUSE_OUT, onOut);
		btn.addEventListener(MouseEvent.CLICK, onClick);
		btn.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		btn.addEventListener(MouseEvent.MOUSE_UP, onUp);
	}
	
	private function onOver(e:MouseEvent)
	{
		drawme(true, false);
	}
	
	private function onOut(e:MouseEvent)
	{
		drawme(false, false);
	}
	
	private function onDown(e:MouseEvent)
	{
		drawme(true, true);
	}
	
	private function onUp(e:MouseEvent)
	{
		drawme(true, false);
	}
	
	private function onClick(e:MouseEvent)
	{
		state = !state;
		drawme(true, false);
	}

	private function drawme(hover : Bool, down : Bool)
	{
		var clr = if (state) colorOn else colorOff;
		var mat : Matrix = new Matrix();
		mat.createGradientBox(_size * 2, _size * 2);
		if (down)
		{
			mat.translate( _size / 4, _size / 4);
		}
		else
		{
			mat.translate( -_size / 2, -_size / 2);
		}
		btn.alpha = if (hover) hoverAlpha else normalAlpha;
		if (down) btn.alpha = pressedAlpha;
		btn.graphics.clear();
		btn.graphics.lineStyle(0, 0, 0);
		if (down)
		{
			btn.graphics.beginGradientFill(GradientType.RADIAL, [ clr, clr ], [1, 1], [0, 255], mat, SpreadMethod.PAD, InterpolationMethod.RGB, 0.1);
		}
		else
		{
			btn.graphics.beginGradientFill(GradientType.RADIAL, [ 0xffffff, clr ], [1, 1], [0, 255], mat, SpreadMethod.PAD, InterpolationMethod.RGB, 0.1);
		}
		btn.graphics.drawCircle(_size, _size, _size-2);
		btn.graphics.endFill();
	}
}