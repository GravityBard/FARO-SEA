%% FARO — Search coverage analysis
init_USV;

% Run the normal scenario, retaining configured GNSS noise and outages.
simulation_input = Simulink.SimulationInput('USV_SAR_GNSS');
simulation_input = simulation_input.setModelParameter( ...
    'StartTime', '0', 'StopTime', '600', 'MaxStep', '0.1', ...
    'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

simOut = sim(simulation_input);

%% Retrieve required signals
x_signal = simOut.logsout.getElement('usv_x');
y_signal = simOut.logsout.getElement('usv_y');
status_signal = simOut.logsout.getElement('mission_status');

assert(~isempty(x_signal) && ~isempty(y_signal) && ...
    ~isempty(status_signal), ...
    'Missing position or mission status signals.');

%% Remove duplicate timestamps, keeping the last value
[tx, ix] = unique(x_signal.Values.Time(:), 'last');
[ty, iy] = unique(y_signal.Values.Time(:), 'last');
[ts, is] = unique(status_signal.Values.Time(:), 'last');

x = double(x_signal.Values.Data(:));
y = double(y_signal.Values.Data(:));
status = double(status_signal.Values.Data(:));

x = x(ix);
y = y(iy);
status = status(is);

assert(numel(tx) >= 2 && numel(ty) >= 2 && numel(ts) >= 2, ...
    'Insufficient signal timestamps.');

%% Align signals at recorded X-position timestamps
% Restrict evaluation to the common recorded time interval.
valid_time = tx >= max([tx(1), ty(1), ts(1)]) & ...
    tx <= min([tx(end), ty(end), ts(end)]);

t = tx(valid_time);
x = x(valid_time);

y_aligned = interp1(ty, y, t, 'linear');
status_aligned = interp1(ts, status, t, 'previous');

assert(all(isfinite(x)) && all(isfinite(y_aligned)) && ...
    all(isfinite(status_aligned)), ...
    'Invalid aligned signal values.');

%% Keep only the Searching mission state
searching = (status_aligned == 0);

assert(any(searching), ...
    'No recorded positions during Searching.');

search_positions = [x(searching), y_aligned(searching)];

%% Calculate coverage
coverage_grid_spacing = 1; % Maximum grid spacing [m]

[coverage_percent, covered, grid_x, grid_y] = ...
    compute_search_coverage( ...
    search_positions, ...
    search_x_min, search_x_max, ...
    search_y_min, search_y_max, ...
    sar_detection_range, coverage_grid_spacing);

fprintf('\nSearch coverage: %.2f %%\n', coverage_percent);
fprintf('Covered grid points: %d / %d\n', ...
    nnz(covered), numel(covered));
fprintf('Recorded search positions: %d\n', ...
    size(search_positions, 1));

%% Plot estimated search coverage
figure;

h_pending = scatter( ...
    grid_x(~covered), grid_y(~covered), ...
    25, [0.8 0.3 0.3], 'filled');

hold on;

h_covered = scatter( ...
    grid_x(covered), grid_y(covered), ...
    25, [0.3 0.7 0.4], 'filled');

h_track = plot( ...
    search_positions(:,1), search_positions(:,2), ...
    'k.', 'MarkerSize', 3);

h_pattern = plot( ...
    waypoints(:,1), waypoints(:,2), ...
    'b--', 'LineWidth', 1);

rectangle('Position', ...
    [search_x_min, search_y_min, ...
    search_x_max-search_x_min, search_y_max-search_y_min]);

axis equal;
grid on;
xlabel('X [m]');
ylabel('Y [m]');
title(sprintf('Search coverage: %.2f %%', coverage_percent));

legend([h_pending, h_covered, h_track, h_pattern], ...
    {'Not covered', 'Covered', 'Recorded search positions', ...
    'Planned search pattern'}, ...
    'Location', 'bestoutside');

hold off;