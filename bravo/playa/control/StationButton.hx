package bravo.playa.control;
import flash.display.GradientType;
import flash.display.InterpolationMethod;
import flash.display.SpreadMethod;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

/**
 * ...
 * @author JB
 */

class StationButton extends Sprite
{

	var label : String;
	var txtfield : TextField;
	
	public function new(txt : String, fnt : String, embed : Bool, size : Float, clr : Int) 
	{
		super();
		buttonMode = true;
		useHandCursor = true;

		var tfmt = new TextFormat(fnt, size, clr);
		txtfield = new TextField();
		txtfield.embedFonts = embed;
		txtfield.defaultTextFormat = tfmt;
		txtfield.autoSize = TextFieldAutoSize.LEFT;
		txtfield.text = (label = txt);
		txtfield.mouseEnabled = false;
		var mat = new Matrix();
		mat.createGradientBox(txtfield.width + 10, txtfield.height + 10, Math.PI / 2);
		graphics.beginGradientFill(GradientType.LINEAR, [0x555555, 0x777777, 0x222222, 0x222222], [ 1.0, 1.0, 1.0, 1.0 ], [0, 127, 128, 255], mat, SpreadMethod.PAD,InterpolationMethod.LINEAR_RGB);
		graphics.drawRect(0, 0, txtfield.textWidth + 10, txtfield.textHeight + 10);
		graphics.endFill();
		addChild(txtfield);
		txtfield.x = (width - txtfield.textWidth) / 2;
		txtfield.y = (height - txtfield.height) / 2;
	}
	
}