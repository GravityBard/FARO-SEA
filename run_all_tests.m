%% FARO — Tests on the current GNSS model
% Integration scenarios use zero GNSS noise and no GNSS outage.
% Navigation estimation remains active.
% Execution stops if any assertion fails.

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

fprintf('\n========================================\n');
fprintf('All integrated tests passed.\n');
fprintf('Simulation model tested: USV_SAR_GNSS.\n');
fprintf('GNSS noise: zero. GNSS outages: disabled.\n');
fprintf('Navigation estimator: active.\n');
fprintf('========================================\n');