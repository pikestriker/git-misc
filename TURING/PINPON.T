loop
    setscreen ("graphics:v16")
    setscreen ("nocursor")
    setscreen ("noecho")
    var x : int := 100
    var y : int := 110
    var yv : int := 3
    var xv : int := 3
    var count : int := 0
    var ps : int := 15
    var reply : string (1)
    var xplace : int := 100
    var ncheck, ycheck : boolean := false
    const LEFT_ARROW : int := 203
    const RIGHT_ARROW : int := 205
    const ESC : int := 27
    var ch : string (1)
    drawfillbox (xplace, 0, xplace + 70, 0 + 5, 15)
    loop
	loop
	    drawfilloval (x, y, 10, 10, 0)
	    x := x + xv
	    y := y + yv
	    if x < 10 or x > maxx - 10 then
		sound (400, 200)
		xv := - xv
	    end if
	    if y > maxy - 10 then
		sound (600, 200)
		yv := - yv
	    end if
	    if y < 20 and x > xplace and x < xplace + 70 then
		sound (800, 400)
		yv := - yv
		count := count + 1
		if count = 5 then
		    xv := xv + 2
		    yv := yv + 2
		    ps := ps + 2
		    count := 0
		end if
	    elsif y < 20 then
		setscreen ("echo")
		cls
		put "YOU LOSE!!!"
		put "Do you want to play again? [Y/N] " ..
		get reply
		if reply = "n" then
		    ncheck := true
		else
		    ycheck := true
		end if
		exit when ncheck
		exit when ycheck
	    end if
	    drawfilloval (x, y, 10, 10, 15)
	    exit when hasch
	end loop
	exit when ycheck
	exit when ncheck
	getch (ch)
	case ord (ch) of
	    label RIGHT_ARROW :
		drawfillbox (xplace, 0, xplace + 70, 0 + 5, 0)
		xplace := xplace + ps
		drawfillbox (xplace, 0, xplace + 70, 0 + 5, 15)
	    label LEFT_ARROW :
		drawfillbox (xplace, 0, xplace + 70, 0 + 5, 0)
		xplace := xplace - ps
		drawfillbox (xplace, 0, xplace + 70, 0 + 5, 15)
	    label ESC :
		exit
	end case
    end loop
    cls
    exit when ncheck
end loop
