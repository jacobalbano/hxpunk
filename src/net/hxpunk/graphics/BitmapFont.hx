package net.hxpunk.graphics;
import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.ds.IntMap.IntMap;
import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Utf8;
import net.hxpunk.HP;
import net.hxpunk.utils.Draw;


/**
 * Holds information and bitmap glyphs for a bitmap font.
 * 
 * Adapted from Beeblerox work (which built upon Pixelizer implementation).
 * 
 * @see https://github.com/Beeblerox/BitmapFont
 */
class BitmapFont 
{
	
	/**
	 * Creates a new bitmap font (if you pass valid parameters fromXML() is called).
	 * 
	 * Otherwise you can use one of the from_ methods to actually load the font from other formats.
	 * 
	 * Ex.:
	 *     var font = new BitmapFont(BM_DATA, XML_DATA);
	 *     // or
	 *     var font = new BitmapFont().fromPixelizer(BM_DATA2, GLYPHS);
	 *     // or
	 *     var font = new BitmapFont().fromSerialized(FONT_DATA);
	 * 
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	XMLData		Font data in XML format.
	 */
	public function new(?source:Dynamic = null, ?XMLData:Xml = null) 
	{
		if (_storedFonts == null) _storedFonts = new Map<String, BitmapFont>();
		
		_colorTransform = new ColorTransform();
		_glyphs = new IntMap<BitmapData>();
		
		if (source != null && XMLData != null) fromXML(source, XMLData);
	}
	
	/**
	 * Loads font data from Pixelizer's format.
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	letters		All letters (in sequential order) contained in this font.
	 * @return this BitmapFont
	 */
	public function fromPixelizer(source:Dynamic, letters:String):BitmapFont
	{
		reset();
		
		var bitmapData:BitmapData = HP.getBitmapData(source);
		if (bitmapData == null) throw new Error("Font source must be of type BitmapData, String or Class.");

		_glyphString = letters;
		
		var tileRects:Array<Rectangle> = [];
		var result:BitmapData = preparePixelizerBMD(bitmapData, tileRects);
		var currRect:Rectangle;
		
		for (letterID in 0...(tileRects.length))
		{
			currRect = tileRects[letterID];
			
			// create glyph
			var bd:BitmapData = new BitmapData(Math.floor(currRect.width), Math.floor(currRect.height), true, 0x0);
			bd.copyPixels(bitmapData, currRect, HP.zero, null, null, true);
			
			// store glyph
			setGlyph(_glyphString.charCodeAt(letterID), bd);
		}
		
		return this;
	}
	
	/**
	 * Loads font data from XML (AngelCode's) format.
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	XMLData		Font data in XML format.
	 * @return	this BitmapFont.
	 */
	public function fromXML(source:Dynamic, XMLData:Xml):BitmapFont
	{
		reset();
		
		var bitmapData:BitmapData = HP.getBitmapData(source);
		if (bitmapData == null) throw new Error("Font source must be of type BitmapData, String or Class.");

		_glyphString = "";
		
		var rect:Rectangle = new Rectangle();
		var point:Point = new Point();
		var bd:BitmapData;
		var letterID:Int = 0;
		var charCode:Int;
		var charString:String;
		
		var chars:Xml = null;
		for (node in XMLData.elements())
		{
			if (node.nodeName == "font")
			{
				for (nodeChild in node.elements())
				{
					if (nodeChild.nodeName == "chars")
					{
						chars = nodeChild;
						break;
					}
				}
			}
		}
		
		if (chars != null)
		{
			for (node in chars.elements())
			{
				if (node.nodeName == "char")
				{
					rect.x = Std.parseInt(node.get("x"));
					rect.y = Std.parseInt(node.get("y"));
					rect.width = Std.parseInt(node.get("width"));
					rect.height = Std.parseInt(node.get("height"));
					
					point.x = Std.parseInt(node.get("xoffset"));
					point.y = Std.parseInt(node.get("yoffset"));
					
					charCode = Std.parseInt(node.get("id"));
					charString = String.fromCharCode(charCode);
					_glyphString += charString;
					
					var xadvance:Int = Std.parseInt(node.get("xadvance"));
					var charWidth:Int = xadvance;
					
					if (rect.width > xadvance)
					{
						charWidth = Std.int(rect.width);
						point.x = 0;
					}
					
					// create glyph
					bd = null;
					if (charString != " " && charString != "")
					{
						bd = new BitmapData(charWidth, Std.parseInt(node.get("height")) + Std.parseInt(node.get("yoffset")), true, 0x0);
					}
					else
					{
						bd = new BitmapData(charWidth, 1, true, 0x0);
					}
					bd.copyPixels(bitmapData, rect, point, null, null, true);
					
					// store glyph
					setGlyph(charCode, bd);
					
					letterID++;
				}
			}
		}
		
		return this;
	}
	
	/**
	 * Deserializes and loads a font encoded with serialize().
	 * 
	 * @return	The deserialized BitmapFont.
	 */
	public function fromSerialized(encodedFont:String):BitmapFont 
	{
		reset();
		
		var deserialized:String = Unserializer.run(encodedFont).toString();
		var letters:String = "";
		var letterPos:Int = 0;
		var i:Int = 0;
		
		var n:Int = deserialized.charCodeAt(i) - 32;	// number of glyphs
		var w:Int = deserialized.charCodeAt(++i) - 32;	// max width of single glyph
		var h:Int = deserialized.charCodeAt(++i) - 32;	// max height of single glyph
		
		var size:Int = Std.int(Math.ceil(Math.sqrt(n * (w + 1) * (h + 1))) + Math.max(w, h));
		var rows:Int = Std.int(size / (h + 1));
		var cols:Int = Std.int(size / (w + 1));
		var bd:BitmapData = new BitmapData(size, size, true, 0xFFFF0000);
		var len:Int = deserialized.length;
		
		while (i < len)
		{
			letters += deserialized.charAt(++i);
			
			if (i >= len) break;
			
			var gw:Int = deserialized.charCodeAt(++i) - 32;
			var gh:Int = deserialized.charCodeAt(++i) - 32;
			for (py in 0...gh) 
			{
				for (px in 0...gw) 
				{
					i++;
					
					var pixelOn:Bool = deserialized.charAt(i) == "1"; 
					bd.setPixel32(1 + (letterPos % cols) * (w + 1) + px, 1 + Std.int(letterPos / cols) * (h + 1) + py, pixelOn ? 0xFFFFFFFF : 0x0);
				}
			}
			
			letterPos++;
		}
		
		var font:BitmapFont = new BitmapFont().fromPixelizer(bd, letters);
		bd.dispose();
		bd = null;
		
		return font;
	}

	/**
	 * Serializes the font as a bit font by encoding it into a big string (only extended-ASCII glyphs between in the range [32..254] are valid, no alpha is encoded, pixels are either on (if alpha == 1) or off (otherwise)).
	 * 
	 * Format:
	 * 	   [fromCharCode(numGlyphs + 32)][fromCharCode(maxWidth + 32)][fromCharCode(height + 32)] then for each glyph [char][fromCharCode(width + 32)][fromCharCode(height + 32)][series of 0 or 1 for each pixel of the glyph]...
	 * 
	 *     the resulting string is then converted to Bytes and serialized via haxe.Serializer.
	 * 
	 * @return	Serialized font string.
	 */
	public function serialize():String 
	{
		var charCode:Int;
		var glyph:BitmapData;
		var nGlyphs:Int = _glyphString.length;
		var outputBuf:StringBuf = new StringBuf();
		
		outputBuf.addChar(nGlyphs + 32);
		outputBuf.addChar(maxWidth + 32);
		outputBuf.addChar(height + 32);

		for (i in 0...nGlyphs) 
		{
			charCode = _glyphString.charCodeAt(i);
			glyph = _glyphs.get(charCode);
			
			outputBuf.add(_glyphString.substr(i, 1));
			outputBuf.addChar(glyph.width + 32);
			outputBuf.addChar(glyph.height + 32);
			
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					outputBuf.add(((glyph.getPixel32(px, py) & 0xFF000000) == 0xFF000000) ? "1" : "0");
				}
			}
		}
		
		return Serializer.run(Bytes.ofString(outputBuf.toString()));
	}

	/**
	 * Internal function. Resets current font
	 */
	private function reset():Void
	{
		dispose();
		_maxWidth = 0;
		_maxHeight = 0;
		_glyphs = new IntMap<BitmapData>();
		_glyphString = "";
	}
	
	/**
	 * Adjusts the font BitmapData making background transparent and stores glyphs positions in the rects array.
	 * @return The modified BitmapData.
	 */
	private function preparePixelizerBMD(bitmapData:BitmapData, rects:Array<Rectangle>):BitmapData
	{
		var bgColor:Int = bitmapData.getPixel(0, 0);
		var cy:Int = 0;
		var cx:Int;
		
		while (cy < bitmapData.height)
		{
			var rowHeight:Int = 0;
			cx = 0;
			
			while (cx < bitmapData.width)
			{
				if (Std.int(bitmapData.getPixel(cx, cy)) != bgColor) 
				{
					// found non bg pixel
					var gx:Int = cx;
					var gy:Int = cy;
					
					// find width and height of glyph
					while (Std.int(bitmapData.getPixel(gx, cy)) != bgColor)
					{
						gx++;
					}
					
					while (Std.int(bitmapData.getPixel(cx, gy)) != bgColor)
					{
						gy++;
					}
					
					var gw:Int = gx - cx;
					var gh:Int = gy - cy;
					
					rects.push(new Rectangle(cx, cy, gw, gh));
					
					// store max size
					if (gh > rowHeight) 
					{
						rowHeight = gh;
					}
					if (gh > _maxHeight) 
					{
						_maxHeight = gh;
					}
					
					// go to next glyph
					cx += gw;
				}
				
				cx++;
			}
			// next row
			cy += (rowHeight + 1);
		}
		
		var resultBitmapData:BitmapData = bitmapData.clone();
		
		var pixelColor:UInt;
		var bgColor32:UInt = bitmapData.getPixel(0, 0);
		
		cy = 0;
		while (cy < bitmapData.height)
		{
			cx = 0;
			while (cx < bitmapData.width)
			{
				pixelColor = bitmapData.getPixel32(cx, cy);
				if (pixelColor == bgColor32)
				{
					resultBitmapData.setPixel32(cx, cy, 0x00000000);
				}
				cx++;
			}
			cy++;
		}
		
		return resultBitmapData;
	}
	
	/**
	 * Prepares and returns a set of glyphs using the specified parameters.
	 */
	public function getPreparedGlyphs(scale:Float, color:Int, ?useColorTransform:Bool = true):IntMap<BitmapData>
	{
		var result:IntMap<BitmapData> = new IntMap<BitmapData>();
		
		HP.matrix.identity();
		HP.matrix.scale(scale, scale);
		
		var colorMultiplier:Float = 0.00392;
		_colorTransform.redOffset = 0;
		_colorTransform.greenOffset = 0;
		_colorTransform.blueOffset = 0;
		_colorTransform.redMultiplier = (color >> 16) * colorMultiplier;
		_colorTransform.greenMultiplier = (color >> 8 & 0xff) * colorMultiplier;
		_colorTransform.blueMultiplier = (color & 0xff) * colorMultiplier;
		
		var glyph:BitmapData;
		var preparedGlyph:BitmapData;
		for (i in (_glyphs.keys()))
		{
			glyph = _glyphs.get(i);
			var bdWidth:Int;
			var bdHeight:Int;
			if (glyph != null)
			{
				if (scale > 0)
				{
					bdWidth = Math.ceil(glyph.width * scale);
					bdHeight = Math.ceil(glyph.height * scale);
				}
				else
				{
					bdWidth = 1;
					bdHeight = 1;
				}
				
				preparedGlyph = new BitmapData(bdWidth, bdHeight, true, 0x00000000);
				if (useColorTransform)
				{
					preparedGlyph.draw(glyph,  HP.matrix, _colorTransform);
				}
				else
				{
					preparedGlyph.draw(glyph,  HP.matrix);
				}
				result.set(i, preparedGlyph);
			}
		}
		
		return result;
	}
	
	/** Returns a string with all the supported glyphs. */
	public var supportedGlyphs(get, null):String;
	private function get_supportedGlyphs():String {
		return _glyphString;
	}
	
	/**
	 * Clears all resources used by the font.
	 */
	public function dispose():Void 
	{
		if (_glyphs != null) {
			var bmd:BitmapData;
			for (i in (_glyphs.keys())) 
			{
				bmd = _glyphs.get(i);
				if (bmd != null) 
				{
					bmd.dispose();
				}
				_glyphs.remove(i);
			}
			_glyphs = null;
		}
	}
	
	/**
	 * Sets the BitmapData for a specific glyph.
	 */
	private function setGlyph(charID:Int, bitmapData:BitmapData):Void 
	{
		if (_glyphs.get(charID) != null) 
		{
			_glyphs.get(charID).dispose();
		}
		
		_glyphs.set(charID, bitmapData);
		
		if (bitmapData.width > _maxWidth) 
		{
			_maxWidth = bitmapData.width;
		}
		if (bitmapData.height > _maxHeight) 
		{
			_maxHeight = bitmapData.height;
		}
	}
	
	/**
	 * Renders a string of text onto bitmap data using the font.
	 * @param	bitmapData	Where to render the text.
	 * @param   fontData	Set of font glyphs BitmapData.
	 * @param	text		Test to render.
	 * @param	color		Color of text to render.
	 * @param	offsetX		X position of text output.
	 * @param	offsetY		Y position of text output.
	 */
	public function render(bitmapData:BitmapData, fontData:IntMap<BitmapData>, text:String, color:UInt, offsetX:Float, offsetY:Float, letterSpacing:Int):Void 
	{
		HP.point.x = offsetX;
		HP.point.y = offsetY;

		var glyph:BitmapData;
		
		for (i in 0...(text.length)) 
		{
			var charCode:Int = text.charCodeAt(i);

			glyph = fontData.get(charCode);
			if (glyph != null) 
			{
				bitmapData.copyPixels(glyph, glyph.rect, HP.point, null, null, true);
				HP.point.x += glyph.width + letterSpacing;
			}
		}
	}
		
	/**
	 * Returns the width of a certain test string.
	 * @param	text			String to measure.
	 * @param	letterSpacing	Distance between letters.
	 * @param	fontScale		"size" of the font.
	 * @return	Width in pixels.
	 */
	public function getTextWidth(text:String, ?letterSpacing:Int = 0, ?fontScale:Float = 1.0):Int 
	{
		var w:Int = 0;
		
		var textLength:Int = text.length;
		for (i in 0...(textLength)) 
		{
			var charCode:Int = text.charCodeAt(i);
			var glyph:BitmapData = _glyphs.get(charCode);
			if (glyph != null) 
			{
				w += glyph.width;
			}
		}
		
		w = Math.round(w * fontScale);
		
		if (textLength > 1)
		{
			w += (textLength - 1) * letterSpacing;
		}
		
		return w;
	}
	
	/**
	 * Returns the height of font in pixels.
	 */
	public var height(get, null):Int;
	private inline function get_height():Int 
	{
		return _maxHeight;
	}
	
	/**
	 * Returns the width of the largest glyph.
	 */
	public var maxWidth(get, null):Int;
	private inline function get_maxWidth():Int 
	{
		return _maxWidth;
	}
	
	/**
	 * Returns number of glyphs available in this font.
	 * @return Number of glyphs available in this font.
	 */
	public var numGlyphs(get, null):Int;
	private inline function get_numGlyphs():Int 
	{
		return _glyphString.length;
	}
	
	/**
	 * Stores a font for global use using an identifier.
	 * @param	fontName	String identifer for the font.
	 * @param	font		Font to store.
	 */
	public static function store(fontName:String, font:BitmapFont):Void 
	{
		_storedFonts.set(fontName, font);
	}
	
	/**
	 * Retrieves a font previously stored.
	 * @param	fontName	Identifier of font to fetch.
	 * @return	Stored font, or null if no font was found.
	 */
	public static function fetch(fontName:String):BitmapFont 
	{
		var f:BitmapFont = _storedFonts.get(fontName);
		return f;
	}

	/**
	 * Creates and stores the default font for later use.
	 */
	public static function createDefaultFont():Void
	{
		var defaultFont:BitmapFont = new BitmapFont().fromSerialized(_DEFAULT_FONT_DATA);
		BitmapFont.store("default", defaultFont);
	}

	/** Serialized default font data. (04B_03__.ttf @ 8px) */
	private static inline var _DEFAULT_FONT_DATA:String = "s3754:fyYoICQhMDAwMCEiJjAwMTAxMDEwMDAxMCIkJDAwMDAxMDEwMTAxMDAwMDAjJiYwMDAwMDAwMTAxMDAxMTExMTAwMTAxMDAxMTExMTAwMTAxMDAkJScwMDAwMDAwMTAwMDExMTAxMTAwMDAwMTEwMTExMDAwMDEwMCUmJjAwMDAwMDEwMDEwMDAwMDEwMDAwMTAwMDAxMDAwMDAxMDAxMCYmJjAwMDAwMDAxMTAwMDEwMDAwMDAxMTAxMDEwMDEwMDAxMTAxMCciJDAwMTAxMDAwKCMmMDAwMDEwMTAwMTAwMTAwMDEwKSMmMDAwMTAwMDEwMDEwMDEwMTAwKiQlMDAwMDEwMTAwMTAwMTAxMDAwMDArJCYwMDAwMDAwMDAxMDAxMTEwMDEwMDAwMDAsIycwMDAwMDAwMDAwMDAwMDAwMTAxMDAtJCUwMDAwMDAwMDAwMDAxMTEwMDAwMC4iJjAwMDAwMDAwMDAxMC8mJjAwMDAwMDAwMDAxMDAwMDEwMDAwMTAwMDAxMDAwMDEwMDAwMDAlJjAwMDAwMDExMDAxMDAxMDEwMDEwMTAwMTAwMTEwMDEjJjAwMDExMDAxMDAxMDAxMDAxMDIlJjAwMDAwMTExMDAwMDAxMDAxMTAwMTAwMDAxMTExMDMlJjAwMDAwMTExMDAwMDAxMDAxMTAwMDAwMTAxMTEwMDQlJjAwMDAwMDAxMDAwMTEwMDEwMTAwMTExMTAwMDEwMDUlJjAwMDAwMTExMTAxMDAwMDExMTAwMDAwMTAxMTEwMDYlJjAwMDAwMDExMDAxMDAwMDExMTAwMTAwMTAwMTEwMDclJjAwMDAwMTExMTAwMDAxMDAwMTAwMDEwMDAwMTAwMDglJjAwMDAwMDExMDAxMDAxMDAxMTAwMTAwMTAwMTEwMDklJjAwMDAwMDExMDAxMDAxMDAxMTEwMDAwMTAwMTEwMDoiJjAwMDAxMDAwMTAwMDsiJjAwMDAxMDAwMTAxMDwkJjAwMDAwMDEwMDEwMDEwMDAwMTAwMDAxMD0kJjAwMDAwMDAwMTExMDAwMDAxMTEwMDAwMD4kJjAwMDAxMDAwMDEwMDAwMTAwMTAwMTAwMD8lJjAwMDAwMTExMDAwMDAxMDAxMTAwMDAwMDAwMTAwMEAmJjAwMDAwMDAxMTEwMDEwMDAxMDEwMTExMDEwMTAxMDAxMTEwMEElJjAwMDAwMDExMDAxMDAxMDEwMDEwMTExMTAxMDAxMEIlJjAwMDAwMTExMDAxMDAxMDExMTAwMTAwMTAxMTEwMEMkJjAwMDAwMTEwMTAwMDEwMDAxMDAwMDExMEQlJjAwMDAwMTExMDAxMDAxMDEwMDEwMTAwMTAxMTEwMEUkJjAwMDAxMTEwMTAwMDExMTAxMDAwMTExMEYkJjAwMDAxMTEwMTAwMDExMTAxMDAwMTAwMEclJjAwMDAwMDExMTAxMDAwMDEwMTEwMTAwMTAwMTExMEglJjAwMDAwMTAwMTAxMDAxMDExMTEwMTAwMTAxMDAxMEkkJjAwMDAxMTEwMDEwMDAxMDAwMTAwMTExMEolJjAwMDAwMDAxMTAwMDAxMDAwMDEwMTAwMTAwMTEwMEslJjAwMDAwMTAwMTAxMDEwMDExMDAwMTAxMDAxMDAxMEwkJjAwMDAxMDAwMTAwMDEwMDAxMDAwMTExME0mJjAwMDAwMDEwMDAxMDExMDExMDEwMTAxMDEwMDAxMDEwMDAxME4lJjAwMDAwMTAwMTAxMTAxMDEwMTEwMTAwMTAxMDAxME8lJjAwMDAwMDExMDAxMDAxMDEwMDEwMTAwMTAwMTEwMFAlJjAwMDAwMTExMDAxMDAxMDEwMDEwMTExMDAxMDAwMFElJzAwMDAwMDExMDAxMDAxMDEwMDEwMTAwMTAwMTEwMDAwMDEwUiUmMDAwMDAxMTEwMDEwMDEwMTAwMTAxMTEwMDEwMDEwUyUmMDAwMDAwMTExMDEwMDAwMDExMDAwMDAxMDExMTAwVCQmMDAwMDExMTAwMTAwMDEwMDAxMDAwMTAwVSUmMDAwMDAxMDAxMDEwMDEwMTAwMTAxMDAxMDAxMTAwViUmMDAwMDAxMDAxMDEwMDEwMTAxMDAxMDEwMDAxMDAwVyYmMDAwMDAwMTAwMDEwMTAxMDEwMTAxMDEwMTAxMDEwMDEwMTAwWCUmMDAwMDAxMDAxMDEwMDEwMDExMDAxMDAxMDEwMDEwWSUmMDAwMDAxMDAxMDEwMDEwMDExMTAwMDAxMDAxMTAwWiQmMDAwMDExMTAwMDEwMDEwMDEwMDAxMTEwWyMmMDAwMTEwMTAwMTAwMTAwMTEwXCYmMDAwMDAwMTAwMDAwMDEwMDAwMDAxMDAwMDAwMTAwMDAwMDEwXSMmMDAwMTEwMDEwMDEwMDEwMTEwXiQkMDAwMDAxMDAxMDEwMDAwMF8lJjAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAxMTExMGAjJDAwMDEwMDAxMDAwMGElJjAwMDAwMDAwMDAwMTExMDEwMDEwMTAwMTAwMTExMGIlJjAwMDAwMTAwMDAxMTEwMDEwMDEwMTAwMTAxMTEwMGMkJjAwMDAwMDAwMDExMDEwMDAxMDAwMDExMGQlJjAwMDAwMDAwMTAwMTExMDEwMDEwMTAwMTAwMTExMGUlJjAwMDAwMDAwMDAwMTEwMDEwMTEwMTEwMDAwMTEwMGYkJjAwMDAwMDEwMDEwMDExMTAwMTAwMDEwMGclKDAwMDAwMDAwMDAwMTExMDEwMDEwMTAwMTAwMTExMDAwMDEwMDExMDBoJSYwMDAwMDEwMDAwMTExMDAxMDAxMDEwMDEwMTAwMTBpIiYwMDEwMDAxMDEwMTBqIygwMDAwMTAwMDAwMTAwMTAwMTAwMTAxMDBrJSYwMDAwMDEwMDAwMTAwMTAxMDEwMDExMTAwMTAwMTBsIiYwMDEwMTAxMDEwMTBtJiYwMDAwMDAwMDAwMDAxMTExMDAxMDEwMTAxMDEwMTAxMDEwMTBuJSYwMDAwMDAwMDAwMTExMDAxMDAxMDEwMDEwMTAwMTBvJSYwMDAwMDAwMDAwMDExMDAxMDAxMDEwMDEwMDExMDBwJSgwMDAwMDAwMDAwMTExMDAxMDAxMDEwMDEwMTExMDAxMDAwMDEwMDAwcSUoMDAwMDAwMDAwMDAxMTEwMTAwMTAxMDAxMDAxMTEwMDAwMTAwMDAxMHIkJjAwMDAwMDAwMTAxMDExMDAxMDAwMTAwMHMlJjAwMDAwMDAwMDAwMTExMDExMDAwMDAxMTAxMTEwMHQkJjAwMDAwMTAwMTExMDAxMDAwMTAwMDAxMHUlJjAwMDAwMDAwMDAxMDAxMDEwMDEwMTAwMTAwMTExMHYlJjAwMDAwMDAwMDAxMDAxMDEwMDEwMTAxMDAwMTAwMHcmJjAwMDAwMDAwMDAwMDEwMTAxMDEwMTAxMDAxMDEwMDAxMDEwMHgkJjAwMDAwMDAwMTAxMDAxMDAwMTAwMTAxMHklKDAwMDAwMDAwMDAxMDAxMDEwMDEwMTAwMTAwMTExMDAwMDEwMDExMDB6JSYwMDAwMDAwMDAwMTExMTAwMDEwMDAxMDAwMTExMTB7JCYwMDAwMDExMDAxMDAxMDAwMDEwMDAxMTB8IiYwMDEwMTAxMDEwMTB9JCYwMDAwMTEwMDAxMDAwMDEwMDEwMDExMDB%JSQwMDAwMDAxMDEwMTAxMDAwMDAwMA";

	// BitmapFont information
	private var _glyphs:IntMap<BitmapData>;

	private var _glyphString:String;
	private var _maxHeight:Int = 0;
	private var _maxWidth:Int = 0;
	
	private var _colorTransform:ColorTransform;
	
	
	// BitmapFonts cache
	private static var _storedFonts:Map<String, BitmapFont>;
	
}