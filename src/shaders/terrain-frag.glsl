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
    vec3 backgroundColor = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
    vec3 terrainColor;
    vec3 landColor = vec3(1.0, 0.5, 0.25) * fs_Height/2.0;
    vec3 oceanColor = vec3(0.0, 0.0, 1.0);
    vec3 snowColor = vec3(1.0, 1.0, 1.0) * fs_Height/2.0;;
    if(fs_Height <= 0.5) terrainColor = oceanColor;
    if(fs_Height > 0.5 && fs_Height < 1.8) terrainColor = landColor;
    if(fs_Height >= 1.80)  terrainColor = snowColor;

    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(terrainColor, backgroundColor, t), 1.0);
    //out_Col = vec4(heightColor, 1.0);
}
