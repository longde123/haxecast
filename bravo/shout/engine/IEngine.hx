/**
 * ...
 * @author JB
 */

package bravo.shout.engine;

import bravo.shout.codec.CodecEvent;
import bravo.shout.stream.StreamEvent;

interface IEngine 
{
	function go() : Void;
	function stop() : Void;
	function cleanup() : Void;
}