%% MOB tracking — response to a drift-factor change
% Controlled scenario:
% - Ideal own-ship GNSS.
% - No artificial MOB contact outage.
% - Noisy MOB position observations.
% - Drift factor changes from 0.8 to 1.2 at 240 s.
%
% Real separation is reported, without a pass/fail distance limit.

run('init_USV.m');

changeTime = 240;
initialFactor = 0.8;
finalFactor = 1.2;

assert(changeTime - 10 > current_change_time, ...
    'The evaluation window must follow the current reversal.');

%% 1. Prepare the scenario
trial = create_gnss_test_input;

trial = trial.setVariable('battery_initial_soc', 1);
trial = trial.setVariable('sar_drift_factor', initialFactor);
trial = trial.setVariable('mob_position_sigma', 0.2);
trial = trial.setVariable('mob_track_alpha', 0.4);
trial = trial.setVariable('mob_track_beta', 0.008);

trial = trial.setVariable('mob_contact_loss_enabled', false);

trial = trial.setVariable('mob_drift_change_enabled', true);
trial = trial.setVariable('mob_drift_change_time', changeTime);
trial = trial.setVariable('mob_drift_factor_after', finalFactor);

trial = trial.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '600', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

result = sim(trial);

%% 2. Align physical signals around the change
tCheck = (changeTime - 10:0.1:changeTime + 50)';

names = {'usv_x', 'usv_y', ...
         'x_mob_true', 'y_mob_true', ...
         'vx_mob_true', 'vy_mob_true'};

s = struct();

for k = 1:numel(names)
    name = names{k};
    signal = result.logsout.getElement(name).Values;

    [time, indices] = unique(signal.Time(:), 'last');
    values = double(signal.Data(:));

    % Positions are continuous; true velocities contain a step.
    method = 'linear';

    if ismember(name, {'vx_mob_true', 'vy_mob_true'})
        method = 'previous';
    end

    s.(name) = interp1( ...
        time, values(indices), tCheck, method, NaN);

    assert(all(isfinite(s.(name))), ...
        'FAIL: missing or invalid data for %s.', name);
end

%% 3. Verify the physical velocity change
before = tCheck >= changeTime - 1 & ...
         tCheck <= changeTime - 0.2;

after = tCheck >= changeTime + 0.2 & ...
        tCheck <= changeTime + 1;

expectedBefore = initialFactor * ...
    [current_x_after, current_y_after];

expectedAfter = finalFactor * ...
    [current_x_after, current_y_after];

errorBefore = hypot( ...
    s.vx_mob_true(before) - expectedBefore(1), ...
    s.vy_mob_true(before) - expectedBefore(2));

errorAfter = hypot( ...
    s.vx_mob_true(after) - expectedAfter(1), ...
    s.vy_mob_true(after) - expectedAfter(2));

assert(any(before) && any(after), ...
    'FAIL: insufficient samples around the drift change.');

assert(norm(expectedAfter - expectedBefore) > 0, ...
    'FAIL: configuration produces no velocity change.');

assert(all(errorBefore < 1e-8) && all(errorAfter < 1e-8), ...
    'FAIL: physical MOB velocity does not match the drift factors.');

fprintf('MOB drift | physical velocity change applied | PASS\n');

%% 4. Verify accompaniment before the change and subsequent recovery
status = result.logsout.getElement('mission_status').Values;

t = status.Time(:);
states = double(status.Data(:));

beforeChange = t >= changeTime - 1 & t < changeTime;

assert(any(beforeChange), ...
    'FAIL: no mission samples before the change.');

assert(all(states(beforeChange) == 2), ...
    'FAIL: accompaniment was not established before the change.');

% An interruption is permitted, but is not required.
iExit = find(t >= changeTime & states == 1, 1, 'first');

if ~isempty(iExit)
    iResume = find( ...
        t > t(iExit) & states == 2, 1, 'first');

    assert(~isempty(iResume), ...
        'FAIL: accompaniment was interrupted and never resumed.');

    fprintf('Accompaniment interrupted: %.3f s\n', t(iExit));
    fprintf('Accompaniment resumed: %.3f s\n', t(iResume));
else
    fprintf('No transition to approach after the drift change.\n');
end

%% 5. Verify final mission outcome
reason = result.logsout.getElement('return_reason').Values;
completed = result.logsout.getElement('mission_completed').Values;

assert(any(states == 4) && states(end) == 5, ...
    'FAIL: mission did not return and finish at home.');

assert(double(reason.Data(end)) == 1, ...
    'FAIL: return was not caused by completed accompaniment.');

assert(logical(completed.Data(end)), ...
    'FAIL: mission_completed is not active.');

fprintf('MOB drift | accompaniment and mission completion | PASS\n');

%% 6. Report actual separation — informational metric
realDistance = hypot( ...
    s.usv_x - s.x_mob_true, ...
    s.usv_y - s.y_mob_true);

evaluationWindow = tCheck >= changeTime & ...
                   tCheck <= changeTime + 40;

[maxDistance, index] = max(realDistance(evaluationWindow));
evaluationTimes = tCheck(evaluationWindow);

fprintf('Maximum real separation, %.0f–%.0f s: %.4f m\n', ...
    changeTime, changeTime + 40, maxDistance);

fprintf('Time of maximum separation: %.3f s\n', ...
    evaluationTimes(index));

fprintf('Separation is informational; no acceptance limit is applied.\n');