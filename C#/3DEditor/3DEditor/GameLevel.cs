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
        float centerPointX, centerPointY, centerPointZ;
        float maxCoord;
        float[,] rgb = { { 1.0f, 1.0f, 0.0f},               //yellow
                         { 0.625f, 0.625f, 0.0f },          //darker yellow
                         { 0.0f, 1.0f, 0.0f },              //green
                         { 0.0f, 0.625f, 0.0f },            //darker green
                         { 0.0f, 1.0f, 1.0f },              //cyan
                         { 0.0f, 0.625f, 0.625f },          //darker cyan
                         { 0.625f, 0.391f, 0.0f },          //brown
                         { 0.43f, 0.195f, 0.0f },           //darker brown
                         { 0.0f, 0.234f, 0.508f }           //background colour
                       };

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
            int maxX = -1000000, maxY = -1000000, maxZ = -1000000;
            int minX = 1000000, minY = 1000000, minZ = 1000000;
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
                        int x = int.Parse(splitLine[0].Trim());
                        int y = int.Parse(splitLine[1].Trim());
                        int z = int.Parse(splitLine[2].Trim());
                        curWall.verts[curVertCount].x = x;
                        curWall.verts[curVertCount].y = y;
                        curWall.verts[curVertCount].z = z;

                        if (x < minX)
                            minX = x;
                        if (y < minY)
                            minY = y;
                        if (z < minZ)
                            minZ = z;

                        if (x > maxX)
                            maxX = x;
                        if (y > maxY)
                            maxY = y;
                        if (z > maxZ)
                            maxZ = z;

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

            centerPointX = (maxX - minX) / 2 + minX;
            centerPointY = (maxY - minY) / 2 + minY;
            centerPointZ = (maxZ - minZ) / 2 + minZ;
            maxCoord = Math.Max(centerPointX, Math.Max(centerPointY, centerPointZ));

            sr.Close();
        }

        public float[] getVertices()
        {
            List<float> vertices = new List<float>();

            foreach (var sector in sectors)
            {
                foreach (var wall in sector.walls)
                {
                    foreach (var vert in wall.verts)
                    {
                        // lets normalize the coordinates before we do this
                        float x = vert.x - centerPointX;
                        float y = vert.y - centerPointY;
                        float z = vert.z - centerPointZ;
                        float length = (float)Math.Sqrt(x*x + y*y + z*z);
                        vertices.Add(x / length);
                        vertices.Add(y / length);
                        vertices.Add(z / length);
                    }
                }
            }

            return vertices.ToArray();
        }

        public float[] getVerticesWithColour()
        {
            List<float> vertices = new List<float>();

            foreach (var sector in sectors)
            {
                foreach (var wall in sector.walls)
                {
                    foreach (var vert in wall.verts)
                    {
                        // center the objects on the screen and divide by a scale factor to fit between -1.0 and 1.0 values
                        float x = vert.x - centerPointX;
                        float y = vert.y - centerPointY;
                        float z = vert.z - centerPointZ;
                        // swapped the y and z values because they are flipped in the C++ program that can navigate the world
                        vertices.Add(x / maxCoord);
                        vertices.Add(z / maxCoord);
                        vertices.Add(y / maxCoord);
                        vertices.Add(rgb[wall.color, 0]);
                        vertices.Add(rgb[wall.color, 1]);
                        vertices.Add(rgb[wall.color, 2]);
                    }
                }
            }

            return vertices.ToArray();
        }

        public int[] getIndices()
        {
            List<int> indices = new List<int>();
            return indices.ToArray();
        }
    }
}
