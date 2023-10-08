setscreen ("graphics")
setscreen ("nocursor")
color(0)
colorback(7)
var spriteWidth :int := 57
var spriteHeight :int := 67
var backColour :int := 7
var enemy : int
var HP : array 1 .. 3 of int
var file : string
var rich_attack : int := 20
var rich_defence : int := 5
var num_enemy : int
var xgrid : int := 1
var t_HP : int := 0
var rich : int := 600
var attack : int
var count : int := 2
var stream : array 1 .. 7 of int
var t_gold, t_EXP : int := 0
var minattack : array 1 .. 3 of int
var maxattack : array 1 .. 3 of int
var defence : array 1 .. 3 of int
var enemy_3 : array 1 .. 3 of string
var gold : array 1 .. 3 of int
var EXP : array 1 .. 3 of int
var nums : array 1 .. spriteHeight, 1 .. spriteWidth of int
drawfillbox(0, 0, maxx, maxy, backColour)
for i : 1 .. 3
    enemy_3 (i) := ""
end for
procedure arrow (x, y, clr : int)
    drawfillbox (x, y, x + 1, y + 8, clr)
    drawfillbox (x - 3, y + 3, x + 4, y + 3, clr)
    drawfillbox (x - 2, y + 2, x + 3, y + 2, clr)
    drawfillbox (x - 1, y + 1, x + 2, y + 1, clr)
end arrow

procedure drawSprite (startX, startY :int, spriteName : string)
    var stream_num : int
    open : stream_num, spriteName + ".pic", get
    var num : array 1 .. spriteHeight, 1 .. spriteWidth of int
    for y : 1 .. spriteHeight
	for x : 1 .. spriteWidth
	    get : stream_num, num (y, x)
	    drawdot (x + startX, y + startY, num (y, x))
	end for
    end for
    
    close : stream_num
end drawSprite

procedure killSprite (startX, startY, colour :int)
    for y : 1 .. spriteHeight
	for x : 1 .. spriteWidth
	    drawdot (x + startX, y + startY, colour)
	end for
    end for
end killSprite

randomize
randint (num_enemy, 1, 3)
for i : 1 .. num_enemy
    randint (enemy, 1, 4)
    if enemy = 1 then
	HP (i) := 30
	minattack (i) := 2
	maxattack (i) := 10
	defence (i) := 3
	file := "wizard"
	gold (i) := 3
	EXP (i) := 10
    elsif enemy = 2 then
	HP (i) := 25
	minattack (i) := 3
	maxattack (i) := 11
	defence (i) := 10
	file := "skeleton"
	gold (i) := 4
	EXP (i) := 8
    elsif enemy = 3 then
	HP (i) := 40
	minattack (i) := 4
	maxattack (i) := 12
	defence (i) := 6
	file := "drued"
	gold (i) := 10
	EXP (i) := 20
    elsif enemy = 4 then
	HP(i) := 200
	minattack(i) := 8
	maxattack(i) := 30
	defence(i) := 15
	file := "evilbun"
	gold(i) := 200
	EXP(i) := 200
    end if
    enemy_3 (i) := file
    t_HP := t_HP + HP (i)
    t_EXP := t_EXP + EXP (i)
    t_gold := t_gold + gold (i)
end for
for i : 1 .. num_enemy
    drawSprite (count, 74, enemy_3(i))
    count := count + 58
end for
var stream_num : int
drawSprite (maxx - 90, 74, "hero1")
loop
    locate (4, 70)
    put "RICHARD"
    locate (5, 70)
    put rich, "/600"
    locate (22, 1)
    color(4)
    put "ATTACK"
    locate (24, 1)
    color(0)
    put "RUN"
    drawbox (0, 70, maxx - 100, maxy, 0)
    drawbox (0, 71, maxx - 101, maxy, 0)
    drawbox (maxx - 98, 70, maxx, maxy, 0)
    drawbox (maxx - 97, 71, maxx, maxy, 0)
    const UP_ARROW : int := 200
    const DOWN_ARROW : int := 208
    const ENTER : int := 10
    var command : string := "attack"
    var ch : string (1)
    loop
	setscreen ("noecho")
	getch (ch)
	case ord (ch) of
	    label UP_ARROW :
		locate (24, 1)
		color (0)
		put "RUN"
		locate (22, 1)
		color (4)
		put "ATTACK"
		command := "attack"
	    label DOWN_ARROW :
		locate (22, 1)
		color (0)
		put "ATTACK"
		locate (24, 1)
		color (4)
		put "RUN"
		command := "run"
	    label ENTER :
		locate (22, 1)
		put ""
		locate (24, 1)
		put ""
		exit
	    label :
		color (15)
		locate (23, 1)
		put "SORRY WRONG KEY"
		locate (23, 1)
		put ""
	end case
    end loop
    if command = "attack" then
	locate (23, 1)
	put "PLEASE CHOOSE ENEMY"
	var x : int := 27
	var y : int := 145
	count := 2
	xgrid := 1
	arrow (x, y, 0)
	loop
	    const RIGHT_ARROW : int := 205
	    const LEFT_ARROW : int := 203
	    getch (ch)
	    case ord (ch) of
		label RIGHT_ARROW :
		    arrow (x, y, 7)
		    if not xgrid = 3 then
			x := x + 58
			count := count + 58
			xgrid := xgrid + 1
		    end if
		    arrow (x, y, 0)
		label LEFT_ARROW :
		    arrow (x, y, 7)
		    if not xgrid = 1 then
			x := x - 58
			count := count - 58
			xgrid := xgrid - 1
		    end if
		    arrow (x, y, 0)
		label ENTER :
		    if enemy_3 (xgrid) = "" then
			locate (24, 1)
			color (0)
			put "No enemy there"
			delay (1000)
			locate (24, 1)
			put ""
		    else
			locate (23, 1)
			put ""
			arrow (x, y, 7)
			exit
		    end if
		label :
		    color (0)
		    locate (23, 1)
		    put "SORRY WRONG KEY"
		    locate (23, 1)
		    put ""
	    end case
	end loop
	drawSprite(maxx - 90, 74, "hero2")
	delay(500)
	drawSprite(maxx - 90, 74, "hero1")

	randomize
	randint (attack, 2, rich_attack - defence (xgrid))
	locate (22, 1)
	color (0)
	put "damage is ", attack, " HP  to the enemy"
	delay (1000)
	locate (22, 1)
	put ""
	HP (xgrid) := HP (xgrid) - attack
	t_HP := t_HP - attack
	locate (23, 1)
    elsif command = "run" then
	var run : int
	randint (run, 1, 3)
	if run = 1 then
	    exit
	else
	    locate (23, 1)
	    color (0)
	    put "CAN'T RUN"
	    delay (1000)
	    locate (23, 1)
	    put ""
	end if
    end if
    if HP (xgrid) <= 0 then
	enemy_3 (xgrid) := ""
	killSprite(count, 74, 7)
    end if
    exit when t_HP <= 0
    count := 2
    for x : 1 .. num_enemy
	if not (enemy_3 (x) = "skeleton" or enemy_3 (x) = "evilbun") then
	    var attackSprite : string := enemy_3 (x) + "2"
	    drawSprite(count, 74, attackSprite)
	    delay(500)
	    drawSprite(count, 74, enemy_3(x))
	end if
	if not enemy_3 (x) = "" then
	    randint (attack, minattack (x), maxattack (x) - rich_defence)
	    locate (22, 1)
	    color (0)
	    put enemy_3(x) + "'s damage is ", attack, " HP to rich"
	    rich := rich - attack
	end if
	if rich <= 0 then
	    put "rich has perished"
	    exit
	end if
	delay (1000)
	count := count + 58
    end for
    exit when rich <= 0
    locate (22, 1)
    put ""
end loop
if rich <= 0 then
    killSprite(maxx - 90, 74, 7)
end if
