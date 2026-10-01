# Present-timing revalidation

Status: **experiment only — no behavior change yet**

## Why re-test this now

LatencyFleX documents that it cannot improve VSync-on latency because it lacks presentation timing.

The current implementation confirms the old limitation:

- `lfx_QueuePresentKHR()` inserts an empty submit and a fence;
- `FenceWaitThread` timestamps when that fence completes;
- that timestamp is passed to `LatencyFleX::EndFrame()`;
- `EndFrame()` therefore learns GPU/completion timing, not actual display presentation.

Modern Linux Vulkan now has `VK_EXT_present_timing` support on current NVIDIA drivers and recent Mesa WSI, so the missing signal should be re-evaluated.

## Question 1 — is the extension usable on the target stack?

Run:

```sh
bash experiments/present-timing/capture-env.sh
```

Required before proceeding:

- `VK_EXT_present_timing` exposed;
- a present stage / time domain suitable for actual presentation;
- stable present IDs;
- timing results correlate with the compositor/display path.

## Question 2 — how wrong is fence completion as a display proxy?

Use a deterministic Vulkan workload and record per frame:

```text
frame_begin
fence_complete        <- current LatencyFleX EndFrame signal
present_requested
actual_present        <- VK_EXT_present_timing
external_display      <- optional photodiode/camera
```

Compute:

```text
fence_to_present = actual_present - fence_complete
input_age_fence  = fence_complete - frame_begin
input_age_actual = actual_present - frame_begin
```

Run with:

- VSync off
- FIFO VSync on
- VRR where available
- 60 / 120 / 144+ Hz where available

## Question 3 — can actual-present feedback stabilize pacing?

Offline first.

Feed recorded actual-present timestamps into a copy of the LatencyFleX controller and compare against the existing fence-completion stream.

Score:

- information-age p50 / p95 / p99
- present-error p50 / p95 / p99
- deadline misses
- oscillation
- recovery after injected GPU spikes

## A/B states

1. LFX disabled
2. `LFX_PLACEBO=1`
3. current LFX
4. offline replay using actual-present feedback

Only after (4) dominates current behavior should we prototype a present-timing-backed implementation.

## Important separation

Do not equate lower frame-time jitter with lower latency.

The experiment is successful if it tells us whether actual presentation timing materially improves the controller's estimate of when a frame becomes visible.

## Related work

- LatencyFleX README: current VSync limitation
- Mesa 26.1/26.2: `VK_EXT_present_timing` WSI work
- NVIDIA Linux 595+: `VK_EXT_present_timing`
- NVIDIA 615: `VK_NV_low_latency` revision 2 and Wayland/direct-display low-latency fixes
