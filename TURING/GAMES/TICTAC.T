setscreen ("graphics:m256")
setscreen ("noecho")
setscreen ("nocursor")
procedure board
    colorback (8)
    var x : int := round (maxx / 3)
    var y : int := round (maxy / 3)
    drawfillbox (x, 0, x + 5, 0 + maxy, 4)
    drawfillbox (x * 2, 0, x * 2 + 5, 0 + maxy, 4)
    drawfillbox (0, y, 0 + maxx, y + 5, 4)
    drawfillbox (0, y * 2, 0 + maxx, y * 2 + 5, 4)
end board
procedure tic (x, y, clr : int)
    drawline (x + 5, y + 5, x + 95, y + 58, clr)
    drawline (x + 95, y + 5, x + 5, y + 58, clr)
end tic
procedure tac (x, y, clr : int)
    drawoval (x + 50, y + 31, 47, 28, clr)
end tac
procedure movement (move : int, var grid : array 1 .. 3, 1 .. 3 of int)
    var xgrid, ygrid : int := 1
    var x, y : int := 0
    const UP_ARROW : int := 200
    const LEFT_ARROW : int := 203
    const RIGHT_ARROW : int := 205
    const DOWN_ARROW : int := 208
    const ENTER : int := 10
    var ch : string (1)
    loop
	getch (ch)
	case ord (ch) of
	    label UP_ARROW :
		if move = 1 then
		    tic (x, y, 8)
		elsif move = 2 then
		    tac (x, y, 8)
		end if
		if ygrid = 3 then
		else
		    y := y + 70
		    ygrid := ygrid + 1
		    if ygrid not= 1 then
			if grid (ygrid - 1, xgrid) not= 0 then
			    if grid (ygrid - 1, xgrid) = 1 then
				tic (x, y - 70, 14)
			    elsif grid (ygrid - 1, xgrid) = 2 then
				tac (x, y - 70, 14)
			    end if
			end if
		    end if
		end if
		if move = 1 then
		    tic (x, y, 32)
		elsif move = 2 then
		    tac (x, y, 32)
		end if
	    label RIGHT_ARROW :
		if move = 1 then
		    tic (x, y, 8)
		elsif move = 2 then
		    tac (x, y, 8)
		end if
		if xgrid = 3 then
		else
		    x := x + 110
		    xgrid := xgrid + 1
		    if xgrid not= 1 then
			if grid (ygrid, xgrid - 1) not= 0 then
			    if grid (ygrid, xgrid - 1) = 1 then
				tic (x - 110, y, 14)
			    elsif grid (ygrid, xgrid - 1) = 2 then
				tac (x - 110, y, 14)
			    end if
			end if
		    end if
		end if
		if move = 1 then
		    tic (x, y, 32)
		elsif move = 2 then
		    tac (x, y, 32)
		end if
	    label LEFT_ARROW :
		if move = 1 then
		    tic (x, y, 8)
		elsif move = 2 then
		    tac (x, y, 8)
		end if
		if xgrid = 1 then
		else
		    x := x - 110
		    xgrid := xgrid - 1
		    if xgrid not= 3 then
			if grid (ygrid, xgrid + 1) not= 0 then
			    if grid (ygrid, xgrid + 1) = 1 then
				tic (x + 110, y, 14)
			    elsif grid (ygrid, xgrid + 1) = 2 then
				tac (x + 110, y, 14)
			    end if
			end if
		    end if
		end if
		if move = 1 then
		    tic (x, y, 32)
		elsif move = 2 then
		    tac (x, y, 32)
		end if
	    label DOWN_ARROW :
		if move = 1 then
		    tic (x, y, 8)
		elsif move = 2 then
		    tac (x, y, 8)
		end if
		if ygrid = 1 then
		else
		    y := y - 70
		    ygrid := ygrid - 1
		    if ygrid not= 3 then
			if grid (ygrid + 1, xgrid) not= 0 then
			    if grid (ygrid + 1, xgrid) = 1 then
				tic (x, y + 70, 14)
			    elsif grid (ygrid + 1, xgrid) = 2 then
				tac (x, y + 70, 14)
			    end if
			end if
		    end if
		end if
		if move = 1 then
		    tic (x, y, 32)
		elsif move = 2 then
		    tac (x, y, 32)
		end if
	    label ENTER :
		if grid (ygrid, xgrid) = 0 then
		    if move = 1 then
			grid (ygrid, xgrid) := 1
		    elsif move = 2 then
			grid (ygrid, xgrid) := 2
		    end if
		    exit
		else
		    sound (400, 200)
		end if
	end case
    end loop
end movement
var grid : array 1 .. 3, 1 .. 3 of int
for i : 1 .. 3
    for j : 1 .. 3
	grid (i, j) := 0
    end for
end for
board
loop
    movement (1, grid)
    movement (2, grid)
end loop
