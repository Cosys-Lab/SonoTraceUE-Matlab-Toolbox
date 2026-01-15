function impulseResponses = synthetizeIRFromPoints(reflectedPoints, sampleRate, ...
                                                   numberOfSamplesIRFilter, frequencies, ...
                                                   iRFilterGaussAlpha, ...
                                                   numberOfIRSamples, ...
                                                   numberOfEmitters, ...
                                                   numberOfReceivers, ...
                                                   approximateIRCutDB, ...
                                                   enableApproximateIR, ...
                                                   speedOfSound)

    freqVecIRFilter = (0 : numberOfSamplesIRFilter - 1) * (single(sampleRate) / numberOfSamplesIRFilter);
    windowsGaussianFilter = gausswin(numberOfSamplesIRFilter, iRFilterGaussAlpha);
    IRFilterFreqDomPhase = exp(-1i * linspace(0, 0*pi, numberOfSamplesIRFilter));           
    impulseResponses = zeros(numberOfEmitters, numberOfReceivers, numberOfIRSamples);

    pointCount = size(reflectedPoints, 1);
    if pointCount > 0
        distancesReflectedTotal = cat(3, reflectedPoints.totalDistanceToReceivers); 
        strengthsTotal = cat(4, reflectedPoints.strengths);
        for emitterIndex = 1 : numberOfEmitters     
            reflectedStrengths = permute(strengthsTotal(emitterIndex, :, :, :), [4, 2, 3, 1]);
            if numberOfReceivers > 1
                distancesReflected = squeeze(distancesReflectedTotal(emitterIndex, :, :))'; 
                reflectedStrengths = permute(reflectedStrengths, [1, 3, 2]);   
            else
               distancesReflected = squeeze(distancesReflectedTotal(emitterIndex, :, :)); 
            end
            if enableApproximateIR
                energyReflectedNormed = sonotraceue.normLog(sum(sum(reflectedStrengths .^ 2, 2), 3), approximateIRCutDB);
                idxsPointsApprox = find(energyReflectedNormed > (approximateIRCutDB + 1));
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
                        curSplStart = max(0, curSample( receiverIndex) - numberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + numberOfSamplesIRFilter - 1, numberOfIRSamples);
                        if curSplStart < numberOfIRSamples
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
                        curSplStart = max(1, curSample(receiverIndex) - numberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + numberOfSamplesIRFilter - 1, numberOfIRSamples);
                        if curSplStart < numberOfIRSamples
                            impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) = squeeze(impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop)) + IRFilterImpresp(1:curSplStop-curSplStart + 1, receiverIndex);
                        end
                   end    
                end
            end
        end
    end
end