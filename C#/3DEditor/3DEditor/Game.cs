using OpenTK.Graphics.OpenGL4;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Editor3D
{
    public class Game : GameWindow
    {

        float[] vertices = {
            -0.5f, -0.5f, 0.0f, //Bottom-left vertex
             0.5f, -0.5f, 0.0f, //Bottom-right vertex
             0.0f,  0.5f, 0.0f  //Top vertex
        };

        //want to draw a square to see how it handles this
        float[] vertices2 =
        {
            -0.5f, -0.5f, 0.0f,
            -0.5f, 0.5f, 0.0f,
            0.5f, 0.5f, 0.0f,
            0.5f, -0.5f, 0.0f,
            -0.5f, -0.5f, 0.5f,
            -0.5f, 0.5f, 0.5f,
            0.5f, 0.5f, 0.5f,
            0.5f, -0.5f, 0.5f
        };
        uint[] indices =
        {
            0, 1, 2,
            1, 2, 3,
            4, 5, 6,
            5, 6, 7,
            8, 9, 10,
            9, 10, 11,
            12, 13, 14,
            13, 14, 15,
            16, 17, 18,
            17, 18, 19,
            20, 21, 22,
            21, 22, 23,
            24, 25, 26,
            25, 26, 27,
            28, 29, 30,
            29, 30, 31,
            32, 33, 34,
            33, 34, 35,
            36, 37, 38,
            37, 38, 39,
            40, 41, 42,
            41, 42, 43,
            44, 45, 46,
            45, 46, 47,
            48, 49, 50,
            49, 50, 51,
            52, 53, 54,
            53, 54, 55,
            56, 57, 58,
            57, 58, 59,
            60, 61, 62,
            61, 62, 63
        };
        GameLevel curLevel = new GameLevel();
        int vertexBuffer;
        int vertexArray;
        int mat4UniformLoc;
        float zPos = 100.0f, xPos = -82.0f, yPos = -20.0f;
        float yRot = 180.0f;
        Camera camera = new Camera(new Vector3(82.0f, 20.0f, 100.0f), new Vector3(82.0f, 20.0f, 101.0f), new Vector3(0.0f, 1.0f, 0.0f));

        int width, height;
        Shader shaderList = new Shader();

        public Game(int width, int height, string title) : base(GameWindowSettings.Default, new NativeWindowSettings() { Size = (width, height), Title = title })
        { 
            this.width = width;
            this.height = height;
        }

        protected override void OnLoad()
        {
            base.OnLoad();
            
            GL.ClearColor(0.0f, 0.24f, 0.51f, 0.0f);
            GL.Enable(EnableCap.DepthTest);

            //was testing the loading and saving of the files
            curLevel.LoadLevelv2("wallsv2.txt");
            //curLevel.SaveLevelv2("walls-savev2.txt");


            //time to see if I can draw the level that I loaded
            //the first time I converted the level to an array it isn't showing anything on the screen but I think it is due to the viewport not
            //being set in the correct position,  will need to figure out that one next.  Actually it appears that things need to be in NDC coordinates
            //which is Normalized Device Coordinates from -1.0 to 1.0 on each of the axis or by default it won't be visible on the screen
            //went on to the next tutorial and I need an element buffer with the primitives
            //float[] levelVertices = curLevel.getVertices();
            float[] levelVertices = curLevel.getVerticesWithColour();

            vertexBuffer = GL.GenBuffer();
            int elementBuffer = GL.GenBuffer();
            vertexArray = GL.GenVertexArray();

            GL.BindVertexArray(vertexArray);

            GL.BindBuffer(BufferTarget.ArrayBuffer, vertexBuffer);
            GL.BufferData(BufferTarget.ArrayBuffer, levelVertices.Length * sizeof(float), levelVertices, BufferUsageHint.StaticDraw);

            GL.VertexAttribPointer(0, 3, VertexAttribPointerType.Float, false, 6 * sizeof(float), 0);
            GL.EnableVertexAttribArray(0);
            GL.VertexAttribPointer(1, 3, VertexAttribPointerType.Float, false, 6 * sizeof(float), 3 * sizeof(float));
            GL.EnableVertexAttribArray(1);

            GL.BindBuffer(BufferTarget.ElementArrayBuffer, elementBuffer);
            GL.BufferData(BufferTarget.ElementArrayBuffer, indices.Length * sizeof(uint), indices, BufferUsageHint.StaticDraw);

            //int retVal = shaderList.loadShaders("BasicVertex.glsl", "BasicFragment.glsl");
            int retVal = shaderList.loadShaders("SimpleTransVertex.glsl", "SimpleFragment.glsl");

            if (retVal != 0)
                Console.WriteLine("Something went wrong with the shaders");
        }

        protected override void OnUpdateFrame(FrameEventArgs e)
        {
            base.OnUpdateFrame(e);

            if (KeyboardState.IsKeyDown(Keys.Escape))
            {
                Close();
            }

            if (KeyboardState.IsKeyDown(Keys.Up))
            {
                camera.moveCamera(0.2f);
                zPos -= 0.1f;
                Console.WriteLine("xPos = {0}, zPos = {1}", xPos, zPos);
            }

            if (KeyboardState.IsKeyDown(Keys.Down))
            {
                camera.moveCamera(-0.2f);
                zPos += 0.1f;
                Console.WriteLine("xPos = {0}, zPos = {1}", xPos, zPos);
            }

            if (KeyboardState.IsKeyDown(Keys.Left))
            {
                camera.addToYaw(-0.09f);
                yRot -= 0.1f; if (yRot < 0) yRot = 360.0f;
                //xPos -= 0.1f;
                Console.WriteLine("xPos = {0}, zPos = {1}", xPos, zPos);
            }

            if (KeyboardState.IsKeyDown(Keys.Right))
            {
                camera.addToYaw(0.09f);
                yRot += 0.1f; if (yRot > 360.0f) yRot = 0.0f;
                //xPos += 0.1f;
                Console.WriteLine("xPos = {0}, zPos = {1}", xPos, zPos);
            }
        }

        protected override void OnRenderFrame(FrameEventArgs e)
        {
            base.OnRenderFrame(e);

            GL.Clear(ClearBufferMask.ColorBufferBit | ClearBufferMask.DepthBufferBit);
            GL.BindVertexArray(vertexArray);
            shaderList.useShader();
            int uniTrans = shaderList.getUniformLoc("trans");
            int uniView = shaderList.getUniformLoc("view");
            int uniProj = shaderList.getUniformLoc("proj");
            Matrix4 trans = Matrix4.CreateTranslation(0.0f, 0.0f, 0.0f);
            //Matrix4 view =  Matrix4.CreateTranslation(xPos, yPos, zPos) * Matrix4.CreateRotationY(MathHelper.DegreesToRadians(yRot));
            Matrix4 view = camera.getLookAt();
            Matrix4 proj = Matrix4.CreatePerspectiveFieldOfView(MathHelper.DegreesToRadians(45.0f), (float)width / (float)height, 0.1f, 200.0f);

            //interesting thing happens, when you have the second parameter set to true (transpose the matrix) then you would need
            //to multiply the matrix after the vector in the shader, if you do it before the vector in the shader some interesting artifacts
            //happen when you do the "translation".  You can also set the paramter to false and do the multiplication before the vector to obtain
            //the same results (true, multiply after the vector or false, multiply before the vector)
            //
            //another interesting thing is the translation along the x-axis, you apparently need to setup a projection matrix
            GL.UniformMatrix4(uniTrans, true, ref trans);
            GL.UniformMatrix4(uniView, true, ref view);
            GL.UniformMatrix4(uniProj, true, ref proj);

            //use the primitive type Triangles for a solid frame or LineLoop for a wireframe model
            //TriangleFan if I want to draw something else I guess...
            //GL.DrawArrays(PrimitiveType.TriangleFan, 0, 64);
            GL.DrawElements(PrimitiveType.Triangles, indices.Length, DrawElementsType.UnsignedInt, 0);

            //Code goes here.
            // Apparently I will need to write some vertex and fragment shaders to even draw anything on the screen
            // I have the vertex arrays loaded in the game level (curLevel) so I would just need to convert those to vertex
            // buffers and draw them to the screen.  I would just like to get something drawn to the screen first though


            SwapBuffers();
        }

        protected override void OnFramebufferResize(FramebufferResizeEventArgs e)
        {
            base.OnFramebufferResize(e);

            GL.Viewport(0, 0, e.Width, e.Height);
        }
    }
}