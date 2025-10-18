clc; clear; close all;

%Parameters 
numSymbols = 2000;                % total symbol intervals
snr_t = 12.5 + 12.5*sin(2*pi*(1:numSymbols)/500);  % slow SNR variation (0–25 dB)
R_nominal = 1e6;                  % nominal bitrate 1 Mbps

% Thresholds from Part B 
th_QPSK = 7;
th_16QAM = 18;

% Containers for metrics 
instantaneous_BER = zeros(1, numSymbols);
throughput = zeros(1, numSymbols);
mod_mode = strings(1, numSymbols);

% Main simulation loop
for i = 1:numSymbols
    thisSNR = snr_t(i);

    % Choosing modulation based on instantaneous SNR 
    if thisSNR < th_QPSK
        M = 2;  mode = 'BPSK';
    elseif thisSNR < th_16QAM
        M = 4;  mode = 'QPSK';
    else
        M = 16; mode = '16QAM';
    end
    mod_mode(i) = mode;

    % Generating random bits & symbols 
    k = log2(M);
    bits = randi([0 1], 1, 1000*k);           % random bits
    dataSymbols = qammod(bi2de(reshape(bits,k,[]).'), M, 'InputType','integer','UnitAveragePower',true);

    % Passing through AWGN channel 
    rx = awgn(dataSymbols, thisSNR, 'measured');

    % Demodulating and calculate BER
    rxBits = de2bi(qamdemod(rx, M, 'OutputType','integer','UnitAveragePower',true), k).';
    rxBits = rxBits(:).';
    [~, ber] = biterr(bits, rxBits);
    instantaneous_BER(i) = ber;

    % Throughput calculation 
    throughput(i) = R_nominal * k * (1 - ber);
end

% Computing average performance
avg_BER = mean(instantaneous_BER);
avg_Throughput = mean(throughput);

% --- Plots ---
figure;
plot(instantaneous_BER,'LineWidth',1.5);
xlabel('Time index'); ylabel('Instantaneous BER');
title('Instantaneous BER vs Time');
grid on;
saveas(gcf,'ber_vs_time.png');

figure;
plot(snr_t, throughput/1e6, 'b','LineWidth',1.5); hold on;

% Baseline QPSK throughput
M_QPSK = 4;
ber_qpsk = berawgn(snr_t,'psk',M_QPSK,'nondiff');
throughput_qpsk = R_nominal * log2(M_QPSK) * (1 - ber_qpsk);
plot(snr_t, throughput_qpsk/1e6,'r--','LineWidth',1.5);

xlabel('SNR (dB)');
ylabel('Throughput (Mbps)');
legend('Adaptive','Fixed QPSK');
title('Throughput vs Average SNR');
grid on;
saveas(gcf,'throughput_vs_snr.png');

%% Summary Table
schemes = {'BPSK','QPSK','16QAM','Adaptive'};
avgBERs = [mean(berawgn(snr_t,'psk',2,'nondiff')), ...
           mean(ber_qpsk), ...
           mean(berawgn(snr_t,'qam',16)), ...
           avg_BER];
avgThroughputs = [R_nominal*1*(1-avgBERs(1)), ...
                  R_nominal*2*(1-avgBERs(2)), ...
                  R_nominal*4*(1-avgBERs(3)), ...
                  avg_Throughput];
summaryTable = table(schemes', avgBERs', avgThroughputs'/1e6, ...
                     'VariableNames', {'Scheme','Average_BER','Average_Throughput_Mbps'});
writetable(summaryTable,'summary_table.csv');
disp(summaryTable);
