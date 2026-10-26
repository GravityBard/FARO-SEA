function test_search_configuration
% TEST_SEARCH_CONFIGURATION Verify the SEARCH-002 spacing constraint.

% Case 1: spacing below the limit must be accepted.
limit = validate_search_configuration(6, 2, 7);

assert(limit == 8, ...
    'FAIL: incorrect spacing limit.');

fprintf('SEARCH-002 | below limit | PASS\n');

% Case 2: spacing exactly at the limit must be accepted.
limit = validate_search_configuration(6, 2, 8);

assert(limit == 8, ...
    'FAIL: incorrect spacing limit.');

fprintf('SEARCH-002 | at limit | PASS\n');

% Case 3: spacing above the limit must be rejected.
rejected = false;

try
    validate_search_configuration(6, 2, 8.1);
catch exception
    if strcmp(exception.identifier, 'FARO:SearchSpacingExceeded')
        rejected = true;
    else
        rethrow(exception);
    end
end

assert(rejected, ...
    'FAIL: spacing above the limit was accepted.');

fprintf('SEARCH-002 | above limit rejected | PASS\n');
% Case 4: zero tracking error allowance must be accepted.
limit = validate_search_configuration(6, 0, 12);

assert(limit == 12, ...
    'FAIL: incorrect spacing limit for zero allowance.');

fprintf('SEARCH-002 | zero allowance accepted | PASS\n');

% Cases 5–7: invalid tracking error allowances must be rejected.
invalid_allowances = [-1, 6, 7];

for k = 1:numel(invalid_allowances)
    allowance = invalid_allowances(k);
    rejected = false;

    try
        validate_search_configuration(6, allowance, 1);
    catch exception
        % Only accept the expected input-validation errors.
        expected_error = ...
            strcmp(exception.identifier, 'MATLAB:expectedNonnegative') || ...
            strcmp(exception.identifier, 'MATLAB:notLess');

        if expected_error
            rejected = true;
        else
            rethrow(exception);
        end
    end

    assert(rejected, ...
        'FAIL: invalid tracking error allowance was accepted.');

    fprintf('SEARCH-002 | allowance %.1f m rejected | PASS\n', ...
        allowance);
end
end