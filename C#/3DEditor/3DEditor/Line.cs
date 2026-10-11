using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OpenTK.Graphics.OpenGL4;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Editor3D
{
    internal class Line : Element
    {
        //the width and height are used to create perspective for the items elements that are being created
        //this is the screen width and height
        int width, height;
        int size = 1;
        Vector3 startPos, stopPos;
        public override void draw()
        {
            shaderUniforms["aColour"] = color;
            base.draw();
            // should we do an entity/compenent system for this design?
        }

        public Line()
        {
            setup();
        }

        public Line(Vector3 pos)
        {
            setup();
            this.pos = pos;
        }

        public Line(int width, int height)
        {
            setWidthAndHeight(width, height);
            setup();
        }

        public Line(int width, int height, Vector3 start, Vector3 stop)
        {
            setWidthAndHeight(width, height);
            setStartAndStopPos(start, stop);
            setup();
        }

        public override void setup()
        {
            //so I could calculate the line as it is right now but there are a couple of problems that I can
            //forsee.  1) How do we deal with not straight lines?  I can calculate the vertice position based
            //on trig but then that brings us to 2) this isn't static like a vertex, if I grab a vertex and drag
            //it around the screen the attached lines would follow behind
            //I suppose for the second problem you can either create it as a dynamic vertex buffer and update the
            //values to the new values or you can delete the current vertex buffer and create a new on based on
            //the new values
            pos = new Vector3(0.0f, 0.0f, 0.0f);
            float[] verts = new float[24];
            uint[] localIndices =
            {
                0, 1, 2,
                1, 2, 3,
                3, 1, 7,
                7, 1, 5,
                6, 7, 5,
                6, 5, 4,
                6, 4, 0,
                6, 0, 2,
                2, 3, 6,
                2, 7, 6,
                1, 0, 4,
                1, 4, 5
            };

            indices = localIndices;

            Vector3 centreAxis = this.stopPos - this.startPos;
            pos = centreAxis / 2 + this.startPos;
            float length = centreAxis.Length;
            centreAxis.Normalize();
            Vector3 perpendicularAxis = new Vector3(-centreAxis.Y, centreAxis.X, 0.0f);
            perpendicularAxis.Normalize();
            float width = size;
            Vector3 crossAxis = Vector3.Cross(centreAxis, perpendicularAxis);
            crossAxis.Normalize();
            float height = size;
            
            int curIdx = 0;
            for (int point1Mult = -1; point1Mult < 2; point1Mult += 2)
                for (int point2Mult = -1; point2Mult < 2; point2Mult += 2)
                    for (int point3Mult = -1; point3Mult < 2; point3Mult += 2)
                    {
                        Vector3 point = (length/2) * centreAxis * point1Mult +
                                        (width/2) * perpendicularAxis * point2Mult +
                                        (height/2) * crossAxis * point3Mult;
                        
                        verts[curIdx++] = point.X;
                        verts[curIdx++] = point.Y;
                        verts[curIdx++] = point.Z;
                    }

            int vertexBuffer = GL.GenBuffer();
            int elementBuffer = GL.GenBuffer();
            vertexArray = GL.GenVertexArray();

            GL.BindVertexArray(vertexArray);

            GL.BindBuffer(BufferTarget.ArrayBuffer, vertexBuffer);
            GL.BufferData(BufferTarget.ArrayBuffer, verts.Length * sizeof(float), verts, BufferUsageHint.StaticDraw);

            GL.VertexAttribPointer(0, 3, VertexAttribPointerType.Float, false, 3 * sizeof(float), 0);
            GL.EnableVertexAttribArray(0);

            GL.BindBuffer(BufferTarget.ElementArrayBuffer, elementBuffer);
            GL.BufferData(BufferTarget.ElementArrayBuffer, indices.Length * sizeof(uint), indices, BufferUsageHint.StaticDraw);

            loadShader();
            color = new Vector3(1.0f, 1.0f, 0.0f);
            shaderUniforms.Add("aColour", color);

            if (curType == viewType.Ortho)
            {
                proj = Matrix4.CreateOrthographic(MathHelper.DegreesToRadians(45.0f), (float)width / (float)height, 0.1f, 200.0f);
            }
            else
            {
                proj = Matrix4.CreatePerspectiveFieldOfView(MathHelper.DegreesToRadians(45.0f), (float)width / (float)height, 0.1f, 200.0f);
            }
        }

        public void setWidthAndHeight(int width, int height)
        {
            this.width = width;
            this.height = height;
        }

        public void setStartAndStopPos(Vector3 start, Vector3 stop)
        {
            this.startPos = start;
            this.stopPos = stop;
        }
    }
}
