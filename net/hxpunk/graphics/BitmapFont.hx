package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import haxe.ds.IntMap.IntMap;
import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Utf8;
import net.hxpunk.HP;


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
	 * @param	XMLData		Font data. An XML object or embedded XML class (in AngelCode's format).
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
	 * @param	source			Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	letters			All letters (in sequential order) contained in this font.
	 * @param	glyphBGColor	An additional background color to remove - often 0xFF202020 is used for glyphs background.
	 * @return this BitmapFont
	 */
	public function fromPixelizer(source:Dynamic, letters:String, ?glyphBGColor:Int = 0xFF202020):BitmapFont
	{
		reset();
		
		var bitmapData:BitmapData = HP.getBitmapData(source);
		if (bitmapData == null) throw new Error("Font source must be of type BitmapData, String or Class.");

		_glyphString = letters;
		
		var tileRects:Array<Rectangle> = [];
		var result:BitmapData = preparePixelizerBMD(bitmapData, tileRects, glyphBGColor);
		var currRect:Rectangle;
		
		for (letterID in 0...(tileRects.length))
		{
			currRect = tileRects[letterID];
			
			// create glyph
			var bd:BitmapData = new BitmapData(Math.floor(currRect.width), Math.floor(currRect.height), true, 0x0);
			bd.copyPixels(result, currRect, HP.zero, null, null, true);
			
			// store glyph
			setGlyph(_glyphString.charCodeAt(letterID), bd);
		}
		
		if (result != null) {
			result.dispose();
			result = null;
		}
			
		return this;
	}
	
	/**
	 * Loads font data from XML (AngelCode's) format.
	 * @param	source		Font source image. An asset id/file, BitmapData object, or embedded BitmapData class.
	 * @param	XMLData		Font data. An XML object or embedded XML class (in AngelCode's format).
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
	 * Serializes the font as a bit font by encoding it into a big string (only extended-ASCII glyphs between in the range [32..254] are valid, no alpha is encoded, pixels are either on (if alpha == 1) or off (otherwise)).
	 * 
	 * Format:
	 * 	   [numGlyphs][maxWidth][height] then for each glyph [utf8 char][width][height][series of false or true for each pixel of the glyph]...
	 * 
	 *     the resulting ByteArray is compressed, converted to string and escaped.
	 * 
	 * @return	Serialized font string.
	 */
	public function serialize():String 
	{
		var charCode:Int;
		var glyph:BitmapData;
		var nGlyphs:Int = _glyphString.length;
		var output:String = "";
		var byteArray:ByteArray = new ByteArray();
		
		byteArray.writeUnsignedInt(nGlyphs);
		byteArray.writeUnsignedInt(maxWidth);
		byteArray.writeUnsignedInt(height);

		for (i in 0...nGlyphs) 
		{
			charCode = Utf8.charCodeAt(_glyphString, i);
			glyph = _glyphs.get(charCode);
			
			byteArray.writeUTF(_glyphString.charAt(i));
			byteArray.writeUnsignedInt(glyph.width);
			byteArray.writeUnsignedInt(glyph.height);
			
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					var pixel:Int = glyph.getPixel32(px, py) & 0xFF000000;
					byteArray.writeBoolean(pixel == 0xFF000000);
				}
			}
		}

#if !html		
		output = ByteArray2String(byteArray, true);
#else
		output = ByteArray2String(byteArray);
#end

		return output;
	}

	/**
	 * Deserializes and loads a font encoded with serialize().
	 * 
	 * @return	The deserialized BitmapFont.
	 */
	public function fromSerialized(encodedFont:String):BitmapFont 
	{
		reset();

#if !html
		var byteArray:ByteArray = String2ByteArray(encodedFont, true);
#else
		var byteArray:ByteArray = String2ByteArray(encodedFont);
#end

		byteArray.position = 0;
		
		var letters:String = "";
		var letterPos:Int = 0;
		
		var n:Int = byteArray.readUnsignedInt();	// number of glyphs
		var w:Int = byteArray.readUnsignedInt();	// max width of single glyph
		var h:Int = byteArray.readUnsignedInt();	// max height of single glyph
		
		var size:Int = Std.int(Math.ceil(Math.sqrt(n * (w + 1) * (h + 1))) + Math.max(w, h));
		var rows:Int = Std.int(size / (h + 1));
		var cols:Int = Std.int(size / (w + 1));
		var bd:BitmapData = new BitmapData(size, size, true, 0xFFFF0000);
		var len:Int = byteArray.length;
		
		while (byteArray.position < len)
		{
			letters += byteArray.readUTF();
			
			if (byteArray.position >= len) break;
			
			var gw:Int = byteArray.readUnsignedInt();
			var gh:Int = byteArray.readUnsignedInt();
			for (py in 0...gh) 
			{
				for (px in 0...gw) 
				{
					var pixelOn:Bool = byteArray.readBoolean();
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
	 * Encodes a ByteArray into a String. 
	 * 
	 * @param byteArray		The ByteArray to be encoded.
	 * @param mustCompress	Whether the ByteArray must be compressed before being encoded.
	 * @return The encoded string.
	 */
	public static function ByteArray2String(byteArray:ByteArray, mustCompress:Bool = false):String {
		var origPos:Int = byteArray.position;
		var result:Array<Int> = new Array<Int>();
		var outputBuf:StringBuf = new StringBuf();

#if !html
		if (mustCompress) {
			byteArray.position = 0;
			byteArray.compress();
		}
#end
		byteArray.position = 0;
		while (byteArray.position < byteArray.length - 1)
			result.push(byteArray.readUnsignedShort());

		if (byteArray.position != byteArray.length)
			result.push(byteArray.readUnsignedByte() << 8);

		byteArray.position = origPos;
		for (i in result) {
			outputBuf.add(StringTools.hex(i, 4));
		}
		return outputBuf.toString();
	}
	
	/** 
	 * Decodes a ByteArray from a String. 
	 * 
	 * @param str				The string to be decoded.
	 * @param mustUncompress	Whether the ByteArray must be uncompressed after being decoded.
	 * @return The decoded ByteArray.
	 */
	public static function String2ByteArray(str:String, mustUncompress:Bool = false):ByteArray {
		var result:ByteArray = new ByteArray();

		var s = "";
		var len:Int = str.length;
		var i:Int = 0;
		var n:Int = 0;
		while (i < len) {
			s = str.substr(i, 4);
			n = 0;
			for (c in 0...s.length) {
				var val:Int = s.charCodeAt(c);
				val -= (val >= 65 ? 65 - 10 : 48);
				n <<= 4;
				n |= val;
			}
			
			result.writeShort(n);
			i += 4;
		}
		
#if !html
		if (mustUncompress) {
			result.position = 0;
			result.uncompress();
		}
#end
		result.position = 0;
		return result;
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
	 * 
	 * @param	bitmapData		The BitmapData containing the font glyphs.
	 * @param	rects			A Vector that will be populate with Rectangles representing glyphs positions and dimensions.
	 * @param	glyphBGColor	An additional background color to remove - often 0xFF202020 is used for glyphs background.
	 * @return The modified BitmapData.
	 */
	private function preparePixelizerBMD(bitmapData:BitmapData, rects:Array<Rectangle>, ?glyphBGColor:Int):BitmapData
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
		
		var resultBitmapData:BitmapData = new BitmapData(bitmapData.width, bitmapData.height, true, 0);
		
		// remove background color
		
		var bgColor32:Int = bitmapData.getPixel32(0, 0);
		
		resultBitmapData.threshold(bitmapData, bitmapData.rect, HP.zero, "==", bgColor32, 0x00000000, 0xFFFFFFFF, true);
		
		if (glyphBGColor != null)
			resultBitmapData.threshold(resultBitmapData, resultBitmapData.rect, HP.zero, "==", glyphBGColor, 0x00000000, 0xFFFFFFFF, true);
		
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
	 * @param	bitmapData		Where to render the text.
	 * @param	text			Test to render.
	 * @param   fontData		Set of font glyphs BitmapData.
	 * @param	offsetX			X position of text output.
	 * @param	offsetY			Y position of text output.
	 * @param	letterSpacing	Space between characters.
	 */
	public function render(bitmapData:BitmapData, text:String, fontData:IntMap<BitmapData>, offsetX:Float = 0, offsetY:Float = 0, letterSpacing:Int = 0):Void 
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
	 */
	public var numGlyphs(get, null):Int;
	private inline function get_numGlyphs():Int 
	{
		return _glyphString.length;
	}
	
	/**
	 * Returns the set of glyphs' BitmapData (it's not a copy).
	 */
	public var glyphs(get, null):IntMap<BitmapData>;
	private inline function get_glyphs():IntMap<BitmapData>
	{
		return _glyphs;
	}
	
	/**
	 * Stores a font for global use using an identifier.
	 * @param	fontName	String identifer for the font.
	 * @param	font		Font to store.
	 */
	public static function store(fontName:String, font:BitmapFont):Void 
	{
		if (_storedFonts == null) _storedFonts = new Map<String, BitmapFont>();
		_storedFonts.set(fontName, font);
	}
	
	/**
	 * Retrieves a font previously stored.
	 * @param	fontName	Identifier of font to fetch.
	 * @return	Stored font, or null if no font was found.
	 */
	public static function fetch(fontName:String):BitmapFont 
	{
		var f:BitmapFont = (_storedFonts != null ? _storedFonts.get(fontName) : null);
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
#if !html
	private static inline var _DEFAULT_FONT_DATA:String = "78DA955685821C310885766E6F3FA3EEEEEEEEEEEDD55DEFEAF6ED9D24840021B3D7D999EC64429007010060060046FD33065CD4FF75FD83102E5CDC0F0BD22AC65F5CC12544D545225E0A93A5C46B04F4216E0897F30EB8AC1FA6FA679AC92305202980719617966BE6C87AEA81167085D505992272CE0C30BDAD2463BBAC1DE0AA7E58983964FA8CC26AB188456A7A5F43F04CE99D59FA5A5ACEAA0141C3FA01AE23F6D3602E92B05E4AE035CC123614D749111B0D26357A0247C04D24605410644766A3A2369B251858C088F716C525EB884C99A2A21FB70E1126D393B86D5AAFECC61262F9DB76CB1159A0E6B8C3B5B438852DDD59732C012021DCD5C00E2CC7DD6D4294F6E31EE9D3226D6FFD396CD9A763AC042F0FB8DF8621C3C271744092E8DDF9F5E004AFF19E43D581C4A23022671272C9E1C1E0235786FB48AD00B26B5138F9A8B217D1B82D901E6BF19292C3CA71054CE625FE014F0C92C48F27AD8D393EA19817799DD27A393810F5692B541A99E667ECE9917E959179D613CAABE2849FB351A29E28F47C95BCC9481425A4D4980B8E68A2D3F65E9C6F8ABA34E8D9927BF1B22E4A4D8EE9EDCA7CD886FB6AC3D55572BB36E4C1F45C6F458335FA46931005DAFD70D3754FF5CB7B6E35F81AB4006FB7097572BB53592DEB6D647B5717199D50EFD5060CFCE1FD46C18AEF0F6483A32BF78C393BF545B5EC2109E8648A017CE4ECB74738EE7F6C81F3830BF049DD4BA0496A4FAD506C087DE66A574E2A7751CFDDE2A262F505F11A4FB054C4C0CBC936A7C92BD99896787E4D988FAB5E9003F78D230254E1A1FBADED7D13C5BBBA8162973BA7E57D0DA86FD18726F2E6447FAC616DE63282E0D3FF78224D67ABCE209F0DA69A6B45B2E9DDF1B3AEBA264EE2872F0E4C553E0BC3D761C2C2F49BEB272793A5F1BB676F69EBC3F0C301DED351F8EAA7EB7D531B03F52FDB98A85E2DCE7FFBF1F847A74DD39FC5F95FD2A2D320A4EB1F2AF02506";
#else
	private static inline var _DEFAULT_FONT_DATA:String = "0000005F0000000600000008000120000000040000000100000000000121000000020000000600000100010001000000010000012200000004000000040000000001000100010001000000000000012300000006000000060000000000000001000100000101010101000001000100000101010101000001000100000001240000000500000007000000000000000100000001010100010100000000000101000101010000000001000000012500000006000000060000000000000100000100000000000100000000010000000001000000000001000001000001260000000600000006000000000000000101000000010000000000000101000100010000010000000101000100000127000000020000000400000100010000000001280000000300000006000000000100010000010000010000000100000129000000030000000600000001000000010000010000010001000000012A0000000400000005000000000100010000010000010001000000000000012B000000040000000600000000000000000001000001010100000100000000000000012C000000030000000700000000000000000000000000000000010001000000012D0000000400000005000000000000000000000000010101000000000000012E000000020000000600000000000000000000010000012F0000000600000006000000000000000000000100000000010000000001000000000100000000010000000000000130000000050000000600000000000001010000010000010001000001000100000100000101000000013100000003000000060000000101000001000001000001000001000001320000000500000006000000000001010100000000000100000101000001000000000101010100000133000000050000000600000000000101010000000000010000010100000000000100010101000000013400000005000000060000000000000001000000010100000100010000010101010000000100000001350000000500000006000000000001010101000100000000010101000000000001000101010000000136000000050000000600000000000001010000010000000001010100000100000100000101000000013700000005000000060000000000010101010000000001000000010000000100000000010000000001380000000500000006000000000000010100000100000100000101000001000001000001010000000139000000050000000600000000000001010000010000010000010101000000000100000101000000013A000000020000000600000000010000000100000000013B000000020000000600000000010000000100010000013C000000040000000600000000000001000001000001000000000100000000010000013D000000040000000600000000000000000101010000000000010101000000000000013E000000040000000600000000010000000001000000000100000100000100000000013F0000000500000006000000000001010100000000000100000101000000000000000001000000000140000000060000000600000000000000010101000001000000010001000101010001000100010000010101000000014100000005000000060000000000000101000001000001000100000100010101010001000001000001420000000500000006000000000001010100000100000100010101000001000001000101010000000143000000040000000600000000000101000100000001000000010000000001010000014400000005000000060000000000010101000001000001000100000100010000010001010100000001450000000400000006000000000101010001000000010101000100000001010100000146000000040000000600000000010101000100000001010100010000000100000000014700000005000000060000000000000101010001000000000100010100010000010000010101000001480000000500000006000000000001000001000100000100010101010001000001000100000100000149000000040000000600000000010101000001000000010000000100000101010000014A000000050000000600000000000000010100000000010000000001000100000100000101000000014B000000050000000600000000000100000100010001000001010000000100010000010000010000014C000000040000000600000000010000000100000001000000010000000101010000014D000000060000000600000000000001000000010001010001010001000100010001000000010001000000010000014E000000050000000600000000000100000100010100010001000101000100000100010000010000014F00000005000000060000000000000101000001000001000100000100010000010000010100000001500000000500000006000000000001010100000100000100010000010001010100000100000000000151000000050000000700000000000001010000010000010001000001000100000100000101000000000001000001520000000500000006000000000001010100000100000100010000010001010100000100000100000153000000050000000600000000000001010100010000000000010100000000000100010101000000015400000004000000060000000001010100000100000001000000010000000100000001550000000500000006000000000001000001000100000100010000010001000001000001010000000156000000050000000600000000000100000100010000010001000100000100010000000100000000015700000006000000060000000000000100000001000100010001000100010001000100010001000001000100000001580000000500000006000000000001000001000100000100000101000001000001000100000100000159000000050000000600000000000100000100010000010000010101000000000100000101000000015A000000040000000600000000010101000000010000010000010000000101010000015B000000030000000600000001010001000001000001000001010000015C000000060000000600000000000001000000000000010000000000000100000000000001000000000000010000015D000000030000000600000001010000010000010000010001010000015E00000004000000040000000000010000010001000000000000015F000000050000000600000000000000000000000000000000000000000000000000010101010000016000000003000000040000000100000001000000000001610000000500000006000000000000000000000001010100010000010001000001000001010100000162000000050000000600000000000100000000010101000001000001000100000100010101000000016300000004000000060000000000000000000101000100000001000000000101000001640000000500000006000000000000000001000001010100010000010001000001000001010100000165000000050000000600000000000000000000000101000001000101000101000000000101000000016600000004000000060000000000000100000100000101010000010000000100000001670000000500000008000000000000000000000001010100010000010001000001000001010100000000010000010100000001680000000500000006000000000001000000000101010000010000010001000001000100000100000169000000020000000600000100000001000100010000016A000000030000000800000000010000000000010000010000010000010001000000016B000000050000000600000000000100000000010000010001000100000101010000010000010000016C000000020000000600000100010001000100010000016D000000060000000600000000000000000000000001010101000001000100010001000100010001000100010000016E000000050000000600000000000000000000010101000001000001000100000100010000010000016F0000000500000006000000000000000000000001010000010000010001000001000001010000000170000000050000000800000000000000000000010101000001000001000100000100010101000001000000000100000000000171000000050000000800000000000000000000000101010001000001000100000100000101010000000001000000000100000172000000040000000600000000000000000100010001010000010000000100000000017300000005000000060000000000000000000000010101000101000000000001010001010100000001740000000400000006000000000001000001010100000100000001000000000100000175000000050000000600000000000000000000010000010001000001000100000100000101010000017600000005000000060000000000000000000001000001000100000100010001000000010000000001770000000600000006000000000000000000000000010001000100010001000100000100010000000100010000000178000000040000000600000000000000000100010000010000000100000100010000017900000005000000080000000000000000000001000001000100000100010000010000010101000000000100000101000000017A000000050000000600000000000000000000010101010000000100000001000000010101010000017B000000040000000600000000000101000001000001000000000100000001010000017C000000020000000600000100010001000100010000017D000000040000000600000000010100000001000000000100000100000101000000017E00000005000000040000000000000100010001000100000000000000";
#end

	// BitmapFont information
	private var _glyphs:IntMap<BitmapData>;

	private var _glyphString:String;
	private var _maxHeight:Int = 0;
	private var _maxWidth:Int = 0;
	
	private var _colorTransform:ColorTransform;
	
	
	// BitmapFonts cache
	private static var _storedFonts:Map<String, BitmapFont>;
	
}