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
        int width, height;
        int size = 2;
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

        public override void setup()
        {
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

            int curIdx = 0;
            for (int x = -(size / 2); x < size / 2 + 1; x += size)
                for (int y = -(size / 2); y < size / 2 + 1; y += size)
                    for (int z = -(size / 2); z < size / 2 + 1; z += size)
                    {
                        verts[curIdx++] = x;
                        verts[curIdx++] = y;
                        verts[curIdx++] = z;
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
    }
}
