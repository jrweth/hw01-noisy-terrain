#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;
uniform float u_SunSpeed;
uniform float u_MistSpeed;
uniform float u_FieldSize;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_LightVector;
flat in int fs_Biome;

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
    return vec4(cos(speed+1.3) * 1000.0, sin(speed+1.3) * 1000.0, -1000.0, 1.0);
}

float interpNoiseRandom1to1(float p, vec2 seed) {
    float fractX = fract(p);
    float x1 = floor(p);
    float x2 = x1 + 1.0;


    float v1 = random1(vec2(x1, seed.x), seed);
    float v2 = random1(vec2(x2, seed.x), seed);

    return mix(v1, v2, fractX);
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
        float amp = pow(persistence, i+1.0);
        total = total + interpNoiseRandom2to1(p * freq, seed) * amp;
    }
    return total;
}

float fbm1to1(float p, vec2 seed) {
    float total  = 0.0;
    float persistence = 0.5;
    float octaves = 8.0;

    for(float i = 0.0; i < octaves; i++) {
        float freq = pow(2.0, i);
        float amp = pow(persistence, i+1.0);
        total = total + interpNoiseRandom1to1(p * freq, seed) * amp;
    }
    return total;
}

float getTime() {
   return clamp(0.0, 1.0, sin(1.3 + (u_Time * u_SunSpeed/ 600.0)));
}

vec4 getSkyColor() {
   vec4 dayColor =   vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0);
   vec4 nightColor =  vec4(0.05, 0.0, 0.2, 1.0);
   return mix(nightColor, dayColor, getTime());
}


vec4 calcMonumentValleyColor(vec2 pos, float height, vec4 normal) {
    vec4 sand = vec4(1.0, 0.8, 0.55, 1.0);
    vec4 grassColor = vec4(0.09, 0.38, 0.12, 1.0);
    vec4 rockColor1 = vec4(1.0, 0.5, 0.25, 1.0);
    vec4 rockColor2 = vec4(0.988, 0.684, 0.492, 1.0);
    vec4 color;

    float height2 = height;

    if(height > 0.9) {
        height2 = height + fbm2to1(pos * 5.0, vec2(1.1,2.2))*0.5 - 0.2;
    }

    if (height2< 0.55) {
        color = sand;
    }
    else {
        color = mix(rockColor1, rockColor2, fbm1to1(height2*2.0, vec2(1.1,2.2)) * 2.0);
    }

    if(normal.y > 0.7) {
        if(fbm2to1(pos * 1.0, vec2(1.1,2.2)) > 0.4
           && fbm2to1(pos * 100.0, vec2(1.1,2.2)) > 0.5
        ) {
            color = mix(sand, grassColor, fbm2to1(pos * 1.0, vec2(1.1,2.2)));
        }
    }

    return color;
}

vec4 calcMountainColor(vec2 pos, float height, vec4 normal) {
   height = height - 4.0;

    float sunHeight = normalize(fs_LightVector).y;
    //adjust the height a bit so we don't get striation
    float adjHeight = height + fbm2to1(pos*5.1, vec2(3,4)) * 0.6 - 0.6;
    //return vec4(vec3(height), 1.0);
    vec4 terrainColor;
    vec4 rockColor1 = vec4(1.0, 0.5, 0.25, 1.0);
    vec4 rockColor2 = vec4(0.2, 0.2, 0.2, 1.0);
    vec4 snowColor  = vec4(1.0, 1.0, 1.0,  1.0);
    if(adjHeight < 1.3 + (sin(pos.x) +cos(pos.y))*0.2 ) {
        terrainColor = mix(rockColor1, rockColor2, fbm2to1(pos, vec2(4,3)));
        terrainColor =  mix(vec4(1.0,1.0,1.0,1.0), terrainColor,  height - fbm2to1(pos+u_Time * 0.02 * u_MistSpeed, vec2(3.4,43.4)) * 0.15);
    }
    else {
        terrainColor = snowColor;
    }
    return terrainColor;
}
vec4 calcDesertColor(vec2 pos, float height, vec4 normal) {
    return calcMonumentValleyColor(pos, height, normal);
    return vec4(0.8, 0.6, 0.0, 1.0);
}


vec4 calcFarmLandColor(vec2 pos, float height, vec4 normal) {

    //color the road
    if(height < 0.18) {
        vec4 roadColor1 = vec4(0.490, 0.325, 0.027, 1.0);
        vec4 roadColor2 = vec4(0.247, 0.176, 0.054, 1.0);
        return mix(roadColor1, roadColor2, fbm2to1(pos, vec2(1,2)));
    }

    //get a random value for the field
    vec2 wPoint = getClosestWorleyPoint2d(pos, vec2(u_FieldSize, u_FieldSize), vec2(3,2));
    float fieldRandom = random1(wPoint, vec2(1,0));
    vec4 cropColor = vec4(1.0);

    //pick a crop type
    //wheet
    if(fieldRandom < 0.3) {
        cropColor = vec4(0.094, 0.478, 0.043, 1.0);
    }
    else if(fieldRandom < 0.6) {
        cropColor = vec4(0.776, 0.662, 0.462, 1.0);
    }
    //corn
    else {
        cropColor = vec4(0.776, 0.776, 0.462, 1.0);
    }
    //grass

    return mix(cropColor, vec4(vec3(0.0), 1.0), 0.5 * fbm2to1(vec2(pos.y, pos.y), vec2(1,2)));
}


vec4 calcForrestColor(vec2 pos, float height, vec4 normal) {
    return calcMountainColor(pos, height, normal);
    return vec4(0.0, 0.45, 0.05, 1.0);
}

vec4 calcCanyonColor(vec2 pos, float height, vec4 normal) {
    vec4 color = calcMonumentValleyColor(pos, height, normal);

    //add some water
    if(height <= 1.0) {
        vec4 water1 = vec4(0.745, 0.921, 0.976, 1.0);
        vec4 water2 = vec4(0.133, 0.529, 0.647, 1.0);

        vec4 water = mix(water1, water2, fbm2to1(pos*0.4, vec2(3.43, 343.2)));
        color = water;

    }
    return color;
}
vec4 calcIslandColor(vec2 pos, float height, vec4 normal) {
    return calcCanyonColor(pos, height, normal);
    return vec4(0.1, 0.1, 0.7, 1.0);
}

vec4 calcFoothillsColor(vec2 pos, float height, vec4 normal) {
    return calcCanyonColor(pos, height, normal);
    return vec4(.78, .97, .5, 1.0);
}

vec4 calcColor(vec2 pos, int biome, float height, vec4 normal) {
    //low elevations
    if(biome == 0) return calcMonumentValleyColor(pos, height, normal);
    if(biome == 1) return calcDesertColor(pos, height, normal);
    if(biome == 2) return calcIslandColor(pos, height, normal);
    if(biome == 3) return calcFarmLandColor(pos, height, normal);
    if(biome == 4) return calcMountainColor(pos, height, normal);
    if(biome == 5) return calcCanyonColor(pos, height, normal);
    if(biome == 6) return calcForrestColor(pos, height, normal);
    if(biome == 7) return calcFoothillsColor(pos, height, normal);
    return vec4(1,1,1, 1.0);
}

void main()
{
    vec4 normal = fs_Nor;
    float sunHeight = normalize(fs_LightVector).y;
    float moonHeight = -sunHeight;

    vec4 col = calcColor(fs_Pos.xz + u_PlanePos, fs_Biome, fs_Height, fs_Nor);
    vec4 diffuseColor;

    //sunlight
    if(fs_LightVector.y > 0.0) {
    // Calculate the diffuse term for Lambert shading
        float sunDiffuseTerm = dot(normalize(normal.xyz), normalize(fs_LightVector.xyz));
        float ambientTerm = 0.3;
        float sunIntensity = clamp(0.1, 1.0, sunDiffuseTerm + ambientTerm) * sunHeight;   //Add a small float value to the color multiplier
        diffuseColor = vec4(col.rgb * sunIntensity, col.a);
    }
    //moonlight
    else{
        float moonDiffuseTerm = dot(normalize(normal.xyz), normalize(vec3(-1.0 * fs_LightVector.x, -1.0*fs_LightVector.y, fs_LightVector.z)));
        float ambientTerm = 0.3;
        float moonIntensity = clamp(0.2, 1.0, moonDiffuseTerm + ambientTerm) * moonHeight * 0.5;   //Add a small float value to the color multiplier
        vec3 greyscaledColor = mix(col.rgb, vec3(length(col.xyz)/3.0), 0.6);
        diffuseColor = vec4(greyscaledColor.rgb * moonDiffuseTerm * moonIntensity, 1.0 );
    }

    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(diffuseColor, getSkyColor(), t));
}
