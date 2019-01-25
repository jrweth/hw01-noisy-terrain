#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Height;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    vec3 backgroundColor = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
    vec3 heightColor = vec3(fs_Height * 5.0);
    vec3 oceanColor = vec3(0.0, 0.0, 1.0);
    if(fs_Height <= 0.06) heightColor = oceanColor;
    out_Col = vec4(mix(heightColor, backgroundColor, t), 1.0);
}
