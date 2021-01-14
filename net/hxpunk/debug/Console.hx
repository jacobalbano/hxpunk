package net.hxpunk.debug;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import net.hxpunk.Entity;
import net.hxpunk.graphics.Text;
import net.hxpunk.HP;
import net.hxpunk.utils.Input;
import net.hxpunk.utils.Key;
import openfl.Assets;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_DEBUG;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_LOGO;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_OUTPUT;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_PAUSE;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_PLAY;
import net.hxpunk.debug.Console._EMBEDDED_CONSOLE_STEP;


/**
 * FlashPunk debug console; can use to log information or pause the game and view/move Entities and step the frame.
 */
@:access(net.hxpunk.HP)		// access HP class private members
class Console
{
	/**
	 * The key used to toggle the Console on/off. Tilde (~) by default.
	 */
	public var toggleKey:Int = 192;
	
	/**
	 * Constructor.
	 */
	public function new() 
	{
		initVars();
		
		Input.define(ARROW_KEYS, [Key.RIGHT, Key.LEFT, Key.DOWN, Key.UP]);
	}
	
	private inline function initVars():Void 
	{
		// Console display objects.
		_sprite = new Sprite();
		if (HP.defaultFont == null) HP.defaultFont = Assets.getFont(HP.defaultFontName);
		_format = new TextFormat(HP.defaultFont.fontName);
		_back = new Bitmap();
		
		// FPS panel information.
		_fpsRead = new Sprite();
		_fpsReadText = new TextField();
		_fpsInfo = new Sprite();
		_fpsInfoText0 = new TextField();
		_fpsInfoText1 = new TextField();
		_memReadText = new TextField();
		
		// Output panel information.
		_logRead = new Sprite();
		_logReadText0 = new TextField();
		_logReadText1 = new TextField();
		
		// Entity count panel information.
		_entRead = new Sprite();
		_entReadText = new TextField();
		
		// Debug panel information.
		_debRead = new Sprite();
		_debReadText0 = new TextField();
		_debReadText1 = new TextField();

		// Button panel information
		_butRead = new Sprite();
		
		// Entity selection information.
		_entScreen = new Sprite();
		_entSelect = new Sprite();
		_entRect = new Rectangle();
		
		// Log information.
		LOG = new Array<String>();
		
		// Entity lists.
		ENTITY_LIST = new Array<Entity>();
		SCREEN_LIST = new Array<Entity>();
		SELECT_LIST = new Array<Entity>();
		
		// Watch information.
		WATCH_LIST = ["x", "y"];
		
		// Embedded assets.
		CONSOLE_LOGO = new _EMBEDDED_CONSOLE_LOGO(0, 0);
		CONSOLE_DEBUG = new _EMBEDDED_CONSOLE_DEBUG(0, 0);
		CONSOLE_OUTPUT = new _EMBEDDED_CONSOLE_OUTPUT(0, 0);
		CONSOLE_PLAY = new _EMBEDDED_CONSOLE_PLAY(0, 0);
		CONSOLE_PAUSE = new _EMBEDDED_CONSOLE_PAUSE(0, 0);
		CONSOLE_STEP = new _EMBEDDED_CONSOLE_STEP(0, 0);
	}
	
	
	/**
	 * Logs data to the console.
	 * @param	data The data parameters to log, can be variables, objects, etc. Parameters will be separated by a space (" ").
	 */
	public var log(get, null):Dynamic;
	private inline function get_log()
	{
		return Reflect.makeVarArgs(_log);
	}
	private inline function _log(data:Array<Dynamic>)
	{
		var s:String = "";
		
		// Iterate through data to build a string.
		for (i in 0...data.length)
		{
			if (i > 0) s += " ";
			s += (data[i] != null) ? Std.string(data[i]) : "null";
		}
		
		// Replace newlines with multiple log statements.
		if (s.indexOf("\n") >= 0)
		{
			var a:Array<String> = s.split("\n");
			for (s in a) LOG.push(s);
		}
		else
		{
			LOG.push(s);
		}
		
		// If the log is running, update it.
		if (_enabled && _sprite.visible) updateLog();
	}
	
	/**
	 * Adds properties to watch in the console's debug panel.
	 * @param	properties		The properties (strings) to watch.
	 */
	public var watch(get, null):Dynamic;
	private inline function get_watch()
	{
		return Reflect.makeVarArgs(_watch);
	}
	private inline function _watch(properties:Array<Dynamic>)
	{
		var i:String;
		if (properties.length > 1)
		{
			for (i in properties) WATCH_LIST.push(i);
		}
		else WATCH_LIST.push(properties[0]);
	}
	
	/**
	 * Enables the console.
	 */
	public function enable():Void
	{
		// Quit if the console is already enabled.
		if (_enabled) return;
		
		// Enable it and add the Sprite to the stage.
		_enabled = true;
		HP.engine.addChild(_sprite);
		
		// Used to determine some text sizing.
		var big:Bool = width >= BIG_WIDTH_THRESHOLD;
		
		// The transparent FlashPunk logo overlay bitmap.
		_sprite.addChild(_back);
		_back.bitmapData = new BitmapData(width, height, true, 0xFFFFFFFF);
		var b:BitmapData = CONSOLE_LOGO;
		HP.matrix.identity();
		HP.matrix.tx = Math.max((_back.bitmapData.width - b.width) / 2, 0);
		HP.matrix.ty = Math.max((_back.bitmapData.height - b.height) / 2, 0);
		HP.matrix.scale(Math.min(width / _back.bitmapData.width, 1), Math.min(height / _back.bitmapData.height, 1));
		_back.bitmapData.draw(b, HP.matrix, null, BlendMode.MULTIPLY);
		_back.bitmapData.draw(_back.bitmapData, null, null, BlendMode.INVERT);
		_back.bitmapData.colorTransform(_back.bitmapData.rect, new ColorTransform(1, 1, 1, 0.5));
		
		// The entity and selection sprites.
		_sprite.addChild(_entScreen);
		_entScreen.addChild(_entSelect);
		
		// The entity count text.
		_sprite.addChild(_entRead);
		_entRead.addChild(_entReadText);
		_entReadText.defaultTextFormat = format(16, 0xFFFFFF, TextFormatAlign.RIGHT);
		_entReadText.embedFonts = true;
		_entReadText.width = 100;
		_entReadText.height = 20;
		_entRead.x = width - _entReadText.width;
		
		// The entity count panel.
		_entRead.graphics.clear();
		_entRead.graphics.beginFill(0, .5);
	#if flash
		_entRead.graphics.drawRoundRectComplex(0, 0, _entReadText.width, 20, 0, 0, 20, 0);
	#else
		_entRead.graphics.drawRoundRect(0, -20, _entReadText.width + 20, 40, 40, 40);
	#end
		
		// The FPS text.
		_sprite.addChild(_fpsRead);
		_fpsRead.addChild(_fpsReadText);
		_fpsReadText.defaultTextFormat = format(16);
		_fpsReadText.embedFonts = true;
		_fpsReadText.width = 70;
		_fpsReadText.height = 20;
		_fpsReadText.x = 2;
		_fpsReadText.y = 1;
		
		// The FPS and frame timing panel.
		_fpsRead.graphics.clear();
		_fpsRead.graphics.beginFill(0, .75);
	#if flash
		_fpsRead.graphics.drawRoundRectComplex(0, 0, big ? 320 : 160, 20, 0, 0, 0, 20);
	#else
		_fpsRead.graphics.drawRoundRect(-20, -20, big ? 320 + 20 : 160 + 20, 40, 40, 40);
	#end
		
		// The frame timing text.
		if (big) _sprite.addChild(_fpsInfo);
		_fpsInfo.addChild(_fpsInfoText0);
		_fpsInfo.addChild(_fpsInfoText1);
		_fpsInfoText0.defaultTextFormat = format(8, 0xAAAAAA);
		_fpsInfoText1.defaultTextFormat = format(8, 0xAAAAAA);
		_fpsInfoText0.embedFonts = true;
		_fpsInfoText1.embedFonts = true;
		_fpsInfoText0.width = _fpsInfoText1.width = 60;
		_fpsInfoText0.height = _fpsInfoText1.height = 20;
		_fpsInfo.x = 75;
		_fpsInfoText1.x = 60;
		_fpsInfo.width = _fpsInfoText0.width + _fpsInfoText1.width;
		
		// The memory usage
		_fpsRead.addChild(_memReadText);
		_memReadText.defaultTextFormat = format(16);
		_memReadText.embedFonts = true;
		_memReadText.width = 110;
		_memReadText.height = 20;
		_memReadText.x = (big) ? _fpsInfo.x + _fpsInfoText0.width + _fpsInfoText1.width + 5 : _fpsInfo.x + 9;
		_memReadText.y = 1;
		
		// The output log text.
		_sprite.addChild(_logRead);
		_logRead.addChild(_logReadText0);
		_logRead.addChild(_logReadText1);
		_logReadText0.defaultTextFormat = format(16, 0xFFFFFF);
		_logReadText1.defaultTextFormat = format(big ? 16 : 8, 0xFFFFFF);
		_logReadText0.embedFonts = true;
		_logReadText1.embedFonts = true;
		_logReadText0.selectable = false;
		_logReadText0.width = 80;
		_logReadText0.height = 20;
		_logReadText1.width = width;
		_logReadText0.x = 2;
		_logReadText0.y = 3;
		_logReadText0.text = "OUTPUT:";
		_logHeight = height - 60;
		_logBar = new Rectangle(8, 24, 16, _logHeight - 8);
		_logBarGlobal = _logBar.clone();
		_logBarGlobal.y += 40;
		if (big) _logLines = Std.int(_logHeight / 16.5);
		else _logLines = Std.int(_logHeight / 8.5);
		
		// The debug text.
		_sprite.addChild(_debRead);
		_debRead.addChild(_debReadText0);
		_debRead.addChild(_debReadText1);
		_debReadText0.defaultTextFormat = format(16, 0xFFFFFF);
		_debReadText1.defaultTextFormat = format(8, 0xFFFFFF);
		_debReadText0.embedFonts = true;
		_debReadText1.embedFonts = true;
		_debReadText0.selectable = false;
		_debReadText0.width = 80;
		_debReadText0.height = 20;
		_debReadText1.width = 160;
		_debReadText1.height = Std.int(height / 4);
		_debReadText0.x = 2;
		_debReadText0.y = 3;
		_debReadText1.x = 2;
		_debReadText1.y = 24;
		_debReadText0.text = "DEBUG:";
		_debRead.y = height - (_debReadText1.y + _debReadText1.height);
		
		// The button panel buttons.
		_sprite.addChild(_butRead);
		_butRead.addChild(_butDebug = new Bitmap(CONSOLE_DEBUG));
		_butRead.addChild(_butOutput = new Bitmap(CONSOLE_OUTPUT));
		_butRead.addChild(_butPlay = new Bitmap(CONSOLE_PLAY)).x = 20;
		_butRead.addChild(_butPause = new Bitmap(CONSOLE_PAUSE)).x = 20;
		_butRead.addChild(_butStep = new Bitmap(CONSOLE_STEP)).x = 40;
		updateButtons();
		
		// The button panel.
		_butRead.graphics.clear();
		_butRead.graphics.beginFill(0, .75);
	#if flash
		_butRead.graphics.drawRoundRectComplex( -20, 0, 100, 20, 0, 0, 20, 20);
	#else
		_butRead.graphics.drawRoundRect( -20, -20, 100, 40, 40, 40);
	#end
		
		// Default the display to debug view
		debug = true;
		
		// Set the state to unpaused.
		paused = false;
		
		// Show version info
		log(HP.NAME + " " + HP.VERSION);
	}
	
	/**
	 * If the console should be visible.
	 */
	public var visible(get, set):Bool;
	private inline function get_visible() { return _sprite.visible; }
	private function set_visible(value:Bool):Bool
	{
		_sprite.visible = value;
		if (_enabled && value) updateLog();
		return value;
	}
	
	/**
	 * Console update, called by game loop.
	 */
	public function update():Void
	{
		// Quit if the console isn't enabled.
		if (!_enabled) return;
		
		// If the console is paused.
		if (_paused)
		{
			// Update buttons.
			updateButtons();
			
			// While in debug mode.
			if (_debug)
			{
				// While the game is paused.
				if (HP.engine.paused)
				{
					// When the mouse is pressed.
					if (Input.mousePressed)
					{
						// Mouse is within clickable area.
						if (Input.mouseFlashY > 20 && (Input.mouseFlashX > _debReadText1.width || Input.mouseFlashY < _debRead.y))
						{
							if (Input.check(Key.SHIFT))
							{
								if (SELECT_LIST.length > 0) startDragging();
								else startPanning();
							}
							else startSelection();
						}
					}
					else
					{
						// Update mouse movement functions.
						if (_selecting) updateSelection();
						if (_dragging) updateDragging();
						if (_panning) updatePanning();
					}
					
					// Select all Entities
					if (Input.pressed(Key.A)) selectAll();
					
					// If the shift key is held.
					if (Input.check(Key.SHIFT))
					{
						// If Entities are selected.
						if (SELECT_LIST.length > 0)
						{
							// Move Entities with the arrow keys.
							if (Input.pressed(Console.ARROW_KEYS)) updateKeyMoving();
						}
						else
						{
							// Pan the camera with the arrow keys.
							if (Input.check(Console.ARROW_KEYS)) updateKeyPanning();
						}
					}
				}
				else
				{
					// Update info while the game runs.
					updateEntityLists(HP.world.count != ENTITY_LIST.length);
					renderEntities();
					updateFPSRead();
					updateEntityCount();
				}
				
				// Update debug panel.
				updateDebugRead();
			}
			else
			{
				// log scrollbar
				if (_scrolling) updateScrolling();
				else if (Input.mousePressed) startScrolling();
			}
		}
		else
		{
			// Update info while the game runs.
			updateFPSRead();
			updateEntityCount();
		}
		
		// Console toggle.
		if (Input.pressed(toggleKey)) paused = !_paused;
	}
	
	/**
	 * If the Console is currently in paused mode.
	 */
	public var paused(get, set):Bool;
	private inline function get_paused() { return _paused; }
	private function set_paused(value:Bool):Bool
	{
		// Quit if the console isn't enabled.
		if (_enabled) {
		
			// Set the console to paused.
			_paused = value;
			HP.engine.paused = value;
			
			// Panel visibility.
			_back.visible = value;
			_entScreen.visible = value;
			_butRead.visible = value;
			
			// If the console is paused.
			if (value)
			{
				// Set the console to paused mode.
				if (_debug) debug = true;
				else updateLog();
			}
			else
			{
				// Set the console to running mode.
				_debRead.visible = false;
				_logRead.visible = true;
				updateLog();
			
				HP.removeAll(ENTITY_LIST);
				HP.removeAll(SCREEN_LIST);
				HP.removeAll(SELECT_LIST);
			}
		}
		return value;
	}
	
	/**
	 * If the Console is currently in debug mode.
	 */
	public var debug(get, set):Bool;
	private inline function get_debug() { return _debug; }
	private function set_debug(value:Bool):Bool
	{
		// Quit if the console isn't enabled.
		if (_enabled) {
			
			// Set the console to debug mode.
			_debug = value;
			_debRead.visible = value;
			_logRead.visible = !value;
			
			// Update console state.
			if (value) updateEntityLists();
			else updateLog();
			renderEntities();
		}
		return value;
	}
	
	/** Steps the frame ahead. */
	private function stepFrame():Void
	{
		HP.engine.update();
		HP.engine.render();
		updateEntityCount();
		updateEntityLists();
		renderEntities();
	}
	
	/** Starts Entity dragging. */
	private function startDragging():Void
	{
		_dragging = true;
		_entRect.x = Input.mouseX;
		_entRect.y = Input.mouseY;
	}
	
	/** Updates Entity dragging. */
	private function updateDragging():Void
	{
		moveSelected(Std.int(Input.mouseX - _entRect.x), Std.int(Input.mouseY - _entRect.y));
		_entRect.x = Input.mouseX;
		_entRect.y = Input.mouseY;
		if (Input.mouseReleased) _dragging = false;
	}
	
	/** Move the selected Entities by the amount. */
	private function moveSelected(xDelta:Int, yDelta:Int):Void
	{
		for (e in SELECT_LIST)
		{
			e.x += xDelta;
			e.y += yDelta;
		}
		HP.engine.render();
		renderEntities();
		updateEntityLists(true);
	}
	
	/** Starts camera panning. */
	private function startPanning():Void
	{
		_panning = true;
		_entRect.x = Input.mouseX;
		_entRect.y = Input.mouseY;
	}
	
	/** Updates camera panning. */
	private function updatePanning():Void
	{
		if (Input.mouseReleased) _panning = false;
		panCamera(Std.int(_entRect.x - Input.mouseX), Std.int(_entRect.y - Input.mouseY));
		_entRect.x = Input.mouseX;
		_entRect.y = Input.mouseY;
	}
	
	/** Pans the camera. */
	private function panCamera(xDelta:Int, yDelta:Int):Void
	{
		HP.camera.x += xDelta;
		HP.camera.y += yDelta;
		HP.engine.render();
		updateEntityLists(true);
		renderEntities();
	}
	
	/** Sets the camera position. */
	private function setCamera(x:Int, y:Int):Void
	{
		HP.camera.x = x;
		HP.camera.y = y;
		HP.engine.render();
		updateEntityLists(true);
		renderEntities();
	}
	
	/** Starts Entity selection. */
	private function startSelection():Void
	{
		_selecting = true;
		_entRect.x = Input.mouseFlashX;
		_entRect.y = Input.mouseFlashY;
		_entRect.width = 0;
		_entRect.height = 0;
	}
	
	/** Updates Entity selection. */
	private function updateSelection():Void
	{
		_entRect.width = Input.mouseFlashX - _entRect.x;
		_entRect.height = Input.mouseFlashY - _entRect.y;
		if (Input.mouseReleased)
		{
			selectEntities(_entRect);
			renderEntities();
			_selecting = false;
			_entSelect.graphics.clear();
		}
		else
		{
			_entSelect.graphics.clear();
			_entSelect.graphics.lineStyle(1, 0xFFFFFF);
			_entSelect.graphics.drawRect(_entRect.x, _entRect.y, _entRect.width, _entRect.height);
		}
	}
	
	/** Selects the Entities in the rectangle. */
	private function selectEntities(rect:Rectangle):Void
	{
		if (rect.width < 0) rect.x -= (rect.width = -rect.width);
		else if (rect.width <= 0) rect.width = 1;
		if (rect.height < 0) rect.y -= (rect.height = -rect.height);
		else if (rect.height <= 0) rect.height = 1;
		
		HP.rect.width = HP.rect.height = 6;
		var sx:Float = HP.screen.scaleX * HP.screen.scale,
			sy:Float = HP.screen.scaleY * HP.screen.scale,
			e:Entity;
			
		if (Input.check(Key.CONTROL))
		{
			// Append selected Entities with new selections.
			for (e in SCREEN_LIST)
			{
				var i:Int = SELECT_LIST.length;
				while (i-- >= 0) if (SELECT_LIST[i] == e) break;
				if (i < 0)
				{
					HP.rect.x = (e.x - HP.camera.x) * sx - 3;
					HP.rect.y = (e.y - HP.camera.y) * sy - 3;
					if (rect.intersects(HP.rect)) SELECT_LIST.push(e);
				}
			}
		}
		else
		{
			// Replace selections with new selections.
			HP.removeAll(SELECT_LIST);
			
			for (e in SCREEN_LIST)
			{
				HP.rect.x = (e.x - HP.camera.x) * sx - 3;
				HP.rect.y = (e.y - HP.camera.y) * sy - 3;
				if (rect.intersects(HP.rect)) SELECT_LIST.push(e);
			}
		}
	}
	
	/** Selects all entities on screen. */
	private function selectAll():Void
	{
		HP.removeAll(SELECT_LIST);
		
		for (e in SCREEN_LIST) SELECT_LIST.push(e);
		renderEntities();
	}
	
	/** Starts log text scrolling. */
	private function startScrolling():Void
	{
		if (LOG.length > _logLines) _scrolling = _logBarGlobal.contains(Input.mouseFlashX, Input.mouseFlashY);
	}
	
	/** Updates log text scrolling. */
	private function updateScrolling():Void
	{
		_scrolling = Input.mouseDown;
		_logScroll = HP.scaleClamp(Input.mouseFlashY, _logBarGlobal.y, _logBarGlobal.bottom, 0, 1);
		updateLog();
	}
	
	/** Moves Entities with the arrow keys. */
	private function updateKeyMoving():Void
	{
		HP.point.x = (Input.pressed(Key.RIGHT) ? 1 : 0) - (Input.pressed(Key.LEFT) ? 1 : 0);
		HP.point.y = (Input.pressed(Key.DOWN) ? 1 : 0) - (Input.pressed(Key.UP) ? 1 : 0);
		if (HP.point.x != 0 || HP.point.y != 0) moveSelected(Std.int(HP.point.x), Std.int(HP.point.y));
	}
	
	/** Pans the camera with the arrow keys. */
	private function updateKeyPanning():Void
	{
		HP.point.x = (Input.check(Key.RIGHT) ? 1 : 0) - (Input.check(Key.LEFT) ? 1 : 0);
		HP.point.y = (Input.check(Key.DOWN) ? 1 : 0) - (Input.check(Key.UP) ? 1 : 0);
		if (HP.point.x != 0 || HP.point.y != 0) panCamera(Std.int(HP.point.x), Std.int(HP.point.y));
	}
	
	/** Update the Entity list information. */
	private function updateEntityLists(fetchList:Bool = true):Void
	{
		// If the list should be re-populated.
		if (fetchList)
		{
			HP.removeAll(ENTITY_LIST);
			HP.world.getAll(ENTITY_LIST);
		}
		
		// Update the list of Entities on screen.
		HP.removeAll(SCREEN_LIST);
		for (e in ENTITY_LIST)
		{
			if (e.collideRect(e.x, e.y, HP.camera.x, HP.camera.y, HP.width, HP.height))
				SCREEN_LIST.push(e);
		}
	}
	
	/** Renders the Entities positions and hitboxes. */
	private function renderEntities():Void
	{
		// If debug mode is on.
		_entScreen.visible = _debug;
		if (_debug)
		{
			var g:Graphics = _entScreen.graphics,
				sx:Float = HP.screen.scaleX * HP.screen.scale,
				sy:Float = HP.screen.scaleY * HP.screen.scale;
			g.clear();
			for (e in SCREEN_LIST)
			{
				// If the Entity is not selected.
				var i:Int = SELECT_LIST.length;
				while (i-- >= 0) if (SELECT_LIST[i] == e) break;
				if (i < 0)
				{
					// Draw the normal hitbox and position.
					if (e.width > 0 && e.height > 0)
					{
						g.lineStyle(1, 0xFF0000);
						g.drawRect((e.x - e.originX - HP.camera.x) * sx, (e.y - e.originY - HP.camera.y) * sy, e.width * sx, e.height * sy);
						if (e.mask != null) e.mask.renderDebug(g);
					}
					g.lineStyle(1, 0x00FF00);
					g.drawRect((e.x - HP.camera.x) * sx - 3, (e.y - HP.camera.y) * sy - 3, 6, 6);
				}
				else
				{
					// Draw the selected hitbox and position.
					if (e.width > 0 && e.height > 0)
					{
						g.lineStyle(1, 0xFFFFFF);
						g.drawRect((e.x - e.originX - HP.camera.x) * sx, (e.y - e.originY - HP.camera.y) * sy, e.width * sx, e.height * sy);
						if (e.mask != null) e.mask.renderDebug(g);
					}
					g.lineStyle(1, 0xFFFFFF);
					g.drawRect((e.x - HP.camera.x) * sx - 3, (e.y - HP.camera.y) * sy - 3, 6, 6);
				}
			}
		}
	}
	
	/** Updates the log window. */
	private function updateLog():Void
	{
		// If the console is paused.
		if (_paused)
		{
			// Draw the log panel.
			_logRead.y = 40;
			_logRead.graphics.clear();
			_logRead.graphics.beginFill(0, .75);
		#if flash
			_logRead.graphics.drawRoundRectComplex(0, 0, _logReadText0.width, 20, 0, 20, 0, 0);
		#else
			_logRead.graphics.drawRect(0, 0, _logReadText0.width - 20, 20);
			_logRead.graphics.moveTo(_logReadText0.width, 20);
			_logRead.graphics.lineTo(_logReadText0.width - 20, 20);
			_logRead.graphics.lineTo(_logReadText0.width - 20, 0);
			_logRead.graphics.curveTo(_logReadText0.width, 0, _logReadText0.width, 20);
			
		#end
			_logRead.graphics.drawRect(0, 20, width, _logHeight);
			
			// Draw the log scrollbar.
			_logRead.graphics.beginFill(0x202020, 1);
		#if flash
			_logRead.graphics.drawRoundRectComplex(_logBar.x, _logBar.y, _logBar.width, _logBar.height, 8, 8, 8, 8);
		#else
			_logRead.graphics.drawRoundRect(_logBar.x, _logBar.y, _logBar.width, _logBar.height, 16, 16);
		#end
			
			// If the log has more lines than the display limit.
			if (LOG.length > _logLines)
			{
				// Draw the log scrollbar handle.
				_logRead.graphics.beginFill(0xFFFFFF, 1);
				var y:Int = Std.int(_logBar.y + 2 + (_logBar.height - 16) * _logScroll);
			#if flash
				_logRead.graphics.drawRoundRectComplex(_logBar.x + 2, y, 12, 12, 6, 6, 6, 6);
			#else
				_logRead.graphics.drawRoundRect(_logBar.x + 2, y, 12, 12, 12, 12);
			#end
			}
			
			// Display the log text lines.
			if (LOG.length > 0)
			{
				var i:Int = 0,
					n:Int = 0,
					s:String = "";
				
				if (LOG.length > _logLines) {
					i = Math.round((LOG.length - _logLines) * _logScroll);
				}
				
				n = Std.int(i + Math.min(_logLines, LOG.length));
					
				while (i < n) s += LOG[i ++] + "\n";
				_logReadText1.text = s;
			}
			else _logReadText1.text = "";
			
			// Indent the text for the scrollbar and size it to the log panel.
			_logReadText1.height = _logHeight;
			_logReadText1.x = 32;
			_logReadText1.y = 24;
			
			// Make text selectable in paused mode.
			_fpsReadText.selectable = true;
			_fpsInfoText0.selectable = true;
			_fpsInfoText1.selectable = true;
			_memReadText.selectable = true;
			_entReadText.selectable = true;
			_debReadText1.selectable = true;
		}
		else
		{
			// Draw the single-line log panel.
			_logRead.y = height - 40;
			_logReadText1.height = 20;
			_logRead.graphics.clear();
			_logRead.graphics.beginFill(0, .75);
		#if flash
			_logRead.graphics.drawRoundRectComplex(0, 0, _logReadText0.width, 20, 0, 20, 0, 0);
		#else
			_logRead.graphics.drawRect(0, 0, _logReadText0.width - 20, 20);
			_logRead.graphics.moveTo(_logReadText0.width, 20);
			_logRead.graphics.lineTo(_logReadText0.width - 20, 20);
			_logRead.graphics.lineTo(_logReadText0.width - 20, 0);
			_logRead.graphics.curveTo(_logReadText0.width, 0, _logReadText0.width, 20);
		#end
			_logRead.graphics.drawRect(0, 20, width, 20);
			
			// Draw the single-line log text with the latests logged text.
			_logReadText1.text = LOG.length > 0 ? LOG[LOG.length - 1] : "";
			_logReadText1.x = 2;
			_logReadText1.y = 21;
			
			// Make text non-selectable while running.
			_logReadText1.selectable = false;
			_fpsReadText.selectable = false;
			_fpsInfoText0.selectable = false;
			_fpsInfoText1.selectable = false;
			_memReadText.selectable = false;
			_entReadText.selectable = false;
			_debReadText0.selectable = false;
			_debReadText1.selectable = false;
		}
	}
	
	/** Update the FPS/frame timing panel text. */
	private function updateFPSRead():Void
	{
		_fpsReadText.text = "FPS: " + HP.toFixed(HP.frameRate, 0);
		_fpsInfoText0.text =
			"Update: " + Std.string(HP._updateTime) + "ms\n" + 
			"Render: " + Std.string(HP._renderTime) + "ms";
		_fpsInfoText1.text =
			"System: " + Std.string(HP._systemTime) + "ms\n" +
			"Logic: " + Std.string(HP._logicTime) + "ms";
		_memReadText.text = (width >= BIG_WIDTH_THRESHOLD ? "MEM: " : "") + HP.toFixed(System.totalMemory/1024/1024, 2) + "MB";
	}
	
	/** Update the debug panel text. */
	private function updateDebugRead():Void
	{
		// Find out the screen size and set the text.
		var big:Bool = width >= BIG_WIDTH_THRESHOLD;
		
		// Update the Debug read text.
		var s:String =
			"Mouse: " + Std.string(HP.world.mouseX) + ", " + Std.string(HP.world.mouseY) +
			"\nCamera: " + Std.string(HP.camera.x) + ", " + Std.string(HP.camera.y);
		if (SELECT_LIST.length > 0)
		{
			if (SELECT_LIST.length > 1)
			{
				s += "\n\nSelected: " + Std.string(SELECT_LIST.length);
			}
			else
			{
				var e:Entity = SELECT_LIST[0];
				s += "\n\n- " + Std.string(e) + " -\n";
				for (i in WATCH_LIST)
				{
					if (Reflect.hasField(e, i)) s += "\n" + i + ": " + Reflect.getProperty(e, i);
				}
			}
		}
		
		// Set the text and format.
		_debReadText1.text = s;
		_debReadText1.setTextFormat(format(big ? 16 : 8));
		_debReadText1.width = Math.max(_debReadText1.textWidth + 4, _debReadText0.width);
		_debReadText1.height = _debReadText1.y + _debReadText1.textHeight + 4;
		
		// The debug panel.
		_debRead.y = Std.int(height - _debReadText1.height);
		_debRead.graphics.clear();
		_debRead.graphics.beginFill(0, .75);
	#if flash
		_debRead.graphics.drawRoundRectComplex(0, 0, _debReadText0.width, 20, 0, 20, 0, 0);
		_debRead.graphics.drawRoundRectComplex(0, 20, _debReadText1.width + 20, height - _debRead.y - 20, 0, 20, 0, 0);
	#else
		_debRead.graphics.drawRect(0, 0, _debReadText0.width - 20, 20);
		_debRead.graphics.moveTo(_debReadText0.width, 20);
		_debRead.graphics.lineTo(_debReadText0.width - 20, 20);
		_debRead.graphics.lineTo(_debReadText0.width - 20, 0);
		_debRead.graphics.curveTo(_debReadText0.width, 0, _debReadText0.width, 20);
		_debRead.graphics.drawRoundRect(-20, 20, _debReadText1.width + 40, height - _debRead.y, 40, 40);
	#end
	}
	
	/** Updates the Entity count text. */
	private function updateEntityCount():Void
	{
		_entReadText.text = Std.string(HP.world.count) + " Entities";
	}
	
	/** Updates the Button panel. */
	private function updateButtons():Void
	{
		// Button visibility.
		_butRead.x = (width >= BIG_WIDTH_THRESHOLD ? _fpsInfo.x + _fpsInfoText0.width + _fpsInfoText1.width + Std.int((_entRead.x - (_fpsInfo.x + _fpsInfoText0.width + _fpsInfoText1.width)) / 2) - 30 : 160 + 20);
		_butDebug.visible = !_debug;
		_butOutput.visible = _debug;
		_butPlay.visible = HP.engine.paused;
		_butPause.visible = !HP.engine.paused;
		
		// Debug/Output button.
		if (_butDebug.bitmapData.rect.contains(_butDebug.mouseX, _butDebug.mouseY))
		{
			_butDebug.alpha = _butOutput.alpha = 1;
			if (Input.mousePressed) debug = !_debug;
		}
		else _butDebug.alpha = _butOutput.alpha = .5;
		
		// Play/Pause button.
		if (_butPlay.bitmapData.rect.contains(_butPlay.mouseX, _butPlay.mouseY))
		{
			_butPlay.alpha = _butPause.alpha = 1;
			if (Input.mousePressed)
			{
				HP.engine.paused = !HP.engine.paused;
				renderEntities();
			}
		}
		else _butPlay.alpha = _butPause.alpha = .5;
		
		// Frame step button.
		if (_butStep.bitmapData.rect.contains(_butStep.mouseX, _butStep.mouseY))
		{
			_butStep.alpha = 1;
			if (Input.mousePressed) stepFrame();
		}
		else _butStep.alpha = .5;
	}
	
	/** Gets a TextFormat object with the formatting. */
#if (flash || html5)
	private function format(size:Int = 16, color:Int = 0xFFFFFF, ?align:TextFormatAlign = null):TextFormat
#else
	private function format(size:Int = 16, color:Int = 0xFFFFFF, ?align:String = null):TextFormat
#end
	{
		if (align == null) align = TextFormatAlign.LEFT;
		_format.size = size;
		_format.color = color;
		_format.align = align;
		return _format;
	}
	
	/**
	 * Get the unscaled screen size for the Console.
	 */
	private var width(get, null):Int;
	private inline function get_width() { return Std.int(HP.width * HP.screen.scaleX * HP.screen.scale); }
	private var height(get, null):Int;
	private inline function get_height() { return Std.int(HP.height * HP.screen.scaleY * HP.screen.scale); }
	
	// Console state information.
	private var _enabled:Bool;
	private var _paused:Bool;
	private var _debug:Bool;
	private var _scrolling:Bool;
	private var _selecting:Bool;
	private var _dragging:Bool;
	private var _panning:Bool;
	
	// Console display objects.
	private var _sprite:Sprite;
	private var _format:TextFormat;
	private var _back:Bitmap;
	
	// FPS panel information.
	private var _fpsRead:Sprite;
	private var _fpsReadText:TextField;
	private var _fpsInfo:Sprite;
	private var _fpsInfoText0:TextField;
	private var _fpsInfoText1:TextField;
	private var _memReadText:TextField;
	
	// Output panel information.
	private var _logRead:Sprite;
	private var _logReadText0:TextField;
	private var _logReadText1:TextField;
	private var _logHeight:Int = 0;
	private var _logBar:Rectangle;
	private var _logBarGlobal:Rectangle;
	private var _logScroll:Float = 0;
	
	// Entity count panel information.
	private var _entRead:Sprite;
	private var _entReadText:TextField;
	
	// Debug panel information.
	private var _debRead:Sprite;
	private var _debReadText0:TextField;
	private var _debReadText1:TextField;

	// Button panel information
	private var _butRead:Sprite;
	private var _butDebug:Bitmap;
	private var _butOutput:Bitmap;
	private var _butPlay:Bitmap;
	private var _butPause:Bitmap;
	private var _butStep:Bitmap;
	
	// Entity selection information.
	private var _entScreen:Sprite;
	private var _entSelect:Sprite;
	private var _entRect:Rectangle;
	
	// Log information.
	private var _logLines:Int = 0;
	private var LOG:Array<String>;
	
	// Entity lists.
	private var ENTITY_LIST:Array<Entity>;
	private var SCREEN_LIST:Array<Entity>;
	private var SELECT_LIST:Array<Entity>;
	
	// Watch information.
	private var WATCH_LIST:Array<String>;
	
	// Embedded assets.
	private var CONSOLE_LOGO:BitmapData;
	private var CONSOLE_DEBUG:BitmapData;
	private var CONSOLE_OUTPUT:BitmapData;
	private var CONSOLE_PLAY:BitmapData;
	private var CONSOLE_PAUSE:BitmapData;
	private var CONSOLE_STEP:BitmapData;
	
	// Reference the Text class so we can access its embedded font
	private static var textRef:Text;

	// Switch to small text in debug if console width > this threshold
	private static inline var BIG_WIDTH_THRESHOLD:Int = 420;
	
	// Arrow keys define
	public static inline var ARROW_KEYS:String = "_ARROWS";
}

@:bitmap("net/hxpunk/assets/console_logo.png") class _EMBEDDED_CONSOLE_LOGO extends BitmapData {}
@:bitmap("net/hxpunk/assets/console_debug.png") class _EMBEDDED_CONSOLE_DEBUG extends BitmapData {}
@:bitmap("net/hxpunk/assets/console_output.png") class _EMBEDDED_CONSOLE_OUTPUT extends BitmapData {}
@:bitmap("net/hxpunk/assets/console_play.png") class _EMBEDDED_CONSOLE_PLAY extends BitmapData {}
@:bitmap("net/hxpunk/assets/console_pause.png") class _EMBEDDED_CONSOLE_PAUSE extends BitmapData {}
@:bitmap("net/hxpunk/assets/console_step.png") class _EMBEDDED_CONSOLE_STEP extends BitmapData {}
