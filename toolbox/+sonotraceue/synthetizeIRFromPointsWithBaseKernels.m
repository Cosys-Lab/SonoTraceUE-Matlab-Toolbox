function impulseResponses = synthetizeIRFromPointsWithBaseKernels(reflectedPoints, sampleRate, ...
                                                                 numberOfSamplesIRFilter, frequencies, ...
                                                                 numberOfIRSamples, ...
                                                                 numberOfEmitters, ...
                                                                 numberOfReceivers, ...
                                                                 approximateIRCutDB, ...
                                                                 enableApproximateIR, ...
                                                                 speedOfSound, ...
                                                                 baseKernels)

 
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
                    curTime = curDistance / speedOfSound;
                    curSample = round(curTime * sampleRate);
    
                    if numberOfReceivers ~= 1
                        curStrengths = squeeze(reflectedStrengths(idxsPointsApprox(cntHitsApprox), :, :));
                    else
                        curStrengths = squeeze(reflectedStrengths(idxsPointsApprox(cntHitsApprox), :))';
                    end  
                    IRFilterImpresp = baseKernels * curStrengths;
                    
                    for receiverIndex = 1 : numberOfReceivers
                        curSplStart = max(1, curSample(receiverIndex) - numberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + numberOfSamplesIRFilter - 1, numberOfIRSamples);                        
                        if curSplStart < numberOfIRSamples
                            len = curSplStop - curSplStart + 1;      
                            valToAdd = reshape(IRFilterImpresp(1:len, receiverIndex), 1, 1, len);
                            impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) = impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) + valToAdd;
                        end
                    end 
                end
            else
                for cntHits = 1 : pointCount
                    curDistance = distancesReflected(cntHits, :);
                    curTime = curDistance / speedOfSound;
                    curSample = round(curTime * sampleRate);

                    if numberOfReceivers ~= 1
                        curStrengths = squeeze(reflectedStrengths(cntHits, :, :));
                    else
                        curStrengths = reflectedStrengths(cntHits, :)';
                    end
                    IRFilterImpresp = baseKernels * curStrengths;

                    for receiverIndex = 1 : numberOfReceivers
                        curSplStart = max(1, curSample(receiverIndex) - numberOfSamplesIRFilter / 2);
                        curSplStop = min(curSplStart + numberOfSamplesIRFilter - 1, numberOfIRSamples);                        
                        if curSplStart < numberOfIRSamples
                            len = curSplStop - curSplStart + 1;  
                            valToAdd = reshape(IRFilterImpresp(1:len, receiverIndex), 1, 1, len);
                            impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) = impulseResponses(emitterIndex, receiverIndex, curSplStart:curSplStop) + valToAdd;
                        end
                    end
                end
            end
        end
    end
end