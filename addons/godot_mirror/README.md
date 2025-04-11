# Godot Planar Reflections: Portals and Mirrors both with and without XR

This is an improved version of the VR mirror available from https://github.com/cheece/godot-vr-mirror-test-g4.

Use it to build portals, planar reflections or stereo compatible cameras.

## Installation

This addon is self-contained: To install, download this anywhere in your project, usually the addons folder.

Read on to learn about the optional engine patch for screenspace mirrors, if desired.

## Frustum vs screenspace mode

By default, this addon uses a frustum camera. This works well, but pixels are not square when rendered on your display which can cause distortion up close, as well as lighting glitches.

The `use_screenspace` checkbox will switch the camera to screenspace mode. This will make the image look far more crisp up close and should generally speaking be pixel perfect. To demonstrate this and test for pixel perfectness, uncheck "Portal is Mirror" and set the "Portal Relative Rotation" to "0 0 0 1" (0, 0, 0 euler) instead of the default 180 degree flip used for the mirror.

This only functions if the engine was compiled with a custom patch:
[vsk-override-projection-4.4](https://github.com/V-Sekai/godot/tree/vsk-override-projection-4.4) for Godot 4.4 (other engines have similarly named branches from our engine fork located at https://github.com/V-Sekai/godot

Note that the screenspace camera still renders the skybox incorrectly. This will need to be addressed in the above patch.

## Common setups

The default settings will work for a mirror.

To change it to a passthrough portal, uncheck "Portal is Mirror" and change the rotation from 0,180,0 to 0,0,0. This should make the portal roughly invisible. To move the portal around, consider assigning the destination portal Node3D to the Portal Relative Node.

Note that the scale can also be adjusted, for example the Z coordinate will make the mirror flat or appear really deep. Generally, it is best to adjust all 3 axes of scale together.

## Caveats

**Aspect ratio issues:** I neglected to propose a feature to Godot to change the aspect ratio. As a consequence of not having aspect ratio, I have to adjust pixel dimensions on the texture instead. This is both a source of up to 1 pixel of error in the frustum mirror, and also perhaps could impact performance if the scales are changed every frame.

**Negative scale unsupported:** You must use the `portal_is_mirror` setting to negate scale. Using negative `portal_relative_scale` axes, or negative/non-uniform scales elsewhere, will mess with the calculations. If you wish to negate the scale, do it only by toggling "Portal is Mirror".

**Lighting and skybox artifacts:** The frustum mode comes with a good share of lighting (shadow acne) artifacts from some angles. The skybox should look okay, but it also fails especially when the mirror is not flat.

The screenspace mode generally handles lighting better, but has issues with the skybox, and the oblique frustum will also stress the shadow cascades.

Engine (or planar reflection) patches are welcome!

## Contact us.

Let us know if you are using it! Join the V-Sekai discord community for support or to chat with us: https://discord.gg/7BQDHesck8
Or @Lyuma2d.bsky.app or mail me xn.lyuma on gmail.
