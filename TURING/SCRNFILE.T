%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                           %
%   ScreenFile:                                                             %
%                                                                           %
%       This module provides routines to read a Turing IMage (.TIM) file    %
%       and display it on a screen and to write a block from the screen to  %
%       a .TIM file.                                                        %
%                                                                           %
%       NOTE:  The initial version of .TIM files do not contain any         %
%              information on the display mode required and it is up to the %
%              user to determine what mode to display the file in.  Mode    %
%              is set with the "setscreen" command and any .TIM file will   %
%              be written in the current display.                           %
%                                                                           %
%   screenToFile (x1, y1, x2, y2 : int, fileName : string, ok : boolean)    %
%       - (x1,y1) and (x2,y2) denote opposing corners of a box surrounding  %  %
%         the part of the screen to be written to a file.                   %
%       - fileName is a string naming the file to be written into.  The     %
%         conventional use will be a file with the DOS extension .TIM       %
%       - ok is a boolean value indicating that the file was successfully   %
%         opened and written into.                                          %
%                                                                           %
%   fileToScreen (x1, y1 : int, fileName : string, ok : boolean)            %
%       - (x1,y1) denotes then bottom-left corner of the block the image    %
%         will be written into.                                             %
%       - fileName is a string naming the file to be read from. Convention  %
%         is a file with the DOS extension .TIM                             %
%       - ok is a boolean value indicating that the file was successfully   %
%         opened and read from.                                             %
%                                                                           %
%   showFiles (descriptor : string)                                         %
%       - descriptor is the string passed along with the DOS "dir" command  %
%         to select which files to display in the named directory.          %
%         This command is the same as saying "dir descriptor"               %
%                                                                           %
%   pause                                                                   %
%       pause is a little utility I make frequent use of.  It waits for a   %
%       keypress before continuing by declaring a single character string   %
%       variable and doing a "getch".                                       %
%                                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

module ScreenFile
    export screenToFile, % takes a box and writes the box to a file
	fileToScreen, % takes a file and writes it to a cleared screen
	showFiles, % shows files matching given specification
	pause % just a simple utility to pause until a key is pressed

    const pointSize := sizepic (1, 1, 1, 1)
    var maxArray := 8000

    % Procedure to wait for the user to press a key.  If you don't want
    % the keypress to be echoed, use
    %                   setscreen ("noecho")
    % to turn off echoing.
    procedure pause
	var ch : string (1)
	getch (ch)
    end pause

    % Procedure to write a portion of the screen to a TIM file.
    procedure screenToFile (x1, y1, x2, y2 : int, fName : string,
	    var ok : boolean)
	var pic : array 1 .. maxArray of int
	var fs : int

	% Open the file and make sure it is OK
	open : fs, fName, write
	ok := fs > 0
	if not ok then
	    put "Open failed on file '", fName, "'"
	    return
	end if

	% Determine the size of each "row" of pixels.
	% NOTE: Images are written out a "chunk" at a time from the
	%       bottom of the screen to the top (since drawpic uses
	%       the bottom-left corner for placing the picture).
	%       When the image is too large to fit in a single "chunk",
	%       a number of rows are collected and written out in a single
	%       operation and the image to be written is then updated to
	%       the next "chunk".

	const rowInc := maxArray div sizepic (x1, 1, x2, 1)
	var firstRow := min (y1, y2)
	const lastRow := max (y1, y2)
	var picSize : int % Number of bytes in current chunk

	loop
	    % Exit if the entire chunk will fit in maxArray integers
	    exit when firstRow + rowInc > lastRow

	    % If not, then break it down into manageable parts
	    takepic (x1, firstRow, x2, firstRow + rowInc - 1, pic)

	    % picSize = number of bytes in the current chunk
	    picSize := sizepic (x1, firstRow, x2, firstRow + rowInc - 1) * 4

	    % A chunk is the number of bytes followed by the image portion
	    write : fs, picSize, pic : picSize
	    firstRow += rowInc
	end loop

	% The final chunk will always fit the given frame buffer.
	picSize := sizepic (x1, firstRow, x2, lastRow) * 4
	takepic (x1, firstRow, x2, lastRow, pic)
	write : fs, picSize, pic : picSize
	close : fs
    end screenToFile

    % Procedure to read a TIM file and write it to the screen
    procedure fileToScreen (x, y : int, fName : string, var ok : boolean)
	var Y := y
	var pic : array 1 .. maxArray of int
	var fs : int

	open : fs, fName, read
	ok := fs > 0
	if not ok then
	    return
	end if
	var bytesToRead, bytesRead : int
	loop
	    exit when eof (fs)
	    read : fs, bytesToRead
	    read : fs, pic : bytesToRead : bytesRead
	    drawpic (x, Y, pic, 0)
	    Y += pic (1) + 1
	end loop
	close : fs
    end fileToScreen

    % Procedure to display files names in a directory
    procedure showFiles (f : string)
	var ok : int
	system ("dir " + f, ok)
    end showFiles
end ScreenFile
