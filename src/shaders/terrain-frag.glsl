#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;
uniform float u_SunSpeed;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_LightVector;

in float fs_Height;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec4 getSkyColor() {
   vec4 dayColor =   vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0);
   vec4 nightColor =  vec4(0.05, 0.0, 0.2, 1.0);
   float time = clamp(0.0, 1.0, sin(1.3 + (u_Time * u_SunSpeed/ 600.0)) + 0.9);
   return mix(nightColor, dayColor, time);
}

void main()
{
    vec4 normal = fs_Nor;

    // Calculate the diffuse term for Lambert shading
    float sunDiffuseTerm = dot(normalize(normal.xyz), normalize(fs_LightVector.xyz));
    vec4 diffuseColor;


    //sunlight
    if(sunDiffuseTerm > 0.0) {
        float ambientTerm = 0.2;
        float sunIntensity = clamp(0.1, 1.0, sunDiffuseTerm + ambientTerm);   //Add a small float value to the color multiplier
        diffuseColor = vec4(fs_Col.rgb * sunIntensity, fs_Col.a);
    }
    //moonlight
    else{
        float moonDiffuseTerm = dot(normalize(normal.xyz), normalize(vec3(-1.0 * fs_LightVector.x, -1.0*fs_LightVector.y, fs_LightVector.z)));
        float ambientTerm = 0.1;
        float moonIntensity = moonDiffuseTerm*1.3 + ambientTerm;   //Add a small float value to the color multiplier
        if(moonIntensity < 1.2) {
            diffuseColor = vec4(0.1,0.1,0.1,1.0);
        }
        else {
            diffuseColor = vec4(fs_Col.rgb * 0.08 + vec3(1.0, 1.0, 1.0) * moonIntensity, fs_Col.a) - vec4(1.0, 1.0, 1.0, 0.0);
        }
    }

    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(diffuseColor, getSkyColor(), t));
}
