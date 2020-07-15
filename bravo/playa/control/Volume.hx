/**
 * ...
 * @author JB
 */

package bravo.playa.control;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;

import flash.geom.Rectangle;

class Volume extends Sprite
{
	var progbutt : Sprite;
	var inDrag : Bool;
	var seekcb : Float->Void;
	var horizontal : Bool;
	
	public function new(iX:Float, iY:Float, iWidth:Float, iHeight:Float, iSeekCB:Float->Void, ?iHorz : Bool = false) 
	{
		super();
		graphics.lineStyle(0, 0, 0);
		graphics.beginFill(0xffffff, 1.0);
		graphics.drawRect(0, 0, iWidth, iHeight);
		graphics.endFill();
		x = iX;
		y = iY;
		horizontal = iHorz;
		seekcb = iSeekCB;
		
		graphics.lineStyle(0, 0, 0);
		graphics.beginFill(0x000000, 1.0);
		if (iHorz)
		{
			graphics.drawRoundRect(5, iHeight / 2 - 1, iWidth - 10, 3, 3);
		}
		else
		{
			graphics.drawRoundRect(iWidth / 2 - 1, 5, 3, iHeight - 10, 3);
		}
		
		progbutt = new Sprite();
		addChild(progbutt);
		progbutt.x = 0;
		progbutt.y = 0;
		progbutt.graphics.lineStyle(0, 0, 0);
		progbutt.graphics.beginFill(0x888888, 1.0);
		if (iHorz)
		{
			progbutt.graphics.drawRoundRect(0, 0, 10, iHeight - 2, 5);
			progbutt.x = 0;
			progbutt.y = 1;
		}
		else
		{
			progbutt.graphics.drawRoundRect(0, 0, iWidth - 2, 10, 5);
			progbutt.x = 1;
			progbutt.y = height - 10;
		}
		progbutt.graphics.endFill();
		
		progbutt.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		progbutt.addEventListener(MouseEvent.MOUSE_UP, onUp, false);
		//progbutt.addEventListener(MouseEvent.MOUSE_UP, onUp, true);
		addEventListener(MouseEvent.CLICK, onClick);
	}
	
	function onDown(e) 
	{
		if( e.currentTarget != e.target )
			return;
		inDrag = true;
		Lib.current.addEventListener(MouseEvent.MOUSE_UP, onUp, false, 1000);
		progbutt.addEventListener(MouseEvent.MOUSE_MOVE, onMove, false, 1000);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove, false, 1000);
		if(horizontal)
		{
			progbutt.startDrag(false, new Rectangle(0, 1, width-progbutt.width, 0));
		}
		else
		{
			progbutt.startDrag(false, new Rectangle(1, 0, 0, height-progbutt.height));
		}
	}

	function onUp(e) 
	{
		if ( inDrag ) 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove, false);
			progbutt.removeEventListener(MouseEvent.MOUSE_MOVE, onMove, false);
			progbutt.stopDrag();
			Lib.current.removeEventListener(MouseEvent.MOUSE_UP, onUp, false);
			if (horizontal)
			{
				seekcb((progbutt.x - x) / (width - progbutt.width));
			}
			else
			{
				seekcb(1.0 - (progbutt.y - y) / (height - progbutt.height));
			}
			inDrag = false;
		}
	}

	function onClick(e) 
	{
		if( e.currentTarget != e.target )
			return;
		if (!inDrag) 
		{
			if (horizontal)
			{
				seekcb((e.localX - x + progbutt.width / 2) / width);
				progbutt.x = e.localX;
			}
			else
			{
				seekcb(1.0 - (e.localY - y + progbutt.height / 2) / height);
				progbutt.y = e.localY;
			}
		}
	}

	function onMove(e) 
	{
		//if( e.currentTarget != e.target )
		//	return;
		if (inDrag) 
		{
			if (e.stageX > Lib.current.stage.stageWidth) 
			{ 
				onUp(e);
			}
			else if (e.stageX < 0) 
			{ 
				onUp(e);
			}
			else if (e.stageY > Lib.current.stage.stageHeight) 
			{ 
				onUp(e);
			}
			else if (e.stageY < 0) 
			{ 
				onUp(e);
			}
			else
			{
				if (horizontal)
				{
					seekcb((progbutt.x - x) / (width - progbutt.width));
				}
				else
				{
					seekcb(1.0 - (progbutt.y - y) / (height - progbutt.height));
				}
			}
		}
	}

	public function setPlay(perc : Float) 
	{
		//if (!inDrag)
		{
			if (horizontal)
			{
				progbutt.x = perc * (width - 10) - progbutt.width / 2;
			}
			else
			{
				progbutt.y = (1.0 - perc) * (height - 10) + progbutt.height / 2;
			}
		}
	}
}