%% SAR-004 — Contact loss interrupts assistance
% Controlled scenario:
% - Moving MOB.
% - No GNSS noise or GNSS outage.
% - Contact outage scheduled during assistance.

%% 1. Prepare the baseline scenario
run('init_USV.m');

pruebaContacto = create_gnss_test_input;

pruebaContacto = pruebaContacto.setVariable( ...
    'sar_drift_factor', 0.8);

pruebaContacto = pruebaContacto.setVariable( ...
    'mob_contact_loss_enabled', false);

pruebaContacto = pruebaContacto.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '600', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

%% 2. Find the baseline assistance start time
resultadoBase = sim(pruebaContacto);

estadoBase = resultadoBase.logsout.getElement('mission_status');

assert(~isempty(estadoBase), ...
    'FAIL: missing baseline mission_status.');

estadoBase = estadoBase.Values;

iAsistencia = find( ...
    double(estadoBase.Data(:)) == 2, 1, 'first');

assert(~isempty(iAsistencia), ...
    'FAIL: baseline scenario did not reach assistance.');

tAsistencia = estadoBase.Time(iAsistencia);

%% 3. Schedule a ten-second contact outage during assistance
tPerdida = tAsistencia + 10;
tRecuperacion = tPerdida + 10;

pruebaPerdidaContacto = pruebaContacto.setVariable( ...
    'mob_contact_loss_enabled', true);

pruebaPerdidaContacto = pruebaPerdidaContacto.setVariable( ...
    'mob_contact_loss_start', tPerdida);

pruebaPerdidaContacto = pruebaPerdidaContacto.setVariable( ...
    'mob_contact_loss_end', tRecuperacion);

resultadoContacto = sim(pruebaPerdidaContacto);

%% 4. Retrieve logged signals
estado = resultadoContacto.logsout.getElement('mission_status');
contacto = resultadoContacto.logsout.getElement('contact_valid');

assert(~isempty(estado) && ~isempty(contacto), ...
    'FAIL: missing mission_status or contact_valid.');

estado = estado.Values;
contacto = contacto.Values;

t = estado.Time(:);
s = double(estado.Data(:));

tc = contacto.Time(:);
vc = logical(contacto.Data(:));

%% 5. Confirm assistance immediately before the scheduled outage
antesPerdida = t >= tPerdida - 1 & t < tPerdida;

assert(any(antesPerdida), ...
    'FAIL: no mission samples before the outage.');

assert(all(s(antesPerdida) == 2), ...
    'FAIL: outage did not start during established assistance.');

%% 6. Confirm contact loss inside the scheduled interval
% Exclude transition boundaries from this first interval check.
interior = tc >= tPerdida + 0.2 & ...
           tc <= tRecuperacion - 0.2;

assert(any(interior), ...
    'FAIL: no contact samples inside the outage.');

assert(all(~vc(interior)), ...
    'FAIL: contact remained valid during the outage.');

%% 7. Confirm assistance is inhibited during contact loss
durantePerdida = t >= tPerdida + 0.2 & ...
                 t <= tRecuperacion - 0.2;

assert(any(durantePerdida), ...
    'FAIL: no mission samples inside the outage.');

assert(all(s(durantePerdida) ~= 2), ...
    'FAIL: assistance remained active during contact loss.');

%% 8. Confirm assistance resumes after contact recovery
iReanudacion = find( ...
    t >= tRecuperacion & s == 2, 1, 'first');

assert(~isempty(iReanudacion), ...
    'FAIL: assistance did not resume after the outage.');

%% 9. Display state transitions and results
cambios = [true; diff(s) ~= 0];

disp(table(t(cambios), s(cambios), ...
    'VariableNames', {'Time_s', 'Mission_status'}));

fprintf('Contact outage: %.3f–%.3f s\n', ...
    tPerdida, tRecuperacion);

fprintf('Assistance resumed: %.3f s\n', t(iReanudacion));

fprintf('SAR-004 | contact loss inhibits assistance | PASS\n');
fprintf('SAR-004 | assistance resumes after outage | PASS\n');

%% 10. Check tracking and guidance during contact loss
% Reuse the simulation performed above.

reference = resultadoContacto.logsout.getElement('track_valid').Values;
tTracking = reference.Time(:);

names = {'track_valid', 'guidance_valid', ...
    'arrival_valid', 'arrived', 'nav_valid'};

tracking = struct();

for k = 1:numel(names)
    name = names{k};
    signal = resultadoContacto.logsout.getElement(name).Values;

    [time, indices] = unique(signal.Time(:), 'last');
    values = double(signal.Data(:));

    tracking.(name) = interp1( ...
        time, values(indices), tTracking, 'previous', NaN);
end

% Avoid transition boundaries in these interval checks.
margin = 2 * mob_track_sample_time;

predictionWindow = ...
    tTracking >= tPerdida + margin & ...
    tTracking <= tPerdida + mob_track_max_age - margin;

expiredWindow = ...
    tTracking >= tPerdida + mob_track_max_age + margin & ...
    tTracking <= tRecuperacion - margin;

outageWindow = ...
    tTracking >= tPerdida + margin & ...
    tTracking <= tRecuperacion - margin;

assert(any(predictionWindow) && any(expiredWindow), ...
    'FAIL: insufficient samples to check tracking expiry.');

assert(all(tracking.nav_valid(outageWindow) == 1), ...
    'FAIL: own-navigation loss confounds this contact-loss test.');

assert(all(tracking.track_valid(predictionWindow) == 1) && ...
    all(tracking.guidance_valid(predictionWindow) == 1), ...
    'FAIL: predictive guidance was unavailable before expiry.');

assert(all(tracking.track_valid(expiredWindow) == 0) && ...
    all(tracking.guidance_valid(expiredWindow) == 0), ...
    'FAIL: tracking or guidance remained valid after expiry.');

fprintf('MOB tracking | prediction and expiry gates | PASS\n');

%% 11. Arrival must remain inhibited throughout contact loss
assert(all(tracking.arrival_valid(outageWindow) == 0) && ...
    all(tracking.arrived(outageWindow) == 0), ...
    'FAIL: arrival remained permitted or confirmed without contact.');

fprintf('SAR-004 | arrival reset during contact loss | PASS\n');

%% 12. Arrival must be confirmed again after recovery
iArrival = find( ...
    tTracking >= tRecuperacion & tracking.arrived == 1, ...
    1, 'first');

assert(~isempty(iArrival), ...
    'FAIL: arrival was not confirmed after contact recovery.');

tArrival = tTracking(iArrival);

assert(tArrival >= ...
    tRecuperacion + arrival_dwell_time - mob_track_sample_time, ...
    'FAIL: arrival resumed before a new settling period elapsed.');

fprintf('SAR-004 | arrival reconfirmed after %.3f s | PASS\n', ...
    tArrival - tRecuperacion);