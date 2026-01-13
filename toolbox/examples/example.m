% This example works best with the Default level of the sample Unreal Engine project of SonoTraceUE

close all
clear all

sendInputSettings = false; % This is not supported yet 
sendAndReceiveTestDataMessage = true;
testTransforms = true;
interfaceIP = 'localhost';
interfacePort = 9099;
STUEInterface = sonotraceue.Interface(interfaceIP, interfacePort, sendInputSettings);

plotEnable = true;
plotSensor = true;
plotDirectPath = false;
plotReflectedPoints = true;
plotDbCutOff = 60;
plotLimitAroundSensor = false;

plotSpecularSeperate = false;
plotDiffractionSeperate = false;
plotDirectPathSeperate = false;

calculateIR = true;
calculateIRSeperate = false;
NumberOfSamplesIRFilter = 256;
IRFilterGaussAlpha = 5;
NumberOfIRSamples = 18000;
ApproximateIRCutDB = -90;
EnableApproximateIR = false;
plotFinalIR = true;

calculatefinalSignals = true;
plotFinalSignals = true;

settings = STUEInterface.receiveSettings();

pause(1)

if testTransforms
    disp("Sending new sensor relative transform...")
    translationMeters = [1; 0.5; 0.2];
    yawDegrees = 45; 
    rotationMatrix = rotz(yawDegrees);  
    relativeNewTForm = eye(4); 
    relativeNewTForm(1:3, 1:3) = rotationMatrix;
    relativeNewTForm(1:3, 4) = translationMeters; 
    STUEInterface.setNewSensorRelativeTransform(relativeNewTForm);
    
    pause(1)
end

if sendAndReceiveTestDataMessage
    disp("Sending message...")
    type = 3;
    order = [2, 2, 0, 0, 1, 1, 2, 1, 0]; % Float, Float, String, String, Int, Int, Float, Int, String
    strings = {'my test string', 'mY SeCoNd TeSt StRiNg', 'Extra String'};
    integers = [5, -2, 999];
    floats = [0.38392, -938.383, -1234.56];
    dataMessage = sonotraceue.DataMessage(type, order, strings, integers, floats);
    STUEInterface.SendDataMessage(dataMessage);
    
    pause(1)
    
    [data, type] = STUEInterface.receiveData();
    if type == 1
        measurement = data;
        warning("Received a measurement message out of order.")           
    elseif type == 0 || type == -1 || type == -2
        warning("Received a close message out of order.")     
    elseif type == 2
        dataMessage = data;    
    else
        warning("Unknown data type")
    end   
    disp("...Received message back! Parsing image...")
    
    numHorizontalPixels = dataMessage.integers(1);
    numVerticalPixels = dataMessage.integers(2);
    numPixels = numHorizontalPixels * numVerticalPixels;    
    rgbValues = dataMessage.integers(3:end);
    if length(rgbValues) ~= numPixels * 3
        error('The number of RGB values does not match the specified dimensions.');
    end
    imageMatrix = reshape(rgbValues, [3, numHorizontalPixels, numVerticalPixels]);
    imageMatrix = permute(imageMatrix, [3, 2, 1]);
    imageMatrix = imageMatrix / 255;
    figure;imshow(imageMatrix)
    title("Scene Capture data")
    pause(1)
end

receivingMeasurements = true;
while receivingMeasurements

    pause(1)
    disp("Triggering new measurement...")
    triggered = STUEInterface.triggerMeasurement();

    if triggered
        [data, type] = STUEInterface.receiveData();
    
        if type == 1
            measurement = data;

            disp("Received measurement #" + num2str(measurement.index) + ". Processing data and updating enabled plots...");

            if plotEnable
                measurement.updatePlot(plotSensor, plotReflectedPoints, plotDirectPath, false, false, plotDbCutOff, plotLimitAroundSensor)
            end
    
            if plotSpecularSeperate && measurement.isSpecularSubOutputSet()
                if settings.pointsInSensorFrame
                    measurement.specularSubOutput.updatePlot("Specular Only - Sensor Frame", plotDbCutOff)
                else
                    measurement.specularSubOutput.updatePlot("Specular Only - World Frame", plotDbCutOff)
                end
            end
    
            if plotDiffractionSeperate && measurement.isDiffractionSubOutputSet()
                if settings.pointsInSensorFrame
                    measurement.diffractionSubOutput.updatePlot("Diffraction Only - Sensor Frame", plotDbCutOff)
                else
                    measurement.diffractionSubOutput.updatePlot("Diffraction Only - World Frame", plotDbCutOff)
                end
            end

            if plotDirectPathSeperate && measurement.isDirectPathSubOutputSet()
                if settings.pointsInSensorFrame
                    measurement.directPathSubOutput.updatePlot("Direct Path Only - Sensor Frame", plotDbCutOff)
                else
                    measurement.directPathSubOutput.updatePlot("Direct Path Only - World Frame", plotDbCutOff)
                end
            end

            if calculateIR
                if calculateIRSeperate
                    measurement = measurement.synthetizeIRFromSubResultsPoints(settings, NumberOfSamplesIRFilter, IRFilterGaussAlpha, NumberOfIRSamples, ApproximateIRCutDB, EnableApproximateIR, false, true);
                else
                    measurement = measurement.synthetizeIRFromPoints(settings, NumberOfSamplesIRFilter, IRFilterGaussAlpha, NumberOfIRSamples, ApproximateIRCutDB, EnableApproximateIR, false);
                end
                if plotEnable
                    measurement.updatePlot(false, false, false, plotFinalIR, false, plotDbCutOff, plotLimitAroundSensor)
                end
            end
    
            if calculatefinalSignals && measurement.isImpulseResponsesSet()      
                measurement = measurement.receiverSignalGenerationFromIR(settings);               
                if plotEnable
                    measurement.updatePlot(false, false, false, false, plotFinalSignals, plotDbCutOff, plotLimitAroundSensor)
                end
            end
            disp("Frame completed. Press a key to continue...");
            pause
        elseif type == 0 || type == -1 || type == -2
            receivingMeasurements = false;
        elseif type == 2
            message = data;
            warning("Received a data message out of order.")
        else
            warning("Unknown data type")
            receivingMeasurements = false;
        end
    else
        warning("Could not trigger this time")
    end
end