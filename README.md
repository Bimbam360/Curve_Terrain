# Curve_Terrain
Add-on for Godot Engine to generate simple 3D platformer terrain meshes based on bezier curves

![BezierTerrain](https://user-images.githubusercontent.com/11803603/177029277-8b0454c0-6166-4a37-93ff-b394b3fe6897.gif)


Installation
-----------
Copy the folder addons/curve_terrain into your project and activate the add-on from the Project -> Project Settings... -> Plugins menu.

Purpose
-------
I've seen several tweets recently of similar tools in Godot for simple/quick prototyping of level objects. Godot's existing CSGMeshs are useful for prefab shapes but the existing tools for custom shapes are laborious.

Usage
-----
Once the addon is active, you can add a curve_terrain node to your scene.
Standard Godot Curve controls are present above the editor viewport to add and manipulate Bezier points. Once more than 3 points are added, the terrain will be generated that matches the Curve profile and is updated in real time as changes are made.

TBD
-----
- Fix non-unique material parameter editing
- Fix add point only updating on every second point
- Add a second subtraction curve that allows you to cut lakes into a landscape.
- Add bevel/lip to terrain edge

Mesh Parameters
----------------
The terrain adjustable parameters currently include:

- *Depth* - The vertical depth of the terrain.
- *Bake Interval* - The effective resolution of the curve shape. Lower = higher resolution
- *Smooth Faces* - Self explanatory
- *Edge Noise Freq* - A very WIP noise modifier for adding procedural variation to the curve. Requires a low Bake Interval and can cause slef intersections which break geometry. 
- *Edge Noise Strength* - The strength of the above variation

**Material**
- *Max Grass Height* - Height of the top edge of the Grass Texture (Hard)
- *Min Grass Height* - Height of the top edge of the Grass Texture (Soft)
- *Grass Scale* - The UV scaling used for the top texture (assumed to be Grass)
- *Dirt Scale* - The UV scaling used for the bottom texture (assumed to be Dirt)
- *Specular* - Basic Specular control (TBC Texture Specular)
- *Metallic* - Basic Metallic control (TBC Texture Metallic)
- *Roughness* - Basic Roughness control (TBC Texture roughness)
- *Edge UV Scale* - Probably redundant as Dirt Scale should be used instead


Current Limitations
-------------------
* Uses a hidden child node to store geometry, so get_children() or get_child(0) will produce unexpected results
* Material is currently hard coded/not unique. Changes made to one will alter all (make unique currently not working).
* Uses builtin CSGPolygon functionality under the hood, so has similar limitations (i.e their may be a performance dropoff as more objects are created, and they probably shouldn't be subjected to movement at runtime)
* The bundled shader currently allows for a basic two tone approach with minimal configuration for PBRs.
* UV scales need to be adjusted manually and are not altered by depth
* Real time performance drops off the lower Bake Interval becomes (too be expected as vertex count increases).

Credits
---------------
* Base textures used and the icon were from the fabulous Kenney assets at https://www.kenney.nl/assets/prototype-textures (CC-0)

Contributing
------------
Please feel free to raise issues or submit PRs. This is my first attempt at a plugin so go easy on me ^^.
