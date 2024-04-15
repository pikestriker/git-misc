using OpenTK.Graphics.OpenGL4;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Editor3D
{
    public class Game : GameWindow
    {
        GameLevel curLevel = new GameLevel();
        public Game(int width, int height, string title) : base(GameWindowSettings.Default, new NativeWindowSettings() { Size = (width, height), Title = title })
        { 
        }

        protected override void OnLoad()
        {
            base.OnLoad();

            GL.ClearColor(0.0f, 0.24f, 0.51f, 0.0f);
            curLevel.LoadLevelv2("wallsv2.txt");
            curLevel.SaveLevelv2("walls-savev2.txt");

            //Code goes here
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

            //Code goes here.

            SwapBuffers();
        }
    }
}