function test_search_coverage
% TEST_SEARCH_COVERAGE Check known coverage geometry.

%% Case 1: five of nine grid points are covered
[coverage, covered] = compute_search_coverage( ...
    [1, 1], 0, 2, 0, 2, 1, 1);

expected_mask = logical([ ...
    0 1 0;
    1 1 1;
    0 1 0]);

assert(isequal(covered, expected_mask), ...
    'FAIL: incorrect covered grid points.');

assert(abs(coverage - 100*5/9) < 1e-10, ...
    'FAIL: incorrect coverage percentage.');

fprintf('SEARCH-003 | known geometry | PASS\n');

%% Case 2: repeated positions must not increase coverage
[repeated_coverage, repeated_mask] = compute_search_coverage( ...
    [1, 1; 1, 1], 0, 2, 0, 2, 1, 1);

assert(isequal(repeated_mask, covered) && ...
    abs(repeated_coverage - coverage) < 1e-10, ...
    'FAIL: repeated positions changed coverage.');

fprintf('SEARCH-003 | repeated position | PASS\n');

end