# FARO SEA

Autonomous maritime search-and-rescue USV simulation developed
with MATLAB, Simulink and Stateflow.

The current mission scope is to locate, signal the position of,
and accompany a person overboard (MOB). Physical rescue equipment
is outside the current scope.

## Implemented features

- Simplified planar vessel dynamics and speed/heading control.
- Current disturbances and a drifting MOB.
- Automatically generated rectangular search patterns.
- GNSS measurements with noise and scheduled outages.
- Alpha-beta estimation of USV position and velocity.
- Alpha-beta MOB tracking with bounded prediction during contact loss.
- Guidance inhibition when navigation or required tracking is invalid.
- Arrival confirmation using distance, relative speed and dwell time.
- Stateflow mission management.
- Simplified battery consumption and low-battery return.
- Manual cancellation with persistent return-home behavior.
- Requirements and implementation/verification traceability.

## Run a simulation

Set MATLAB's Current Folder to the repository root, then run:

```matlab
init_USV;
simOut = sim('USV_SAR_GNSS');
```

Active model:

```text
models/USV_SAR_GNSS.slx
```

## Run the automated checks

From the repository root:

```matlab
run_all_tests
```

The suite checks:

- Search-pattern geometry, spacing validation and sampled coverage.
- Low-battery threshold and return response.
- Manual cancellation and return persistence.
- Home arrival and mission-completion persistence.
- Contact-loss interruption and subsequent accompaniment recovery.
- MOB prediction availability, tracking expiry and guidance inhibition.
- Arrival reset and a new settling period after contact recovery.

The latest complete suite passed on 26 October 2026.

Integration tests use zero GNSS noise and disabled GNSS outages.
MOB observations are ideal. These results do not establish
performance under realistic sensing and environmental conditions.

## Project structure

- `models/`: Simulink models.
- `functions/`: reusable MATLAB functions.
- `tests/`: automated verification scripts and functions.
- `requirements/`: requirement set.
- `results/`: analysis outputs.
- `archive/`: historical models.
- `init_USV.m`: simulation parameters and initialization.
- `setup_FARO.m`: project-path configuration.
- `run_all_tests.m`: integrated test runner.
- `analyze_search_coverage.m`: offline search-coverage analysis.

Requirement-link files (`.slmx`) are stored alongside their
associated model or MATLAB source files.

## Software

- MATLAB
- Simulink
- Stateflow
- Requirements Toolbox for editing requirements and traceability

## Current limitations

- Educational vessel parameters; no calibration against a real USV.
- Simplified planar dynamics and energy consumption.
- Ideal range-based MOB detection and exact position observations.
- No radar returns, camera images or machine-learning detector.
- Scheduled current changes and sensor/contact outages.
- Simplified current estimation using simulated environmental truth.
- Some true vessel states remain available to control and arrival logic.
- The 60-second accompaniment duration is a simulation setting,
  not confirmation that a person has been rescued.
- No obstacle avoidance or hardware deployment validation.

## Next steps

- Evaluate tracking with noisy and sampled MOB observations.
- Test changes in target motion during contact loss.
- Extend verification of tracking and return-home interaction.
- Improve environmental and sensor realism incrementally.