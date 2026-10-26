function spacing_limit = validate_search_configuration( ...
    detection_range, tracking_error_allowance, max_spacing)
% VALIDATE_SEARCH_CONFIGURATION Check the SEARCH-002 constraint.

% Validate detection range.
validateattributes(detection_range, {'numeric'}, ...
    {'scalar','real','finite','positive'});

% Validate the lateral tracking error allowance.
validateattributes(tracking_error_allowance, {'numeric'}, ...
    {'scalar','real','finite','nonnegative','<',detection_range});

% Validate maximum pass spacing.
validateattributes(max_spacing, {'numeric'}, ...
    {'scalar','real','finite','positive'});

% Calculate the allowed spacing limit [m].
spacing_limit = 2 * (detection_range - tracking_error_allowance);

% Reject configurations exceeding the limit.
assert(max_spacing <= spacing_limit, ...
    'FARO:SearchSpacingExceeded', ...
    'SEARCH-002: maximum pass spacing exceeds the allowed limit.');

end