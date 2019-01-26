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

###Starting Point - Sine Wave Terrain 
The base project uses a 2D mapping of the plane coordinates to height using sine/cosine wave function.  The terrain 
color brightness is then determined by same height field. 
![](img/startScene.png)

###Using [Fractal Brownian Motion](https://en.wikipedia.org/wiki/Fractional_Brownian_motion) to Specify Height
The first adjustment was to replace the sine function with  [FBM](https://en.wikipedia.org/wiki/Fractional_Brownian_motion)
to determine the vertex height in the vertex shader.  
![](img/fbm.png)

###Using Height to determine elevation color
To add more interest to the color, a few simple changes were made to the fragment shader in
order to create elevation based coloration:
- values of highest height were given snow color
- values of medium height were given rock color
- values below waterline threshold were given water color and adjusted up to the waterline 
![](img/fbm_simple_color.png)

###Determining Normals
In order to determine the normals which can be used by the fragment shader the normal at 
each adjusted plane vertex needed to be determined.  This was done in the vertex shader by
simply calculating the positions of the four neighboring vertex positions and averaging these
to get the slope at the vertex in question.







