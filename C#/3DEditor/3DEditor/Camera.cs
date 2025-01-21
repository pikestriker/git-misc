using OpenTK.Graphics.OpenGL4;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Editor3D
{
    internal class Camera
    {
        Vector3 position;
        Vector3 front;
        Vector3 up;
        float yaw, pitch;

        public Camera(Vector3 position, Vector3 front, Vector3 up)
        {
            this.position = position;
            this.front = Vector3.Normalize(position - front);
            this.up = up;

            //this is the way to calculate the yaw (https://stackoverflow.com/a/1847495) based on the front vector
            yaw = MathHelper.RadiansToDegrees((float)Math.Atan2(this.front.Z, this.front.X));
            pitch = 0.0f;
            //calculateFront();
        }

        void calculateFront()
        {
            front.X = (float)Math.Cos(MathHelper.DegreesToRadians(pitch)) * (float)Math.Cos(MathHelper.DegreesToRadians(yaw));
            front.Y = (float)Math.Sin(MathHelper.DegreesToRadians(pitch));
            front.Z = (float)Math.Cos(MathHelper.DegreesToRadians(pitch)) * (float)Math.Sin(MathHelper.DegreesToRadians(yaw));
            front = Vector3.Normalize(front);
        }

        public void addToPitch(float updatePitch)
        {
            pitch += updatePitch;

            // make sure that we can't look straight up and possibly cause a gimbal lock
            if (pitch > 89.0f) pitch = 89.0f;
            else if (pitch < -89.0f) pitch = -89.0f;
            calculateFront();
        }

        public void addToYaw(float updateYaw) 
        {
            yaw += updateYaw;
            calculateFront();
        }

        public Matrix4 getLookAt()
        {
            return Matrix4.LookAt(position, position + front, up);
        }

        //this moves it in the direction of front
        public void moveCamera(float speed)
        {
            position += front * speed;
        }
    }
}
