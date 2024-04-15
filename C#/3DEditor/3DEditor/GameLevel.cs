using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace Editor3D
{
    class vertexType
    {
        public int x, y, z;
    };

    class wallType
    {
        public vertexType[] verts;
        public int color;
    };

    class sectorType
    {
        public List<wallType> walls;
        //int surfaceCoord[WIDTH]; going to leave this out for now as I just want to write out a 2D representation
        public int topColor;
        public int bottomColor;
    };

    internal class GameLevel
    {
        List<sectorType> sectors = new List<sectorType>();

        public void SaveLevelv2(string filename)
        {
            if (sectors != null && sectors.Count > 0)
            {
                StreamWriter sw = new StreamWriter(filename);
                sw.WriteLine("2");  //version number
                sw.WriteLine(sectors.Count);
                foreach (var curSector in sectors)
                {
                    sw.WriteLine(curSector.walls.Count);
                    sw.WriteLine(curSector.topColor + " " + curSector.bottomColor);
                    foreach (var curWall in curSector.walls)
                    {
                        sw.WriteLine(curWall.color);
                        foreach (var curVert in curWall.verts)
                        {
                            sw.WriteLine(curVert.x + " " + curVert.y + " " + curVert.z);
                        }
                    }
                }
                sw.Close();
            }
        }

        public void LoadLevelv2(string filename)
        {
            StreamReader sr = new StreamReader(filename);
            string line = sr.ReadLine();
            bool versionExpected = true;
            int version;
            bool numSectorsExpected = true;
            int numSectors;
            bool numWallsExpected = true;
            int numWalls = 0;
            int curWallCount = 0;
            int curVertCount = 0;
            bool topBottomExpected = true;
            bool wallColorExpected = true;
            sectorType curSector = null;
            wallType curWall = null;

            while (line != null)
            {
                if (versionExpected)
                {
                    versionExpected = false;
                    version = int.Parse(line);
                }
                else if (numSectorsExpected)
                {
                    numSectorsExpected = false;
                    numSectors = int.Parse(line);
                }
                else if (numWallsExpected)
                {
                    numWallsExpected = false;
                    numWalls = int.Parse(line);
                }
                else if (topBottomExpected)
                {
                    topBottomExpected = false;
                    string[] splitLine = line.Split(' ');
                    if (curSector != null)
                    {
                        if (curWall != null)
                        {
                            curSector.walls.Add(curWall);
                            curWall = null;
                        }
                        sectors.Add(curSector);
                    }
                    curSector = new sectorType();
                    curSector.walls = new List<wallType>();
                    curSector.topColor = int.Parse(splitLine[0].Trim());
                    curSector.bottomColor = int.Parse(splitLine[1].Trim());
                }
                else if (wallColorExpected)
                {
                    wallColorExpected = false;
                    if (curWall != null)
                    {
                        curSector.walls.Add(curWall);
                    }
                    curWall = new wallType();
                    curWall.verts = new vertexType[4];
                    curWall.color = int.Parse(line);
                }
                else
                {
                    if (curVertCount < 4)
                    {
                        //current wall vertices
                        curWall.verts[curVertCount] = new vertexType();

                        //the line currently contains an x, y, z coordinate
                        string[] splitLine = line.Split(" ");
                        curWall.verts[curVertCount].x = int.Parse(splitLine[0].Trim());
                        curWall.verts[curVertCount].y = int.Parse(splitLine[1].Trim());
                        curWall.verts[curVertCount].z = int.Parse(splitLine[2].Trim());
                        curVertCount++;
                        if (curVertCount == 4)
                        {
                            //The wall is done
                            wallColorExpected = true;
                            curVertCount = 0;
                            curWallCount++;
                        }
                    }
                    
                    if (curWallCount == numWalls)
                    {
                        curWallCount = 0;
                        numWallsExpected = true;
                        topBottomExpected = true;
                    }
                }
                line = sr.ReadLine();
            }

            if (curWall != null)
            {
                curSector.walls.Add(curWall);
                sectors.Add(curSector);
            }
            sr.Close();
        }
    }
}
