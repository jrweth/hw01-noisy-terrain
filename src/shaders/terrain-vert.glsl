#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Height;

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}


float interpNoiseRandom2to1(vec2 p) {
    float fractX = fract(p.x);
    float x1 = p.x - fractX;
    float x2 = x1 + 1.0;
    float fractY = fract(p.y);
    float y1 = p.y - fractY;
    float y2 = y1 + 1.0;

    float v1 = random1(vec2(x1, y1), vec2(12.232, 3212.123));
    float v2 = random1(vec2(x2, y1), vec2(12.232, 3212.123));
    float v3 = random1(vec2(x1, y2), vec2(12.232, 3212.123));
    float v4 = random1(vec2(x2, y2), vec2(12.232, 3212.123));

    float i1 = smoothstep(v1, v2, fractX);
    float i2 = smoothstep(v3, v4, fractX);

    return smoothstep(i1, i2, fractY);

}

float fbm2to1(vec2 p) {
    float total  = 0.0;
    float persistence = 0.5;
    float octaves = 8.0;

    for(float i = 0.0; i < octaves; i++) {
        float freq = pow(2.0, i);
        float amp = pow(persistence, i);
        total = total + interpNoiseRandom2to1(vec2(p.x * freq, p.y * freq)) * amp;
    }
    return total;
}

void main()
{
  float sampling = 1.0;
  fs_Pos = vs_Pos.xyz;
  fs_Height = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  fs_Height = fbm2to1(vec2(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y) * sampling) / 10.0;
  if(fs_Height < 0.05) fs_Height = 0.05;

  vec4 modelposition = vec4(vs_Pos.x, fs_Height * 2.0, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
