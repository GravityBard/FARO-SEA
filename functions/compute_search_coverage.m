function [coverage_percent, covered, grid_x, grid_y] = ...
    compute_search_coverage(positions, ...
    x_min, x_max, y_min, y_max, detection_range, grid_spacing)
% COMPUTE_SEARCH_COVERAGE Estimate coverage from recorded search positions.
% positions: N-by-2 matrix of true USV coordinates during Searching.
% covered: logical mask indicating which grid points were covered.

%% Validate inputs
validateattributes(positions, {'numeric'}, ...
    {'2d','ncols',2,'real','finite'});

validateattributes(x_min, {'numeric'}, ...
    {'scalar','real','finite'});
validateattributes(x_max, {'numeric'}, ...
    {'scalar','real','finite','>',x_min});

validateattributes(y_min, {'numeric'}, ...
    {'scalar','real','finite'});
validateattributes(y_max, {'numeric'}, ...
    {'scalar','real','finite','>',y_min});

validateattributes(detection_range, {'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(grid_spacing, {'numeric'}, ...
    {'scalar','real','finite','positive'});

%% Build a uniform grid including the area boundaries
num_x_intervals = ceil((x_max - x_min) / grid_spacing);
num_y_intervals = ceil((y_max - y_min) / grid_spacing);

x_levels = linspace(x_min, x_max, num_x_intervals + 1);
y_levels = linspace(y_min, y_max, num_y_intervals + 1);

[grid_x, grid_y] = meshgrid(x_levels, y_levels);

%% Mark points within detection range of any recorded position
covered = false(size(grid_x));

for k = 1:size(positions, 1)
    distance_squared = ...
        (grid_x - positions(k,1)).^2 + ...
        (grid_y - positions(k,2)).^2;

    covered = covered | ...
        (distance_squared <= detection_range^2);
end

%% Percentage of grid points covered
coverage_percent = 100 * nnz(covered) / numel(covered);

end