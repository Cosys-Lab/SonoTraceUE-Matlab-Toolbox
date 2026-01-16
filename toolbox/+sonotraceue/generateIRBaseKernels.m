function baseKernels = generateIRBaseKernels(settings, iRFilterGaussAlpha, numberOfSamplesIRFilter)
    sampleRate = settings.sampleRate;
    frequencies = settings.frequencies; 
    numberOfSimFrequencies = length(frequencies);

    freqVecIRFilter = (0 : numberOfSamplesIRFilter - 1) * (single(sampleRate) / numberOfSamplesIRFilter);
    windowsGaussianFilter = gausswin(numberOfSamplesIRFilter, iRFilterGaussAlpha);
    IRFilterFreqDomPhase = exp(-1i * linspace(0, 0*pi, numberOfSamplesIRFilter));

    baseKernels = zeros(numberOfSamplesIRFilter, numberOfSimFrequencies);

    for fIndex = 1 : numberOfSimFrequencies
        dummyStrengths = zeros(1, numberOfSimFrequencies);
        dummyStrengths(fIndex) = 1.0;

        IRFilterFreqDomMagnitude = interp1(frequencies, dummyStrengths, freqVecIRFilter, 'linear', 0);      
        IRFilterFreqDom = IRFilterFreqDomMagnitude(:) .* IRFilterFreqDomPhase(:);
        IRFilterImpresp = fftshift(ifft(IRFilterFreqDom, [], 1, 'symmetric'), 1);
        IRFilterImpresp = IRFilterImpresp .* windowsGaussianFilter;
        baseKernels(:, fIndex) = IRFilterImpresp;
    end    
end