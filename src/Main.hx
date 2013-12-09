package ;

import flash.display.BitmapData;
import flash.events.KeyboardEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFormatAlign;
import flash.utils.ByteArray;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.Utf8;
import net.hxpunk.debug.Console;
import net.hxpunk.Engine;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Backdrop;
import net.hxpunk.graphics.Emitter;
import net.hxpunk.graphics.Image;
import net.hxpunk.graphics.ParticleType;
import net.hxpunk.graphics.PreRotation;
import net.hxpunk.graphics.Text;
import net.hxpunk.graphics.TiledImage;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Grid;
import net.hxpunk.masks.Pixelmask;
import net.hxpunk.Sfx;
import net.hxpunk.utils.Data;
import net.hxpunk.utils.Draw;
import net.hxpunk.utils.Ease;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import openfl.Assets;
import openfl.display.FPS;
import net.hxpunk.graphics.BitmapFont;
import net.hxpunk.graphics.BitmapText;



/**
 * ...
 * @author azrafe7
 */

class Main extends Engine
{
	
    public function new() {
        super(320, 240, 60, false);
    }
	
    override public function init():Void {
        super.init();
		HP.screen.scale = 2;
        HP.console.enable();

		trace(HP.NAME + " is running!");
		
		HP.world = new TestLayerWorld();
	}
		
	override public function update():Void 
	{
		super.update();
		
		// ESC to exit
		if (Input.pressed(Key.ESCAPE)) {
		#if web
			System.exit(0);
		#else
			Sys.exit(0);
		#end
		}
		
		// R to reset the world
		if (Input.pressed(Key.R)) {
			HP.world.removeAll();
			var worldClass = Type.getClass(HP.world);
			HP.world = Type.createInstance(worldClass, []);
		}	
		
	}
	
	override public function render():Void 
	{
		super.render();
		
	}
}
