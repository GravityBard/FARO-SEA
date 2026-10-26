%% SAFE-001: manual cancellation with sufficient battery

%% 1. Prepare the simulation
run('init_USV.m');

bloqueCancelacion = ...
    'USV_SAR_GNSS/Operator_Commands/Step';

simIn = create_gnss_test_input;

simIn = simIn.setVariable('battery_initial_soc', 1);
simIn = simIn.setVariable('battery_return_soc', 0.25);

simIn = simIn.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '20', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

%% 2. Configure cancellation at 10 seconds
simIn = simIn.setBlockParameter( ...
    bloqueCancelacion, 'Time', '10');

simIn = simIn.setBlockParameter( ...
    bloqueCancelacion, 'InitialValue', '0');

simIn = simIn.setBlockParameter( ...
    bloqueCancelacion, 'FinalValue', '1');

%% 3. Run the simulation
resultadoCancelacion = sim(simIn);

%% 4. Retrieve logged signals
abort = resultadoCancelacion.logsout.getElement('abort_mission');
alarm = resultadoCancelacion.logsout.getElement('battery_low');
status = resultadoCancelacion.logsout.getElement('mission_status');
home = resultadoCancelacion.logsout.getElement('return_home');
reason = resultadoCancelacion.logsout.getElement('return_reason');

assert(~isempty(abort) && ~isempty(alarm) ...
    && ~isempty(status) && ~isempty(home) && ~isempty(reason), ...
    'FAIL: faltan señales registradas.');

%% 5. Check that low battery did not trigger the return
assert(~any(logical(alarm.Values.Data(:))), ...
    'FAIL: se activó batería baja durante la prueba.');

%% 6. Find cancellation and return times
iAbort = find(logical(abort.Values.Data(:)), 1, 'first');
iReturn = find(double(status.Values.Data(:)) == 4, 1, 'first');

assert(~isempty(iAbort) && ~isempty(iReturn), ...
    'FAIL: falta la cancelación o la entrada en regreso.');

tAbort = abort.Values.Time(iAbort);
tReturn = status.Values.Time(iReturn);

%% 7. Check response timing
assert(abs(tAbort - 10) <= 0.1, ...
    'FAIL: cancelación fuera del instante esperado.');

assert(tReturn >= tAbort - 1e-8 && tReturn <= tAbort + 0.2, ...
    'FAIL: respuesta al comando fuera del intervalo esperado.');

%% 8. Check return command and reason
iHome = find(home.Values.Time >= tAbort + 0.2, 1, 'first');
iReason = find(reason.Values.Time >= tAbort + 0.2, 1, 'first');

assert(~isempty(iHome) && ~isempty(iReason), ...
    'FAIL: faltan datos posteriores a la cancelación.');

assert(logical(home.Values.Data(iHome)), ...
    'FAIL: return_home no está activo.');

assert(double(reason.Values.Data(iReason)) == 3, ...
    'FAIL: return_reason no indica cancelación manual.');

%% 9. Report result
fprintf( ...
    'SAFE-001 | cancelación %.4f s | regreso %.4f s | PASS\n', ...
    tAbort, tReturn);

fprintf('Caso probado: cancelación manual con batería suficiente.\n');
fprintf('No comprueba llegada a base ni retirada del comando.\n');