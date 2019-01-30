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
out vec3 fs_Biome;             // represents the biome [elevation, moisture, erosion] 0.0 for low, 1 for high


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

float interpNoiseRandom2to1(vec2 p, vec2 seed) {
    float fractX = fract(p.x);
    float x1 = floor(p.x);
    float x2 = x1 + 1.0;

    float fractY = fract(p.y);
    float y1 = floor(p.y);
    float y2 = y1 + 1.0;

    float v1 = random1(vec2(x1, y1), seed);
    float v2 = random1(vec2(x2, y1), seed);
    float v3 = random1(vec2(x1, y2), seed);
    float v4 = random1(vec2(x2, y2), seed);

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

//    return smoothstep(i1, i2, fractY);
    return mix(i1, i2, fractY);

}

float fbm2to1(vec2 p, vec2 seed) {
    float total  = 0.0;
    float persistence = 0.5;
    float octaves = 8.0;

    for(float i = 0.0; i < octaves; i++) {
        float freq = pow(2.0, i);
        float amp = pow(persistence, i);
        total = total + interpNoiseRandom2to1(vec2(p.x * freq, p.y * freq), seed) * amp;
    }
    return total;
}


float calcMonumentValleyHeight(vec2 pos) {
    return 0.0;
}

float calcDesertHeight(vec2 pos) {
    return 0.0;
}

float calcIslandHeight(vec2 pos) {
    return 0.0;
}

float calcFarmLandHeight(vec2 pos) {
    return 0.0;
}

float calcMountainHeight(vec2 pos) {
    return fbm2to1(pos, vec2(1.0,2.0));
}

float calcForrestHeight(vec2 pos) {
    return 0.0;
}

float calcCanyonHeight(vec2 pos) {
    return 0.0;
}

float calcFoothillsHeight(vec2 pos) {
    return 0.0;
}

float calcHeight(vec2 pos, vec3 biome) {
    return calcMountainHeight(pos);
       //low elevations
       if(biome[0] < 0.5) {
          //low moisture
          if(biome[1] < 0.5) {
             //low erosion
             if(biome[2] < 0.5) return calcMonumentValleyHeight(pos);
             //high erosion
             if(biome[2] >= 0.5) return calcDesertHeight(pos);
          }
          //high moisture
          if(biome[1] >= 0.5) {
             //low erosion
             if(biome[2] < 0.5) return calcIslandHeight(pos);
             //high erosion
             if(biome[2] >= 0.5) return calcFarmLandHeight(pos);
          }
       }
       //high elevations
       if(biome[0] >- 0.5) {
          //low moisture
          if(biome[1] < 0.5) {
             //low erosion
             if(biome[2] < 0.5) return calcMountainHeight(pos);
             //high erosion
             if(biome[2] >= 0.5) return calcCanyonHeight(pos);
          }
          //high moisture
          if(biome[1] < 0.5) {
             //low erosion
             if(biome[2] < 0.5) return calcForrestHeight(pos);
             //high erosion
             if(biome[2] >= 0.5) return calcFoothillsHeight(pos);
          }
       }

       return 0.0;
}


/**
Calcuate the biome based upon the closest worley poing
- return vec
**/

vec3 calcBiome(vec2 pos) {

    vec3 biome;
    float biomeSize = 100.0;
    vec2 worleyGridSize = vec2(40.0, 40.0);

    //set the biome based upon the noise values at the nearest worley point
    vec2 closestWorleyPoint = getClosestWorleyPoint2d(pos, worleyGridSize, vec2(1.0, 2.0));

    //get the elevation/moisture and erosion values
    biome[0] = floor(fbm2to1(closestWorleyPoint/biomeSize, vec2(1.0, 2.0)));
    biome[1] = floor(fbm2to1(closestWorleyPoint/biomeSize, vec2(2.0, 3.0)));
    biome[2] = floor(fbm2to1(closestWorleyPoint/biomeSize, vec2(3.0, 4.0)));

    return biome;
}

/**
Calculate the normal for each vertex by getting the height of the four
surrounding vertex and calculate the slope between them
*/
vec4 calcNormal(vec2 pos) {

     //USE CROSS PRODUCT STUPID!!!!!!!

    //get the normal for X direction
    float xSpacing = 0.09765625;
//    float x1Height = calcHeight(vec2(pos.x - xSpacing, pos.y));
//    float x2Height = calcHeight(vec2(pos.x + xSpacing, pos.y));
//    float slopeXY = (x2Height - x1Height) / (xSpacing * 2.0);
//
//    //get the normal for the Z direction
//    float zSpacing = 0.09765625;
//    float z1Height = calcHeight(vec2(pos.x, pos.y - zSpacing));
//    float z2Height = calcHeight(vec2(pos.x, pos.y + zSpacing));
//    float slopeZY = (z2Height - z1Height) / (zSpacing * 2.0);

    return vec4(0.0, 1.0, 0.0, 0.0);

}

vec4 calcMonumentValleyColor(vec2 pos, float height, vec4 normal) {
    //return vec4(0.3, 0.5, 0.0, 1.0);
    return vec4(0.3, 0.5, 0.0, 1.0);
}

vec4 calcDesertColor(vec2 pos, float height, vec4 normal) {
    return vec4(0.8, 0.6, 0.0, 1.0);
}

vec4 calcIslandColor(vec2 pos, float height, vec4 normal) {
    return vec4(0.1, 0.1, 0.7, 1.0);
}

vec4 calcFarmLandColor(vec2 pos, float height, vec4 normal) {
    return vec4(.9, 0.9, 0.1, 1.0);
}

vec4 calcMountainColor(vec2 pos, float height, vec4 normal) {
    return vec4(vec3(0.9, 0.75, 0.60) * height, 1.0);
}

vec4 calcForrestColor(vec2 pos, float height, vec4 normal) {
    return vec4(0.0, 0.45, 0.05, 1.0);
}

vec4 calcCanyonColor(vec2 pos, float height, vec4 normal) {
    return vec4(.65, .28, 0.20, 1.0);
}

vec4 calcFoothillsColor(vec2 pos, float height, vec4 normal) {
    return vec4(.78, .97, .5, 1.0);
}


vec4 calcColor(vec2 pos, vec3 biome, float height, vec4 normal) {
    return calcMountainColor(pos, height, normal);
    //low elevations
    if(biome[0] < 0.5) {
       //low moisture
       if(biome[1] < 0.5) {
          //low erosion
          if(biome[2] < 0.5) return calcMonumentValleyColor(pos, height, normal);
          //high erosion
          if(biome[2] >= 0.5) return calcDesertColor(pos, height, normal);
       }
       //high moisture
       if(biome[1] >= 0.5) {
          //low erosion
          if(biome[2] < 0.5) return calcIslandColor(pos, height, normal);
          //high erosion
          if(biome[2] >= 0.5) return calcFarmLandColor(pos, height, normal);
       }
    }
    //high elevations
    if(biome[0] >- 0.5) {
       //low moisture
       if(biome[1] < 0.5) {
          //low erosion
          if(biome[2] < 0.5) return calcMountainColor(pos, height, normal);
          //high erosion
          if(biome[2] >= 0.5) return calcCanyonColor(pos, height, normal);
       }
       //high moisture
       if(biome[1] < 0.5) {
          //low erosion
          if(biome[2] < 0.5) return calcForrestColor(pos, height, normal);
          //high erosion
          if(biome[2] >= 0.5) return calcFoothillsColor(pos, height, normal);
       }
    }
    return vec4(calcBiome(pos), 1.0);
}


void main()
{
  float sampling = 1.0;
  vec2 worldPlanePos = vs_Pos.xz + u_PlanePos;

  fs_Pos = vs_Pos.xyz;
  fs_Biome = calcBiome(worldPlanePos);
  fs_Height = calcHeight(worldPlanePos, fs_Biome);
  fs_Nor = calcNormal(worldPlanePos);
  fs_Col = calcColor(worldPlanePos, fs_Biome, fs_Height, fs_Nor);

  vec4 modelposition = vec4(vs_Pos.x, fs_Height, vs_Pos.z, 1.0);

  fs_LightVector = getLightPosition() - modelposition;
  //vec4 modelposition = vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

}
