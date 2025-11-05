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

# contibuting
all contributions are welcome, whether that's through github issues, messaging contributors (especially zodiepupper so i can organize things correctly) directly, emailing the support email barkvrsupport@pupper.dev, or submitting PRs!!

i want to add some stuff here about contributions, though. so here are some rules
- contributions should be presented, and handled in all aspects with respect and compassion for all involved.
- contributions and statements made by contributions should:
-   NOT BE hateful, or made with the intention of causing harm
-   NOT BE discriminatory against any specific type of person
-   NOT BE in support or in the interest of any Nazi ideals, hateful rhetoric, or suggesting ill fate on any group

this is not a place for politics that are unrelated to this project, and it is not a place for people to be hateful. 
if you contribute here, you are expected to treat others with kindness, love, and respect in all ways. if you don't give it, you don't deserve it.

code contributions should be:
- documented in code with clear and concise information that expects the reader does not have any prior knowledge about the project (within reason, no need to write books in comment blocks)
- straight to the point, a commit message should say what was done (and sometimes why)
- PRs should concisely state what is being changed as the title
- PRs should have a description that is as detailed as an Issue regarding the same topic would be
- PRs should contain 1 commit per discrete change
- PRs should focus on a single bug/issue/feature request and solving it quickly and reasonably
- Issues should be concise and explain what the problem is and what you expect to be the end goal of the problem being fixed
- it is prefered that Issues be conversational and informal, but formal is also fine. just don't be shy!

thank you for being here, thank you for being interested

## let's make something cool together!!

### For latest, look at the "dev" branch!
