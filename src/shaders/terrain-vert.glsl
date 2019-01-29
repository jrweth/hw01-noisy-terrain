#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;   //Time (in terms of frames)
uniform float u_SunSpeed;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;
out vec4 fs_LightVector;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out float fs_Height;

const vec4 vs_LightPosition = vec4(500.0, 50.0, 0.0, 0.0);

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}


//get the grid position of the lower corner for the given position
vec2 getGridSection2d(vec2 pos, float gridSize) {
   return pos - mod(pos, gridSize);
}

/*
Determine worley noise for given position and grid size
- param vec2 pos :      the position to test for
- param vec2 gridSize:  the size of the grid
- param vec2 seed:       the random seed
- return vec2:          the location of the closest worley point
*/
vec2 getClosestWorleyPoint2d(vec2 pos, vec2 gridSize, vec2 seed) {
    vec2 centerGridPos = pos - mod(pos, gridSize);  //the corner of the grid in which this point resides
    vec2 closestWorleyPoint = vec2(1.0, 1.0);
    float closestDistance = (gridSize.x + gridSize.y) * 2.0;

    vec2 currentGridPos;
    vec2 currentWorleyPoint;
    float currentDistance;
    //loop through the 9 grid sections surrouding this one to find the closes worley point
    for(float gridX = -1.0; gridX <= 1.0; gridX += 1.0) {
        for(float gridY = -1.0; gridY <= 1.0; gridY += 1.0) {
            currentGridPos = centerGridPos + vec2(gridX, gridY) * gridSize;
            currentWorleyPoint = currentGridPos + random2(currentGridPos, seed) * gridSize;
            currentDistance = length(currentWorleyPoint - pos);
            if(currentDistance < closestDistance) {
                closestDistance = currentDistance;
                closestWorleyPoint = currentWorleyPoint;
            }
        }
    }

    return closestWorleyPoint;
}

float getWorleyNoise2d(vec2 pos, vec2 gridSize, vec2 seed) {
    vec2 wPoint = getClosestWorleyPoint2d(pos, gridSize, seed);
    return length(wPoint - pos) / length(gridSize);
}

//git the position of the sun / moon
vec4 getLightPosition() {
    float speed = u_Time * u_SunSpeed/ 600.0;
    return vec4(cos(speed) * 1000.0, sin(speed) * 1000.0, -1000.0, 1.0);
}

float interpNoiseRandom2to1(vec2 p) {
    float fractX = fract(p.x);
    float x1 = floor(p.x);
    float x2 = x1 + 1.0;

    float fractY = fract(p.y);
    float y1 = floor(p.y);
    float y2 = y1 + 1.0;

    float v1 = random1(vec2(x1, y1), vec2(1.1, 2.3));
    float v2 = random1(vec2(x2, y1), vec2(1.1, 2.3));
    float v3 = random1(vec2(x1, y2), vec2(1.1, 2.3));
    float v4 = random1(vec2(x2, y2), vec2(1.1, 2.3));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

//    return smoothstep(i1, i2, fractY);
    return mix(i1, i2, fractY);

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

float calcHeight(vec2 pos) {

    //return x*sin(u_Time/40.0);
//    return 20.0 + sin(3.14159/2.0 + (x + u_PlanePos.x) * 3.14159/25.0) * 5.0
//       + cos((z + u_PlanePos.y) * 3.14159 /25.0) * 5.0;
   return fbm2to1((pos + u_PlanePos)/5.0)*2.0 - 1.0;

}

/**
Calculate the normal for each vertex by getting the height of the four
surrounding vertex and calculate the slope between them
*/
vec4 calcNormal() {

    //get the normal for X direction
    float xSpacing = 0.09765625;
    float x1Height = calcHeight(vec2(vs_Pos.x - xSpacing, vs_Pos.z));
    float x2Height = calcHeight(vec2(vs_Pos.x + xSpacing, vs_Pos.z));
    float slopeXY = (x2Height - x1Height) / (xSpacing * 2.0);
    vec4 normalXY;
    if(slopeXY > 0.0) {
        normalXY = vec4(-1.0, 1.0/slopeXY,  0.0, 0.0);
    }
    else if(slopeXY < 0.0) {
        normalXY = vec4(1.0, -1.0/slopeXY,  0.0, 0.0);
    }
    else {
        normalXY = vec4(0.0, 1.0, 0.0, 0.0);
    }

    //get the normal for the Z direction
    float zSpacing = 0.09765625;
    float z1Height = calcHeight(vec2(vs_Pos.x, vs_Pos.z - zSpacing));
    float z2Height = calcHeight(vec2(vs_Pos.x, vs_Pos.z + zSpacing));
    float slopeZY = (z2Height - z1Height) / (zSpacing * 2.0);
    vec4 normalZY;

    if(slopeZY > 0.0) {
        normalZY = vec4(0.0, 1.0/slopeZY,  -1.0, 0.0);
    }
    else if(slopeZY < 0.0) {
        normalZY = vec4(0.0, -1.0/slopeZY,  1.0, 0.0);
    }
    else {
        normalZY = vec4(0.0, 1.0, 0.0, 0.0);
    }
    //return vec4(0.0,1.0,0.0,1.0);
    return normalXY;

    return normalXY + normalZY;
}

void main()
{
  float sampling = 1.0;
  fs_Pos = vs_Pos.xyz;
  fs_Height = calcHeight(vs_Pos.xz);
  fs_Nor = calcNormal();

  //vec4 modelposition = vec4(vs_Pos.x, fs_Height * 2.0, vs_Pos.z, 1.0);
  vec4 modelposition = vec4(vs_Pos.x, calcHeight(vs_Pos.xz), vs_Pos.z, 1.0);

  vec2 biomeGridSize = vec2(20.0, 20.0);

  //set the color based upon worley noise
  vec2 closestWorleyPoint = getClosestWorleyPoint2d(vs_Pos.xz, biomeGridSize, vec2(1.0, 2.0));

  //use worley noise to get base biome color
  fs_Col = vec4(
      vec3(
          random1(closestWorleyPoint.xy, vec2(1.0)),
          random1(closestWorleyPoint.xy, vec2(2.0)),
          random1(closestWorleyPoint.xy, vec2(3.0))
      ) * 2.0 * getWorleyNoise2d(vs_Pos.xz, biomeGridSize, vec2(1.0, 2.0)),
      1.0
  );

  fs_LightVector = getLightPosition() - modelposition;
  //vec4 modelposition = vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

}
