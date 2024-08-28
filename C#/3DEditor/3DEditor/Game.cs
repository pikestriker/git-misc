using OpenTK.Graphics.OpenGL4;
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
        GameLevel curLevel = new GameLevel();
        int vertexBuffer;
        int vertexArray;
        Shader shaderList = new Shader();
        public Game(int width, int height, string title) : base(GameWindowSettings.Default, new NativeWindowSettings() { Size = (width, height), Title = title })
        { 
        }

        protected override void OnLoad()
        {
            base.OnLoad();

            GL.ClearColor(0.0f, 0.24f, 0.51f, 0.0f);
            curLevel.LoadLevelv2("wallsv2.txt");
            curLevel.SaveLevelv2("walls-savev2.txt");

            vertexBuffer = GL.GenBuffer();
            vertexArray = GL.GenVertexArray();

            GL.BindVertexArray(vertexArray);

            GL.BindBuffer(BufferTarget.ArrayBuffer, vertexBuffer);
            GL.BufferData(BufferTarget.ArrayBuffer, vertices.Length * sizeof(float), vertices, BufferUsageHint.StaticDraw);

            GL.VertexAttribPointer(0, 3, VertexAttribPointerType.Float, false, 3 * sizeof(float), 0);
            GL.EnableVertexAttribArray(0);

            int retVal = shaderList.loadShaders("BasicVertex.glsl", "BasicFragment.glsl");

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
        }

        protected override void OnRenderFrame(FrameEventArgs e)
        {
            base.OnRenderFrame(e);

            GL.Clear(ClearBufferMask.ColorBufferBit);
            GL.BindVertexArray(vertexArray);
            shaderList.useShader();
            GL.DrawArrays(PrimitiveType.Triangles, 0, 3);

            //Code goes here.
            // Apparently I will need to write some vertex and fragment shaders to even draw anything on the screen
            // I have the vertex arrays loaded in the game level (curLevel) so I would just need to convert those to vertex
            // buffers and draw them to the screen.  I would just like to get something drawn to the screen first though
            

            SwapBuffers();
        }
    }
}