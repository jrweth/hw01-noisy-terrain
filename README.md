# Procedurally Generated Terrain with WebGl Shaders

By J. Reuben Wetherbee
University of Pennsylvania
Computer Graphics and Game Technology Masters Program
CIS 566 Spring 2019

## Overview
The purpose of this project was to create procedurally generated terrain using a combination of noise functions to
 adjust the height and color of a plane in the WebGl vertex and fragment shaders.  Features of this project include the following:
 - Fractal Brownian Noise (FBM) to generate terrain height
Demo can be viewed [in github pages](https://jrweth.github.io/hw01-noisy-terrain/)

## Basic Setup (non shader code)
- A subdivided plane rendered with a shader that deforms it with a sine curve
and applies a blue distance fog to it to blend it into the background.
- A movable camera 
- A keyboard input listener that listens for the WASD keys
and updates the plane shader representing a 2D position
- A square that spans the range [-1, 1] in X and Y that is rendered as the
"background" of the scene

### Starting Point - Sine Wave Terrain 
The base project uses a 2D mapping of the plane coordinates to height using sine/cosine wave function.  The terrain 
color brightness is then determined by same height field. 
![](img/startScene.png)

### Using [Fractal Brownian Motion](https://en.wikipedia.org/wiki/Fractional_Brownian_motion) to Specify Height
The first adjustment was to replace the sine/cosine height function with a height function based upon [FBM](https://en.wikipedia.org/wiki/Fractional_Brownian_motion)
in the vertex shader.  Samples were taken iteratively 8 times adjusting the sample length by 50% for each iteration.
![](img/fbm.png)

### Using Height to determine elevation color
To add more interest to the color, a few simple changes were made to the fragment shader in
order to create elevation based coloration:
- values of highest height were given snow color
- values of medium height were given rock color
- values of low height were given water color and the height was adjusted up to the waterline 
![](img/fbm_simple_color.png)

### Determining Normals
In order to determine the normals which to be used by the fragment shader the normal at 
each adjusted plane vertex needed to be determined.  This was done in the vertex shader by
simply calculating the gradient from four neighboring points.  The normal value was then passed to the fragment
shader which used the position of the light source (sun) to adjust the color value via [lambert shading](https://en.wikipedia.org/wiki/Lambertian_reflectance).
![](img/fbm_simple_color_normals.png)

### Sun and Moon Transversal 
Since the lambert shading developed in the previous step was based upon the light position, it was then possible to modify this position
over time to create the effect of the sun transversing across the sky over time.  Therefore a uniform time value
was added to the shader program so that the sun position could be calculated.   During the night the base color value was 
adjusted to be nearly grey scale to simulate the moon transversal.  The background color was also adjust to simulate night time.
![](img/nighttime.png)

### Separating Terrain into Biomes using [Worley Noise](https://en.wikipedia.org/wiki/Worley_noise)
The next step is to separate terrain into biomes.  This was accomplished by dividing the plane up into a grid, assigning
a random point to each grid, and the using the technique of Worley noise to divide up the plane.
![](img/worley.png)
The worley noise map can then be combined with the height terrain to eventually create separate biomes.
![](img/worley_terrain.png)


### Criteria for selecting Biome type
- elevation
- moisture
- erosion

Biomes:
- Islands (low elevation, high moisture, high erosion) 
- Farm Lands (low elevation, high moisture, low erosion)
- Dessert (low elevation, low moisture, high erosion)
- Monument Valley (low elevation , low moisture, low erosion)

- Foothills (high elevation, high moisture, high erosion)
- Forrest (high elevation, high moisture, low erosion)
- Mountain (high elevation, low moisture, low erosion)
- Canyons (high elevation , low moisture, high erosion)







