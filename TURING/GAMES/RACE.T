/* Display Adaptor Constants */
const CGA : int := 1
const EGA : int := 2
const VGA : int := 3

/* Grid Points in Game */
const XSIZE : int := 40
const YSIZE : int := 30

/* Grid Array */
var track : array 0 .. XSIZE - 1, 0 .. YSIZE - 1 of int

/* Start Grid Points */
const XSTART : int := XSIZE div 2
const YSTART : int := 2

/* Grid Separation */
var DX, DY : int

/* Keyboard Codes */
const RETURN : int := 10
const ESC : int := 27
const SPACE : int := 32
const RIGHT_ARROW : int := 205
const LEFT_ARROW : int := 203
const UP_ARROW : int := 200
const DOWN_ARROW : int := 208
const PAGE_UP : int := 201
const PAGE_DOWN : int := 209
const HOME : int := 199
const END : int := 207

/* FATES */
const SAFE : int := 0
const WIN : int := - 1
const CRASH_INTO_WALL : int := 1
const CRASH_INTO_CAR : int := 2

/* Colours */
var BORDERCOLOUR : int
var FILLCOLOUR : int
var DOTCOLOUR : int
var TMPCOLOUR : int
var COLOUR : array 1 .. 2 of int
var WINCOLOUR : int
var ALTDOTCOLOUR : int

/* Flag */
var errorFlag : boolean := false

/* Turn Counter */
var turn : int := 0

/* Track Array */
var trackc : array 1 .. 50 of
    record
	angle : int
	radius : real
	distance : int
    end record

/* Car Array */
var cars : array 1 .. 2 of
    record
	px : int
	py : int
	vx : int
	vy : int
    end record

procedure BlankTopLine
    locate (1, 1)
    put repeat (" ", maxcol - 1)
    locate (1, 1)
end BlankTopLine

procedure SetResolution
    var adaptor : int

    put CGA, "..CGA"
    put EGA, "..EGA"
    put VGA, "..VGA"
    put "   Enter adaptor: " ..
    get adaptor

    case adaptor of
	label CGA :
	    BORDERCOLOUR := 3
	    FILLCOLOUR := 2
	    DOTCOLOUR := 1
	    TMPCOLOUR := 2
	    COLOUR (1) := 1
	    COLOUR (2) := 1
	    setscreen ("graphics")
	label EGA :
	    BORDERCOLOUR := 5
	    FILLCOLOUR := 1
	    DOTCOLOUR := 15
	    COLOUR (1) := 11
	    COLOUR (2) := 14
	    TMPCOLOUR := 12
	    WINCOLOUR := 10
	    setscreen ("graphics:e16")
	label VGA :
	    BORDERCOLOUR := 5
	    FILLCOLOUR := 1
	    DOTCOLOUR := 15
	    COLOUR (1) := 11
	    COLOUR (2) := 14
	    TMPCOLOUR := 12
	    WINCOLOUR := 10
	    ALTDOTCOLOUR := 2
	    setscreen ("graphics:v16")
    end case

    DX := (maxx + 1) div XSIZE
    DY := (maxy + 1) div YSIZE
end SetResolution

procedure DrawMap
    SetResolution

    const YBORDER : int := maxy - (maxy + 1) div maxrow
    const START_RADIUS : int := 5
    const DXINC : real := DX * 0.5
    const DYINC : real := DY * 0.5
    const DXR : real := DX * 2.5
    const DYR : real := DY * 2.5

    var x1, x2, x3, x4, y1, y2, y3, y4, tx, ty : real
    var ox2, ox4, oy2, oy4 : real
    var xinrad, xoutrad, xcntrad, yinrad, youtrad, ycntrad : real
    var rad, nang, sang, eang, sgn : int
    var ch : string (1)
    var exitFlag : boolean := false

    var oldAngle : int := 0
    var angle : int
    var distance : int
    var px : real := XSTART * DX
    var py : real := YSTART * DY - 2

    var minix : int := maxx
    var maxix : int := 0
    var miniy : int := maxy
    var maxiy : int := 0

    const startx : int := round (px)
    const starty : int := round (py)

    var rightBorder, leftBorder : int

    setscreen ("noecho")

    x1 := px - cosd (oldAngle) * DXR
    y1 := py + sind (oldAngle) * DYR
    x2 := px + cosd (oldAngle) * DXR
    y2 := py - sind (oldAngle) * DYR
    drawline (round (x1), round (y1), round (x2), round (y2), BORDERCOLOUR)

    drawbox (0, 0, maxx, YBORDER, BORDERCOLOUR)

    loop
	BlankTopLine
	put "Use right and left arrow keys to specify turn"
	angle := oldAngle
	rad := START_RADIUS
	rightBorder := oldAngle + 180
	if rightBorder > 360 then
	    rightBorder -= 360
	end if
	leftBorder := oldAngle - 175
	if leftBorder < 0 then
	    leftBorder += 360
	end if
	loop
	    xinrad := rad * DXINC
	    xcntrad := xinrad + DXR
	    xoutrad := xcntrad + DXR
	    yinrad := rad * DYINC
	    ycntrad := yinrad + DYR
	    youtrad := ycntrad + DYR
	    nang := oldAngle - angle
	    if nang < 0 then
		nang += 360
	    end if
	    if nang < 180 then
		/* Piece curves left */
		sang := 360 - oldAngle
		eang := 360 - angle
		sgn := - 1
		tx := px - cosd (oldAngle) * xcntrad
		ty := py + sind (oldAngle) * ycntrad
	    else
		/* Piece curves right */
		sang := 180 - angle
		eang := 180 - oldAngle
		sgn := 1
		tx := px + cosd (oldAngle) * xcntrad
		ty := py - sind (oldAngle) * ycntrad
	    end if

	    drawarc (round (tx), round (ty), round (xinrad), round (yinrad),
		sang, eang, TMPCOLOUR)
	    drawarc (round (tx), round (ty), round (xoutrad),
		round (youtrad), sang, eang, TMPCOLOUR)

	    getch (ch)
	    drawarc (round (tx), round (ty), round (xinrad), round (yinrad),
		sang, eang, 0)
	    drawarc (round (tx), round (ty), round (xoutrad),
		round (youtrad), sang, eang, 0)
	    case ord (ch) of
		label RETURN, SPACE :
		    exit
		label ESC :
		    exitFlag := true
		    exit
		label RIGHT_ARROW :
		    if angle not= rightBorder then
			angle := angle + 5
			if angle > 360 then
			    angle -= 360
			end if
		    end if
		label LEFT_ARROW :
		    if angle not= leftBorder then
			angle := angle - 5
			if angle < 0 then
			    angle += 360
			end if
		    end if
		label UP_ARROW :
		    if rad < 15 then
			rad += 1
		    end if
		label DOWN_ARROW :
		    if rad > 1 then
			rad -= 1
		    end if
		label :
	    end case
	end loop

	/* Set Loop Variables */
	exit when exitFlag
	turn += 1
	trackc (turn).angle := angle
	trackc (turn).radius := rad
	oldAngle := angle

	/* Final Drawing of Turn */
	drawarc (round (tx), round (ty), round (xinrad), round (yinrad),
	    sang, eang, BORDERCOLOUR)
	drawarc (round (tx), round (ty), round (xinrad - 1),
	    round (yinrad - 1), sang, eang, BORDERCOLOUR)
	drawarc (round (tx), round (ty), round (xoutrad), round (youtrad),
	    sang, eang, BORDERCOLOUR)
	drawarc (round (tx), round (ty), round (xoutrad + 1),
	    round (youtrad + 1), sang, eang, BORDERCOLOUR)

	px := tx - cosd (angle) * xcntrad * sgn
	py := ty + sind (angle) * ycntrad * sgn

	distance := 0

	var SX : real
	var SY : real

	x1 := tx - cosd (angle) * xinrad * sgn
	y1 := ty + sind (angle) * yinrad * sgn
	x3 := tx - cosd (angle) * xoutrad * sgn
	y3 := ty + sind (angle) * youtrad * sgn
	if x1 < 0 or x1 > maxx or y1 < 0 or y1 > YBORDER or
		x3 < 0 or x3 > maxx or y3 < 0 or y3 > YBORDER then
	    errorFlag := true
	    return
	end if
	if x1 < minix then
	    minix := round (x1)
	end if
	if y1 < miniy then
	    miniy := round (y1)
	end if
	if x1 > maxix then
	    maxix := round (x1)
	end if
	if y1 > maxiy then
	    maxiy := round (y1)
	end if
	if x3 < minix then
	    minix := round (x3)
	end if
	if y3 < miniy then
	    miniy := round (y3)
	end if
	if x3 > maxix then
	    maxix := round (x3)
	end if
	if y3 > maxiy then
	    maxiy := round (y3)
	end if

	x2 := x1
	y2 := y1
	x4 := x3
	y4 := y3

	BlankTopLine
	put "Change distance by using up/down arrows"

	loop
	    SX := distance * sind (angle)
	    SY := distance * cosd (angle)

	    ox2 := x2
	    oy2 := y2
	    ox4 := x4
	    oy4 := y4
	    x2 := x1 + SX
	    y2 := y1 + SY
	    x4 := x3 + SX
	    y4 := y3 + SY
	    if x2 < 0 or x2 > maxx or y2 < 0 or y2 > YBORDER or
		    x4 < 0 or x4 > maxx or y4 < 0 or y4 > YBORDER then
		distance -= 1
		SX := distance * sind (angle)
		SY := distance * cosd (angle)
		x2 := x1 + SX
		y2 := y1 + SY
		x4 := x3 + SX
		y4 := y3 + SY
	    end if
	    drawline (round (x1), round (y1), round (ox2), round (oy2), 0)
	    drawline (round (x3), round (y3), round (ox4), round (oy4), 0)
	    drawline (round (x1), round (y1), round (x2), round (y2),
		TMPCOLOUR)
	    drawline (round (x3), round (y3), round (x4), round (y4),
		TMPCOLOUR)

	    getch (ch)
	    case ord (ch) of
		label RETURN, SPACE :
		    exit
		label ESC :
		    exitFlag := true
		    exit
		label UP_ARROW :
		    if distance < 25 * DX then
			distance += 3
		    end if
		label DOWN_ARROW :
		    if distance > 0 then
			distance -= 3
		    end if
		label :
	    end case
	    loop
		exit when not hasch
		getch (ch)
	    end loop
	end loop

	/* Set Loop Variables */
	if exitFlag then
	    trackc (turn).distance := - 1
	else
	    trackc (turn).distance := distance
	end if
	exit when exitFlag

	/* Final Drawing of Distance */
	x2 := x1 + SX
	y2 := y1 + SY
	drawline (round (x1), round (y1), round (x2), round (y2),
	    BORDERCOLOUR)
	x4 := x3 + SX
	y4 := y3 + SY
	drawline (round (x3), round (y3), round (x4), round (y4),
	    BORDERCOLOUR)
	x1 := tx - cosd (angle) * (xinrad - 1) * sgn
	y1 := ty + sind (angle) * (yinrad - 1) * sgn
	x2 := x1 + SX
	y2 := y1 + SY
	drawline (round (x1), round (y1), round (x2), round (y2),
	    BORDERCOLOUR)
	x3 := tx - cosd (angle) * (xoutrad + 1) * sgn
	y3 := ty + sind (angle) * (youtrad + 1) * sgn
	x4 := x3 + SX
	y4 := y3 + SY
	drawline (round (x3), round (y3), round (x4), round (y4),
	    BORDERCOLOUR)

	if x2 < minix then
	    minix := round (x2)
	end if
	if y2 < miniy then
	    miniy := round (y2)
	end if
	if x2 > maxix then
	    maxix := round (x2)
	end if
	if y2 > maxiy then
	    maxiy := round (y2)
	end if
	if x4 < minix then
	    minix := round (x4)
	end if
	if y4 < miniy then
	    miniy := round (y4)
	end if
	if x4 > maxix then
	    maxix := round (x4)
	end if
	if y4 > maxiy then
	    maxiy := round (y4)
	end if
	px := px + SX
	py := py + SY
    end loop

    BlankTopLine

    x1 := px - cosd (oldAngle) * DXR
    y1 := py + sind (oldAngle) * DYR
    x2 := px + cosd (oldAngle) * DXR
    y2 := py - sind (oldAngle) * DYR
    drawline (round (x1), round (y1), round (x2), round (y2),
	BORDERCOLOUR)

    drawfill (startx, starty - 2, FILLCOLOUR, BORDERCOLOUR)

    const tmpx : real := sind (oldAngle) / 6
    const tmpy : real := cosd (oldAngle) / 6
    for : 1 .. 144
	drawline (round (x1), round (y1), round (x2), round (y2),
	    WINCOLOUR)
	x1 += tmpx
	y1 += tmpy
	x2 += tmpx
	y2 += tmpy
    end for

    const sx : int := max (0, (minix - DX * 13) div DX)
    const sy : int := max (0, (miniy - DY * 13) div DY)
    const ex : int := min (XSIZE - 1, (maxix + DX * 13) div DX + 1)
    const ey : int := min ((YBORDER - 1) div DY , (maxiy + DY * 13) div DY + 1)
    for i : 0 .. XSIZE - 1
	for j : 0 .. YSIZE - 1
	    track (i, j) := CRASH_INTO_WALL
	end for
    end for
    for i : sx .. ex
	for j : sy .. ey
	    var clr : int := whatdotcolour (round (i * DX), round (j *
		DY))
	    if clr = 0 then
		drawdot (round (i * DX), round (j * DY), DOTCOLOUR)
		track (i, j) := SAFE
	    elsif clr = WINCOLOUR then
		drawbox (round (i * DX) - 1, round (j * DY) - 1,
		    round (i * DX) + 1, round (j * DY) + 1, 0)
		drawdot (round (i * DX), round (j * DY), DOTCOLOUR)
		track (i, j) := WIN
	    end if
	end for
    end for
end DrawMap

procedure DoMove (player : int, var theFate : int)
    var ch : string (1)

    const px := cars (player).px
    const py := cars (player).py
    const vx := cars (player).vx
    const vy := cars (player).vy

    const pxp : int := px * DX
    const pyp : int := py * DY
    const pvx : int := px + vx
    const pvy : int := py + vy

    var ndvx : int := 0
    var ndvy : int := 0
    var dvx : int := 0
    var dvy : int := 0

    var fate : array - 1 .. 1, - 1 .. 1 of int

    var numLegalMoves : int := 0

    var legalArray : array 1 .. 9, 1 .. 2 of int

    for i : - 1 .. 1
	for j : - 1 .. 1
	    if pvx + i = cars (3 - player).px and
		    pvy + j = cars (3 - player).py then
		fate (i, j) := CRASH_INTO_CAR
	    else
		fate (i, j) := track (pvx + i, pvy + j)
		if fate (i, j) = SAFE or fate (i, j) = WIN then
		    numLegalMoves += 1
		    legalArray (numLegalMoves, 1) := (pvx + i) * DX
		    legalArray (numLegalMoves, 2) := (pvy + j) * DY
		end if
	    end if
	end for
    end for

    drawline (pxp, pyp, pvx * DX, pvy * DY, TMPCOLOUR)

    loop
	BlankTopLine
	put "VX = ", vx + dvx, " (", dvx, ")    VY = ", vy + dvy, " (",
	    dvy, ")   " ..
	case fate (dvx, dvy) of
	    label SAFE :
	    label CRASH_INTO_WALL :
		play ("A")
		put "This move hits a wall"
	    label CRASH_INTO_CAR :
		play ("A")
		put "This move crashes"
	    label WIN :
		play ("E")
		put "This move wins"
	end case
	loop
	    exit when hasch
	    for i : 1 .. numLegalMoves
		drawdot (legalArray (i, 1), legalArray (i, 2), ALTDOTCOLOUR)
	    end for
	    drawline (pxp, pyp, (pvx + ndvx) * DX, (pvy + ndvy) * DY, 0)
	    delay (60)
	    for i : 1 .. numLegalMoves
		drawdot (legalArray (i, 1), legalArray (i, 2), DOTCOLOUR)
	    end for
	    drawline (pxp, pyp, (pvx + ndvx) * DX, (pvy + ndvy) * DY,
		TMPCOLOUR)
	    delay (60)
	end loop
	getch (ch)
	case ord (ch) of
	    label RETURN, SPACE :
		exit
	    label RIGHT_ARROW :
		ndvx := min (1, dvx + 1)
	    label LEFT_ARROW :
		ndvx := max ( - 1, dvx - 1)
	    label UP_ARROW :
		ndvy := min (1, dvy + 1)
	    label DOWN_ARROW :
		ndvy := max ( - 1, dvy - 1)
	    label PAGE_UP :
		ndvx := min (1, dvx + 1)
		ndvy := min (1, dvy + 1)
	    label PAGE_DOWN :
		ndvx := min (1, dvx + 1)
		ndvy := max ( - 1, dvy - 1)
	    label HOME :
		ndvx := max ( - 1, dvx - 1)
		ndvy := min (1, dvy + 1)
	    label END :
		ndvx := max ( - 1, dvx - 1)
		ndvy := max ( - 1, dvy - 1)
	    label :
	end case
	drawline (pxp, pyp, (pvx + dvx) * DX, (pvy + dvy) * DY, 0)
	drawline (pxp, pyp, (pvx + ndvx) * DX, (pvy + ndvy) * DY,
	    TMPCOLOUR)
	dvx := ndvx
	dvy := ndvy
    end loop
    cars (player).vx := vx + dvx
    cars (player).vy := vy + dvy
    drawline (pxp, pyp, (px + cars (player).vx) * DX,
	(py + cars (player).vy) * DY, COLOUR (player))
    drawbox (pxp - 1, pyp - 1, pxp + 1, pyp + 1, 0)
    drawdot (pxp, pyp, DOTCOLOUR)
    cars (player).px := px + cars (player).vx
    cars (player).py := py + cars (player).vy
    drawbox (pxp - 1, pyp - 1, pxp + 1, pyp + 1, 0)
    drawdot (cars (player).px * DX, cars (player).py * DY,
	DOTCOLOUR)
    theFate := fate (dvx, dvy)
end DoMove

procedure PlayGame
    setscreen ("noecho")

    cars (1).px := XSTART - 1
    cars (1).py := YSTART
    cars (1).vx := 0
    cars (1).vy := 0
    cars (2).px := XSTART + 1
    cars (2).py := YSTART
    cars (2).vx := 0
    cars (2).vy := 0


    var ch : string (1)

    loop
	var fate : int
	DoMove (1, fate)
	if fate not= SAFE then
	    BlankTopLine
	    if fate = WIN then
		put "Player 1 Wins!"
	    elsif fate = CRASH_INTO_CAR then
		put "Player 1 crashed into player 2!"
	    elsif fate = CRASH_INTO_WALL then
		put "Player 1 crashed into a wall"
	    end if
	    exit
	end if
	DoMove (2, fate)
	if fate not= SAFE then
	    BlankTopLine
	    if fate = WIN then
		put "Player 2 Wins!"
	    elsif fate = CRASH_INTO_CAR then
		put "Player 2 crashed into player 2!"
	    elsif fate = CRASH_INTO_WALL then
		put "Player 2 crashed into a wall"
	    end if
	    exit
	end if
    end loop
end PlayGame

DrawMap
if errorFlag then
    cls
    put "Map went out of bounds."
else
    PlayGame
end if
