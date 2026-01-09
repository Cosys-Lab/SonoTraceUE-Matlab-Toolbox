function impulseResponses = synthetizeIRFromPoints(reflectedPoints, sampleRate, ...
                                                   NumberOfSamplesIRFilter, frequencies, ...
                                                   IRFilterGaussAlpha, ...
                                                   NumberOfIRSamples, ...
                                                   numberOfEmitters, ...
                                                   numberOfReceivers, ...
                                                   ApproximateIRCutDB, ...
                                                   EnableApproximateIR, ...
                                                   speedOfSound)

    freqVecIRFilter = (0 : NumberOfSamplesIRFilter - 1) * (single(sampleRate) / NumberOfSamplesIRFilter);
    windowsGaussianFilter = gausswin(NumberOfSamplesIRFilter, IRFilterGaussAlpha);
    IRFilterFreqDomPhase = exp(-1i * linspace(0, 0*pi, NumberOfSamplesIRFilter));           
    impulseResponses = zeros(numberOfEmitters, numberOfReceivers, NumberOfIRSamples);

    pointCount = size(reflectedPoints, 1);
    if pointCount > 0
        for emitterIndex = 1 : numberOfEmitters
            distancesReflected = cat(3, reflectedPoints.totalDistanceToReceivers); 
            if numberOfReceivers == 1
                distancesReflected = squeeze(distancesReflected(emitterIndex, :, :)); 
                reflectedStrengths = zeros(pointCount, size(frequencies, 2), numberOfReceivers);
                for pointIndex = 1 : pointCount
                    reflectedStrengths(pointIndex, :, :) = squeeze(reflectedPoints(pointIndex).strengths(emitterIndex, :, :)); 
                end
            else
                distancesReflected = squeeze(distancesReflected(emitterIndex, :, :))'; 
                reflectedStrengths = zeros(pointCount, size(frequencies, 2), numberOfReceivers);
                for pointIndex = 1 : pointCount
                    reflectedStrengths(pointIndex, :, :) = squeeze(reflectedPoints(pointIndex).strengths(emitterIndex, :, :))'; 
                end
            end
            if EnableApproximateIR
                energyReflectedNormed = sonotraceue.normLog(sum(sum(reflectedStrengths .^ 2, 2), 3), ApproximateIRCutDB);
                idxsPointsApprox = find(energyReflectedNormed > (ApproximateIRCutDB + 1));
                numHitsApprox = size(idxsPointsApprox, 1);
                for cntHitsApprox = 1 : numHitsApprox
                    curDistance = distancesReflected(idxsPointsApprox(cntHitsApprox), :);
                     if numberOfReceivers ~= 1
                        curStrengths = squeeze(reflectedStrengths(idxsPointsApprox(cntHitsApprox), :, :));
                     else
                        curStrengths = squeeze(reflectedStrengths(idxsPointsApprox(cntHitsApprox), :))';
                     end                    
                    curTime = curDistance / speedOfSound;
                    curSample = round(curTime * sampleRate);
            
                    IRFilterFreqDomMagnitude = interp1(frequencies, curStrengths, freqVecIRFilter, 'linear', 0);

                    if numberOfReceivers ~= 1
                        IRFilterFreqDom = IRFilterFreqDomMagnitude .* IRFilterFreqDomPhase(:);
                        IRFilterImpresp = fftshift(ifft(IRFilterFreqDom, [], 1, 'symmetric'), 1);
                        IRFilterImpresp = IRFilterImpresp .* windowsGaussianFilter;
                    else
                        IRFilterFreqDom = IRFilterFreqDomMagnitude .* IRFilterFreqDomPhase(:);
                        IRFilterImpresp = fftshift(ifft(IRFilterFreqDom, [], 1, 'symmetric'), 1);
                        IRFilterImpresp = IRFilterImpresp .* windowsGaussianFilter;
                    end
                    for receiverIndex = 1 : numberOfReceivers
                        curSplStart = max(0, curSample( receiverIndex) - NumberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + NumberOfSamplesIRFilter - 1, NumberOfIRSamples);
                        if curSplStart < NumberOfIRSamples
                            impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) = squeeze(impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop))  + IRFilterImpresp(:, receiverIndex);
                        end
                   end        
                end
            else
                for cntHits = 1 : pointCount
                    curDistance = distancesReflected(cntHits, :);
                    if numberOfReceivers ~= 1
                        curStrengths = squeeze(reflectedStrengths(cntHits, :, :));
                    else
                        curStrengths = reflectedStrengths(cntHits, :)';
                    end
                    curTime = curDistance / speedOfSound;
                    curSample = round(curTime * sampleRate);
            

                    if numberOfReceivers ~= 1
                        IRFilterFreqDomMagnitude = interp1(frequencies, curStrengths, freqVecIRFilter, 'linear', 0);
                        IRFilterFreqDom = IRFilterFreqDomMagnitude .* IRFilterFreqDomPhase(:);
                        IRFilterImpresp = fftshift(ifft(IRFilterFreqDom, [], 1, 'symmetric'), 1);
                        IRFilterImpresp = IRFilterImpresp .* windowsGaussianFilter;
                    else
                        IRFilterFreqDomMagnitude = interp1(frequencies, curStrengths, freqVecIRFilter, 'linear', 0)';
                        IRFilterFreqDom = IRFilterFreqDomMagnitude .* IRFilterFreqDomPhase(:);
                        IRFilterImpresp = fftshift(ifft(IRFilterFreqDom, [], 1, 'symmetric'), 1);
                        IRFilterImpresp = IRFilterImpresp .* windowsGaussianFilter;
                    end
                    for receiverIndex = 1 : numberOfReceivers
                        curSplStart = max(1, curSample(receiverIndex) - NumberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + NumberOfSamplesIRFilter - 1, NumberOfIRSamples);
                        if curSplStart < NumberOfIRSamples
                            impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) = squeeze(impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop)) + IRFilterImpresp(1:curSplStop-curSplStart + 1, receiverIndex);
                        end
                   end    
                end
            end
        end
    end
end