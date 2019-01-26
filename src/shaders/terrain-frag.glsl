#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_LightVector;

in float fs_Height;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    vec4 backgroundColor = vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0);
    vec4 terrainColor;
    vec4 landColor  = vec4(1.0, 0.5, 0.25, 1.0);
    vec4 oceanColor = vec4(0.0, 0.0, 1.0, 1.0);
    vec4 snowColor  = vec4(1.0, 1.0, 1.0,  1.0);
    if(fs_Height <= 0.5) terrainColor = oceanColor;
    if(fs_Height > 0.5 && fs_Height < 1.8) terrainColor = landColor;
    if(fs_Height >= 1.80)  terrainColor = snowColor;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor.xyz), normalize(fs_LightVector.xyz));
    // Avoid negative lighting values
    //diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.1;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.
    vec4 diffuseColor = vec4(terrainColor.rgb * lightIntensity, terrainColor.a);
    //vec4 diffuseColor = vec4(terrainColor.rgb * fs_Height / 40.0, terrainColor.a);

    //make sure normals are correct for ocean
    if(fs_Height <= 0.5) diffuseColor = oceanColor;

    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(diffuseColor, backgroundColor, t));
    //out_Col = vec4(normalize(fs_Nor.xyz), 1.0);
    //out_Col = vec4(diffuseColor);

    //out_Col = vec4(heightColor, 1.0);
}
