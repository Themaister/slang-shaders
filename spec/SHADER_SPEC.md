# Vulkan GLSL RetroArch shader system

This document is a draft of RetroArch's new GPU shader system.
It will outline the features in the new shader subsystem and describe details for how it will work in practice.

In addition this document will contain various musings on why certain design choices are made and which compromised have been made to arrive at the conclusion. This is mostly for discussing and deliberation while the new system is under development.

## Introduction

### Target shader languages
 - Vulkan
 - GL 2.x (legacy desktop)
 - GL 3.x+ (modern desktop)
 - GLES2 (legacy mobile)
 - GLES3 (modern mobile)
 - (HLSL, potentially)
 - (Metal, potentially)

RetroArch is still expected to run on GLES2 and GL2 systems.
GL2 is mostly not relevant any longer, but GLES2 is certainly a very relevant platform still and having GLES2 compatibility makes GL2 very easy.
We therefore want to avoid speccing out a design which deliberately ruins GLES2 compatibility.

However, we also do not want to artificially limit shader features which are only available in GLES2. There are many shader builtins for example which only work in GLES3/GL3 and we should not hold back support in these cases. When we want to consider GLES2 compat we should not spec out high level features which do not make much sense in the context of GLES2.

### Why a new spec?

The current shader subsystem in RetroArch is quite mature with a large body of shaders written for it. While it has served us well, it is not forward-compatible.

The current state of writing high-level shading languages that work "everywhere" is very challenging.
There was no good ready-made solution for this.
Up until now, we have relied on nVidia Cg to serve as a basic foundation for shaders, but Cg has been discontinued for years and is closed source.
This is very problematic since Cg is not a forward compatible platform.
It has many warts which are heavily tied in to legacy APIs and systems.
For this reason, we cannot use Cg for newer APIs such as Vulkan and potentially D3D12 and Metal.

Cg cross compilation to GLSL is barely working and it is horribly unmaintainable, there are several unfixable issues.
The output is so horribly mangled and unoptimized that it is clearly not the approach we should be taking.
We also cannot do the Cg transform in runtime on mobile due to lack of open source Cg runtime, so there's that as well.

Another alternative is to write straight-up GLSL, but this too has some severe problems.
All the different GL versions and GLSL variants are different enough that it becomes painful to write portable GLSL code that works without modification.
Examples include:

 - varying/attribute vs in/out (legacy vs modern)
 - precision qualifiers (GLSL vs ESSL)
 - texture2D vs texture (legacy vs modern)

We do not want to litter every shader with heaps of #ifdefs everywhere.
We also want to avoid having to write pseudo-GLSL with some text based replacement behind the scenes.

### Warts in old shader system

While the old shader system is functional it has some severe warts which have accumulated over time.
In hindsight, some of the early design decisions were misguided and need to be properly fixed.

#### Forced POT with padding

This is arguably the largest wart of them all. The original reason behind this design decision was caused by a misguided effort to combat FP precision issues with texture sampling. The idea at the time was to avoid cases where nearest neighbor sampling at texel edges would cause artifacts. This is a typical case when textures are scaled with non-integer factors. However, the problem to begin with is naive nearest neighbor and non-integer scaling factors, and not FP precision. It was pure luck that POT tended to give better results with broken shaders, but we should not make this mistake again. POT padding has some severe issues which are not just cleanliness related either.

Technically, GLES2 doesn't require non-POT support, but in practice, all GPUs support this.

##### No proper UV wrapping
Since the texture "ends" at UV coords < 1.0, we cannot properly
use sampler wrapping modes. We can only fake `CLAMP_TO_BORDER` by padding with black color, but this filtering mode is not available by default in GLES2 and even GLES3!
`CLAMP_TO_BORDER` isn't necessarily what we want either. `CLAMP_TO_EDGE` is usually a far more sane default.

##### Extra arguments for actual width vs. texture width

With normalized coordinates we need to think in both real resolution (e.g. 320x240) vs. POT padded resolutions (512x512) to deal with normalized UV coords. This complicates things massively and
we were passing an insane amount of attributes and varyings to deal with this because the ratios between the two needn't be the same for two different textures.

#### Arbitrary limits
The way the old shader system deals with limits is quite naive.
There is a hard limit of 8 when referencing other passes and older frames.
There is no reason why we should have arbitrary limits like these.
Part of the reason is C where dealing with dynamic memory is more painful than is should be so it was easier to take the lazy way out.

#### Tacked on format handling

In more complex shaders we need to consider more than just the plain `RGBA8_UNORM` format.
The old shader system tacked on these things after the fact by adding booleans for SRGB and FP support, but this obviously doesn't scale.
This point does get problematic since GLES2 has terrible support for render target formats, but we should allow complex shaders to use complex RT formats
and rather just allow some shader presets to drop GLES2 compat.

#### PASS vs PASSPREV

Ugly. We do not need two ways to access previous passes, the actual solution is to have aliases for passes instead and access by name.


## High level Overview

The RetroArch shader format outlines a filter chain/graph, a series of shader passes which operate on previously generated data to produce a final result.
The goal is for every individual pass to access information from *all* previous shader passes, even across frames, easily.

 - The filter chain specifies a number of shader passes to be executed one after the other.
 - Each pass renders a full-screen quad to a texture of a certain resolution and format.
 - The resolution can be dependent on external information.
 - All filter chains begin at an input texture, which is created by a libretro core or similar.
 - All filter chains terminate by rendering to the "backbuffer".

The backbuffer is somewhat special since the resolution of it cannot be controlled by the shader.
It can also not be fed back into the filter chain later
because the frontend (here RetroArch) will render UI elements and such on top of the final pass output.

Let's first look at what we mean by filter chains and how far we can expand this idea.

### Simplest filter chain

The simplest filter chain we can specify is a single pass.

```
(Input) -> [ Shader Pass #0 ] -> (Backbuffer)
```

In this case there are no offscreen render targets necessary since our input is rendered directly to screen.

### Multiple passes

A trivial extension is to keep our straight line view of the world where each pass looks at the previous output.

```
(Input) -> [ Shader Pass #0 ] -> (Framebuffer) -> [ Shader Pass #1 ] -> (Backbuffer)
```

Framebuffer here might have a different resolution than both Input and Backbuffer.
A very common scenario for this is separable filters where we first scale horizontally, then vertically.

### Multiple passes and multiple inputs

There is no reason why we should restrict ourselves to a straight-line view.

```
     /------------------------------------------------\
    /                                                  v
(Input) -> [ Shader Pass #0 ] -> (Framebuffer #0) -> [ Shader Pass #1 ] -> (Backbuffer)
```

In this scenario, we have two inputs to shader pass #1, both the original, untouched input as well as a pass in-between.

We are now at a point where we can express an arbitrarily complex filter graph, but we can do better.
For certain effects, time can be an important factor.

### Multiple passes, multiple inputs, with history

We now extend our filter graph, where we also have access to information from earlier frames.

```
Frame N:        (Input     N, Input N - 1, Input N - 2) -> [ Shader Pass #0 ] -> (Framebuffer     N, Framebuffer N - 1, Input N - 3) -> [ Shader Pass #1 ] -> (Backbuffer)
Frame N - 1:    (Input N - 1, Input N - 2, Input N - 3) -> [ Shader Pass #0 ] -> (Framebuffer N - 1, Framebuffer N - 2, Input N - 4) -> [ Shader Pass #1 ] -> (Backbuffer)
Frame N - 2:    (Input N - 2, Input N - 3, Input N - 4) -> [ Shader Pass #0 ] -> (Framebuffer N - 2, Framebuffer N - 3, Input N - 5) -> [ Shader Pass #1 ] -> (Backbuffer)
```

For framebuffers we can read the previous frames framebuffer. We don't really need more than one frame of history since we have a feedback effect in place.
Just like IIR filters, the "response" of such a feedback in the filter graph gives us essentially "infinite" history back in time, albeit it is mostly useful for long-lasting blurs and ghosting effects. Supporting more than one frame of feedback would also be extremely memory intensive since framebuffers tend to be
much higher resolution than their input counterparts.

Input textures can have arbitrary number of textures as history (just limited by memory).
They cannot feedback since the filter chain cannot render into it, so it effectively is finite response (FIR).

For the very first frames, frames with frame N < 0 are transparent black (all values 0).


