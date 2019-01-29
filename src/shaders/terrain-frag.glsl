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
   float time = clamp(0.0, 1.0, sin(u_Time * u_SunSpeed/ 600.0) + 0.9);
   return mix(nightColor, dayColor, time);
}

void main()
{
    vec4 normal = fs_Nor;
    vec4 terrainColor;
    vec4 landColor  = vec4(1.0, 0.5, 0.25, 1.0);
    vec4 oceanColor = vec4(0.0, 0.0, 1.0, 1.0);
    vec4 snowColor  = vec4(1.0, 1.0, 1.0,  1.0);
    if(fs_Height <= 0.5) {terrainColor = oceanColor; normal = vec4(0.0, 1.0, 0.0, 1.0);}
    if(fs_Height > 0.5 && fs_Height < 1.8) terrainColor = landColor;
    if(fs_Height >= 1.80)  terrainColor = snowColor;

    // Calculate the diffuse term for Lambert shading
    float sunDiffuseTerm = dot(normalize(normal.xyz), normalize(fs_LightVector.xyz));
    vec4 diffuseColor;

    //make sure normals are correct for ocean
    if(fs_Height <= 0.5) diffuseColor = oceanColor;

    //sunlight
    if(sunDiffuseTerm > 0.0) {
        float ambientTerm = 0.2;
        float sunIntensity = clamp(0.1, 1.0, sunDiffuseTerm + ambientTerm);   //Add a small float value to the color multiplier
        diffuseColor = vec4(terrainColor.rgb * sunIntensity, terrainColor.a);
    }
    //moonlight
    else{
        float moonDiffuseTerm = dot(normalize(normal.xyz), normalize(vec3(-1.0 * fs_LightVector.x, -1.0*fs_LightVector.y, fs_LightVector.z)));
        float ambientTerm = 0.1;
        float moonIntensity = moonDiffuseTerm*2.0 + ambientTerm;   //Add a small float value to the color multiplier
        if(moonIntensity < 1.2) {
            diffuseColor = vec4(0.1,0.1,0.1,1.0);
        }
        else {
            diffuseColor = vec4(terrainColor.rgb * 0.08 + vec3(1.0, 1.0, 1.0) * moonIntensity, terrainColor.a) - vec4(1.0, 1.0, 1.0, 0.0);
        }
    }


    //mix the diffuse color with the color coming from the shader
    diffuseColor = mix(diffuseColor, fs_Col, 0.3);


    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(diffuseColor, getSkyColor(), t));
}
