#version 300 es
precision highp float;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting
uniform float u_Time;
uniform float u_SunSpeed;

out vec4 out_Col;

vec4 getSkyColor() {
   vec4 dayColor =   vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0);
   vec4 nightColor =  vec4(0.05, 0.0, 0.2, 1.0);
   float time = clamp(0.0, 1.0, sin(u_Time * u_SunSpeed/ 600.0) + 0.9);
   return mix(nightColor, dayColor, time);
}

void main() {
    out_Col = getSkyColor();
}
