%% SAFE-001: return persists after cancellation is removed
% Prepare this test independently.
run('init_USV.m');

pruebaPulso = create_gnss_test_input;

pruebaPulso = pruebaPulso.setVariable('battery_initial_soc', 1);
pruebaPulso = pruebaPulso.setVariable('battery_return_soc', 0.25);

pruebaPulso = pruebaPulso.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '20', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

% Activate cancellation at 10 seconds.
bloqueCancelacion = ...
    'USV_SAR_GNSS/Operator_Commands/Step';

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueCancelacion, 'Time', '10');

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueCancelacion, 'InitialValue', '0');

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueCancelacion, 'FinalValue', '1');

bloqueRetirada = ...
    'USV_SAR_GNSS/Operator_Commands/Cancel_Release_Step';

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueRetirada, 'Time', '11');

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueRetirada, 'InitialValue', '0');

pruebaPulso = pruebaPulso.setBlockParameter( ...
    bloqueRetirada, 'FinalValue', '1');

resultadoPulso = sim(pruebaPulso);

% Recuperar señales.
abort = resultadoPulso.logsout.getElement('abort_mission');
alarm = resultadoPulso.logsout.getElement('battery_low');
status = resultadoPulso.logsout.getElement('mission_status');
home = resultadoPulso.logsout.getElement('return_home');
reason = resultadoPulso.logsout.getElement('return_reason');

assert(~isempty(abort) && ~isempty(alarm) ...
    && ~isempty(status) && ~isempty(home) && ~isempty(reason), ...
    'FAIL: faltan señales registradas.');

% Confirmar que el comando fue un pulso.
tAbort = abort.Values.Time(:);
comando = logical(abort.Values.Data(:));

durantePulso = tAbort >= 10.2 & tAbort <= 10.8;
despuesPulso = tAbort >= 11.2;

assert(any(durantePulso) && any(despuesPulso), ...
    'FAIL: faltan muestras para comprobar el pulso.');

assert(~comando(1) && all(comando(durantePulso)) ...
    && all(~comando(despuesPulso)), ...
    'FAIL: el comando no se activó y retiró como se esperaba.');

assert(~any(logical(alarm.Values.Data(:))), ...
    'FAIL: batería baja puede estar manteniendo el regreso.');

% Comprobar el comportamiento después de retirar la orden.
estado = double(status.Values.Data(:));
ordenRegreso = logical(home.Values.Data(:));
motivo = double(reason.Values.Data(:));

iEstado = status.Values.Time(:) >= 11.2;
iHome = home.Values.Time(:) >= 11.2;
iMotivo = reason.Values.Time(:) >= 11.2;

assert(any(iEstado) && any(iHome) && any(iMotivo), ...
    'FAIL: faltan datos posteriores a la retirada.');

assert(all(estado(iEstado) == 4 | estado(iEstado) == 5), ...
    'FAIL: la misión abandonó el regreso o el estado de llegada.');

assert(all(ordenRegreso(iHome)), ...
    'FAIL: return_home se desactivó al retirar el comando.');

assert(all(motivo(iMotivo) == 3), ...
    'FAIL: se perdió el motivo de cancelación manual.');

fprintf('SAFE-001 | pulso 10-11 s | regreso persistente | PASS\n');