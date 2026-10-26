function waypoints = generate_search_pattern( ...
    x_min, x_max, y_min, y_max, max_spacing)

% Validate the search area and maximum spacing.
validateattributes(x_min, {'numeric'}, {'scalar','real','finite'});
validateattributes(x_max, {'numeric'}, ...
    {'scalar','real','finite','>',x_min});

validateattributes(y_min, {'numeric'}, {'scalar','real','finite'});
validateattributes(y_max, {'numeric'}, ...
    {'scalar','real','finite','>',y_min});

validateattributes(max_spacing, {'numeric'}, ...
    {'scalar','real','finite','positive'});

% Calculate enough intervals to respect the maximum spacing.
num_intervals = ceil((y_max - y_min) / max_spacing);

% Include both boundaries of the search area.
y_levels = linspace(y_min, y_max, num_intervals + 1);

% Each horizontal pass has two endpoints.
waypoints = zeros(2 * numel(y_levels), 2);

for k = 1:numel(y_levels)
    row = 2*k - 1;

    if mod(k, 2) == 1
        waypoints(row, :)   = [x_min, y_levels(k)];
        waypoints(row+1, :) = [x_max, y_levels(k)];
    else
        waypoints(row, :)   = [x_max, y_levels(k)];
        waypoints(row+1, :) = [x_min, y_levels(k)];
    end
end

end