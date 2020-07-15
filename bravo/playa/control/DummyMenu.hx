package bravo.playa.control;

/**
 * ...
 * @author JB
 */

import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;

class DummyMenu
{
	static inline var VERSION_MAJOR : UInt = 1;
	static inline var VERSION_MINOR : UInt = 2;
	static inline var VERSION_REL : UInt = 1;
	static inline function VERSION() : String return Std.string(VERSION_MAJOR) + '.' + Std.string(VERSION_MINOR) + '.' + Std.string(VERSION_REL)

	public var menu(default, null) : ContextMenu;
	
	public function new(cap : String, ?hide : Bool = true)
	{
		menu = new ContextMenu();
		if(hide)
			menu.hideBuiltInItems();
		menu.customItems.push(new ContextMenuItem(cap + ' (c) 2011 PCGraFix : ' + VERSION(), false, false, true));
	}
}

