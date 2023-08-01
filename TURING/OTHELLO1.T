%Richard Dickerson
%Major Project
%This program is a remake of the original board game othello

%These variables are for the procedures
var xr, yr, y, x, x1, y1, clr, cr1 : int
var clr1 : string

%This array is for my text othello
var grid : array 1 .. 8, 1 .. 8 of string

%This is to read in values into my array
for i : 1 .. 8
    for j : 1 .. 8
	grid (i, j) := ""
    end for
end for

%These are the set up chips for the text othello
grid (4, 4) := "black"
grid (4, 5) := "white"
grid (5, 4) := "white"
grid (5, 5) := "black"
var where : int := 0
var ycheck : int

%These variables are for the location of my text othello
var ygrid : int := 8
var xgrid : int := 1
x := 27
y := 27
xr := 25
yr := 25

%The constants are for moving the chip around
const UP_ARROW : int := 200
const LEFT_ARROW : int := 203
const RIGHT_ARROW : int := 205
const DOWN_ARROW : int := 208
const ESC : int := 27
const RETURN : int := 10
const SPACE : int := 32
%These constants are the width, and height of my grid squares
const height := 54
const width := 54

%This procedure is for the border with numbers to count the chips
procedure border (var whitecount, blackcount : int)
    drawfillbox (maxx, 446, maxx - 180, 446 - 446, 11)
    drawfillbox (500, 190, 500 + 20, 190 + 20, 0)
    drawfillbox (500, 220, 500 + 20, 220 + 20, 15)
    color (15)
    locate (16, 67)
    put whitecount
    locate (18, 67)
    put blackcount
    drawfillbox (maxx, 446, maxx - 90, 446 - 446, 11)
end border

%This procedure is to centre text in the middle of the screen
procedure centre (text : string)
    var diff : int := round ( (80 - length (text)) / 2)
    put repeat (" ", diff) ..
    put text
end centre

%This procedure is for my starting chips, and the chips that flip
procedure chips (x1, y1, clr : int)
    drawoval (x1, y1, xr, yr, clr)
    drawfill (x1 + 1, y1 + 1, clr, clr)
end chips

%This procedure is for the chp that movves around
procedure circle (clr : int)
    drawoval (x, y, xr, yr, clr)
    drawfill (x + 1, y + 1, clr, clr)
end circle

%This is the procedure with my first square for the grid
procedure box
    drawbox (0, 0, 0 + 54, 0 + 54, 10)
    drawfill (0 + 1, 0 + 1, 10, 10)
end box

%This procedure is to see if the player can make a move before going
procedure turn (c1, c2 : string, var chipcheck : boolean)
    var ycount : int := ygrid
    var xcount : int := xgrid
    chipcheck := false

    %These two for end for loops are to check each grid sqaure
    for i : 1 .. 8
	for j : 1 .. 8
	    if grid (i, j) = "" then

		%This one is to check down for any moves
		if i not= 8 then
		    if grid (i + 1, j) = c1 then
			for y : i + 1 .. 8
			    if grid (y, j) = c2 then
				chipcheck := true
			    end if
			end for
		    end if
		end if
		exit when chipcheck = true

		%This one is to check up for any moves
		if i not= 1 then
		    if grid (i - 1, j) = c1 then
			for decreasing y : i - 1 .. 1
			    if grid (y, j) = c2 then
				chipcheck := true
			    end if
			end for
		    end if
		end if
		exit when chipcheck = true

		%This one is to check to the right for any moves
		if j not= 8 then
		    if grid (i, j + 1) = c1 then
			for x : j + 1 .. 8
			    if grid (i, x) = c2 then
				chipcheck := true
			    end if
			end for
		    end if
		end if
		exit when chipcheck = true

		%This one is to check to the left for any moves
		if j not= 1 then
		    if grid (i, j - 1) = c1 then
			for decreasing x : j - 1 .. 1
			    if grid (i, x) = c2 then
				chipcheck := true
			    end if
			end for
		    end if
		end if
		exit when chipcheck = true
		xcount := j

		%This one checks up to the right for any moves
		if i not= 1 then
		    if j not= 8 then
			if grid (i - 1, j + 1) = c1 then
			    for decreasing y : i - 1 .. 1
				loop
				    xcount := xcount + 1
				    if grid (y, xcount) = c2 then
					chipcheck := true
				    end if
				    exit
				end loop
				exit when xcount = 8
				exit when grid (y, xcount) = ""
				exit when chipcheck = true
			    end for
			    xcount := j
			end if
		    end if
		end if
		exit when chipcheck = true
		xcount := j

		%This one checks up to the left for any moves
		if i not= 1 then
		    if j not= 1 then
			if grid (i - 1, j - 1) = c1 then
			    for decreasing y : i - 1 .. 1
				loop
				    xcount := xcount - 1
				    if grid (y, xcount) = c2 then
					chipcheck := true
				    end if
				    exit
				end loop
				exit when xcount = 1
				exit when grid (y, xcount) = ""
				exit when chipcheck = true
			    end for
			    xcount := j
			end if
		    end if
		end if
		exit when chipcheck = true
		xcount := j

		%This one checks down to the left for any moves
		if i not= 8 then
		    if j not= 1 then
			if grid (i + 1, j - 1) = c1 then
			    for y : i + 1 .. 8
				loop
				    xcount := xcount - 1
				    if grid (y, xcount) = c2 then
					chipcheck := true
				    end if
				    exit
				end loop
				exit when xcount = 1
				exit when grid (y, xcount) = ""
				exit when chipcheck = true
			    end for
			    xcount := j
			end if
		    end if
		end if
		exit when chipcheck = true
		xcount := j

		%This checks down to the right for any moves
		if i not= 8 then
		    if j not= 8 then
			if grid (i + 1, j + 1) = c1 then
			    for y : i + 1 .. 8
				loop
				    xcount := xcount + 1
				    if grid (y, xcount) = c2 then
					chipcheck := true
				    end if
				    exit
				end loop
				exit when xcount = 8
				exit when grid (y, xcount) = ""
				exit when chipcheck = true
			    end for
			end if
		    end if
		end if
	    end if
	    exit when chipcheck = true
	end for
	exit when chipcheck = true
    end for
end turn

%This procedure is to flip the chips in every direction
procedure flip (xgrid, ygrid, ycheck, colr : int, c1, c2 : string, var
	check : boolean, var whitecount, blackcount : int)
    check := false

    %These variables are for tis procedure alone
    var flipcheck : boolean := false
    var countx, xcount : int := xgrid
    whitecount := 0
    blackcount := 0

    %This variable alonemakes it work for the graphic othello
    var county : int := ycheck
    var where : int := 1

    %These two variables are for chip counters

    %This one is to flip the chips in the right direction
    if xgrid not= 8 then
	if grid (ygrid, xgrid + 1) = c1 then
	    for i : xgrid + 1 .. 8
		exit when grid (ygrid, i) = ""
		if grid (ygrid, i) = c2 then
		    where := i
		    check := true
		    flipcheck := true
		    for x : xgrid .. where
			grid (ygrid, x) := c2
			chips (x * 56 - 29, county * 56 - 29, colr)
		    end for
		    exit
		end if
		exit when grid (ygrid, i) = ""
	    end for
	end if
    end if

    %This one is to flip any chips to the left
    if xgrid not= 1 then
	if grid (ygrid, xgrid - 1) = c1 then
	    for decreasing i : xgrid - 1 .. 1
		exit when grid (ygrid, i) = ""
		if grid (ygrid, i) = c2 then
		    where := i
		    check := true
		    for decreasing x : xgrid .. where
			grid (ygrid, x) := c2
			chips (x * 56 - 29, county * 56 - 29, colr)
		    end for
		    exit
		end if
		exit when grid (ygrid, i) = ""
	    end for
	end if
    end if
    county := ycheck

    %This one is to flip chips in the up direction
    if ygrid not= 1 then
	if grid (ygrid - 1, xgrid) = c1 then
	    for decreasing i : ygrid - 1 .. 1
		exit when grid (i, xgrid) = ""
		if grid (i, xgrid) = c2 then
		    where := i
		    check := true
		    for decreasing y : ygrid .. where
			grid (y, xgrid) := c2
			chips (xgrid * 56 - 29, county * 56 - 29, colr)
			county := county + 1
		    end for
		    exit
		end if
		exit when grid (i, xgrid) = ""
	    end for
	end if
    end if
    county := ycheck

    %This is to flp chips in the down direction
    if ygrid not= 8 then
	if grid (ygrid + 1, xgrid) = c1 then
	    for i : ygrid + 1 .. 8
		exit when grid (i, xgrid) = ""
		if grid (i, xgrid) = c2 then
		    where := i
		    check := true
		    for y : ygrid .. where
			grid (y, xgrid) := c2
			chips (xgrid * 56 - 29, county * 56 - 29, colr)
			county := county - 1
		    end for
		    exit
		end if
		exit when grid (i, xgrid) = ""
	    end for
	end if
    end if
    county := ycheck
    countx := xgrid
    xcount := xgrid
    flipcheck := false

    %This one flips chips up to the right direction
    if ygrid not= 1 and xgrid not= 8 then
	if grid (ygrid - 1, xgrid + 1) = c1 then
	    for decreasing y : ygrid - 1 .. 1
		countx := countx + 1
		if countx > 8 then
		    exit
		end if
		exit when grid (y, countx) = ""
		loop
		    if grid (y, countx) = c2 then
			where := y
			check := true
			flipcheck := true
			for decreasing i : ygrid .. where
			    loop
				grid (i, xcount) := c2
				chips (xcount * 56 - 29, county * 56 -
				    29,
				    colr)
				xcount := xcount + 1
				county := county + 1
				exit
			    end loop
			end for
		    end if
		    exit
		end loop
		exit when flipcheck
	    end for
	end if
    end if
    county := ycheck
    countx := xgrid
    xcount := xgrid
    flipcheck := false

    %This one flips chips down to the right
    if ygrid not= 8 and xgrid not= 8 then
	if grid (ygrid + 1, xgrid + 1) = c1 then
	    for y : ygrid + 1 .. 8
		countx := countx + 1
		if countx > 8 then
		    exit
		end if
		exit when grid (y, countx) = ""
		loop
		    if grid (y, countx) = c2 then
			where := y
			check := true
			flipcheck := true
			for i : ygrid .. where
			    loop
				grid (i, xcount) := c2
				chips (xcount * 56 - 29, county * 56
				    - 29, colr)
				xcount := xcount + 1
				county := county - 1
				exit
			    end loop
			end for
		    end if
		    exit
		end loop
		exit when flipcheck
	    end for
	end if
    end if
    county := ycheck
    countx := xgrid
    xcount := xgrid
    flipcheck := false

    %This one flips chips up to the left
    if ygrid not= 1 and xgrid not= 1 then
	if grid (ygrid - 1, xgrid - 1) = c1 then
	    for decreasing y : ygrid - 1 .. 1
		countx := countx - 1
		if countx < 1 then
		    exit
		end if
		exit when grid (y, countx) = ""
		loop
		    if grid (y, countx) = c2 then
			where := y
			check := true
			flipcheck := true
			for decreasing i : ygrid .. where
			    loop
				grid (i, xcount) := c2
				chips (xcount * 56 - 29, county * 56
				    - 29, colr)
				county := county + 1
				xcount := xcount - 1
				exit
			    end loop
			end for
		    end if
		    exit
		end loop
		exit when flipcheck
	    end for
	end if
    end if
    county := ycheck
    countx := xgrid
    xcount := xgrid
    flipcheck := false

    %This one flips chips down to the left
    if ygrid not= 8 and xgrid not= 1 then
	if grid (ygrid + 1, xgrid - 1) = c1 then
	    for y : ygrid + 1 .. 8
		countx := countx - 1
		if countx < 1 then
		    exit
		end if
		exit when grid (y, countx) = ""
		loop
		    if grid (y, countx) = c2 then
			where := y
			check := true
			flipcheck := true
			for i : ygrid .. where
			    loop
				grid (i, xcount) := c2
				chips (xcount * 56 - 29, county * 56
				    - 29, colr)
				xcount := xcount - 1
				county := county - 1
				exit
			    end loop
			end for
		    end if
		    exit
		end loop
		exit when flipcheck
	    end for
	end if
    end if
    %These two for loops count the number of chips there is in each color
    for i : 1 .. 8
	for j : 1 .. 8
	    if grid (i, j) = "black" then
		blackcount := blackcount + 1
	    elsif grid (i, j) = "white" then
		whitecount := whitecount + 1
	    end if
	end for
    end for
    border (whitecount, blackcount)
end flip

%This procedure is to move the chip around
procedure movement (c1, c2 : string, colr, chipcolr : int, var
	checkcount : int, var exitcheck : boolean, var whitecount, blackcount
	: int)
    exitcheck := false
    var skipcount : int := - 1
    var ygrid, xgrid : int := 1
    var ycheck : int := 8
    var ch : string (1)
    var xwhere, ywhere : int := 1
    x := 27
    y := 419
    var chipcheck : boolean := false
    var xycheck : boolean := false

    %This is where I call my checking procedure
    turn (c1, c2, chipcheck)
    if chipcheck = false then
	checkcount := checkcount + 1
    else
	checkcount := 0
    end if

    %This part is to find an empty space on the bord an place it there
    for i : 1 .. 8
	exit when chipcheck = false
	if i > 1 then
	    ycheck := ycheck - 1
	end if
	for j : 1 .. 8
	    if grid (i, j) = "" then
		xwhere := j
		ywhere := i
		x := j * 56 - 29
		y := ycheck * 56 - 29
		xgrid := j
		ygrid := i
		exit
	    end if
	end for
	exit when grid (ywhere, xwhere) = ""
    end for
    if chipcheck then
	grid (ywhere, xwhere) := c2
	circle (chipcolr)
    end if
    loop
	exit when chipcheck = false
	xycheck := false
	skipcount := - 1

	%When I getch it just needs one character instead of pressing a
	%key followed by Enter
	getch (ch)

	%This case structure is to move the chip around on the board
	case ord (ch) of
	    label UP_ARROW :

		%This is to see that the chip doesn't go over the board
		if y > 419 then
		    y := y - 56
		    ycheck := ycheck - 1
		    ygrid := ygrid + 1
		end if

		%This is to check if the chip ahead of yours is a different
		%color.  If it is it will skip over those chips to the next
		%empty space
		if ygrid not= 1 then
		    if grid (ygrid - 1, xgrid) not= "" then
			for decreasing i : ygrid .. 1
			    skipcount := skipcount + 1
			    if grid (i, xgrid) = "" then
				xycheck := true
				grid (ygrid, xgrid) := ""
				circle (10)
				ygrid := i
				ycheck := ycheck + skipcount
				y := ycheck * 56 - 29
				grid (ygrid, xgrid) := c2
				circle (chipcolr)
			    end if
			    exit when xycheck
			end for

			%This is to just move it one space
		    elsif grid (ygrid - 1, xgrid) = "" then
			circle (10)
			grid (ygrid, xgrid) := ""
			y := y + 56
			ycheck := ycheck + 1
			ygrid := ygrid - 1
			grid (ygrid, xgrid) := c2
			circle (chipcolr)
		    end if
		end if
	    label RIGHT_ARROW :

		%This is to see that the chip doesn't go over the board
		if x > 419 then
		    x := x - 56
		    xgrid := xgrid - 1
		    sound (400, 200)
		end if

		%This is to check if the chip ahead of yours is a different
		%color.  If it is it will skip over those chips to the next
		%empty space
		if xgrid not= 8 then
		    if grid (ygrid, xgrid + 1) not= "" then
			for i : xgrid .. 8
			    if grid (ygrid, i) = "" then
				xycheck := true
				grid (ygrid, xgrid) := ""
				circle (10)
				x := i * 56 - 29
				xgrid := i
				grid (ygrid, xgrid) := c2
				circle (chipcolr)
			    end if
			    exit when xycheck
			end for

			%This is to just move it one space
		    elsif grid (ygrid, xgrid + 1) = "" then
			grid (ygrid, xgrid) := ""
			circle (10)
			xgrid := xgrid + 1
			x := x + 56
			grid (ygrid, xgrid) := c2
			circle (chipcolr)
		    end if
		end if
	    label LEFT_ARROW :

		%This is to see that the chip doesn't go over the board
		if x < 27 then
		    x := x + 56
		    xgrid := xgrid + 1
		    sound (400, 200)
		end if

		%This is to check if the chip ahead of yours is a different
		%color.  If it is it will skip over those chips to the next
		%empty space
		if xgrid not= 1 then
		    if grid (ygrid, xgrid - 1) not= "" then
			for decreasing i : xgrid .. 1
			    if grid (ygrid, i) = "" then
				xycheck := true
				grid (ygrid, xgrid) := ""
				circle (10)
				xgrid := i
				x := i * 56 - 29
				grid (ygrid, xgrid) := c2
				circle (chipcolr)
			    end if
			    exit when xycheck
			end for

			%This is to just move it one space
		    elsif grid (ygrid, xgrid - 1) = "" then
			grid (ygrid, xgrid) := ""
			circle (10)
			xgrid := xgrid - 1
			x := x - 56
			grid (ygrid, xgrid) := c2
			circle (chipcolr)
		    end if
		end if
	    label DOWN_ARROW :

		%This is to see that the chip doesn't go over the board
		if y < 27 then
		    y := y + 56
		    ycheck := ycheck + 1
		    ygrid := ygrid - 1
		    sound (400, 200)
		end if

		%This is to check if the chip ahead of yours is a different
		%color.  If it is it will skip over those chips to the next
		%empty space
		if ygrid not= 8 then
		    if grid (ygrid + 1, xgrid) not= "" then
			for i : ygrid .. 8
			    skipcount := skipcount + 1
			    if grid (i, xgrid) = "" then
				xycheck := true
				grid (ygrid, xgrid) := ""
				circle (10)
				ycheck := ycheck - skipcount
				ygrid := i
				y := ycheck * 56 - 29
				grid (ygrid, xgrid) := c2
				circle (chipcolr)
			    end if
			    exit when xycheck
			end for

			%This is to just move it one space
		    elsif grid (ygrid + 1, xgrid) = "" then
			circle (10)
			grid (ygrid, xgrid) := ""
			y := y - 56
			ycheck := ycheck - 1
			ygrid := ygrid + 1
			grid (ygrid, xgrid) := c2
			circle (chipcolr)
		    end if
		end if

		%This is to is the button to be pressed when you want to
		%flip chips
	    label RETURN :
		var check : boolean := false

		%This is where I call my flip procedure
		grid (ygrid, xgrid) := ""
		flip (xgrid, ygrid, ycheck, colr, c1, c2, check, whitecount,
		    blackcount)
		exit when check
		sound (400, 200)
	    label SPACE :
		setscreen ("echo")
		locate (1, 1)
		centre ("what grid do you want to move to?")
		var x_grid, y_grid : int
		loop
		    locate (2, 1)
		    get x_grid
		    if x_grid > 0 and x_grid < 9 then
			exit
		    else
			locate (2, 2)
			put ""
			sound (400, 200)
		    end if
		end loop
		loop
		    locate (2, 2)
		    get y_grid
		    if y_grid > 0 and y_grid < 9 then
			exit
		    else
			locate (2, 1)
			put ""
			sound (400, 200)
		    end if
		end loop
		if grid (y_grid, x_grid) not= "" then
		    locate (1, 1)
		    centre
			("S O R R Y  C A N ' T  M O V E  T H E R E")

		    delay (1000)
		    locate (1, 1)
		    centre ("O T H E L L O")
		    locate (2, 1)
		    put ""
		    setscreen ("noecho")
		elsif grid (y_grid, x_grid) = "" then
		    grid (ygrid, xgrid) := ""
		    circle (10)
		    xgrid := x_grid
		    ygrid := y_grid
		    ycheck := 9 - y_grid
		    x := xgrid * 56 - 29
		    y := ycheck * 56 - 29
		    grid (ygrid, xgrid) := c2
		    circle (chipcolr)
		    locate (1, 1)
		    centre ("O T H E L L O")
		    locate (2, 1)
		    put ""
		    setscreen ("noecho")
		end if
	    label ESC :
		exitcheck := true
		exit
	    label :
		locate (1, 1)
		centre ("S O R R Y  W R O N G  K E Y ! ! !")
		delay (1000)
		locate (1, 1)
		centre ("O T H E L L O")
	end case
    end loop
end movement

%These things are for my games intro
loop
    var count : int := 16
    loop
	setscreen ("graphics:m256")
	color (count)
	locate (13, 10)
	put "COPYRIGHT 1995-96"
	count := count + 1
	exit when count = 31
	delay (100)
    end loop
    delay (1000)
    cls
    count := 16
    loop
	setscreen ("graphics:m256")
	color (count)
	locate (13, 6)
	put "A RICHARD DICKERSON PRODUCTION"
	count := count + 1
	delay (300)
	exit when count = 31
    end loop
    delay (1000)
    cls
    count := 16
    loop
	setscreen ("graphics:m256")
	color (count)
	locate (13, 10)
	put "O  T  H  E  L  L  O"
	count := count + 1
	delay (300)
	exit when count = 31
    end loop
    const CScale := "CDEFGAB"
    randomize
    play ("5")
    var note : int
    var scale_count : int := 0
    loop
	randint (note, 1, 7)
	play (CScale (note))
	scale_count := scale_count + 1
	exit when scale_count = 10
    end loop
    delay (1000)
    cls
    setscreen ("graphics:v16")
    locate (7, 1)

    %These are the rules to the game
    centre ("R U L E S")
    put ""
    centre ("The rules of this game are very simple.")
    centre ("You just move your chip to a place where just ahead")
    centre ("of it (in any direction) the oppisite color is there.")
    centre ("On the other side of that chip your color must be")
    centre ("there in order to flip the chips to your color,")
    centre ("from where you placed your chip to where the chip")
    centre ("was on the other side.  When you want to get to a grid")
    centre ("square fast press [SPACE] the x value 1-8 [ENTER] the y")
    centre ("value 1-8 [ENTER]")
    centre ("One thing to remember is that the black chip that moves")
    centre ("around is dark grey, and the white chip is white.")
    centre ("Press [ESC] to exit")
    put ""
    centre ("Hit Enter to continue")
    loop
	exit when hasch
    end loop
    cls

    %These setscreens are for graphics, cursor, and print
    setscreen ("graphics:v16")
    setscreen ("nocursor")
    setscreen ("noecho")
    box
    var whitecount, blackcount : int := 0

    %This is to draw the grid of the board
    var snapshot : array 1 .. sizepic (0, 0, width, height)
	of int
    takepic (0, 0, width, height, snapshot)
    drawpic (0, 0, snapshot, 1)
    for xcount : 0 .. 7
	for ycount : 0 .. 7
	    const xdone := xcount * (width + 2)
	    const ydone := ycount * (height + 2)
	    drawpic (xdone, ydone, snapshot, 0)
	end for
    end for

    %This is to read in values into my array
    for i : 1 .. 8
	for j : 1 .. 8
	    grid (i, j) := ""
	end for
    end for

    %These are the set up chips for the text othello
    grid (4, 4) := "black"
    grid (4, 5) := "white"
    grid (5, 4) := "white"
    grid (5, 5) := "black"
    border (whitecount, blackcount)

    %This is for the first chips on the board
    chips (195, 195, 15)
    chips (251, 251, 15)
    chips (195, 251, 0)
    chips (251, 195, 0)
    locate (1, 1)
    centre ("O T H E L L O")
    var exitcheck : boolean := false
    loop
	var checkcount : int := 0

	%This is where I call my movement procedure twice
	movement ("black", "white", 15, 7, checkcount,
	    exitcheck, whitecount, blackcount)
	exit when exitcheck
	movement ("white", "black", 0, 8, checkcount,
	    exitcheck, whitecount, blackcount)
	exit when exitcheck
	exit when checkcount = 2
    end loop
    cls
    exit when exitcheck
    setscreen ("graphics:m256")
    play ("5E+F+G+5")
    for i : 1 .. 20
	if whitecount > blackcount then
	    locate (11, 10)
	    color (16)
	    put "W H I T E  W I N S  ", whitecount
	    locate (13, 9)
	    put "B L A C K  L O S E S  ", blackcount
	    delay (100)
	    locate (11, 10)
	    color (31)
	    put "W H I T E  W I N S  ", whitecount
	    locate (13, 9)
	    put "B L A C K  L O S E S  ", blackcount
	    delay (100)
	elsif whitecount < blackcount then
	    locate (11, 10)
	    color (16)
	    put "B L A C K  W I N S  ", blackcount
	    locate (13, 9)
	    put "W H I T E  L O S E S  ", whitecount
	    locate (11, 10)
	    color (31)
	    put "B L A C K  W I N S  ", blackcount
	    locate (13, 9)
	    put "W H I T E  L O S E S  ", whitecount
	    delay (100)
	end if
    end for
    cls
    locate (11, 15)
    put "PROGRAMMING BY"
    delay (2000)
    locate (13, 13)
    put "RICHARD DICKERSON"
    delay (2000)
    cls
    locate (11, 12)
    put "GRAPHICS & SOUND BY"
    delay (2000)
    locate (13, 13)
    put "RICHARD DICKERSON"
    delay (2000)
    cls
    locate (11, 13)
    put "SPECIAL THANKS TO"
    delay (2000)
    locate (13, 17)
    put "C. FARHOOD"
    delay (2000)
    cls
    count := 16
    loop
	locate (13, 17)
	color (count)
	put "T H E  E N D"
	count := count + 1
	exit when count = 31
    end loop
    delay (3000)
    cls
    setscreen ("graphics:v16")
    locate (13, 1)
    centre ("Do you want to play again? [Y/N]")
    setscreen ("echo")
    var reply : string (1)
    get reply
    exit when reply = "n"
end loop
