function test_search_pattern

% Test configuration for SEARCH-001.
search_x_min = 20;
search_x_max = 60;
search_y_min = 20;
search_y_max = 50;
search_max_spacing = 8;

waypoints = generate_search_pattern( ...
    search_x_min, search_x_max, ...
    search_y_min, search_y_max, ...
    search_max_spacing);

% Check waypoint coordinates.
assert(all(isfinite(waypoints(:))), ...
    'FAIL: non-finite waypoint coordinates.');

assert(all(waypoints(:,1) >= search_x_min & ...
    waypoints(:,1) <= search_x_max), ...
    'FAIL: X coordinates outside the search area.');

assert(all(waypoints(:,2) >= search_y_min & ...
    waypoints(:,2) <= search_y_max), ...
    'FAIL: Y coordinates outside the search area.');

% Check horizontal passes and alternating direction.
starts = waypoints(1:2:end, :);
ends = waypoints(2:2:end, :);

assert(all(starts(:,2) == ends(:,2)), ...
    'FAIL: a search pass is not horizontal.');

expected_direction = (-1).^(0:size(starts,1)-1)';
assert(all(sign(ends(:,1) - starts(:,1)) == expected_direction), ...
    'FAIL: pass directions do not alternate.');

assert(all(min(starts(:,1), ends(:,1)) == search_x_min & ...
    max(starts(:,1), ends(:,1)) == search_x_max), ...
    'FAIL: a pass does not span the search area.');

% Check spacing and both Y boundaries.
spacing = diff(starts(:,2));
tolerance = 1e-9;

assert(all(spacing > 0 & ...
    spacing <= search_max_spacing + tolerance), ...
    'FAIL: invalid spacing between passes.');

assert(abs(starts(1,2) - search_y_min) <= tolerance && ...
    abs(starts(end,2) - search_y_max) <= tolerance, ...
    'FAIL: missing search area boundaries.');

fprintf('SEARCH-001 | geometry | %d passes | PASS\n', ...
    size(starts,1));

end