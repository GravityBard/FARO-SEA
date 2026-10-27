%% Manual return with expired MOB tracking
run('init_USV.m');

%% Prepare a controlled moving-MOB scenario
trial = create_gnss_test_input;

trial = trial.setVariable('battery_initial_soc', 1);
trial = trial.setVariable('sar_drift_factor', 0.8);
trial = trial.setVariable('mob_position_sigma', 0);
trial = trial.setVariable('mob_contact_loss_enabled', false);

trial = trial.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '600', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

%% Locate accompaniment in the baseline simulation
baseline = sim(trial);

status = baseline.logsout.getElement('mission_status').Values;
iAssist = find(double(status.Data(:)) == 2, 1, 'first');

assert(~isempty(iAssist), ...
    'FAIL: baseline did not reach accompaniment.');

%% Lose contact, wait for expiry, then cancel
tLoss = status.Time(iAssist) + 10;
tRecovery = tLoss + mob_track_max_age + 5;
tCancel = tLoss + mob_track_max_age + 1;
tStop = tRecovery - 0.5;

trial = trial.setVariable('mob_contact_loss_enabled', true);
trial = trial.setVariable('mob_contact_loss_start', tLoss);
trial = trial.setVariable('mob_contact_loss_end', tRecovery);

cancelBlock = 'USV_SAR_GNSS/Operator_Commands/Step';

trial = trial.setBlockParameter( ...
    cancelBlock, 'Time', num2str(tCancel, 17));

trial = trial.setBlockParameter( ...
    cancelBlock, 'InitialValue', '0');

trial = trial.setBlockParameter( ...
    cancelBlock, 'FinalValue', '1');

trial = trial.setModelParameter( ...
    'StopTime', num2str(tStop, 17));

result = sim(trial);

%% Check conditions after the cancellation response
names = {'abort_mission', 'return_home', 'return_reason', ...
    'track_valid', 'guidance_valid', 'nav_valid', ...
    'contact_valid', 'battery_low'};

expected = [1, 1, 3, 0, 1, 1, 0, 0];

for k = 1:numel(names)
    signal = result.logsout.getElement(names{k}).Values;

    time = signal.Time(:);
    values = double(signal.Data(:));

    window = time >= tCancel + 0.2 & time <= tStop;

    assert(any(window), ...
        'FAIL: no verification samples for %s.', names{k});

    assert(all(values(window) == expected(k)), ...
        'FAIL: unexpected %s during return.', names{k});
end

%% Check that the mission entered return
status = result.logsout.getElement('mission_status').Values;

time = status.Time(:);
states = double(status.Data(:));
window = time >= tCancel + 0.2 & time <= tStop;

assert(any(window), ...
    'FAIL: no mission-state verification samples.');

assert(all(states(window) == 4 | states(window) == 5), ...
    'FAIL: mission did not remain in return or home-reached state.');

fprintf('SAR-005 | manual return with expired MOB tracking | PASS\n');
fprintf('Checks return permission; does not verify arrival home.\n');