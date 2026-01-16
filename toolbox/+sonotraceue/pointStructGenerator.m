function pointStruct = pointStructGenerator(dataReflectedPoint, numberOfEmitters, numberOfReceivers, numberOfFrequencies)

    pointStruct.index = -1;
    pointStruct.location = [0 0 0];
    pointStruct.reflectionDirection = [0 0 0];
    pointStruct.summedStrength = 0;
    pointStruct.totalDistance = 0;
    pointStruct.totalDistancesFromEmitters = [];
    pointStruct.distanceToSensor = 0;
    pointStruct.objectTypeIndex = -1;
    pointStruct.curvatureMagnitude = 0;
    pointStruct.isHit = false;
    pointStruct.isLastHit = false;
    pointStruct.strengths = [];
    pointStruct.totalDistanceToReceivers = [];
    pointStruct.isSpecular = true;
    pointStruct.isDiffraction = false;
    pointStruct.isDirectPath = false;
    pointStruct.rayIndex = 0;
    pointStruct.bounceIndex = 0;
    pointStruct.label = "UNKNOWN";
    pointStruct.emitterDirectivities = [];

    if nargin > 1 
        if ~isempty(dataReflectedPoint)
            % Location (FVector - 3 doubles)
            pointStruct.location = typecast(swapbytes(typecast(dataReflectedPoint(1:24), 'uint8')), 'double');
            pointStruct.location = pointStruct.location / 100;
            pointStruct.location(2) = -pointStruct.location(2);
        
            % ReflectionDirection (FVector - 3 doubles)
            pointStruct.reflectionDirection = typecast(swapbytes(typecast(dataReflectedPoint(25:48), 'uint8')), 'double');
            pointStruct.reflectionDirection(2) = -pointStruct.reflectionDirection(2);
        
            % Index (int32)
            pointStruct.index = typecast(swapbytes(typecast(dataReflectedPoint(49:52), 'uint8')), 'int32');
        
            % SummedStrength (float)
            pointStruct.summedStrength = typecast(swapbytes(typecast(dataReflectedPoint(53:56), 'uint8')), 'single');
        
            % TotalDistance (float)
            pointStruct.totalDistance = typecast(swapbytes(typecast(dataReflectedPoint(57:60), 'uint8')), 'single') / 100;

            % Total Distances from emitter count (int32)
            totalDistancesFromEmitterCount = typecast(swapbytes(typecast(dataReflectedPoint(61:64), 'uint8')), 'int32');            
        
            % TotalDistancesFromEmitters (TArray<float> - numberOfEmitters floats)                
            if totalDistancesFromEmitterCount > 0
                totalDistancesFromEmittersStartByte = 64 + 1;
                totalDistancesFromEmittersEndByte = totalDistancesFromEmittersStartByte + totalDistancesFromEmitterCount * 4 - 1;
                pointStruct.totalDistancesFromEmitters = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersStartByte:totalDistancesFromEmittersEndByte), 'uint8')), 'single')' / 100;
            else
                totalDistancesFromEmittersEndByte = 64;
            end

            % DistanceToSensor (float)
            pointStruct.distanceToSensor = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 1:totalDistancesFromEmittersEndByte + 4), 'uint8')), 'single') / 100;
        
            % ObjectTypeIndex (int32)
            pointStruct.objectTypeIndex = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 5:totalDistancesFromEmittersEndByte + 8), 'uint8')), 'int32');
        
            % CurvatureMagnitude (float)
            pointStruct.curvatureMagnitude = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 9:totalDistancesFromEmittersEndByte + 12), 'uint8')), 'single');
        
            % IsHit (bool - 4 bytes)
            pointStruct.isHit = logical(typecast(swapbytes(dataReflectedPoint(totalDistancesFromEmittersEndByte + 13:totalDistancesFromEmittersEndByte + 16)), 'int32'));
            
            % IsLastHit (bool - 4 bytes)
            pointStruct.isLastHit = logical(typecast(swapbytes(dataReflectedPoint(totalDistancesFromEmittersEndByte + 17:totalDistancesFromEmittersEndByte + 20)), 'int32'));
        
            % isSpecular (bool - 4 bytes)
            pointStruct.isSpecular = logical(typecast(swapbytes(dataReflectedPoint(totalDistancesFromEmittersEndByte + 21:totalDistancesFromEmittersEndByte + 24)), 'int32'));
        
            % isDiffraction (bool - 4 bytes)
            pointStruct.isDiffraction = logical(typecast(swapbytes(dataReflectedPoint(totalDistancesFromEmittersEndByte + 25:totalDistancesFromEmittersEndByte + 28)), 'int32'));
        
            % isDirectPath (bool - 4 bytes)
            pointStruct.isDirectPath = logical(typecast(swapbytes(dataReflectedPoint(totalDistancesFromEmittersEndByte + 29:totalDistancesFromEmittersEndByte + 32)), 'int32'));
        
            % rayIndex (int32 - 4 bytes)
            pointStruct.rayIndex = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 33:totalDistancesFromEmittersEndByte + 36), 'uint8')), 'int32');

            % bounceIndex (int32 - 4 bytes)
            pointStruct.bounceIndex = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 37:totalDistancesFromEmittersEndByte + 40), 'uint8')), 'int32');
        
            % emitterDirectivities Count (int32)
            emitterDirectivityCount = typecast(swapbytes(typecast(dataReflectedPoint(totalDistancesFromEmittersEndByte + 41:totalDistancesFromEmittersEndByte + 44), 'uint8')), 'int32');            
        
            % emitterDirectivities (TArray<float> - numberOfEmitters floats)                
            if emitterDirectivityCount > 0
                emitterDirectivitiesStartByte = totalDistancesFromEmittersEndByte + 44 + 1;
                emitterDirectivitiesEndByte = emitterDirectivitiesStartByte + emitterDirectivityCount * 4 - 1;
                pointStruct.emitterDirectivities = typecast(swapbytes(typecast(dataReflectedPoint(emitterDirectivitiesStartByte:emitterDirectivitiesEndByte), 'uint8')), 'single')';
            else
                emitterDirectivitiesEndByte = totalDistancesFromEmittersEndByte + 44;
            end

            % Strengths (TArray<TArray<TArray<float>>> - numberOfEmitters x numberOfReceivers x numberOfFrequencies floats)
            strengthsStartByte = emitterDirectivitiesEndByte + 1;
            strengthsEndByte = strengthsStartByte + numberOfEmitters * numberOfReceivers * numberOfFrequencies * 4 -1;
            pointStruct.strengths = permute(reshape(typecast(swapbytes(typecast(dataReflectedPoint(strengthsStartByte:strengthsEndByte), 'uint8')), 'single'), numberOfFrequencies, numberOfReceivers, numberOfEmitters), [3, 2, 1]);
            
            % TotalDistanceToReceivers (TArray<TArray<float>> - numberOfEmitters x numberOfReceivers floats)
            totalDistanceStartByte = strengthsEndByte + 1;
            totalDistanceEndByte = totalDistanceStartByte + numberOfEmitters * numberOfReceivers * 4 -1;
            pointStruct.totalDistanceToReceivers = reshape(typecast(swapbytes(typecast(dataReflectedPoint(totalDistanceStartByte:totalDistanceEndByte), 'uint8')), 'single'), numberOfReceivers, numberOfEmitters)' / 100;
        
            decodedString = native2unicode(dataReflectedPoint(totalDistanceEndByte + 1 : end), 'UTF-8');
            decodedString = strtrim(decodedString);
            pointStruct.label = decodedString;
        end
    end
end

