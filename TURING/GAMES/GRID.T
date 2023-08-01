setscreen ("graphics:m256")
setscreen ("noecho")
setscreen ("nocursor")
procedure land (x, y, clr1, clr2 : int)
    drawfillbox (x, y, x + 19, y + 19, clr1)
    drawdot (x + 5, y + 5, clr2)
    drawdot (x + 6, y + 4, clr2)
    drawdot (x + 7, y + 4, clr2)
    drawdot (x + 8, y + 5, clr2)
    drawdot (x + 9, y + 4, clr2)
    drawdot (x + 10, y + 4, clr2)
    drawdot (x + 11, y + 5, clr2)
    drawdot (x + 12, y + 4, clr2)
    drawdot (x + 13, y + 4, clr2)
    drawdot (x + 14, y + 4, clr2)
    drawdot (x + 15, y + 5, clr2)
    drawdot (x + 5, y + 15, clr2)
    drawdot (x + 6, y + 14, clr2)
    drawdot (x + 7, y + 14, clr2)
    drawdot (x + 8, y + 15, clr2)
    drawdot (x + 9, y + 14, clr2)
    drawdot (x + 10, y + 14, clr2)
    drawdot (x + 11, y + 15, clr2)
    drawdot (x + 12, y + 14, clr2)
    drawdot (x + 13, y + 14, clr2)
    drawdot (x + 14, y + 15, clr2)
    drawdot (x + 15, y + 15, clr2)
end land
var ch : string (1)
var grid : array 1 .. 9, 1 .. 16 of int
var clr_2 : array 1 .. 9, 1 .. 16 of int
for i : 1 .. 9
    for j : 1 .. 16
	clr_2 (i, j) := 0
	grid (i, j) := 0
    end for
end for
const UP_ARROW : int := 200
const RIGHT_ARROW : int := 205
const LEFT_ARROW : int := 203
const DOWN_ARROW : int := 208
const ENTER : int := 10
const ESC : int := 27
const c : int := 99
const s : int := 115
const e : int := 101
const p : int := 112
var x, y : int := 1
var xgrid, ygrid : int := 1
var clr : int := 32
var clr2 : int := 15
var num : array 1 .. 9, 1 .. 16 of int
var num2 : array 1 .. 9, 1 .. 16 of int
var file : string
var stream : int
loop
    locate (1, 1) put grid (ygrid, xgrid), " ", clr_2 (ygrid, xgrid)
    getch (ch)
    case ord (ch) of
	label UP_ARROW :
	    land (x, y, 0, 0)
	    if ygrid = 9 then
		sound (400, 200)
	    else
		y := y + 20
		ygrid := ygrid + 1
	    end if
	    if ygrid not= 1 then
		land (x, y - 20, grid (ygrid - 1, xgrid), clr_2 (ygrid - 1,
		    xgrid))
	    end if
	    land (x, y, clr, clr2)
	label RIGHT_ARROW :
	    land (x, y, 0, 0)
	    if xgrid = 16 then
		sound (400, 200)
	    else
		x := x + 20
		xgrid := xgrid + 1
	    end if
	    if xgrid not= 1 then
		land (x - 20, y, grid (ygrid, xgrid - 1), clr_2 (ygrid,
		    xgrid - 1))
	    end if
	    land (x, y, clr, clr2)
	label LEFT_ARROW :
	    land (x, y, 0, 0)
	    if xgrid = 1 then
		sound (400, 200)
	    else
		x := x - 20
		xgrid := xgrid - 1
	    end if
	    if xgrid not= 16 then
		land (x + 20, y, grid (ygrid, xgrid + 1), clr_2 (ygrid,
		    xgrid + 1))
	    end if
	    land (x, y, clr, clr2)
	label DOWN_ARROW :
	    land (x, y, 0, 0)
	    if ygrid = 1 then
		sound (400, 200)
	    else
		y := y - 20
		ygrid := ygrid - 1
	    end if
	    if ygrid not= 10 then
		land (x, y + 20, grid (ygrid + 1, xgrid), clr_2 (ygrid +
		    1,
		    xgrid))
	    end if
	    land (x, y, clr, clr2)
	label c :
	    locate (1, 1)
	    put "COLOUR # 1 TO : " ..
	    setscreen ("echo")
	    get clr
	    locate (1, 1)
	    put "COLOUR # 2 TO : " ..
	    get clr2
	    setscreen ("noecho")
	    locate (1, 1)
	    put ""
	label ENTER :
	    grid (ygrid, xgrid) := clr
	    clr_2 (ygrid, xgrid) := clr2
	label s :
	    locate (1, 1)
	    put "What do you want to save it as? " ..
	    setscreen ("echo")
	    get file
	    file := "a:/turing/games/world/" + file + ".wor"
	    locate (1, 1)
	    put ""
	    open : stream, file, put
	    for i : 1 .. 9
		for j : 1 .. 16
		    num (i, j) := grid (i, j)
		    num2 (i, j) := clr_2 (i, j)
		    put : stream, num (i, j)
		    put : stream, num2 (i, j)
		end for
	    end for
	    setscreen ("noecho")
	    close : stream
	label e :
	    locate (1, 1)
	    put "Load what file? " ..
	    setscreen ("echo")
	    get file
	    file := "a:/turing/games/world/" + file + ".wor"
	    locate (1, 1)
	    put ""
	    open : stream, file, get
	    if stream = 0 then
		locate (1, 1)
		put "SORRY FILE DOES NOT EXIST"
		delay (1000)
		locate (1, 1)
		put ""
	    else
		var tempx, tempy : int := 1
		for i : 1 .. 9
		    tempx := 1
		    for j : 1 .. 16
			get : stream, grid (i, j)
			get : stream, clr_2 (i, j)
			land (tempx, tempy, grid (i, j), clr_2 (i, j))
			tempx := tempx + 20
		    end for
		    tempy := tempy + 20
		end for
		close : stream
	    end if
	    setscreen ("noecho")
	label p :
	    var colr : int := 1
	    loop
		getch (ch)
		case ord (ch) of
		    label UP_ARROW :
			if colr = 255 then
			    sound (400, 200)
			else
			    colr := colr + 1
			end if
			locate (1, 1)
			put colr
			drawfillbox (150, 190, 150 + 10, 190 + 9, colr)
		    label DOWN_ARROW :
			if colr = 0 then
			    sound (400, 200)
			else
			    colr := colr - 1
			end if
			locate (1, 1)
			put colr
			drawfillbox (150, 190, 150 + 10, 190 + 9, colr)
		    label ESC :
			locate (1, 1)
			put ""
			drawfillbox (150, 190, 150 + 10, 190 + 9, 0)
			exit
		    label :
		end case
	    end loop
	label ESC :
	    cls
	    exit
	label :
	    locate (1, 1)
	    put "SORRY WRONG KEY"
	    delay (1000)
	    locate (1, 1)
	    put ""
    end case
end loop
