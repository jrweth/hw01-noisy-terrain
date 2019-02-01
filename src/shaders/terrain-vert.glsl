#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;   //Time (in terms of frames)
uniform float u_SunSpeed;
uniform float u_MistSpeed;
uniform float u_FieldSize;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;
out vec4 fs_LightVector;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out float fs_Height;

//Biome Data necessary for shader
const int numBiomes = 8;
float[numBiomes] fs_BiomeHeight;

vec4[numBiomes] fs_BiomeNormal;
float[numBiomes] fs_BiomePercentage;
flat out int fs_Biome;


//
const vec4 vs_LightPosition = vec4(500.0, 50.0, 0.0, 0.0);
vec2[9] worleyPoints;

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
Order the supplied list of points by their distance from the supplied point
*/
void orderPointsByDistance(in vec2 point, inout vec2[9] points){
    bool changeMade;
    vec2 tempPoint;
    do{
        changeMade = false;
        for(int i=0; i<8; i++) {
            if(length(point - points[i]) > length(point - points[i+1])) {
                changeMade = true;
                tempPoint = points[i];
                points[i] = points[i+1];
                points[i+1] = tempPoint;
            }
        }
    } while (changeMade == true);
}


vec2[9] getNeigboringWorleyPoints2d(vec2 pos, vec2 gridSize, vec2 seed) {

    vec2[9] points;
    vec2 centerGridPos = pos - mod(pos, gridSize);  //the corner of the grid in which this point resides
    vec2 currentGridPos;
    int index = 0;

    for(float gridX = -1.0; gridX <= 1.0; gridX += 1.0) {
        for(float gridY = -1.0; gridY <= 1.0; gridY += 1.0) {
            currentGridPos = centerGridPos + vec2(gridX, gridY) * gridSize;
            points[index++] = currentGridPos + random2(currentGridPos, seed) * gridSize;
        }
    }
    orderPointsByDistance(pos, points);
    return points;
}

void insertAtIndex(in vec2 p, inout vec2[9] points, int index) {
    for(int i = 8; i > index; i--) {
        points[i] = points[i-1];
    }
    points[index] = p;
}

void insertAtIndex(in float p, inout float[9] points, int index) {
    for(int i = 8; i > index; i--) {
        points[i] = points[i-1];
    }
    points[index] = p;
}

vec2[9] getPoints(vec2 pos, vec2 gridSize, vec2 seed) {
    vec2[9] points;
    float[9] distances;
    for(int i =0; i< 9; i++) {
        points[i] = vec2(0.0,0.0);
        distances[i] = 100000.0;
    }

    vec2 centerGridPos = pos - mod(pos, gridSize);  //the corner of the grid in which this point resides

    vec2 currentGridPos;
    vec2 currentWorleyPoint;
    float currentDistance;
    int currentIndex = 0;
    //loop through the 9 grid sections surrouding this one to find the closes worley point
    for(float gridX = -1.0; gridX <= 1.0; gridX += 1.0) {
        for(float gridY = -1.0; gridY <= 1.0; gridY += 1.0) {
            currentGridPos = centerGridPos + vec2(gridX, gridY) * gridSize;
            currentWorleyPoint = currentGridPos + random2(currentGridPos, seed) * gridSize;
            currentDistance = length(currentWorleyPoint - pos);

            //put it where it belongs
            for(int i = 0; i <= currentIndex; i++) {
               if(currentDistance < distances[i]) {
                    for(int j = 8; j > i; j--) {
                        points[i] = points[i-1];
                        distances[i] = distances[i-1];
                    }
                    points[i] = currentWorleyPoint;
                    distances[i] = currentDistance;
               }
            }

            currentIndex++;
        }
    }
    return points;
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

vec2 getNextWorleyPoint2d(vec2 pos, vec2 gridSize, vec2 seed) {
    vec2 centerGridPos = pos - mod(pos, gridSize);  //the corner of the grid in which this point resides
    vec2 closestWorleyPoint = vec2(1.0, 1.0);
    vec2 nextWorleyPoint = vec2(1.0, 1.0);
    float closestDistance = (gridSize.x + gridSize.y) * 2.0;
    float nextDistance = (gridSize.x + gridSize.y) * 2.0;

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
                nextDistance = closestDistance;
                nextWorleyPoint = closestWorleyPoint;
                closestDistance = currentDistance;
                closestWorleyPoint = currentWorleyPoint;
            }
            else if (currentDistance < nextDistance) {
                nextDistance = currentDistance;
                nextWorleyPoint = currentWorleyPoint;
            }
        }
    }

    return nextWorleyPoint;
}

float onWorleyBoundary(vec2 pos, vec2 gridSize, float boundarySize, vec2 seed) {
    vec2 wPoint = getClosestWorleyPoint2d(pos, gridSize, seed);
    vec2 nextWPoint = getNextWorleyPoint2d(pos, gridSize, seed);

    float dist1 = length(pos - wPoint);
    float dist2 = length(pos - nextWPoint);

    return clamp((boundarySize - abs(dist1 -dist2)) / boundarySize, 0.0, 1.0 );
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


float calcMonumentValleyHeight(vec2 pos) {
    float noise = fbm2to1(pos*.2, vec2(34.4, 64.4));
    float height = 0.5 + smoothstep(0.7, 0.85, noise+0.13)*4.0 + pow(noise, 5.0);

    return height;
}



float calcDesertHeight(vec2 pos) {
    return calcMonumentValleyHeight(pos);
    return 0.0;
}

float calcIslandHeight(vec2 pos) {
    return 0.0;
}

float calcFarmLandHeight(vec2 pos) {
    float height = 0.3 + fbm2to1(pos*0.1, vec2(u_FieldSize, u_FieldSize))*0.1 ;
    float onBoundary = onWorleyBoundary(pos, vec2(u_FieldSize, u_FieldSize), 1.0, vec2(3,2));
    if(onBoundary > 0.0) {
        height = 0.3 -smoothstep(.3, .7, onBoundary) * 0.2;
//        if(onBoundary > 0.9)
//        height -= onBoundary * 0.05;
    }

    return height;
}

float calcMountainHeight(vec2 pos) {
    float fNoise = fbm2to1(pos, vec2(1,2));
    float wNoise = getWorleyNoise2d(pos*3.0, vec2(20.0, 20.0), vec2(1,2));
    wNoise = clamp(pow(wNoise + 0.4, 2.0),0.0, 1.0);
    float noise = mix(fNoise, wNoise, 0.7);
    return 4.5 + pow(noise, 3.0) * 3.0;
}


float calcForrestHeight(vec2 pos) {
    return calcMountainHeight(pos);
    return 0.0;
}

float calcCanyonHeight(vec2 pos) {
    float noise = fbm2to1(pos*.2, vec2(34.4, 64.4));
    float height = 0.5 + smoothstep(0.4, 0.5, noise)*4.0 + pow(clamp(0.0,1.0,noise + 0.6), 10.0);
    //flatten off water level
    if(height < 1.0) height = 1.0;


    return height;
}

float calcFoothillsHeight(vec2 pos) {
    return calcCanyonHeight(pos);
    return 0.0;
}

float calcBiomeHeight(vec2 pos, int biome) {
    if(biome == 0) return calcMonumentValleyHeight(pos);
    if(biome == 1) return calcDesertHeight(pos);
    if(biome == 2) return calcIslandHeight(pos);
    if(biome == 3) return calcFarmLandHeight(pos);
    if(biome == 4) return calcMountainHeight(pos);
    if(biome == 5) return calcCanyonHeight(pos);
    if(biome == 6) return calcForrestHeight(pos);
    return calcFoothillsHeight(pos);
}


/**
Calcuate the biome based upon sampling of noise at the closest worley point
- 0 = Monument Valley
- 1 = Dessert
- 2 = Farm Lands
- 3 = Islancs
- 4 = Mountain
- 5 = Canyons
- 6 = Forrest
- 7 = Foothills
**/

int calcBiome(vec2 pos) {

    vec3 biome;
    float biomeSize = 10.0;
    vec2 worleyGridSize = vec2(40.0, 40.0);

    //set the biome based upon the noise values at the nearest worley point
    vec2 closestWorleyPoint = worleyPoints[0];

    //get the elevation/moisture and erosion values
    int elevation = int(floor(fbm2to1(closestWorleyPoint / biomeSize, vec2(1.0, 2.0)) + 0.5));
    int moisture =  int(floor(fbm2to1(closestWorleyPoint / biomeSize, vec2(2.0, 3.0)) + 0.5));
    int erosion =   int(floor(fbm2to1(closestWorleyPoint / biomeSize, vec2(3.0, 4.0)) + 0.5));

    return elevation * 4 + moisture * 2 + erosion;

}

/**
Calculate the normal for each vertex by getting the height of the four
surrounding vertex and calculate the slope between them
*/
vec4 calcBiomeNormal(vec2 pos, int biome) {

    //get the four surrounding points
    float sampleDistance = 0.1;
    vec3 x1 = vec3(pos.x, calcBiomeHeight(pos - vec2(0.0, sampleDistance), biome), pos.y - sampleDistance);
    vec3 x2 = vec3(pos.x, calcBiomeHeight(pos + vec2(0.0, sampleDistance), biome), pos.y + sampleDistance);

    vec3 y1 = vec3(pos.x - sampleDistance, calcBiomeHeight(pos - vec2(sampleDistance, 0.0), biome), pos.y);
    vec3 y2 = vec3(pos.x + sampleDistance, calcBiomeHeight(pos + vec2(sampleDistance, 0.0), biome), pos.y);

    return vec4(normalize(cross(x1-x2, y1-y2)), 1.0);

}


/**
Initialize the biom data to pass to the fragment shader
**/
void initBiomes() {
    for(int i = 0; i<8; i++) {
        fs_BiomeHeight[i] = 0.0;
        fs_BiomeNormal[i] = vec4(0.0, 1.0, 0.0, 1.0);
        fs_BiomePercentage[i] = 0.0;
    }
}

void calcBiomePercentages(vec2 pos) {
    float borderThreshold = 5.0;

    vec2 p1 = getClosestWorleyPoint2d(pos, vec2(50.0,50.0), vec2(1.0,2.0));
    vec2 p2 = getNextWorleyPoint2d(pos, vec2(50.0,50.0), vec2(1.0,2.0));

    //if the distance from our point to the first worley point is way more
    // than  the distance to the second worley point we just have to
    // worry about one biomeo
    float dist1 = length(pos - p1);
    float dist2 = length(pos - p2);
    int point2Biome = calcBiome(worleyPoints[1]);
    if(dist2 - dist1 > borderThreshold || fs_Biome == point2Biome) {
        fs_BiomePercentage[fs_Biome] = 1.0;
    }

    else {
        fs_BiomePercentage[fs_Biome] = dist2 / (dist1 + dist2);
        fs_BiomePercentage[point2Biome] = dist1 / (dist1 + dist2);
    }
}

//this assumes we have already calculated the biome percentages
void calcBiomeHeights(vec2 pos) {
    for(int i=0; i<numBiomes; i++) {
        if(fs_BiomePercentage[i] > 0.0) {
            fs_BiomeHeight[i] = calcBiomeHeight(pos, i);
        }
    }

}

void calcBiomeNormals(vec2 pos) {
    for(int i=0; i<numBiomes; i++) {
        if(fs_BiomePercentage[i] > 0.0) {
            fs_BiomeNormal[i] = calcBiomeNormal(pos, i);
        }
    }
}

float calcHeight() {
    float height = 0.0;
    for(int i=0; i<numBiomes; i++) {
        if(fs_BiomePercentage[i] > 0.0) {
            height += fs_BiomePercentage[i] * fs_BiomeHeight[i];
        }
    }
    return height;
}


void main()
{
  initBiomes();
  float sampling = 1.0;
  vec2 worldPlanePos = vs_Pos.xz + u_PlanePos;
  float biomeSize = 10.0;
  vec2 worleyGridSize = vec2(50.0, 50.0);
  vec2 worleySeed = vec2(1.0,2.0);
  worleyPoints = getPoints(worldPlanePos, worleyGridSize, worleySeed);

  fs_Pos = vs_Pos.xyz;
  fs_Biome = calcBiome(worldPlanePos);
  calcBiomePercentages(worldPlanePos);
  calcBiomeHeights(worldPlanePos);
  calcBiomeNormals(worldPlanePos);

  fs_Height = calcHeight();
  fs_Nor = calcBiomeNormal(worldPlanePos, fs_Biome);
  fs_Col = vs_Col;

  vec4 modelposition = vec4(vs_Pos.x, fs_Height, vs_Pos.z, 1.0);

  fs_LightVector = getLightPosition() - modelposition;
  //vec4 modelposition = vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

}
