# Try realtime texture paint

This project is for self-studying of realtime texture paint

# DEMO

![Unity 2019 1 6f1 Personal - SampleScene unity - TryUnityShader - PC, Mac   Linux Standalone _DX12_ 2020-02-24 16-11-32_Trim](https://user-images.githubusercontent.com/29055086/75148350-c30ba600-5742-11ea-9a07-5a55414e9e3b.gif)

I can update texture in realtime using `CustomRenderTexture`.

# Features

Realtime texture paint is implemented in two ways.

- using `RenderTexture` and computing world coordinates directly
- using `CustomRenderTexture` and computing world coordinates by vertex map output in advance

# Requirement

- Unity2019

# Usage

Click the play button in unity editor.

Paint a target object by mouse clicks

# Note

I tested an environment under windows only.
