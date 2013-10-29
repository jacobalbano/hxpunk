package ;

import flash.system.System;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;


/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	private var e:Entity;
	var deltaScale:Float = -.1;

	
    public function new() {
        super(640, 480, 60, false);
    }
	
    override public function init():Void {
        super.init();
        HP.console.enable();
		
		trace("HXPunk is running!");
		
		var img:Image = Image.createRect(40, 40);
		img.centerOrigin();
		e = HP.world.addGraphic(img, 0, HP.halfWidth, HP.halfHeight);
		e.setHitboxTo(img);
		e.centerOrigin();
		img.angle = 45;
		
		
		
		HP.log(1, [1, 2, 3]);
		
		HP.world.addGraphic(new Text("ecciao", 100, 100));
    }
	
	override public function update():Void 
	{
		super.update();
		
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
		if (Input.check(Key.ANY)) e.x += HP.sign(Math.random() * 4 - 2) * Math.random() * 3;
		
		var img:Image = cast e.graphic;
		if (img.scale > 3 || img.scale < 0.5) deltaScale *= -1;
		img.scale += deltaScale;
	}
	
    public static function main() { 
		new Main(); 
	}
}
