<div align="center">
  <h3><strong>BarkVR</strong></h3>
</div>

BarkVR is an open-source and decentralized social XR creativity tool, built upon the solid foundation of Godot 4.x.

# WARNING:

Please keep in mind that this software is not secure in it's current state. It is a completely open tool that exposes
godot functionality to you and any other user you connect to. This will likely remain true until the first alpha. The
first alpha will contain security and network sync exclusions to allow you to prevent users from pushing code
to your device unless you clearly and explicitly allow it. But those features are not ready yet.

## Status:
The project is still in the very early stages. Please feel free to support the project however you wish, or not at all.

[Patreon](https://www.patreon.com/pupperdev)

[Ko-Fi](https://ko-fi.com/zodiepupper)

[Liberapay](https://liberapay.com/zodiepupper)

## Socials:
[discord](https://discord.gg/VW9qhmjuXM)

[matrix](https://matrix.to/#/#pupperdev:matrix.pupper.dev)

## Core Focus:
- Accessibility: Making BarkVR welcoming to everyone, regardless of background or ability.
- Decentralized Design: Giving users the power to shape BarkVR's world through decentralization.
- User Empowerment: Providing users with complete control over their creations for a sense of ownership.
- Open Design: Welcoming collaboration and transparency to evolve BarkVR together.
- Social VR: Creating a space where connections thrive beyond physical limits, fostering shared experiences and boundless imagination.

We're working to incorporate technologies like the Matrix messaging API for user managment, ppfs or any other static file hosting, and webrtc for the peer connections for our storage solution.
This means the whole platform is completely open and capable of being run/hosted without any reliance on the maintainers.

## features:
- realtime networked scene editing of any object in the shared godot scene
- realtime voice over ip, using the gdopus utility
- realtime gdscript loading (a virtual scripting environment is planned for the future for security)
- runtime import of any asset supported by godot with some extensions (vrm, gltf, fbx, images, audio)
- full fledged chat and call system through matrix (calling features are still partially WIP)
- spatialized VOIP using Opus
- full peer to peer mesh networking with WebRTC with PAXOS state resolution (PAXOS library WIP)
- generative audio tools (can load samples, act as a modular synthesizer/FM-synth | WIP)
- full modeling, rigging, and texturing toolset (supports voxel based mesh drawing | WIP)

### For latest, look at the "dev" branch!
