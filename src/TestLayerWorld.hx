package;

import flash.system.System;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import net.hxpunk.World;

/**
 * ...
 * @author azrafe7
 */
class TestLayerWorld extends World
{

	public var images:Array<Text>;
	public var entities:Array<Entity>;
	public static inline var N:Int = 4;
	
	public function new() 
	{
		super();
	}
	
	override public function begin():Void {
		
		entities = new Array<Entity>();
		images = new Array<Text>();
		for (i in 0...N) {
			images[i] = new Text("layer xxx");
			images[i].setTextProperty("background", true);
			images[i].setTextProperty("backgroundColor", 0xFF000000 | HP.rand(0xFFFFFF));
			images[i].alpha = .75;
			entities[i] = new Entity(70 + 10 * i, 70 + 10 * i, images[i]);
			entities[i].layer = -i * 10;
			images[i].text = "Layer " + entities[i].layer;
		}
		
		addList(entities);
	}
	
	override public function update():Void 
	{
		super.update();
		
		// shuffle layers
		if (Input.pressed(Key.SPACE)) {
			for (i in 0...N) {
				var newLayer:Int = HP.rand(N+1) - N * 2;
				entities[i].layer = newLayer;
				images[i].text = "Layer " + newLayer;
			}
			
			var s:String = "";
			for (i in _renderFirst.keys()) s += i + ", ";
			trace(s);
		}
	}
	
	override public function render():Void 
	{
		super.render();
	}
}
