setscreen ("graphics:m256")
setscreen ("nocursor")
setscreen ("noecho")
var find_color : array 1 .. 67, 1 .. 57 of int
for i : 1 .. 67
    for j : 1 .. 57
	find_color (i, j) := 0
    end for
end for
procedure cursor (var x, y : int, clr : int)
    drawdot (x + 1, y, clr)
    drawdot (x - 1, y, clr)
    drawdot (x, y + 1, clr)
    drawdot (x, y - 1, clr)
end cursor
procedure set_up
    put "COLOUR : "
    var row, col : int
    row := round (maxx / 2 - 30)
    col := round (maxy / 2 - 35)
    drawbox (row, col, row + 60, col + 70, 15)
end set_up
procedure centre (s : string)
    var diff : int := round ( (40 - length (s)) / 2)
    put repeat (" ", diff) ..
    put s
end centre

set_up
var x, y : int
x := 132
y := 67
var ygrid, xgrid : int := 1
var clr : int
cursor (x, y, 15)
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
var colr : int
var ch : string (1)
loop
    locate (2, 1)
    put ""
    locate (2, 1)
    put x, " ", y
    put "DOT COLOUR : ", find_color (ygrid, xgrid)
    put ygrid, " ", xgrid
    getch (ch)
    case ord (ch) of
	label UP_ARROW :
	    cursor (x, y, 0)
	    if ygrid = 67 then
		locate (7, 1)
		centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
		delay (1000)
		locate (7, 1)
		put ""
	    elsif ygrid not= 67 then
		y := y + 1
		ygrid := ygrid + 1
		if ygrid > 2 then
		    drawdot (x, y - 2, find_color (ygrid - 2, xgrid))
		end if
		if ygrid > 1 and xgrid > 1 then
		    drawdot (x - 1, y - 1, find_color (ygrid - 1, xgrid - 1))
		end if
		if xgrid < 57 and ygrid > 1 then
		    drawdot (x + 1, y - 1, find_color (ygrid - 1, xgrid + 1))
		end if
		drawdot (x, y, find_color (ygrid, xgrid))
	    end if
	    cursor (x, y, 15)
	label RIGHT_ARROW :
	    cursor (x, y, 0)
	    if xgrid = 57 then
		locate (7, 1)
		centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
		delay (1000)
		locate (7, 1)
		put ""
	    elsif xgrid not= 57 then
		xgrid := xgrid + 1
		x := x + 1
		if xgrid > 2 then
		    drawdot (x - 2, y, find_color (ygrid, xgrid - 2))
		end if
		if ygrid > 1 and xgrid > 1 then
		    drawdot (x - 1, y - 1, find_color (ygrid - 1, xgrid - 1))
		end if
		if xgrid > 1 and ygrid < 67 then
		    drawdot (x - 1, y + 1, find_color (ygrid + 1, xgrid - 1))
		end if
		drawdot (x, y, find_color (ygrid, xgrid))
	    end if
	    cursor (x, y, 15)
	label LEFT_ARROW :
	    cursor (x, y, 0)
	    if xgrid = 1 then
		locate (7, 1)
		centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
		delay (1000)
		locate (7, 1)
		put ""
	    elsif xgrid not= 1 then
		xgrid := xgrid - 1
		x := x - 1
		if xgrid < 56 then
		    drawdot (x + 2, y, find_color (ygrid, xgrid + 2))
		end if
		if ygrid < 67 and xgrid < 57 then
		    drawdot (x + 1, y + 1, find_color (ygrid + 1, xgrid + 1))
		end if
		if xgrid < 57 and ygrid > 1 then
		    drawdot (x + 1, y - 1, find_color (ygrid - 1, xgrid + 1))
		end if
		drawdot (x, y, find_color (ygrid, xgrid))
	    end if
	    cursor (x, y, 15)
	label DOWN_ARROW :
	    cursor (x, y, 0)
	    if ygrid = 1 then
		locate (7, 1)
		centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
		delay (1000)
		locate (7, 1)
		put ""
	    elsif ygrid not= 1 then
		ygrid := ygrid - 1
		y := y - 1
		if ygrid < 66 then
		    drawdot (x, y + 2, find_color (ygrid + 2, xgrid))
		end if
		if xgrid > 1 and ygrid < 67 then
		    drawdot (x - 1, y + 1, find_color (ygrid + 1, xgrid - 1))
		end if
		if ygrid < 67 and xgrid < 57 then
		    drawdot (x + 1, y + 1, find_color (ygrid + 1, xgrid + 1))
		end if
		drawdot (x, y, find_color (ygrid, xgrid))
	    end if
	    cursor (x, y, 15)
	label c :
	    locate (1, 10)
	    put ""
	    setscreen ("echo")
	    locate (1, 10)
	    get colr
	    setscreen ("noecho")
	label d :
	    drawdot (x, y, colr)
	    find_color (ygrid, xgrid) := colr
	label a :
	    locate (7, 1)
	    var tclr : int
	    setscreen ("echo")
	    put "CHANGE COLOUR TO : " ..
	    get tclr
	    var old_color : int := find_color (ygrid, xgrid)
	    locate (7, 1)
	    put ""
	    for i : 1 .. 67
		for j : 1 .. 57
		    if find_color (i, j) = old_color then
			find_color (i, j) := tclr
			drawdot (j + 131, i + 66, tclr)
		    end if
		end for
	    end for
	    setscreen ("noecho")
	    cursor (x, y, 15)
	label p :
	    var reply : string (1)
	    var count : int := 0
	    loop
		locate (5, 1)
		put count
		getch (reply)
		case ord (reply) of
		    label UP_ARROW :
			if count = 255 then
			    sound (400, 200)
			elsif count < 255 then
			    count := count + 1
			    drawfillbox (0, 0, 0 + 50, 0 + 50, count)
			end if
		    label DOWN_ARROW :
			if count = 0 then
			    sound (400, 200)
			elsif count > 0 then
			    count := count - 1
			    drawfillbox (0, 0, 0 + 50, 0 + 50, count)
			end if
		    label ESC :
			drawfillbox (0, 0, 0 + 50, 0 + 50, 0)
			locate (5, 1)
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
			cursor (x, y, 0)
			if ygrid = 67 then
			    locate (7, 1)
			    centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
			    delay (1000)
			    locate (7, 1)
			    put ""
			elsif ygrid not= 67 then
			    y := y + 1
			    ygrid := ygrid + 1
			    if ygrid > 2 then
				drawdot (x, y - 2, find_color (ygrid - 2,
				    xgrid))
			    end if
			    if ygrid > 1 and xgrid > 1 then
				drawdot (x - 1, y - 1, find_color (ygrid -
				    1, xgrid - 1))
			    end if
			    if xgrid < 57 and ygrid > 1 then
				drawdot (x + 1, y - 1, find_color (ygrid -
				    1, xgrid + 1))
			    end if
			    drawdot (x, y, find_color (ygrid, xgrid))
			end if
			cursor (x, y, 15)
		    label RIGHT_ARROW :
			cursor (x, y, 0)
			if xgrid = 57 then
			    locate (7, 1)
			    centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
			    delay (1000)
			    locate (7, 1)
			    put ""
			elsif xgrid not= 57 then
			    xgrid := xgrid + 1
			    x := x + 1
			    if xgrid > 2 then
				drawdot (x - 2, y, find_color (ygrid, xgrid
				    - 2))
			    end if
			    if ygrid > 1 and xgrid > 1 then
				drawdot (x - 1, y - 1, find_color (ygrid -
				    1, xgrid - 1))
			    end if
			    if xgrid > 1 and ygrid < 67 then
				drawdot (x - 1, y + 1, find_color (ygrid +
				    1, xgrid - 1))
			    end if
			    drawdot (x, y, find_color (ygrid, xgrid))
			end if
			cursor (x, y, 15)
		    label LEFT_ARROW :
			cursor (x, y, 0)
			if xgrid = 1 then
			    locate (7, 1)
			    centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
			    delay (1000)
			    locate (7, 1)
			    put ""
			elsif xgrid not= 1 then
			    xgrid := xgrid - 1
			    x := x - 1
			    if xgrid < 56 then
				drawdot (x + 2, y, find_color (ygrid, xgrid
				    + 2))
			    end if
			    if ygrid < 67 and xgrid < 57 then
				drawdot (x + 1, y + 1, find_color (ygrid +
				    1, xgrid + 1))
			    end if
			    if xgrid < 57 and ygrid > 1 then
				drawdot (x + 1, y - 1, find_color (ygrid -
				    1, xgrid + 1))
			    end if
			    drawdot (x, y, find_color (ygrid, xgrid))
			end if
			cursor (x, y, 15)
		    label DOWN_ARROW :
			cursor (x, y, 0)
			if ygrid = 1 then
			    locate (7, 1)
			    centre ("SORRY CAN'T MOVE IN THAT DIRECTION")
			    delay (1000)
			    locate (7, 1)
			    put ""
			elsif ygrid not= 1 then
			    ygrid := ygrid - 1
			    y := y - 1
			    if ygrid < 66 then
				drawdot (x, y + 2, find_color (ygrid + 2,
				    xgrid))
			    end if
			    if xgrid > 1 and ygrid < 67 then
				drawdot (x - 1, y + 1, find_color (ygrid +
				    1, xgrid - 1))
			    end if
			    if ygrid < 67 and xgrid < 57 then
				drawdot (x + 1, y + 1, find_color (ygrid +
				    1, xgrid + 1))
			    end if
			    drawdot (x, y, find_color (ygrid, xgrid))
			end if
			cursor (x, y, 15)
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
	    file := "a:/turing/games/" + file + ".pic"
	    var stream : int
	    open : stream, file, put
	    var num : array 1 .. 67, 1 .. 57 of int
	    for i : 1 .. 67
		for j : 1 .. 57
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
	    file := "a:/turing/games/" + file + ".pic"
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
		var grid : array 1 .. 67, 1 .. 57 of int
		for i : 1 .. 67
		    for j : 1 .. 57
			get : stream, grid (i, j)
			drawdot (j + 131, i + 66, grid (i, j))
			find_color (i, j) := grid (i, j)
		    end for
		end for
	    end if
	    setscreen ("noecho")
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
