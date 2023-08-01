setscreen ("nocursor")
setscreen ("noecho")
loop
    put "Please Enter The Correct Password"
    var password : string
    get password
    exit when password = "fighter"
end loop
