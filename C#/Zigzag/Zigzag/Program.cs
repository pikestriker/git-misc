// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

//This is a program that was created based on assignment that I was looking for to test coding ability of
//some of the candidates.  I was able to do this challenge myself but I did deem it too challenging to give
//to a potential hire

string s = "PAYPALISHIRING";
int numLines = 4;
int addToLine = 0;
string [] lines = new string[numLines];
string[] lines2 = new string[numLines]; 

for (int i = 0; i < s.Length; i++)
{
    addToLine = i % (numLines + 2);
    if (addToLine >= numLines)
    {
        addToLine = numLines - ((addToLine % numLines) + 2);
        for (int j = 0; j < numLines; j++)
        {
            if (j != addToLine)
                lines2[j] += " ";
        }
    }
    lines[addToLine] += s[i];
    lines2[addToLine] += s[i];
}

foreach (string line in lines)
{
    Console.Write(line);
}
Console.WriteLine();
foreach (string line in lines2)
{
    Console.WriteLine(line);
}
