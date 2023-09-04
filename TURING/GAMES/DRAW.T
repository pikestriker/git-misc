% default graphics has 640x400 graphics
setscreen ("graphics")
setscreen ("nocursor")
setscreen ("noecho")
color(0)
colorback(7)
var picWidth :int := 57
var picHeight :int := 67
% this is the newest addition since 0 is now white in the windows version (7 is black)
var backColour :int := 7
var find_color : array 1 .. picHeight, 1 .. picWidth of int
for i : 1 .. picHeight
	for j : 1 .. picWidth
		find_color (i, j) := 7
	end for
end for
procedure cursor (var x, y : int, clr : int)
	drawdot (x + 1, y, clr)
	drawdot (x - 1, y, clr)
	drawdot (x, y + 1, clr)
	drawdot (x, y - 1, clr)
end cursor
procedure set_up
	drawfillbox(0, 0, maxx, maxy, 7)
	put "COLOUR : "
	var row, col : int
	row := round (maxx / 2 - 30)
	col := round (maxy / 2 - 35)
	drawbox (row, col, row + picWidth + 3, col + picHeight + 3, 0)
	drawbox (row - 1, col - 1, row + picWidth + 4, col + picHeight + 4, 0)
end set_up
procedure centre (s : string)
	var diff : int := round ( (40 - length (s)) / 2)
	put repeat (" ", diff) ..
	put s
end centre

set_up
var x, y : int
var cur_clr : int := 0
% x and y is the physical location of the cursor on the screen
x := (floor(maxx / 2)) - (floor(picWidth / 2)) + 1
y := (floor(maxy / 2)) - (floor(picHeight / 2)) + 1
const startX : int := x - 1
const startY : int := y - 1
% ygrid and xgrid is the relative position of the cursor in the window
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
const n : int := 110
const b : int := 98
var colr : int := 0
var colrc : boolean := true
var ch : string (1)

procedure fillOldCurPos
	% we have x, y and xgrid and ygrid (relative position)
	% lets do a 5x5 around the cursor position to make it easier
	var curx : int
	var cury : int
	for i : -2 .. 2
		for j : -2 .. 2
			curx := xgrid + i
			cury := ygrid + j
			if curx >= 1 and curx <= picWidth and
				cury >= 1 and cury <= picHeight then
				drawdot(curx + startX, cury + startY, find_color(cury, curx))
			end if
		end for
	end for
end fillOldCurPos

loop
	locate (2, 1)
	put "DOT COLOUR : ", find_color (ygrid, xgrid)
	locate (1, 10)
	put colr
	getch (ch)
	case ord (ch) of
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
						drawdot (j + startX, i + startY, grid (i, j))
						find_color (i, j) := grid (i, j)
					end for
				end for
				close : stream
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
