#version 330 core
layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aColour;

out vec3 ourColour;


// apparently you need to use the variable in your shader or it gets optimized out when it is compiled
// this was causing the GetUniformLocation to return a -1 when looking for this variable name
uniform mat4 trans;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    gl_Position = vec4(aPosition, 1.0) * trans * view * proj;
    ourColour = aColour;
}