---@meta
--- PICO-8 v0.2.7 API definitions for lua-language-server.
--- Signatures taken from /opt/pico-8/pico-8_manual.txt.
--- This file is never loaded by PICO-8 -- it exists only so the editor can
--- offer completion, signature help and hover docs.

--#region Game loop

--- Called once on cartridge startup, before the first _update.
function _init() end

--- Called once per frame at 30fps. Define _update60 instead for 60fps.
function _update() end

--- Called once per frame at 60fps, instead of _update.
function _update60() end

--- Called once per frame after _update, to draw the screen.
function _draw() end

--#endregion

--#region Graphics

--- Clear the screen and reset the clipping rectangle.
---@param col? integer Colour to clear to (default 0/black)
function cls(col) end

--- Set the draw colour, or return the current one.
---@param col? integer 0..15
---@return integer prev The previous draw colour
function color(col) end

--- Set a pixel.
---@param x integer
---@param y integer
---@param col? integer 0..15 (default: current draw colour)
function pset(x, y, col) end

--- Read the colour of a screen pixel.
---@param x integer
---@param y integer
---@return integer col
function pget(x, y) end

--- Draw a line. Omit x1,y1 to continue from the last line endpoint.
---@param x0 integer
---@param y0 integer
---@param x1? integer
---@param y1? integer
---@param col? integer
function line(x0, y0, x1, y1, col) end

--- Draw a rectangle outline.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param col? integer
function rect(x0, y0, x1, y1, col) end

--- Draw a filled rectangle.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param col? integer
function rectfill(x0, y0, x1, y1, col) end

--- Draw a rounded rectangle outline.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param r integer Corner radius
---@param col? integer
function rrect(x, y, w, h, r, col) end

--- Draw a filled rounded rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param r integer Corner radius
---@param col? integer
function rrectfill(x, y, w, h, r, col) end

--- Draw a circle outline.
---@param x integer
---@param y integer
---@param r number Radius
---@param col? integer
function circ(x, y, r, col) end

--- Draw a filled circle.
---@param x integer
---@param y integer
---@param r number Radius
---@param col? integer
function circfill(x, y, r, col) end

--- Draw an ellipse outline inscribed in the given rectangle.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param col? integer
function oval(x0, y0, x1, y1, col) end

--- Draw a filled ellipse inscribed in the given rectangle.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param col? integer
function ovalfill(x0, y0, x1, y1, col) end

--- Print a string to the screen.
---@param str any
---@param x? integer
---@param y? integer
---@param col? integer
---@return integer next_x Right edge of the printed text
function print(str, x, y, col) end

--- Set the cursor position (and optionally colour) used by print.
---@param x? integer
---@param y? integer
---@param col? integer
function cursor(x, y, col) end

--- Draw a sprite from the sprite sheet.
---@param n integer Sprite index 0..255
---@param x integer
---@param y integer
---@param w? number Width in sprites (default 1)
---@param h? number Height in sprites (default 1)
---@param flip_x? boolean
---@param flip_y? boolean
function spr(n, x, y, w, h, flip_x, flip_y) end

--- Draw a stretched region of the sprite sheet.
---@param sx integer Source x in sprite-sheet pixels
---@param sy integer Source y
---@param sw integer Source width
---@param sh integer Source height
---@param dx integer Destination x
---@param dy integer Destination y
---@param dw? integer Destination width (default sw)
---@param dh? integer Destination height (default sh)
---@param flip_x? boolean
---@param flip_y? boolean
function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y) end

--- Read a pixel from the sprite sheet.
---@param x integer
---@param y integer
---@return integer col
function sget(x, y) end

--- Write a pixel to the sprite sheet.
---@param x integer
---@param y integer
---@param col? integer
function sset(x, y, col) end

--- Get sprite flags. Returns the whole bitfield if f is omitted.
---@param n integer Sprite index
---@param f? integer Flag index 0..7
---@return integer|boolean
function fget(n, f) end

--- Set sprite flags.
---@param n integer Sprite index
---@param f? integer Flag index 0..7
---@param val integer|boolean
function fset(n, f, val) end

--- Set the clipping rectangle. Call with no arguments to reset to fullscreen.
---@param x? integer
---@param y? integer
---@param w? integer
---@param h? integer
---@param clip_previous? boolean Intersect with the current clip instead of replacing
function clip(x, y, w, h, clip_previous) end

--- Offset all drawing operations. Call with no arguments to reset to 0,0.
---@param x? integer
---@param y? integer
function camera(x, y) end

--- Remap draw or screen palette colours.
---@param c0 integer|table Colour to remap, or a table of remappings
---@param c1? integer Colour to use instead
---@param p? integer 0 = draw palette, 1 = screen palette, 2 = secondary
function pal(c0, c1, p) end

--- Set colour transparency for spr/sspr/map. Call with no args to reset.
---@param c? integer
---@param t? boolean true = transparent
function palt(c, t) end

--- Set the fill pattern used by shape-drawing functions.
---@param p? integer 16-bit pattern
function fillp(p) end

--#endregion

--#region Input

--- True while a button is held.
--- Buttons: 0 left, 1 right, 2 up, 3 down, 4 O/Z, 5 X.
---@param b? integer Button index 0..5
---@param pl? integer Player 0..7 (default 0)
---@return boolean
function btn(b, pl) end

--- True on the frame a button is pressed, then again on autorepeat.
--- Prefer this over btn for menus and one-shot actions.
---@param b integer Button index 0..5
---@param pl? integer Player 0..7 (default 0)
---@return boolean
function btnp(b, pl) end

--#endregion

--#region Map

--- Read a map cell.
---@param x integer
---@param y integer
---@return integer sprite_index
function mget(x, y) end

--- Write a map cell.
---@param x integer
---@param y integer
---@param val integer Sprite index
function mset(x, y, val) end

--- Draw a region of the map.
---@param tile_x integer
---@param tile_y integer
---@param sx? integer Screen x (default 0)
---@param sy? integer Screen y (default 0)
---@param tile_w? integer
---@param tile_h? integer
---@param layers? integer Only draw tiles whose flags match this bitfield
function map(tile_x, tile_y, sx, sy, tile_w, tile_h, layers) end

--- Draw a textured line using the map as a texture.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param mx number
---@param my number
---@param mdx? number
---@param mdy? number
---@param layers? integer
function tline(x0, y0, x1, y1, mx, my, mdx, mdy, layers) end

--#endregion

--#region Sound

--- Play a sound effect. n = -1 stops the channel, -2 releases a looping sfx.
---@param n integer Sfx index 0..63
---@param channel? integer 0..3, or -1 to auto-pick, -2 to stop this sfx
---@param offset? integer Start note
---@param length? integer Notes to play
function sfx(n, channel, offset, length) end

--- Play a music pattern. n = -1 stops music.
---@param n integer Pattern index 0..63
---@param fade_len? integer Fade-in milliseconds
---@param channel_mask? integer Channels to reserve
function music(n, fade_len, channel_mask) end

--#endregion

--#region Tables

--- Append a value to a table.
---@generic T
---@param tbl T[]
---@param val T
---@param index? integer Insert position (default: end)
---@return T val
function add(tbl, val, index) end

--- Remove the first occurrence of a value.
--- Careful: removing while iterating with foreach/all skips elements.
--- Loop backwards with `for i=#tbl,1,-1` when deleting in a loop.
---@generic T
---@param tbl T[]
---@param val T
---@return T? deleted
function del(tbl, val) end

--- Remove by index and return it. Defaults to the last element.
---@generic T
---@param tbl T[]
---@param i? integer
---@return T? deleted
function deli(tbl, i) end

--- Count elements, or count occurrences of val.
---@param tbl table
---@param val? any
---@return integer
function count(tbl, val) end

--- Iterator over the sequential values of a table, safe for deletion.
---@generic T
---@param tbl T[]
---@return fun(): T?
function all(tbl) end

--- Call func once per sequential value.
---@generic T
---@param tbl T[]
---@param func fun(v: T)
function foreach(tbl, func) end

--- Iterate over all key/value pairs in a table.
---@param tbl table
---@return fun(): any, any
function pairs(tbl) end

--#endregion

--#region Metatables and raw access

---@param tbl table
---@param m table|nil
---@return table tbl
function setmetatable(tbl, m) end

---@param tbl table
---@return table|nil
function getmetatable(tbl) end

--- Set a key without invoking the __newindex metamethod.
---@param tbl table
---@param key any
---@param value any
function rawset(tbl, key, value) end

--- Read a key without invoking the __index metamethod.
---@param tbl table
---@param key any
---@return any
function rawget(tbl, key) end

--- Compare without invoking the __eq metamethod.
---@param tbl1 any
---@param tbl2 any
---@return boolean
function rawequal(tbl1, tbl2) end

--- Length without invoking the __len metamethod.
---@param tbl table|string
---@return integer
function rawlen(tbl) end

--#endregion

--#region Math

---@param x number
---@param y number
---@return number
function max(x, y) end

---@param x number
---@param y number
---@return number
function min(x, y) end

--- Middle of three values -- handy for clamping: mid(lo, val, hi).
---@param x number
---@param y number
---@param z number
---@return number
function mid(x, y, z) end

--- Round down.
---@param x number
---@return integer
function flr(x) end

--- Round up.
---@param x number
---@return integer
function ceil(x) end

--- Cosine. Note: takes turns (0..1), not radians.
---@param x number
---@return number
function cos(x) end

--- Sine. Note: takes turns (0..1), not radians, and is inverted vs standard Lua.
---@param x number
---@return number
function sin(x) end

--- Angle of a vector, in turns (0..1). Note the inverted y convention.
---@param dx number
---@param dy number
---@return number
function atan2(dx, dy) end

---@param x number
---@return number
function sqrt(x) end

---@param x number
---@return number
function abs(x) end

--- Random number in [0, x), or a random element if x is a table.
---@param x? number|table
---@return any
function rnd(x) end

--- Seed the random number generator.
---@param x number
function srand(x) end

--#endregion

--#region Strings and types

--- Convert a value to a string.
---@param val any
---@param format_flags? integer|boolean
---@return string
function tostr(val, format_flags) end

--- Convert a value to a number, or nil if it can't be converted.
---@param val any
---@param format_flags? integer|boolean
---@return number?
function tonum(val, format_flags) end

--- Substring. Negative positions count from the end.
---@param str string
---@param pos0 integer
---@param pos1? integer
---@return string
function sub(str, pos0, pos1) end

--- Split a string into a table.
---@param str string
---@param separator? string|integer Default ","
---@param convert_numbers? boolean Default true
---@return table
function split(str, separator, convert_numbers) end

--- Character from an ordinal value.
---@param val0 integer
---@param ... integer
---@return string
function chr(val0, ...) end

--- Ordinal value of a character.
---@param str string
---@param index? integer
---@param num_results? integer
---@return integer ...
function ord(str, index, num_results) end

--- Type name of a value.
---@param val any
---@return string
function type(val) end

--#endregion

--#region System

--- Frames elapsed since startup, in seconds. `t()` is a shorthand.
---@return number
function time() end

--- Frames elapsed since startup, in seconds.
---@return number
function t() end

--- Query system state. 0/1 = memory, 7 = fps, 30..36 = mouse/keyboard, ...
---@param x integer
---@return any
function stat(x) end

--- Print to the host console or a file -- your main debugging tool.
--- printh(str, "@clip") copies to the clipboard.
---@param str any
---@param filename? string
---@param overwrite? boolean
---@param save_to_desktop? boolean
function printh(str, filename, overwrite, save_to_desktop) end

--- Add an entry to the pause menu.
---@param index integer 1..5
---@param label? string
---@param callback? fun(b: integer)
function menuitem(index, label, callback) end

--- Stop the cart and return to the console.
---@param message? string
function stop(message) end

--- Throw an error if condition is false.
---@param condition any
---@param message? string
function assert(condition, message) end

--- Flush the screen and wait for the next frame. Rarely needed.
function flip() end

--- Reset the draw state (palette, clip, camera, fill pattern).
function reset() end

--- Restart the current cart.
---@param param_str? string
function run(param_str) end

--- Load a cart. Ends the current program.
---@param filename string
---@param breadcrumb? string
---@param param_str? string
function load(filename, breadcrumb, param_str) end

--- Save the current cart.
---@param filename string
function save(filename) end

--- List files in the current directory.
---@param directory? string
---@return table
function ls(directory) end

--- Print cart info to the console.
function info() end

--- Special commands: "reset", "pause", "screen", "video", "audio_rec", ...
---@param cmd_str string
---@param p1? any
---@param p2? any
function extcmd(cmd_str, p1, p2) end

--#endregion

--#region Persistent cart data

--- Open a 64-number persistent data slot. Call once, before dget/dset.
---@param id string Unique id, e.g. "yourname_gamename"
function cartdata(id) end

--- Read a persistent value.
---@param index integer 0..63
---@return number
function dget(index) end

--- Write a persistent value.
---@param index integer 0..63
---@param value number
function dset(index, value) end

--#endregion

--#region Memory

---@param addr integer
---@param n? integer Number of bytes to return
---@return integer ...
function peek(addr, n) end

---@param addr integer
---@param ... integer Values to write
function poke(addr, ...) end

---@param addr integer
---@return integer
function peek2(addr) end

---@param addr integer
---@param val integer
function poke2(addr, val) end

---@param addr integer
---@return number
function peek4(addr) end

---@param addr integer
---@param val number
function poke4(addr, val) end

---@param dest_addr integer
---@param source_addr integer
---@param len integer
function memcpy(dest_addr, source_addr, len) end

---@param dest_addr integer
---@param val integer
---@param len integer
function memset(dest_addr, val, len) end

--- Load data from a cart into memory.
---@param dest_addr integer
---@param source_addr integer
---@param len integer
---@param filename? string
function reload(dest_addr, source_addr, len, filename) end

--- Store memory into a cart file.
---@param dest_addr integer
---@param source_addr integer
---@param len integer
---@param filename? string
function cstore(dest_addr, source_addr, len, filename) end

--#endregion

--#region Coroutines

---@param f function
---@return thread
function cocreate(f) end

---@param c thread
---@param ... any
---@return boolean ok, any ...
function coresume(c, ...) end

--- "running", "suspended" or "dead".
---@param c thread
---@return string
function costatus(c) end

--- Yield from inside a coroutine.
---@param ... any
function yield(...) end

--#endregion
