% Adaptive Modulation - Part A: BER vs SNR for BPSK, QPSK, and 16-QAM
% Objective is to generate BER vs SNR curves for three modulation schemes over AWGN

clear; clc; close all;

% Simulation parameters
SNR_dB = 0:2:25;           % SNR range in dB
N_bits = 1e5;              % Number of bits per SNR point
bitrate = 1e6;             % 1 Mbps nominal rate

% Pre-allocate results
ber_bpsk = zeros(size(SNR_dB));
ber_qpsk = zeros(size(SNR_dB));
ber_16qam = zeros(size(SNR_dB));

%%  BPSK 
disp('Simulating BPSK...');
for i = 1:length(SNR_dB)
    bits = randi([0 1], N_bits, 1);
    % Mapping: 0 -> -1, 1 -> +1
    symbols = 2*bits - 1;
    
    % Adding AWGN noise
    snr = SNR_dB(i);
    rx = awgn(symbols, snr, 'measured');
    
    % Demodulating
    bits_hat = rx > 0;
    
    % Computing BER
    ber_bpsk(i) = sum(bits ~= bits_hat) / N_bits;
end

%%  QPSK 
disp('Simulating QPSK...');
M_qpsk = 4;  % modulation order
k_qpsk = log2(M_qpsk);
for i = 1:length(SNR_dB)
    bits = randi([0 1], N_bits, 1);
    % Grouping bits into symbols
    bits_reshaped = reshape(bits, k_qpsk, []).';
    
    % Gray mapping: 00->1+1j, 01->-1+1j, 11->-1-1j, 10->1-1j
    mapping = [1+1j; -1+1j; -1-1j; 1-1j]/sqrt(2);
    idx = bi2de(bits_reshaped, 'left-msb') + 1;
    symbols = mapping(idx);
    
    % Adding noise
    rx = awgn(symbols, SNR_dB(i), 'measured');
    
    % Demodulating (minimum distance)
    dist = abs(rx - mapping.').^2;
    [~, dec_idx] = min(dist, [], 2);
    bits_hat = de2bi(dec_idx-1, k_qpsk, 'left-msb');
    bits_hat = bits_hat(:);
    
    ber_qpsk(i) = sum(bits ~= bits_hat) / N_bits;
end

%%  16-QAM 
disp('Simulating 16-QAM...');
M_16qam = 16;
k_16qam = log2(M_16qam);
for i = 1:length(SNR_dB)
    bits = randi([0 1], N_bits, 1);
    bits_reshaped = reshape(bits, k_16qam, []).';
    
    % Use built-in modulation (Gray-coded)
    tx = qammod(bi2de(bits_reshaped, 'left-msb'), M_16qam, 'gray', 'UnitAveragePower', true);
    rx = awgn(tx, SNR_dB(i), 'measured');
    rx_bits = de2bi(qamdemod(rx, M_16qam, 'gray', 'UnitAveragePower', true), k_16qam, 'left-msb');
    bits_hat = rx_bits(:);
    
    ber_16qam(i) = sum(bits ~= bits_hat) / N_bits;
end

%%  Plot Results 
figure;
semilogy(SNR_dB, ber_bpsk, 'o-', 'LineWidth', 1.5); hold on;
semilogy(SNR_dB, ber_qpsk, 's-', 'LineWidth', 1.5);
semilogy(SNR_dB, ber_16qam, '^-', 'LineWidth', 1.5);
grid on; xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
legend('BPSK','QPSK','16-QAM','Location','southwest');
title('BER vs SNR for Different Modulation Schemes over AWGN');
