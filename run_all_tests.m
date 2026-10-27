%% FARO — Tests on the current GNSS model
% Integration scenarios use zero GNSS noise and no GNSS outage.
% The MOB sensor-noise test explicitly enables noisy MOB observations.
% Navigation and MOB estimation remain active.


setup_FARO;

fprintf('\n=== FARO: search tests ===\n\n');

test_search_pattern;
test_search_configuration;
test_search_coverage;
fprintf('\n=== GNSS model: battery and safety ===\n\n');

run('test_energy_requirements.m');

fprintf('\n=== GNSS model: manual cancellation ===\n\n');

run('test_manual_cancellation.m');

fprintf('\n=== GNSS model: return persistence ===\n\n');

run('test_return_persistence.m');

fprintf('\n=== GNSS model: home arrival ===\n\n');

run('test_home_arrival.m');

fprintf('\n=== GNSS model: MOB contact loss ===\n\n');

run('test_contact_loss.m');

fprintf('\n=== GNSS model: noisy MOB observations ===\n\n');

run('test_mob_sensor_noise.m');

fprintf('\n=== GNSS model: return with expired MOB tracking ===\n\n');

run('test_return_without_mob_track.m');

fprintf('\n=== GNSS model: MOB drift change ===\n\n');

run('test_mob_drift_change.m');

fprintf('\n========================================\n');
fprintf('All integrated tests passed.\n');
fprintf('Simulation model tested: USV_SAR_GNSS.\n');
fprintf('GNSS noise: zero. GNSS outages: disabled.\n');
fprintf('Navigation estimator: active.\n');
fprintf('MOB observations: ideal and fixed-seed noisy scenarios.\n');
fprintf('========================================\n');