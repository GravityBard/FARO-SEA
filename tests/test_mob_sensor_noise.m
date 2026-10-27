%% MOB tracking with noisy observations and contact loss
% Controlled scenario:
% - Ideal own-ship GNSS.
% - Moving MOB.
% - Position noise: 0.2 m standard deviation per axis.
% - Fixed random seeds configured in the sensor blocks.
% - Contact outage between 260 and 270 seconds.

run('init_USV.m');

trial = create_gnss_test_input;

trial = trial.setVariable('sar_drift_factor', 0.8);
trial = trial.setVariable('mob_position_sigma', 0.2);
trial = trial.setVariable('mob_track_alpha', 0.4);
trial = trial.setVariable('mob_track_beta', 0.008);

trial = trial.setVariable('mob_contact_loss_enabled', true);
trial = trial.setVariable('mob_contact_loss_start', 260);
trial = trial.setVariable('mob_contact_loss_end', 270);

trial = trial.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '600', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

result = sim(trial);

%% 1. Check mission interruption and recovery
status = result.logsout.getElement('mission_status').Values;

t = status.Time(:);
states = double(status.Data(:));

beforeLoss = t >= 259 & t < 260;
duringLoss = t >= 260.2 & t <= 269.8;

assert(any(beforeLoss) && any(duringLoss), ...
    'FAIL: insufficient mission samples.');

assert(all(states(beforeLoss) == 2), ...
    'FAIL: accompaniment was not established before the outage.');

assert(all(states(duringLoss) ~= 2), ...
    'FAIL: accompaniment remained active during the outage.');

iResume = find(t >= 270 & states == 2, 1, 'first');

assert(~isempty(iResume), ...
    'FAIL: accompaniment did not resume.');

assert(t(iResume) >= 270 + arrival_dwell_time - 0.1, ...
    'FAIL: accompaniment resumed before a new settling period.');

fprintf('MOB noise | interruption and recovery | PASS\n');

%% 2. Compare measured and estimated positions before the outage
% Evaluate both at identical timestamps during steady target motion.
tCompare = (220:0.1:250)';

names = {'x_mob_true', 'y_mob_true', ...
         'x_mob_meas', 'y_mob_meas', ...
         'x_mob_est', 'y_mob_est', ...
         'contact_valid', 'track_valid'};

s = struct();

for k = 1:numel(names)
    name = names{k};
    signal = result.logsout.getElement(name).Values;

    [time, indices] = unique(signal.Time(:), 'last');
    values = double(signal.Data(:));

    method = 'previous';

    if ismember(name, {'x_mob_true', 'y_mob_true'})
        method = 'linear';
    end

    s.(name) = interp1( ...
        time, values(indices), tCompare, method, NaN);

    assert(all(isfinite(s.(name))), ...
        'FAIL: missing or invalid comparison data for %s.', name);
end

assert(all(s.contact_valid == 1 & s.track_valid == 1), ...
    'FAIL: comparison interval lacks valid contact or tracking.');

measurementError = hypot( ...
    s.x_mob_meas - s.x_mob_true, ...
    s.y_mob_meas - s.y_mob_true);

positionError = hypot( ...
    s.x_mob_est - s.x_mob_true, ...
    s.y_mob_est - s.y_mob_true);

measurementRMSE = sqrt(mean(measurementError.^2));
positionRMSE = sqrt(mean(positionError.^2));

assert(measurementRMSE > 0, ...
    'FAIL: observations contain no position error.');

assert(positionRMSE < measurementRMSE, ...
    'FAIL: estimation did not reduce position RMSE.');

fprintf(['MOB noise | measurement RMSE %.4f m | ' ...
         'estimate RMSE %.4f m | PASS\n'], ...
    measurementRMSE, positionRMSE);

%% 3. Check mission completion
reason = result.logsout.getElement('return_reason').Values;
completed = result.logsout.getElement('mission_completed').Values;

assert(any(states == 4) && states(end) == 5, ...
    'FAIL: mission did not return and finish at home.');

assert(double(reason.Data(end)) == 1, ...
    'FAIL: return was not caused by completed accompaniment.');

assert(logical(completed.Data(end)), ...
    'FAIL: mission_completed is not active.');

fprintf('MOB noise | mission completed and home reached | PASS\n');