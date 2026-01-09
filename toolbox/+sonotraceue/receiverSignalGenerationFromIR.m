function receiverSignals = receiverSignalGenerationFromIR(impulseResponses, emitterSignals, emitterSignalIndexes)
    iRSamplesCount = size(impulseResponses, 3);
    emitterCount = size(impulseResponses, 1);
    receiverCount = size(impulseResponses, 2);
    receiverSignals = zeros(iRSamplesCount, receiverCount);
    for emitterIndex = 1 : emitterCount
        emitterSignal = emitterSignals{emitterSignalIndexes(emitterIndex)};
        for receiverIndex = 1 : receiverCount
            irSimulated = squeeze(impulseResponses(emitterIndex, receiverIndex, :));
            irSimulated = conv(irSimulated, emitterSignal, 'same');
            irSimulated = circshift(irSimulated, round(length(emitterSignal) / 2));
            irSimulated([1 : round(length(emitterSignal) / 2), end + round(length(emitterSignal) / 2) + 1 : end]) = 0;
            receiverSignals(:, receiverIndex) = receiverSignals(:, receiverIndex) + irSimulated;
        end
    end
    receiverSignals = receiverSignals';
end