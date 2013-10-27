package ;

import flash.system.System;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Image;
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
		
    }
	
	override public function update():Void 
	{
		super.update();
		
		if (Input.pressed(Key.ESCAPE)) {
			System.exit(1);
		}
		
	}
	
    public static function main() { 
		new Main(); 
	}
}
