using OpenTK.Mathematics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OpenTK.Graphics.OpenGL4;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Editor3D
{
    internal class Element
    {
        protected Vector3 pos;
        protected Vector3 color;
        protected int vertexArray;
        protected string shaderKey;
        bool isReady = false;       //shader is compiled and ready, setup is executed
        protected uint[] indices;
        protected Dictionary<string, object> shaderUniforms = new Dictionary<string, object>();
        protected enum viewType
        {
            Projection,
            Ortho
        }
        protected viewType curType { get; }
        protected Matrix4 proj;
        protected Matrix4 view;

        //drawing could be the same thing, bind the shader, vertex array, change the viewport and set the perspective then draw primitives
        //doesn't matter what you are drawing.  You do need to know what you are selecting when you are modifying something though
        //might just make this a regular function because drawing is similar to all things (what I mentioned above) so that it can be used in
        //subclasses but you can get uniform location and set what you need to set there then call the super class draw
        public virtual void draw()
        {
            if (isReady)
            {
                GL.BindVertexArray(vertexArray);
                Shader shaderList = new Shader();
                shaderList.getShader(shaderKey);
                shaderList.useShader();
                int uniTrans = shaderList.getUniformLoc("trans");
                int uniView = shaderList.getUniformLoc("view");  //not sure why I commented this line out...
                int uniProj = shaderList.getUniformLoc("proj");
                Matrix4 trans = Matrix4.CreateTranslation(pos);

                GL.UniformMatrix4(uniTrans, true, ref trans);
                GL.UniformMatrix4(uniView, true, ref view);
                GL.UniformMatrix4(uniProj, true, ref proj);

                if (shaderUniforms.Count > 0)
                {
                    foreach (var (key, value) in shaderUniforms)
                    {
                        //key is the uniform name and value is the value
                        int uniLoc = shaderList.getUniformLoc(key);

                        if (uniLoc < 0)
                        {
                            Console.WriteLine("Problem getting uniform location for " + key);
                        }
                        else
                        {
                            if (value is Vector3)
                            {
                                Vector3 vector = (Vector3)value;
                                GL.Uniform3(uniLoc, vector.X, vector.Y, vector.Z);
                            }
                            else if (value is Matrix4)
                            {
                                Matrix4 matrix = (Matrix4)value;
                                GL.UniformMatrix4(uniLoc, true, ref matrix);
                            }
                        }
                    }
                }
                GL.DrawElements(PrimitiveType.Triangles, indices.Length, DrawElementsType.UnsignedInt, 0);
            }
        }

        public virtual void setup()
        { }


        public virtual void loadShader(string vertexShader = "VertexVertex.glsl", string fragmentShader = "VertexFragment.glsl")
        {
            Shader shaderList = new Shader();
            int retVal = shaderList.loadShaders(vertexShader, fragmentShader);

            if (retVal != 0)
                Console.WriteLine("Something went wrong with the shaders");

            shaderKey = shaderList.key;
            isReady = true;
        }

        public void setPos(Vector3 pos)
        {
            this.pos = pos;
        }

        public void setView(Matrix4 view)
        {
            this.view = view;
        }
    }
}
