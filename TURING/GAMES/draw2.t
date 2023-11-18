% default graphics has 640x400 graphics
setscreen ("graphics")
setscreen ("nocursor")
setscreen ("noecho")
color (0)
colorback (7)
%going to try something different.  Since this is so much smaller and I made a change to the world editor
%I'm going to make the pixels bigger as well (boxes)
var picWidth : int := 57
var picHeight : int := 67
var scale : int := 7
var boxSize : int := 1
% this is the newest addition since 0 is now white in the windows version (7 is black)
var backColour : int := 7
var find_color : array 1 .. picHeight, 1 .. picWidth of int
var startX : int
var startY : int
for i : 1 .. picHeight
    for j : 1 .. picWidth
	find_color (i, j) := 7
    end for
end for
procedure cursor (var x, y : int, clr : int)
    if scale = 1 then
	drawdot (x + 1, y, clr)
	drawdot (x - 1, y, clr)
	drawdot (x, y + 1, clr)
	drawdot (x, y - 1, clr)
    else
	var begX : int := x + scale
	var begY : int := y
	drawfillbox (begX, begY, begX + scale - 1, begY + scale - 1, clr)
	begX := x - 1
	drawfillbox (begX, begY, begX - scale + 1, begY + scale - 1, clr)
	begX := x
	begY := y + scale
	drawfillbox (begX, begY, begX + scale - 1, begY + scale - 1, clr)
	begY := y - 1
	drawfillbox (begX, begY, begX + scale - 1, begY - scale + 1, clr)
    end if
    
    % this was just debugging stuff
    drawfillbox (0, 0, boxSize + 1, boxSize + 1, 7)
    drawfillbox (0, 0, boxSize, boxSize, 10)
    drawdot(10, 20, 10)
    drawdot(11, 20, 10)
    drawdot(10, 21, 10)
    drawdot(11, 21, 10)
end cursor
procedure set_up
    drawfillbox (0, 0, maxx, maxy, 7)
    locate (1, 1)
    put "COLOUR : "
    var row, col : int
    % row := round (maxx / 2 - (picWidth + 3) * scale / 2)
    % col := round (maxy / 2 - (picHeight + 3) * scale / 2)
    row := round (maxx / 2 - (picWidth * scale + 3 * scale) / 2)
    col := round (maxy / 2 - (picHeight * scale + 3 * scale) / 2)
    drawbox (row, col, row + picWidth * scale + (4 * scale - 1), col + picHeight * scale + (4 * scale - 1), 0)
    drawbox (row - 1, col - 1, row + picWidth * scale + (4 * scale), col + picHeight * scale + (4 * scale), 0)
end set_up
procedure centre (s : string)
    var diff : int := round ((40 - length (s)) / 2)
    put repeat (" ", diff) ..
    put s
end centre

procedure drawSprite
    for i : 1 .. picHeight
	for j : 1 .. picWidth
	    if scale = 1 then
		drawdot (j + startX - 1, i + startY - 1, find_color (i, j))
	    else
		var curX : int := (j - 1) * scale + startX
		var curY : int := (i - 1) * scale + startY
		drawfillbox (curX, curY, curX + scale - 1, curY + scale - 1, find_color (i, j))
	    end if
	    %delay(1)
	end for
    end for
end drawSprite

set_up
var x, y : int
var cur_clr : int := 0
% x and y is the physical location of the cursor on the screen
x := ((floor (maxx / 2)) - (floor (picWidth * scale / 2)) + scale)
y := ((floor (maxy / 2)) - (floor (picHeight * scale / 2)) + scale)
startX := x
startY := y
% ygrid and xgrid is the relative position of the cursor in the window
var ygrid, xgrid : int := 1
var clr : int
cursor (x, y, 0)
const UP_ARROW : int := 200
const RIGHT_ARROW : int := 205
const LEFT_ARROW : int := 203
const DOWN_ARROW : int := 208
const SPACE : int := 32
const ENTER : int := 10
const ESC : int := 27
const c : int := 99
const d : int := 100
const f : int := 102
const a : int := 97
const p : int := 112
const l : int := 108
const s : int := 115
const e : int := 101
const n : int := 110
const b : int := 98
const z : int := 122
var colr : int := 0
var colrc : boolean := true
var ch : string (1)

procedure fillOldCurPos
    % we have x, y and xgrid and ygrid (relative position)
    % lets do a 5x5 around the cursor position to make it easier
    var curx : int
    var cury : int
    var curgridx : int
    var curgridy : int
    for i : -2 .. 2
	for j : -2 .. 2
	    % using the xgrid and ygrid will get the index into the array so for the canvas we should be using x and y
	    curgridx := xgrid + j
	    curgridy := ygrid + i
	    if curgridx >= 1 and curgridx <= picWidth and
		    curgridy >= 1 and curgridy <= picHeight then
		if scale = 1 then
		    drawdot (curgridx + startX - 1, curgridy + startY - 1, find_color (curgridy, curgridx))
		else
		    % todo: draw boxes for different scales
		    % drawdot (curx + startX, cury + startY, find_color (cury, curx))
		    curx := (curgridx - 1) * scale + startX
		    cury := (curgridy - 1) * scale + startY
		    
		    drawfillbox (curx, cury, curx + scale - 1, cury + scale - 1, find_color (curgridy, curgridx))
		end if
	    end if
	end for
    end for
end fillOldCurPos

% x:= 125
% y:= -30
loop
    locate (2, 1)
    put "DOT COLOUR : ", find_color (ygrid, xgrid)
    locate (3, 1)
    put "x: ", x
    locate (4, 1)
    put "y: ", y
    locate (1, 10)
    put colr
    getch (ch)
    case ord (ch) of
	label UP_ARROW :
	    cursor (x, y, 7)
	    if ygrid not= picHeight then
		boxSize := boxSize + 1
		fillOldCurPos
		y := y + scale
		ygrid := ygrid + 1
	    end if
	    cursor (x, y, cur_clr)
	label RIGHT_ARROW :
	    cursor (x, y, 7)
	    if xgrid not= picWidth then
		fillOldCurPos
		xgrid := xgrid + 1
		x := x + scale
	    end if
	    cursor (x, y, cur_clr)
	label LEFT_ARROW :
	    cursor (x, y, 7)
	    if xgrid not= 1 then
		%delay(1000)
		fillOldCurPos
		%delay(1000)
		xgrid := xgrid - 1
		x := x - scale
	    end if
	    cursor (x, y, cur_clr)
	label DOWN_ARROW :
	    cursor (x, y, 7)
	    if ygrid not= 1 then
		boxSize := boxSize - 1
		fillOldCurPos
		ygrid := ygrid - 1
		y := y - scale
	    end if
	    cursor (x, y, cur_clr)
	label c :
	    colrc := true
	    locate (1, 10)
	    put ""
	    setscreen ("echo")
	    locate (1, 10)
	    get colr
	    setscreen ("noecho")
	label d :
	    if colrc = false then
		locate (7, 1)
		centre ("Sorry Enter in color")
		delay (1000)
		locate (7, 1)
		put ""
	    else
		drawdot (x, y, colr)
		find_color (ygrid, xgrid) := colr
	    end if
	label a :
	    locate (7, 1)
	    var tclr : int
	    setscreen ("echo")
	    put "CHANGE COLOUR TO : " ..
	    get tclr
	    var old_color : int := find_color (ygrid, xgrid)
	    locate (7, 1)
	    put ""
	    for i : 1 .. picHeight
		for j : 1 .. picWidth
		    if find_color (i, j) = old_color then
			find_color (i, j) := tclr
			drawdot (j + startX, i + startY, tclr)
		    end if
		end for
	    end for
	    setscreen ("noecho")
	    cursor (x, y, 15)
	label p :
	    var reply : string (1)
	    var count : int := 0
	    loop
		locate (3, 1)
		put count
		getch (reply)
		case ord (reply) of
		    label UP_ARROW :
			if count < 255 then
			    count := count + 1
			    drawfillbox (0, 0, 0 + 50, 0 + 50, count)
			end if
		    label DOWN_ARROW :
			if count > 0 then
			    count := count - 1
			    drawfillbox (0, 0, 0 + 50, 0 + 50, count)
			end if
		    label ESC :
			drawfillbox (0, 0, 0 + 50, 0 + 50, 7)
			locate (3, 1)
			put ""
			exit
		    label :
			locate (7, 1)
			centre ("SORRY WRONG KEY!!!")
			delay (1000)
			locate (7, 1)
			put ""
		end case
	    end loop
	label l :
	    var reply : string (1)
	    var xwhere, ywhere : int
	    xwhere := xgrid
	    ywhere := ygrid
	    loop
		find_color (ygrid, xgrid) := colr
		drawdot (x, y, colr)
		getch (reply)
		case ord (reply) of
		    label UP_ARROW :
			cursor (x, y, 7)
			if ygrid not= picHeight then
			    fillOldCurPos
			    y := y + 1
			    ygrid := ygrid + 1
			end if
			cursor (x, y, cur_clr)
		    label RIGHT_ARROW :
			cursor (x, y, 7)
			if xgrid not= picWidth then
			    fillOldCurPos
			    xgrid := xgrid + 1
			    x := x + 1
			end if
			cursor (x, y, cur_clr)
		    label LEFT_ARROW :
			cursor (x, y, 7)
			if xgrid not= 1 then
			    fillOldCurPos
			    xgrid := xgrid - 1
			    x := x - 1
			end if
			cursor (x, y, cur_clr)
		    label DOWN_ARROW :
			cursor (x, y, 7)
			if ygrid not= 1 then
			    fillOldCurPos
			    ygrid := ygrid - 1
			    y := y - 1
			end if
			cursor (x, y, cur_clr)
		    label ESC :
			exit
		    label :
			locate (7, 1)
			centre ("SORRY WRONG KEY")
			locate (7, 1)
			delay (1000)
			put ""
		end case
	    end loop
	label s :
	    locate (24, 1)
	    put "What do you want to save it as? " ..
	    var file : string
	    setscreen ("echo")
	    get file
	    locate (24, 1)
	    put ""
	    file := file + ".pic"
	    var stream : int
	    open : stream, file, put
	    var num : array 1 .. picHeight, 1 .. picWidth of int
	    for i : 1 .. picHeight
		for j : 1 .. picWidth
		    num (i, j) := find_color (i, j)
		    put : stream, num (i, j)
		end for
	    end for
	    close : stream
	    setscreen ("noecho")
	label e :
	    locate (24, 1)
	    put "Load what file? " ..
	    var file : string
	    setscreen ("echo")
	    get file
	    locate (24, 1)
	    put ""
	    file := file + ".pic"
	    var stream : int
	    open : stream, file, get
	    if stream <= 0 then
		locate (24, 1)
		put "SORRY FILE DOES NOT EXIST"
		delay (1000)
		locate (24, 1)
		put ""
	    else
		var num : int
		var grid : array 1 .. picHeight, 1 .. picWidth of int
		for i : 1 .. picHeight
		    for j : 1 .. picWidth
			get : stream, grid (i, j)
			find_color (i, j) := grid (i, j)
		    end for
		end for
		close : stream
		drawSprite
	    end if
	    setscreen ("noecho")
	label n :
	    cls
	    for i : 1 .. picHeight
		for j : 1 .. picWidth
		    find_color (i, j) := 7
		end for
	    end for
	    set_up
	label b :
	    locate (7, 1)
	    put "CHANGE CURSOR COLOR TO : " ..
	    setscreen ("echo")
	    get cur_clr
	    setscreen ("noecho")
	    locate (7, 1)
	    put ""
	label z :
	    var curX : int := x
	    var curY : int := y
	    var curScale : int := scale
	    if scale = 7 then
		scale := 1
	    else
		scale := scale + 1
	    end if
	    x := (floor (maxx / 2)) - (floor (picWidth * scale / 2)) + scale
	    y := (floor (maxy / 2)) - (floor (picHeight * scale / 2)) + scale
	    startX := x
	    startY := y
	    x := x + (xgrid - 1) * scale
	    y := y + (ygrid - 1) * scale
	    set_up
	    drawSprite
	    cursor (x, y, cur_clr)
	label ESC :
	    cls
	    exit
	label :
	    locate (7, 1)
	    centre ("SORRY WRONG KEY!!!")
	    delay (1000)
	    locate (7, 1)
	    put ""
    end case
end loop
