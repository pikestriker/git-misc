using OpenTK.Compute.OpenCL;
using OpenTK.Graphics.OpenGL4;
using OpenTK.Windowing.GraphicsLibraryFramework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

// sort of a copy from some code that I have done before in C++ for
// vertex and fragment shaders that allows multiple sets that you can
// call and state to use (a monostate class with a static list of all the
// shader classes).  It is incomplete just to get the example working

namespace Editor3D
{
    internal class Shader// : IDisposable
    {
        static Dictionary<string, Shader> shaders;
        static Shader curShader;

        string vFileName, fFileName;
        int vertexHandle, fragmentHandle, programHandle;
        bool isReady = false;
        bool disposedValue = false;
        public string key { get; private set; }

        public Shader()
        {
            if (shaders == null)
            {
                shaders = new Dictionary<string, Shader>();
                curShader = this;
            }
        }

        //protected virtual void Dispose(bool disposing)
        //{
        //    if (!disposedValue)
        //    {
        //        GL.DeleteProgram(programHandle);

        //        disposedValue = true;
        //    }
        //}

        //~Shader()
        //{
        //    if (!disposedValue)
        //    {
        //        Console.WriteLine("GPU resource leak!");
        //    }
        //}

        //public void Dispose()
        //{
        //    Dispose(true);
        //    GC.SuppressFinalize(this);
        //}

        private int loadAndCompileShader(ShaderType shaderType, string fileName)
        {
            string source = File.ReadAllText(fileName);
            int shader = GL.CreateShader(shaderType);
            GL.ShaderSource(shader, source);
            GL.CompileShader(shader);
            GL.GetShader(shader, ShaderParameter.CompileStatus, out int success);
            if (success == 0)
            {
                string infoLog = GL.GetShaderInfoLog(shader);
                Console.WriteLine(infoLog);
                return -1;
            }

            if (shaderType == ShaderType.VertexShader)
            {
                vFileName = fileName;
                vertexHandle = shader;
            }
            else
            {
                fFileName = fileName;
                fragmentHandle = shader;
            }
            return 0;
        }

        public int loadShaders(string vertexShader, string fragmentShader)
        {
            //prevent the same combination of shaders being loaded
            int retVal = getShader(vertexShader + fragmentShader);

            if (retVal < 0)
            {
                retVal = loadAndCompileShader(ShaderType.VertexShader, vertexShader);

                if (retVal != 0)
                {
                    return retVal;
                }

                retVal = loadAndCompileShader(ShaderType.FragmentShader, fragmentShader);

                if (retVal != 0)
                {
                    return retVal;
                }

                programHandle = GL.CreateProgram();

                GL.AttachShader(programHandle, vertexHandle);
                GL.AttachShader(programHandle, fragmentHandle);

                GL.LinkProgram(programHandle);

                GL.GetProgram(programHandle, GetProgramParameterName.LinkStatus, out int success);

                if (success == 0)
                {
                    string infoLog = GL.GetShaderInfoLog(programHandle);
                    Console.WriteLine(infoLog);
                    return -2;      // because the compile part can return -1
                }

                GL.DetachShader(programHandle, vertexHandle);
                GL.DetachShader(programHandle, fragmentHandle);
                GL.DeleteShader(fragmentHandle);
                GL.DeleteShader(vertexHandle);

                isReady = true;
                curShader = this;
                key = vertexShader + fragmentShader;
                shaders.Add(key, this);
            }
            return retVal;
        }

        public int useShader()
        {
            if (!isReady)
            {
                return -1;
            }
            GL.UseProgram(curShader.programHandle);
            return 0;
        }

        public int getShader(string shaderName)
        {
            int retVal = -1;

            if (shaders.ContainsKey(shaderName) && shaders[shaderName].isReady) 
            {
                retVal = shaders[shaderName].programHandle;
                isReady = true;
                key = shaderName;
                curShader = shaders[shaderName];
            }

            return retVal;
        }

        public int getUniformLoc(string uniformName)
        {
            int retVal = -1;
            if (isReady)
            {
                // going to add code later to find a shader to use (this class is initially setup to load multiple shaders)
                retVal = GL.GetUniformLocation(curShader.programHandle, uniformName);
            }
            return retVal;
        }
    }
}
