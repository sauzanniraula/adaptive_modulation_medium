% Adaptive Modulation – Part B
% Task: Switch between BPSK / QPSK / 16-QAM depending on channel SNR

clear; clc; close all;

%% Parameters
N = 1200;                 % number of time intervals
t = (0:N-1)';             % time index

% slow varying SNR profile (simulates slow fading)
snr_mean = 12;            % average SNR (dB)
snr_amp  = 12;            % amplitude of variation
cycles   = 2;             % number of full sinusoidal cycles

% generate SNR(t)
snr_t = snr_mean + snr_amp * sin(2*pi*cycles*t/N);
snr_t = max(0, min(25, snr_t));    % limit SNR between 0 and 25 dB

%% Thresholds (from Part A BER curves) 
% around BER = 1e-3 switching points
th_QPSK   = 7;            % switch to QPSK above 7 dB
th_16QAM  = 18;           % switch to 16-QAM above 18 dB

mode_num  = zeros(N,1);   % numeric code (2,4,16)
mode_name = strings(N,1); % store modulation name (optional)

%%  Adaptive Modulation Controller 
for i = 1:N
    s = snr_t(i);
    
    if s < th_QPSK
        mode_num(i)  = 2;          % choose BPSK
        mode_name(i) = "BPSK";
    elseif s < th_16QAM
        mode_num(i)  = 4;          % choose QPSK
        mode_name(i) = "QPSK";
    else
        mode_num(i)  = 16;         % choose 16-QAM
        mode_name(i) = "16-QAM";
    end
end

%% Plot 1: SNR(t) over time 
figure(1);
plot(t, snr_t, 'LineWidth', 1.4);
xlabel('Time index');
ylabel('SNR (dB)');
title('SNR(t) – Slow Fading Channel');
grid on; ylim([0 26]);
saveas(gcf, 'snr_vs_time.png');

%% Plot 2: Selected Modulation Mode 
figure(2);
stairs(t, mode_num, 'LineWidth', 1.5);
xlabel('Time index');
ylabel('Selected Modulation');
yticks([2 4 16]);
yticklabels({'BPSK','QPSK','16-QAM'});
title('Selected Modulation vs Time');
grid on;
saveas(gcf, 'mode_vs_time.png');

%% Display basic info 
disp('Plots saved: snr_vs_time.png and mode_vs_time.png');
disp(['Thresholds used →  QPSK ≥ ' num2str(th_QPSK) ' dB,  16-QAM ≥ ' num2str(th_16QAM) ' dB']);
