% Group Members: Wong Jun-Shen 35135840 , Ryan Tan Yi Xing 34852409
% Date: 12/5/2026

clear; clc; close all;

%% Load frame trace data
happyCompressedVideoFrames = "films_happy_framesonly.txt";
tronCompressedVideoFrames = "tronlegacy_framesonly.txt";
compressedVid = [happyCompressedVideoFrames,tronCompressedVideoFrames];
for vid = 1:length(compressedVid)
    frameBytes = readmatrix(compressedVid(vid));
    frameBytes = frameBytes(~isnan(frameBytes));
    
    N = length(frameBytes);
    frameRate = 30;             % we set as 30 fps
    
    %% Settings
    avgBytes = mean(frameBytes);
    rateFactor = 0.25:0.25:2;
    startupFrameOptions = [15 30 60];
    
    T_values = rateFactor * avgBytes;       % find transmission rate, T values
    
    %% initialise storage arrays
    numUnderflows = zeros(length(rateFactor), length(startupFrameOptions));
    maxEncoderBufferStore = zeros(length(rateFactor), length(startupFrameOptions));
    encoderDelayFramesStore = zeros(length(rateFactor), length(startupFrameOptions));
    startupDelaySecondsStore = zeros(length(rateFactor), length(startupFrameOptions));
    
    %% Main simulation
    resultsTable = table();
    
    for i = 1:length(rateFactor)
        currentT = T_values(i);
        for s = 1:length(startupFrameOptions)
    
            startupFrames = startupFrameOptions(s);
    
            %% Encoder buffer simulation
            encoderBuffer = zeros(N,1);
            qEnc = 0;
    
            for j = 1:N
                qEnc = qEnc + frameBytes(j) - currentT;
    
                if qEnc < 0
                    qEnc = 0;
                end
    
                encoderBuffer(j) = qEnc;
            end
            % find maximum buffer capacity of encoder
            maxEncoderBuffer = max(encoderBuffer);       
            % calculate the frames delayed due to queueing
            encoderDelayFrames = maxEncoderBuffer / currentT;
            % Convert frames delayed to seconds dleyad using
            % framerate
            encoderDelaySeconds = encoderDelayFrames / frameRate;
    
            %% Decoder buffer simulation
            decoderBuffer = zeros(N,1);
            underflow = zeros(N,1);
            % initialise the decoder buffer size based on the startup frames size set
            qDec = startupFrames * currentT;
    
            for j = 1:N
                qDec = qDec + currentT;
    
                if j > startupFrames
                    qDec = qDec - frameBytes(j);
                end
    
                if qDec < 0
                    underflow(j) = 1;
                    qDec = 0;
                end
    
                decoderBuffer(j) = qDec;
            end
            % Calculate the delays and underflows occur at a given startup frame
            underflowCount = sum(underflow);
            numUnderflows(i,s) = underflowCount;
            % Decoder delay = Startup Frames / frame rate
            startupDelaySeconds = startupFrames / frameRate;

            totalDelaySeconds = encoderDelaySeconds + startupDelaySeconds;
    
            newRow = table(rateFactor(i), round(currentT), startupFrames, round(maxEncoderBuffer), ...
                startupDelaySeconds, round(encoderDelaySeconds,3),round(totalDelaySeconds,3),underflowCount, ...
                'VariableNames', {'RateFactor','T_Rate','StartupFrames','MaxEncoderBufferCap', ...
                    'StartupDelay (s)', ...
                    'EncoderDelay (s)', ...
                    'TotalDelay_Seconds', ...
                    'DecoderUnderflows' ...
                } ...
            );
    
            resultsTable = [resultsTable; newRow];
    
        end
    end
    
    %% save tables
    if (vid == 1)
        writetable(resultsTable, "happy_tree_table_results.xlsx");
    end
    if (vid == 2)
        writetable(resultsTable, "tron_legacy_table_results.xlsx");
    end
end 